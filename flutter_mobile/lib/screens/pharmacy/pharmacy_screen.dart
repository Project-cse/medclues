import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:qr_flutter/qr_flutter.dart';

import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';
import '../../services/payment_service.dart';
import '../../services/razorpay_checkout_service.dart';
import '../../utils/theme_context.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/pharmacy/pharmacy_corporate_ui.dart';

class PharmacyScreen extends ConsumerStatefulWidget {
  const PharmacyScreen({super.key});

  @override
  ConsumerState<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends ConsumerState<PharmacyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _loading = true;
  String? _error;
  
  List<Map<String, dynamic>> _prescriptions = [];
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _payments = [];

  // Search & Filters for "All Medicines"
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _catalogSearching = false;
  String _selectedCategory = 'All';
  String _selectedDisease = 'All';

  // Cart state management
  final Map<dynamic, int> _cart = {}; // medicineId -> quantity
  Map<String, dynamic>? _selectedStore;
  /// Default: retail home delivery (MedPlus-style). Pickup = hospital Rx counter.
  String _selectedDeliveryMode = 'delivery';
  String _selectedPaymentMethod = 'upi'; // upi | cod
  final TextEditingController _deliveryAddressController = TextEditingController();
  bool _placingOrder = false;
  List<Map<String, dynamic>> _nearbyPharmacies = [];

  int get _cartItemCount => _cart.values.fold(0, (sum, q) => sum + q);

  double get _cartTotalAmount {
    double total = 0.0;
    _cart.forEach((medId, qty) {
      final med = _catalogMedicines.firstWhere(
        (m) => (m['id'] == medId || m['_id'] == medId),
        orElse: () => {},
      );
      if (med.isNotEmpty) {
        final price = (med['price'] is num) ? (med['price'] as num).toDouble() : 0.0;
        total += price * qty;
      }
    });
    return total;
  }

  void _addToCart(Map<String, dynamic> item) {
    final id = item['id'] ?? item['_id'];
    if (id == null) return;
    setState(() {
      _cart[id] = (_cart[id] ?? 0) + 1;
    });
    AppSnackbar.showSuccess(
      context,
      '${item['name']} added to cart!',
    );
  }

  void _removeFromCart(Map<String, dynamic> item) {
    final id = item['id'] ?? item['_id'];
    if (id == null || !_cart.containsKey(id)) return;
    setState(() {
      if (_cart[id]! > 1) {
        _cart[id] = _cart[id]! - 1;
      } else {
        _cart.remove(id);
      }
    });
  }

  // Catalog data for "All Medicines" (live master catalog)
  List<Map<String, dynamic>> _catalogMedicines = [];
  List<String> _catalogCategories = const [];

  List<Map<String, dynamic>> _pharmaciesFromPrescriptions(
    List<Map<String, dynamic>> prescriptions,
  ) {
    final byId = <int, Map<String, dynamic>>{};
    for (final rx in prescriptions) {
      final list = (rx['pharmacies'] as List?) ?? const [];
      for (final raw in list) {
        if (raw is! Map) continue;
        final p = Map<String, dynamic>.from(raw);
        final id = p['id'] is int
            ? p['id'] as int
            : int.tryParse('${p['id'] ?? ''}');
        if (id == null) continue;
        byId.putIfAbsent(
          id,
          () => {
            'id': id,
            'name': p['name']?.toString() ?? 'Hospital pharmacy',
            'address': p['address']?.toString() ?? '',
            'status': (p['supportsPickup'] == false && p['supportsDelivery'] == false)
                ? 'Limited'
                : 'Hospital mapped',
            'phone': p['phone']?.toString() ?? '',
            'isInHouse': true,
            'supportsPickup': p['supportsPickup'] != false,
            'supportsDelivery': p['supportsDelivery'] == true,
          },
        );
      }
    }
    return byId.values.toList();
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tabs.dispose();
    _searchController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  Future<void> _searchCatalog(String query) async {
    final svc = ref.read(pharmacyServiceProvider);
    if (mounted) setState(() => _catalogSearching = true);
    try {
      final list = await svc.searchMedicines(query);
      final cats = await svc.getCatalogCategories().catchError((_) => _catalogCategories);
      if (!mounted) return;
      setState(() {
        _catalogMedicines = list;
        if (cats.isNotEmpty) _catalogCategories = cats;
        _catalogSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _catalogMedicines = [];
        _catalogSearching = false;
      });
    }
  }

  void _onCatalogSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchCatalog(value.trim());
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = ref.read(pharmacyServiceProvider);
      final results = await Future.wait([
        svc.getPrescriptions().catchError((_) => <Map<String, dynamic>>[]),
        svc.getOrders().catchError((_) => <Map<String, dynamic>>[]),
        svc.getPayments().catchError((_) => <Map<String, dynamic>>[]),
        svc.searchMedicines(_searchController.text).catchError((_) => <Map<String, dynamic>>[]),
        svc.getCatalogCategories().catchError((_) => <String>[]),
      ]);
      if (!mounted) return;
      final stores = _pharmaciesFromPrescriptions(results[0] as List<Map<String, dynamic>>);
      setState(() {
        _prescriptions = results[0] as List<Map<String, dynamic>>;
        _orders = results[1] as List<Map<String, dynamic>>;
        _payments = results[2] as List<Map<String, dynamic>>;
        _catalogMedicines = results[3] as List<Map<String, dynamic>>;
        _catalogCategories = results[4] as List<String>;
        _nearbyPharmacies = stores;
        if (_selectedStore == null ||
            stores.every((s) => s['id'] != _selectedStore?['id'])) {
          _selectedStore = stores.isNotEmpty ? stores.first : null;
        }
        if (_selectedCategory != 'All' &&
            !_catalogCategories.contains(_selectedCategory)) {
          _selectedCategory = 'All';
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Color _softTint(Color base, {double light = 0.12, double dark = 0.28}) {
    return base.withValues(alpha: context.isDark ? dark : light);
  }

  Widget _medImagePlaceholder({double width = 80, double height = 80}) {
    return Container(
      width: width,
      height: height,
      color: _softTint(AppColors.primary, light: 0.1, dark: 0.22),
      child: const Icon(Icons.medication, color: AppColors.primary),
    );
  }

  Widget _buildMedicineImage(String? imageStr, {double width = 80, double height = 80}) {
    if (imageStr == null || imageStr.trim().isEmpty) {
      return _medImagePlaceholder(width: width, height: height);
    }

    final trimmed = imageStr.trim();
    if (trimmed.startsWith('data:image/') || trimmed.startsWith('data:;base64,')) {
      try {
        final base64Data = trimmed.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _medImagePlaceholder(width: width, height: height),
        );
      } catch (_) {
        return _medImagePlaceholder(width: width, height: height);
      }
    }

    return Image.network(
      trimmed,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          _medImagePlaceholder(width: width, height: height),
    );
  }

  int? _asInt(dynamic v) => v is int ? v : int.tryParse('$v');

  void _showStoreSelectorDialog() {
    if (_nearbyPharmacies.isEmpty) {
      AppSnackbar.showError(
        context,
        AppLocalizations.of(context)!.pharmacyNoMapped,
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.storefront, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Fulfilling Pharmacy Store'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select which pharmacy store will fulfill and deliver your medicine order:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            ..._nearbyPharmacies.map((store) {
              final isSelected = store['id'] == _selectedStore?['id'];
              final status = (store['status'] ?? '').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : Border.all(color: context.borderColor),
                  color: isSelected ? _softTint(AppColors.primary) : null,
                ),
                child: ListTile(
                  leading: Icon(
                    store['isInHouse'] == true ? Icons.local_hospital : Icons.store,
                    color: isSelected ? AppColors.primary : context.iconMuted,
                  ),
                  title: Text(
                    store['name']?.toString() ?? 'Pharmacy',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                      color: isSelected ? context.primaryText : null,
                    ),
                  ),
                  subtitle: Text(
                    status.isEmpty ? 'Hospital mapped pharmacy' : status,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? context.secondaryText : null,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedStore = store;
                    });
                    Navigator.pop(ctx);
                    AppSnackbar.showSuccess(
                      context,
                      'Fulfilling store updated to ${store['name']}',
                    );
                  },
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openCartCheckoutSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final cartItems = _cart.entries.map((entry) {
              final med = _catalogMedicines.firstWhere(
                (m) => m['id'] == entry.key || m['_id'] == entry.key,
                orElse: () => {'id': entry.key, 'name': 'Medicine Item', 'price': 0.0},
              );
              return {'med': med, 'qty': entry.value};
            }).toList();

            final hasRxItems = cartItems.any((item) {
              final med = item['med'];
              if (med is! Map) return false;
              return med['requiresRx'] == true;
            });
            final isHospitalPickup = _selectedDeliveryMode == 'pickup';
            final isHomeDelivery = !isHospitalPickup;
            final subtotal = _cartTotalAmount;
            final deliveryFee =
                isHomeDelivery ? (subtotal > 500 ? 0.0 : 29.0) : 0.0;
            final grandTotal = subtotal + deliveryFee;
            final cs = Theme.of(context).colorScheme;

            Widget scenarioCard({
              required bool selected,
              required IconData icon,
              required String title,
              required String subtitle,
              required VoidCallback onTap,
            }) {
              return Expanded(
                child: Material(
                  color: selected
                      ? AppColors.primary.withValues(alpha: context.isDark ? 0.28 : 0.12)
                      : (context.isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? AppColors.primary : context.borderColor,
                          width: selected ? 1.8 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : context.borderColor.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              icon,
                              size: 18,
                              color: selected ? AppColors.primary : context.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: context.primaryText,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(fontSize: 10.5, color: context.secondaryText, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.88,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: context.borderColor,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Checkout · ${_cartItemCount} item${_cartItemCount == 1 ? '' : 's'}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        children: [
                          Text(
                            'How would you like to receive medicines?',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: context.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              scenarioCard(
                                selected: isHomeDelivery,
                                icon: Icons.home_outlined,
                                title: 'Home delivery',
                                subtitle: 'Order like a pharmacy store · COD or UPI',
                                onTap: () {
                                  setSheetState(() {
                                    _selectedDeliveryMode = 'delivery';
                                  });
                                  setState(() {});
                                },
                              ),
                              const SizedBox(width: 10),
                              scenarioCard(
                                selected: isHospitalPickup,
                                icon: Icons.local_hospital_outlined,
                                title: 'Hospital counter',
                                subtitle: 'After doctor visit · pickup with Rx',
                                onTap: () {
                                  setSheetState(() {
                                    _selectedDeliveryMode = 'pickup';
                                  });
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _softTint(isHomeDelivery ? Colors.teal : Colors.indigo),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (isHomeDelivery ? Colors.teal : Colors.indigo)
                                    .withValues(alpha: 0.28),
                              ),
                            ),
                            child: Text(
                              isHomeDelivery
                                  ? 'Retail order — no prescription needed for regular medicines. Pay by UPI or Cash on Delivery.'
                                  : 'Hospital pharmacy counter — use this after your doctor ends the appointment with an e-prescription.',
                              style: TextStyle(fontSize: 12, height: 1.35, color: context.primaryText),
                            ),
                          ),
                          if (hasRxItems) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _softTint(Colors.amber, light: 0.18, dark: 0.22),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Some items need a prescription. Remove them for home delivery, or order from the Prescriptions tab.',
                                style: TextStyle(fontSize: 11.5, color: context.primaryText),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Text('Items', style: TextStyle(fontWeight: FontWeight.w700, color: context.primaryText)),
                          const SizedBox(height: 8),
                          ...cartItems.map((item) {
                            final med = item['med'] as Map<String, dynamic>;
                            final qty = item['qty'] as int;
                            final price = (med['price'] is num) ? (med['price'] as num).toDouble() : 0.0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: PharmacyUi.panel(context, elevated: false, radius: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: context.borderColor),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: _buildMedicineImage(med['image']?.toString(), width: 48, height: 48),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          med['name']?.toString() ?? 'Medicine',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                        ),
                                        Text(
                                          '₹${price.toStringAsFixed(2)} each',
                                          style: TextStyle(fontSize: 11.5, color: context.secondaryText),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PharmacyQtyStepper(
                                    qty: qty,
                                    onMinus: () {
                                      _removeFromCart(med);
                                      setSheetState(() {});
                                      setState(() {});
                                    },
                                    onPlus: () {
                                      _addToCart(med);
                                      setSheetState(() {});
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (isHomeDelivery) ...[
                            const SizedBox(height: 8),
                            Text('Delivery address', style: TextStyle(fontWeight: FontWeight.w700, color: context.primaryText)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _deliveryAddressController,
                              maxLines: 2,
                              onChanged: (_) => setSheetState(() {}),
                              decoration: InputDecoration(
                                hintText: 'House / flat, street, landmark, city, PIN',
                                filled: true,
                                fillColor: context.isDark ? const Color(0xFF222222) : Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text('Payment', style: TextStyle(fontWeight: FontWeight.w700, color: context.primaryText)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    selected: _selectedPaymentMethod == 'upi',
                                    label: const Text('UPI / Razorpay'),
                                    avatar: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                                    onSelected: (_) {
                                      setSheetState(() => _selectedPaymentMethod = 'upi');
                                      setState(() {});
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ChoiceChip(
                                    selected: _selectedPaymentMethod == 'cod',
                                    label: const Text('Cash on Delivery'),
                                    avatar: const Icon(Icons.payments_outlined, size: 16),
                                    onSelected: (_) {
                                      setSheetState(() => _selectedPaymentMethod = 'cod');
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.storefront, color: cs.primary),
                              title: Text(
                                _selectedStore?['name']?.toString() ??
                                    (_nearbyPharmacies.isNotEmpty
                                        ? _nearbyPharmacies.first['name']?.toString() ?? 'Hospital pharmacy'
                                        : 'Hospital pharmacy from your prescription'),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              subtitle: const Text('Counter pickup after Rx order is placed', style: TextStyle(fontSize: 11)),
                              trailing: TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showStoreSelectorDialog();
                                },
                                child: const Text('Change'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: PharmacyUi.panel(context, elevated: false, radius: 14),
                            child: Column(
                              children: [
                                _billRow(context, 'Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                                const SizedBox(height: 6),
                                _billRow(
                                  context,
                                  'Delivery',
                                  deliveryFee == 0 ? 'FREE' : '₹${deliveryFee.toStringAsFixed(2)}',
                                  valueColor: deliveryFee == 0 ? Colors.green : null,
                                ),
                                const Divider(height: 18),
                                _billRow(
                                  context,
                                  'Grand total',
                                  '₹${grandTotal.toStringAsFixed(2)}',
                                  bold: true,
                                  valueColor: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            onPressed: _placingOrder
                                ? null
                                : () {
                                    Navigator.pop(ctx);
                                    _placeCartOrder(
                                      grandTotal,
                                      deliveryFee: deliveryFee,
                                    );
                                  },
                            child: Text(
                              isHomeDelivery
                                  ? (_selectedPaymentMethod == 'cod'
                                      ? 'Place COD order · ₹${grandTotal.toStringAsFixed(2)}'
                                      : 'Pay with UPI · ₹${grandTotal.toStringAsFixed(2)}')
                                  : 'Place hospital counter order',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _billRow(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? context.primaryText : context.secondaryText,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            fontSize: bold ? 17 : 14,
            color: valueColor ?? context.primaryText,
          ),
        ),
      ],
    );
  }

  Future<void> _placeCartOrder(double totalAmount, {double deliveryFee = 0}) async {
    if (_cart.isEmpty) {
      AppSnackbar.showInfo(context, 'Your cart is empty.');
      return;
    }
    if (_placingOrder) return;
    setState(() => _placingOrder = true);

    try {
      // Scenario 1: Hospital counter — prescription-linked order
      if (_selectedDeliveryMode == 'pickup') {
        if (_prescriptions.isEmpty) {
          AppSnackbar.showError(
            context,
            'Hospital counter pickup needs an active doctor prescription. '
            'For normal medicines from home, choose Home delivery.',
          );
          _tabs.animateTo(1);
          return;
        }
        final rx = _prescriptions.first;
        final consultationId = _asInt(rx['consultationId']);
        final pharmacies = (rx['pharmacies'] as List?) ?? [];
        final selectedId = _asInt(_selectedStore?['id']);
        final pharmacyId = selectedId ??
            (pharmacies.isNotEmpty ? _asInt((pharmacies.first as Map)['id']) : null);
        if (consultationId == null || pharmacyId == null) {
          AppSnackbar.showError(context, 'No hospital pharmacy mapped for your prescription.');
          return;
        }
        final placed = await ref.read(pharmacyServiceProvider).placeOrder(
              consultationId: consultationId,
              pharmacyId: pharmacyId,
              fulfillment: 'pickup',
              notes: 'Hospital counter · cart ₹$totalAmount',
            );
        if (!mounted) return;
        setState(() {
          _orders.insert(0, placed);
          _cart.clear();
        });
        AppSnackbar.showSuccess(
          context,
          'Counter order placed. Show the pickup QR at the hospital pharmacy.',
        );
        _tabs.animateTo(2);
        await _load();
        if (!mounted) return;
        if ((placed['publicId'] ?? '').toString().toUpperCase().startsWith('PHO')) {
          await _showQrDialog(placed);
        }
        return;
      }

      // Scenario 2: Retail home delivery — no prescription required
      final address = _deliveryAddressController.text.trim();
      if (address.length < 8) {
        AppSnackbar.showError(context, 'Enter a complete delivery address to continue.');
        _openCartCheckoutSheet();
        return;
      }

      final items = <Map<String, dynamic>>[];
      for (final entry in _cart.entries) {
        final med = _catalogMedicines.firstWhere(
          (m) => m['id'] == entry.key || m['_id'] == entry.key,
          orElse: () => {},
        );
        if (med.isEmpty) continue;
        if (med['requiresRx'] == true) {
          AppSnackbar.showError(
            context,
            '${med['name']} needs a prescription. Remove it or order from Prescriptions.',
          );
          return;
        }
        items.add({
          'name': med['name'],
          'quantity': entry.value,
          'unitPrice': med['price'],
          'medicineId': med['id'] ?? med['_id'],
          'salt': med['salt'],
          'requiresRx': false,
        });
      }
      if (items.isEmpty) {
        AppSnackbar.showError(context, 'Could not build order items from cart.');
        return;
      }

      final placed = await ref.read(pharmacyServiceProvider).placeCatalogOrder(
            items: items,
            fulfillment: 'delivery',
            paymentMethod: _selectedPaymentMethod,
            deliveryAddress: address,
            pharmacyId: _asInt(_selectedStore?['id']),
            deliveryFee: deliveryFee,
          );
      if (!mounted) return;

      setState(() {
        _orders.insert(0, placed);
        _cart.clear();
      });

      final needsPay = placed['requiresPayment'] == true ||
          (_selectedPaymentMethod == 'upi' &&
              '${placed['status'] ?? ''}'.toLowerCase() == 'billed');

      if (needsPay) {
        AppSnackbar.showInfo(context, 'Order created. Opening secure UPI payment…');
        await _payPharmacyOrder(placed);
      } else {
        AppSnackbar.showSuccess(
          context,
          _selectedPaymentMethod == 'cod'
              ? 'COD order placed. Pay when medicines arrive.'
              : 'Order placed successfully.',
        );
      }
      if (!mounted) return;
      _tabs.animateTo(2);
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  Future<void> _payPharmacyOrder(Map<String, dynamic> order) async {
    final orderId = _asInt(order['id']);
    if (orderId == null) {
      AppSnackbar.showError(context, 'Order id missing.');
      return;
    }
    try {
      final pay = await ref.read(pharmacyServiceProvider).createPayment(orderId);
      final key = (pay['razorpayKey'] ?? pay['key_id'] ?? '').toString();
      final rzOrderId = (pay['razorpayOrderId'] ?? pay['id'] ?? '').toString();
      final checkoutToken = (pay['checkoutToken'] ?? pay['checkout_token'] ?? '').toString();
      final amountPaise = (pay['amountPaise'] is num)
          ? (pay['amountPaise'] as num).toInt()
          : ((pay['amount'] is num) ? ((pay['amount'] as num) * 100).round() : 0);
      if (key.isEmpty || rzOrderId.isEmpty || amountPaise < 100) {
        throw Exception(pay['message']?.toString() ?? 'Could not start payment');
      }

      final paymentService = ref.read(paymentServiceProvider);
      final user = ref.read(authProvider).user;
      final useNativeCheckout = !kIsWeb;

      if (useNativeCheckout) {
        final checkout = RazorpayCheckoutService();
        try {
          final result = await checkout.openCheckout(
            key: key,
            orderId: rzOrderId,
            amountPaise: amountPaise,
            name: 'MedClues Pharmacy',
            description: 'Pharmacy order #$orderId',
            customerName: user?.name,
            customerEmail: user?.email,
            customerPhone: user?.phone,
          );
          await ref.read(pharmacyServiceProvider).verifyPayment(
                orderId: orderId,
                razorpayOrderId: result.orderId,
                razorpayPaymentId: result.paymentId,
                razorpaySignature: result.signature,
              );
        } finally {
          checkout.dispose();
        }
      } else {
        if (checkoutToken.isEmpty) {
          throw Exception('Checkout session missing. Please try again.');
        }
        final url = paymentService.checkoutUrl(checkoutToken);
        final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        if (!launched) {
          throw Exception('Could not open Razorpay checkout');
        }
        await _waitForPharmacyWebPayment(paymentService, rzOrderId, orderId);
      }

      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Payment successful.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _waitForPharmacyWebPayment(
    PaymentService paymentService,
    String razorpayOrderId,
    int pharmacyOrderId,
  ) async {
    final cancel = Completer<void>();
    final confirm = Completer<void>();
    var dialogOpen = false;

    if (mounted) {
      dialogOpen = true;
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('Complete payment'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Finish UPI / card payment in the Razorpay window, then tap I’ve paid.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (!cancel.isCompleted) cancel.complete();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!confirm.isCompleted) confirm.complete();
                  },
                  child: const Text("I've paid"),
                ),
              ],
            ),
          ),
        ).whenComplete(() => dialogOpen = false),
      );
    }

    try {
      final deadline = DateTime.now().add(const Duration(minutes: 5));
      while (DateTime.now().isBefore(deadline)) {
        if (cancel.isCompleted) throw Exception('Payment cancelled');
        if (!mounted) throw Exception('Payment cancelled');

        if (confirm.isCompleted) {
          final confirmed = await paymentService.confirmPaidOrder(razorpayOrderId);
          if (confirmed['success'] == true || confirmed['paid'] == true) {
            if (dialogOpen && mounted) Navigator.of(context, rootNavigator: true).pop();
            return;
          }
        }

        try {
          final status = await paymentService.getOrderStatus(razorpayOrderId);
          if (status['paid'] == true || status['status'] == 'paid') {
            await paymentService.confirmPaidOrder(razorpayOrderId);
            if (dialogOpen && mounted) Navigator.of(context, rootNavigator: true).pop();
            return;
          }
        } catch (_) {}

        await Future<void>.delayed(const Duration(seconds: 2));
      }
      throw Exception('Payment timed out. If money was deducted, open Orders and tap Pay bill.');
    } finally {
      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    }
  }

  Future<void> _orderMeds(Map<String, dynamic> rx) async {
    final pharmacies = (rx['pharmacies'] as List?) ?? [];
    if (pharmacies.isEmpty) {
      AppSnackbar.show(context, AppLocalizations.of(context)!.pharmacyNoMapped);
      return;
    }
    final consultationId = _asInt(rx['consultationId']);
    if (consultationId == null) return;

    final pharmacy = pharmacies.first as Map;
    final pharmacyId = _asInt(pharmacy['id']);
    if (pharmacyId == null) return;

    try {
      final placed = await ref.read(pharmacyServiceProvider).placeOrder(
            consultationId: consultationId,
            pharmacyId: pharmacyId,
            fulfillment: 'pickup',
          );
      if (!mounted) return;
      setState(() {
        _orders.insert(0, placed);
      });
      AppSnackbar.showSuccess(context, 'Prescription order sent to In-House Hospital Pharmacy!');
      _tabs.animateTo(2); // Switch to Orders tab
      await _load();
      if (!mounted) return;
      if ((placed['publicId'] ?? placed['public_id'] ?? '')
          .toString()
          .toUpperCase()
          .startsWith('PHO')) {
        await _showQrDialog(placed);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _showQrDialog(Map<String, dynamic> orderOrRx) async {
    final raw = (orderOrRx['publicId'] ?? orderOrRx['public_id'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    // Pickup QR must be real PHO… order public id (counter scan), never consultation id.
    if (!raw.startsWith('PHO')) {
      AppSnackbar.showError(
        context,
        'Pickup QR available after order is placed (PHO…). Open Orders tab.',
      );
      return;
    }
    final token = raw;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Hospital Pickup QR'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Show this QR at the hospital pharmacy counter to collect your order.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: token,
                size: 180,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              token,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'MedClues Pharmacy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _cartItemCount > 0,
              label: Text('$_cartItemCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            tooltip: 'View Cart',
            onPressed: () {
              if (_cartItemCount > 0) {
                _openCartCheckoutSheet();
              } else {
                AppSnackbar.showInfo(context, 'Your cart is empty. Add medicines to checkout.');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.medication), text: 'All Medicines'),
            Tab(icon: Icon(Icons.assignment), text: 'Prescriptions'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Orders'),
            Tab(icon: Icon(Icons.local_pharmacy), text: 'Nearby Stores'),
          ],
        ),
      ),
      bottomSheet: _cartItemCount > 0
          ? PharmacyStickyCartBar(
              itemCount: _cartItemCount,
              totalLabel: '₹${_cartTotalAmount.toStringAsFixed(2)}',
              subtitle: _selectedDeliveryMode == 'delivery'
                  ? (_selectedPaymentMethod == 'cod'
                      ? 'Home delivery · Cash on Delivery'
                      : 'Home delivery · Pay by UPI')
                  : 'Hospital counter · ${_selectedStore?['name'] ?? 'pharmacy'}',
              onCheckout: _openCartCheckoutSheet,
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildAllMedicinesTab(),
                  _buildPrescriptionsTab(),
                  _buildOrdersTab(),
                  _buildNearbyPharmaciesTab(),
                ],
              ),
            ),
    );
  }

  // 1️⃣ ALL MEDICINES TAB — Blinkit-style 2-column grid + detail sheet
  Widget _buildAllMedicinesTab() {
    final q = _searchController.text.toLowerCase().trim();
    final filtered = _catalogMedicines.where((item) {
      final matchesSearch = q.isEmpty ||
          item['name'].toString().toLowerCase().contains(q) ||
          item['brand'].toString().toLowerCase().contains(q) ||
          item['salt'].toString().toLowerCase().contains(q);
      final matchesCategory = _selectedCategory == 'All' ||
          item['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    final storeTitle = _selectedStore?['name']?.toString().isNotEmpty == true
        ? _selectedStore!['name'].toString()
        : 'Select pharmacy / delivery preference';
    final storeSubtitle = _selectedStore == null
        ? (_selectedDeliveryMode == 'delivery'
            ? 'Home delivery available · tap to change store'
            : 'Mapped from prescriptions when available')
        : ((_selectedStore!['address']?.toString().isNotEmpty ?? false)
            ? _selectedStore!['address'].toString()
            : 'Hospital mapped pharmacy');

    return ListView(
      padding: EdgeInsets.fromLTRB(14, 12, 14, _cartItemCount > 0 ? 110 : 24),
      children: [
        PharmacyStoreBanner(
          title: storeTitle,
          subtitle: storeSubtitle,
          onTap: _showStoreSelectorDialog,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          onChanged: _onCatalogSearchChanged,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search medicines, tablets, supplements…',
            hintStyle: TextStyle(color: context.secondaryText, fontSize: 13.5),
            prefixIcon: Icon(Icons.search, color: context.secondaryText),
            suffixIcon: _catalogSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (_searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onCatalogSearchChanged('');
                        },
                      )
                    : null),
            filled: true,
            fillColor: context.cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PharmacyUi.controlRadius),
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PharmacyUi.controlRadius),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PharmacyUi.controlRadius),
              borderSide: BorderSide(color: context.borderColor),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const PharmacySectionTitle('Shop by category'),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', ..._catalogCategories].map((cat) {
              return PharmacyCategoryChip(
                label: cat,
                selected: _selectedCategory == cat,
                onTap: () => setState(() => _selectedCategory = cat),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'No medicines found matching your search.',
                style: TextStyle(color: context.secondaryText),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (context, index) {
              final item = filtered[index];
              final id = item['id'] ?? item['_id'];
              final qty = _cart[id] ?? 0;
              final price = (item['price'] as num?)?.toDouble() ?? 0;
              final mrp = (item['mrp'] as num?)?.toDouble();
              final discount = (item['discount']?.toString() ?? '').trim();
              final showMrp = mrp != null && mrp > price;
              final stock = (item['stock'] is num) ? (item['stock'] as num).toInt() : 0;

              void openDetail() {
                showPharmacyProductDetail(
                  context: context,
                  item: item,
                  getQty: () => _cart[id] ?? 0,
                  image: _buildMedicineImage(item['image']?.toString(), width: 160, height: 160),
                  onAdd: () {
                    _addToCart(item);
                    setState(() {});
                  },
                  onMinus: () {
                    _removeFromCart(item);
                    setState(() {});
                  },
                  onPlus: () {
                    _addToCart(item);
                    setState(() {});
                  },
                );
              }

              return PharmacyProductCard(
                name: item['name']?.toString() ?? 'Medicine',
                brand: item['brand']?.toString() ?? '',
                salt: item['salt']?.toString() ?? '',
                category: item['category']?.toString() ?? 'General',
                priceLabel: '₹${price.toStringAsFixed(0)}',
                mrpLabel: showMrp ? '₹${mrp.toStringAsFixed(0)}' : null,
                discountLabel: discount.isNotEmpty ? discount : null,
                qty: qty,
                stock: stock,
                requiresRx: item['requiresRx'] == true,
                image: _buildMedicineImage(item['image']?.toString(), width: 110, height: 110),
                onOpen: openDetail,
                onAdd: () => _addToCart(item),
                onMinus: () => _removeFromCart(item),
                onPlus: () => _addToCart(item),
              );
            },
          ),
      ],
    );
  }

  void _showUploadCustomRxDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.camera_alt, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Upload Paper Prescription'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upload a clear photo or PDF of your doctor paper prescription. Our hospital pharmacist will verify and fulfill your order.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _softTint(Colors.blue),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withValues(alpha: context.isDark ? 0.35 : 0.25)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, size: 40, color: AppColors.primary),
                  SizedBox(height: 8),
                  Text(
                    'Tap to select photo or take picture',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppSnackbar.showError(
                context,
                'Paper prescription upload is not available yet. Use an in-app prescription to order.',
              );
            },
            child: const Text('Upload & Submit'),
          ),
        ],
      ),
    );
  }

  // 2️⃣ PRESCRIPTIONS TAB (Scenario A: Offline Visit 10m Counter Pickup vs Scenario B: Online Call 30m Home Delivery)
  Widget _buildPrescriptionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Upload Custom Rx Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: PharmacyUi.panel(context),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: context.isDark ? 0.22 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.note_add_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'External paper prescription?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: context.primaryText,
                      ),
                    ),
                    Text(
                      'Upload a photo to order medicines directly',
                      style: TextStyle(fontSize: 11.5, color: context.secondaryText),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: _showUploadCustomRxDialog,
                style: PharmacyUi.primaryButton(),
                child: const Text('Upload Rx'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_prescriptions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: Text(
                'No active hospital digital prescriptions.\nDoctor e-prescriptions appear here automatically after consultation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.secondaryText),
              ),
            ),
          )
        else
          ..._prescriptions.map((rx) {
            final items = (rx['items'] as List?) ?? [];
            final consultationType = rx['type'] ?? (rx['consultationId'] != null && _asInt(rx['consultationId'])! % 2 == 0 ? 'online' : 'offline');
            final isOffline = consultationType == 'offline' || consultationType == 'in_person';

            // Selected fulfillment mode for this prescription (defaults per Scenario A / B)
            final currentFulfillment = rx['selectedFulfillment'] ?? (isOffline ? 'pickup' : 'delivery');

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StatefulBuilder(
                builder: (context, setRxState) {
                  final isPickup = currentFulfillment == 'pickup';

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Consultation #${rx['consultationId'] ?? 'RX-9842'}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isOffline
                                      ? _softTint(Colors.teal)
                                      : _softTint(Colors.purple),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isOffline
                                        ? Colors.teal.withValues(alpha: 0.4)
                                        : Colors.purple.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  isOffline ? '🏥 Offline Visit' : '💻 Online Call',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isOffline
                                        ? (context.isDark ? Colors.teal.shade200 : Colors.teal.shade900)
                                        : (context.isDark ? Colors.purple.shade200 : Colors.purple.shade900),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isOffline
                                ? 'Scenario A: In-Person Hospital Visit (Ready in 10 mins)'
                                : 'Scenario B: Online Video Call (Express Home Delivery 30 mins)',
                            style: TextStyle(fontSize: 11, color: context.secondaryText),
                          ),
                          const Divider(height: 18),

                          if ((rx['prescriptionNotes'] as String?)?.isNotEmpty == true) ...[
                            Text(
                              'Doctor Notes: ${rx['prescriptionNotes']}',
                              style: TextStyle(color: context.secondaryText, fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 8),
                          ],
                          const Text(
                            'Prescribed Medicines:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          if (items.isNotEmpty)
                            ...items.map((it) {
                              final m = it as Map;
                              return Text(
                                '• ${m['name']}${m['dosage'] != null ? ' — ${m['dosage']}' : ''}',
                                style: const TextStyle(fontSize: 13),
                              );
                            }),
                          const SizedBox(height: 14),

                          // Interactive Fulfillment Selector Toggle
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.isDark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setRxState(() {
                                        rx['selectedFulfillment'] = 'pickup';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isPickup ? context.cardColor : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: isPickup
                                            ? [
                                                BoxShadow(
                                                  color: context.shadowColor,
                                                  blurRadius: 4,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: const Column(
                                        children: [
                                          Icon(Icons.storefront, size: 18, color: AppColors.primary),
                                          SizedBox(height: 2),
                                          Text(
                                            'Hospital Counter Pickup\n(10 Mins)',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setRxState(() {
                                        rx['selectedFulfillment'] = 'delivery';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: !isPickup ? context.cardColor : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: !isPickup
                                            ? [
                                                BoxShadow(
                                                  color: context.shadowColor,
                                                  blurRadius: 4,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: const Column(
                                        children: [
                                          Icon(Icons.two_wheeler, size: 18, color: Colors.purple),
                                          SizedBox(height: 2),
                                          Text(
                                            'Express Home Delivery\n(30 Mins)',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Action Buttons based on selection
                          if (isPickup) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.qr_code),
                                    label: const Text('Show Hospital Pickup QR'),
                                    onPressed: () {
                                      // QR only after a real PHO order exists — find matching order.
                                      final cid = rx['consultationId'];
                                      Map<String, dynamic>? match;
                                      for (final o in _orders) {
                                        if (o['consultationId'] == cid ||
                                            o['consultation_id'] == cid) {
                                          match = o;
                                          break;
                                        }
                                      }
                                      if (match != null) {
                                        _showQrDialog(match);
                                      } else {
                                        AppSnackbar.showError(
                                          context,
                                          'Place counter order first to get a PHO pickup QR.',
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    icon: const Icon(Icons.send),
                                    label: const Text('Order to Counter (10m)'),
                                    onPressed: () => _orderMeds(rx),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                icon: const Icon(Icons.local_shipping),
                                label: const Text('Confirm Express 30-Min Home Delivery'),
                                style: FilledButton.styleFrom(backgroundColor: Colors.purple.shade700),
                                onPressed: () async {
                                  final pharmacies = (rx['pharmacies'] as List?) ?? [];
                                  final consultationId = _asInt(rx['consultationId']);
                                  if (pharmacies.isEmpty || consultationId == null) {
                                    AppSnackbar.showError(
                                      context,
                                      'No pharmacy mapped for delivery.',
                                    );
                                    return;
                                  }
                                  final pharmacyId = _asInt((pharmacies.first as Map)['id']);
                                  if (pharmacyId == null) return;
                                  try {
                                    final placed = await ref
                                        .read(pharmacyServiceProvider)
                                        .placeOrder(
                                          consultationId: consultationId,
                                          pharmacyId: pharmacyId,
                                          fulfillment: 'delivery',
                                        );
                                    if (!mounted) return;
                                    setState(() => _orders.insert(0, placed));
                                    AppSnackbar.showSuccess(
                                      context,
                                      'Home delivery order placed. Track it under Orders.',
                                    );
                                    _tabs.animateTo(2);
                                    await _load();
                                  } catch (e) {
                                    if (!mounted) return;
                                    AppSnackbar.showError(
                                      context,
                                      e.toString().replaceFirst('Exception: ', ''),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
      ],
    );
  }

  Future<void> _downloadInvoice(dynamic orderId) async {
    final id = _asInt(orderId);
    if (id == null) return;
    try {
      final bytes = await ref.read(pharmacyServiceProvider).downloadInvoicePdf(id);
      await Printing.sharePdf(bytes: bytes, filename: 'invoice-$id.pdf');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _refillOrder(dynamic orderId) async {
    final id = _asInt(orderId);
    if (id == null) return;
    try {
      await ref.read(pharmacyServiceProvider).refillOrder(id);
      if (!mounted) return;
      AppSnackbar.show(context, '1-Click Monthly Refill placed successfully!');
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // 3️⃣ ORDERS TAB
  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(child: Text('No active medicine orders yet.')),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final o = _orders[i];
        final rawStatus = '${o['status'] ?? 'received'}'.toLowerCase();
        final status = rawStatus.replaceAll('_', ' ').toUpperCase();
        final total = o['amountTotal'];
        final orderId = o['id'];
        final pho = (o['publicId'] ?? o['public_id'] ?? '').toString().trim();
        final publicId = pho.toUpperCase().startsWith('PHO')
            ? pho.toUpperCase()
            : (pho.isNotEmpty ? pho : null);
        final isPickup = '${o['fulfillment'] ?? o['selectedFulfillment'] ?? 'pickup'}'
            .toLowerCase()
            .contains('pickup');

        Color statusColor = Colors.blue;
        int currentStep = 1;
        if (rawStatus == 'packed' || rawStatus == 'verified' || rawStatus == 'ready' || rawStatus == 'billed' || rawStatus == 'paid') {
          statusColor = Colors.orange;
          currentStep = 2;
        } else if (rawStatus == 'out_for_delivery' || rawStatus == 'dispatched' || rawStatus == 'ready_for_pickup') {
          statusColor = Colors.purple;
          currentStep = 3;
        } else if (rawStatus == 'delivered' || rawStatus == 'completed') {
          statusColor = Colors.green;
          currentStep = 4;
        }

        final riderName = o['riderName']?.toString();
        final riderPhone = o['riderPhone']?.toString();
        final vehicleNo = o['vehicleNo']?.toString();
        final hasRider = (riderName ?? '').isNotEmpty && (riderPhone ?? '').isNotEmpty;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        o['pharmacyName']?.toString() ?? 'Hospital In-House Pharmacy',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  publicId != null
                      ? 'Order ID: $publicId${total != null ? ' · Total: ₹$total' : ''}'
                      : (total != null ? 'ID pending · Total: ₹$total' : 'ID pending'),
                  style: TextStyle(color: context.secondaryText, fontSize: 13),
                ),
                const SizedBox(height: 12),

                // Visual Live Order Tracker Steps
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Order Tracking',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildTrackerStep('Received', 1, currentStep),
                          _buildTrackerLine(1, currentStep),
                          _buildTrackerStep('Packed', 2, currentStep),
                          _buildTrackerLine(2, currentStep),
                          _buildTrackerStep('On Way', 3, currentStep),
                          _buildTrackerLine(3, currentStep),
                          _buildTrackerStep('Delivered', 4, currentStep),
                        ],
                      ),
                    ],
                  ),
                ),

                // Assigned Delivery Partner Card (only when API provides rider)
                if (currentStep >= 3 && hasRider) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _softTint(Colors.purple),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: context.isDark ? 0.35 : 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.two_wheeler, color: Colors.purple, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delivery Partner: $riderName',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Vehicle: ${vehicleNo ?? '—'} · Mobile: $riderPhone',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.isDark ? Colors.purple.shade200 : Colors.purple.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone, color: Colors.purple),
                          onPressed: () => launchUrl(Uri.parse('tel:$riderPhone')),
                          tooltip: 'Call Rider',
                        ),
                      ],
                    ),
                  ),
                ],

                const Divider(height: 20),
                Row(
                  children: [
                    if (isPickup && pho.toUpperCase().startsWith('PHO')) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.qr_code, size: 16),
                          label: const Text('Pickup QR'),
                          onPressed: () => _showQrDialog(o),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (rawStatus == 'billed') ...[
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.payment, size: 16),
                          label: const Text('Pay bill'),
                          onPressed: () => _payPharmacyOrder(o),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (currentStep >= 3 && hasRider) ...[
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.map, size: 16),
                          label: const Text('Track Live'),
                          style: FilledButton.styleFrom(backgroundColor: Colors.purple.shade700),
                          onPressed: () => _showLiveRiderTrackerModal(o),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (currentStep == 4) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.star, size: 16, color: Colors.amber),
                          label: const Text('Rate Order'),
                          onPressed: () => _showRatingReviewModal(o),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text('Invoice'),
                        onPressed: () => _downloadInvoice(orderId),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLiveRiderTrackerModal(Map<String, dynamic> order) {
    final riderName = order['riderName']?.toString();
    final riderPhone = order['riderPhone']?.toString();
    final vehicleNo = order['vehicleNo']?.toString();
    if (riderName == null || riderPhone == null) {
      AppSnackbar.showError(context, 'Rider details not available yet.');
      return;
    }
    final deliveryOtp = order['otp']?.toString() ?? '—';
    final etaText = (order['etaText'] ?? order['eta'] ?? order['riderEta'])?.toString().trim();
    final distanceText = (order['distanceText'] ?? order['riderDistance'])?.toString().trim();
    final etaLine = [
      if (distanceText != null && distanceText.isNotEmpty) distanceText,
      if (etaText != null && etaText.isNotEmpty) etaText,
    ].join(' · ');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.near_me, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('Live Rider Tracking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _softTint(Colors.blue),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withValues(alpha: context.isDark ? 0.35 : 0.25)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.map, size: 160, color: Colors.blue.withValues(alpha: 0.25)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.purple.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 4),
                          ],
                        ),
                        child: const Icon(Icons.two_wheeler, color: Colors.white, size: 28),
                      ),
                      if (etaLine.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            etaLine,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Doorstep Delivery OTP Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _softTint(Colors.amber, light: 0.18, dark: 0.22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.45)),
              ),
              child: Row(
                children: [
                  Icon(Icons.key, color: context.isDark ? Colors.amber.shade200 : Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Doorstep Handover OTP',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: context.isDark ? Colors.amber.shade100 : Colors.brown,
                          ),
                        ),
                        Text(
                          'Share with $riderName upon delivery',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.isDark ? Colors.amber.shade200 : Colors.brown,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: context.isDark ? 0.35 : 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$deliveryOtp',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 2,
                        color: context.isDark ? Colors.amber.shade50 : Colors.brown,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rider Card
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rider: $riderName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Vehicle: $vehicleNo', style: TextStyle(color: context.secondaryText, fontSize: 13)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.phone),
                  label: const Text('Call Rider'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                  onPressed: () => launchUrl(Uri.parse('tel:$riderPhone')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingReviewModal(Map<String, dynamic> order) {
    int rating = 5;
    final textController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.stars, size: 48, color: Colors.amber),
              SizedBox(height: 8),
              Text('Rate Your Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your medicine delivery experience?', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return IconButton(
                    icon: Icon(
                      starNum <= rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() => rating = starNum);
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: 'Write optional review for rider & pharmacy...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Skip')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                AppSnackbar.showError(
                  context,
                  'Order reviews are not available yet. Please contact support if you had an issue.',
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerStep(String label, int stepNumber, int activeStep) {
    final isDone = activeStep >= stepNumber;
    final idle = context.isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300;
    return Column(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: isDone ? Colors.green : idle,
          child: Icon(
            isDone ? Icons.check : Icons.circle,
            size: 10,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            color: isDone ? context.primaryText : context.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackerLine(int stepNumber, int activeStep) {
    final isDone = activeStep > stepNumber;
    final idle = context.isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300;
    return Expanded(
      child: Container(
        height: 2,
        color: isDone ? Colors.green : idle,
        margin: const EdgeInsets.symmetric(horizontal: 2),
      ),
    );
  }

  // 4️⃣ HOSPITAL-MAPPED PHARMACIES (from prescriptions API)
  Widget _buildNearbyPharmaciesTab() {
    if (_nearbyPharmacies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppLocalizations.of(context)!.pharmacyNoMapped,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.secondaryText),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _nearbyPharmacies.length,
      itemBuilder: (_, i) {
        final store = _nearbyPharmacies[i];
        final isInHouse = store['isInHouse'] == true;
        final isSelected = store['id'] == _selectedStore?['id'];
        final phone = (store['phone'] ?? '').toString().trim();
        final address = (store['address'] ?? '').toString().trim();
        final status = (store['status'] ?? 'Hospital mapped').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: PharmacyUi.panel(context).copyWith(
            border: Border.all(
              color: isSelected ? AppColors.primary : context.borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      store['name']?.toString() ?? 'Pharmacy',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                    ),
                  ),
                  if (isInHouse)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _softTint(Colors.green),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Hospital In-House',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.isDark ? Colors.green.shade300 : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (address.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  address,
                  style: TextStyle(color: context.secondaryText, fontSize: 13),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.local_pharmacy,
                    size: 14,
                    color: context.isDark ? Colors.green.shade300 : Colors.green.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.isDark ? Colors.green.shade300 : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (phone.isNotEmpty) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.phone, size: 14),
                          label: const Text('Call Store', style: TextStyle(fontSize: 12)),
                          onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (address.isNotEmpty) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.directions, size: 14),
                          label: const Text('Directions', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            final query = Uri.encodeComponent('${store['name']} $address');
                            launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'));
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.shopping_bag, size: 14),
                        label: Text(isSelected ? 'Selected' : 'Order from', style: const TextStyle(fontSize: 12)),
                        style: PharmacyUi.primaryButton().copyWith(
                          backgroundColor: WidgetStatePropertyAll(
                            isSelected ? const Color(0xFF16A34A) : AppColors.primary,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedStore = store;
                            _tabs.animateTo(0);
                          });
                          AppSnackbar.show(
                            context,
                            'Selected ${store['name']} as your delivery pharmacy!',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
        );
      },
    );
  }
}
