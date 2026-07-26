import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:qr_flutter/qr_flutter.dart';

import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/service_providers.dart';
import '../../services/razorpay_checkout_service.dart';
import '../../widgets/common/app_snackbar.dart';

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
  String _selectedCategory = 'All';
  String _selectedDisease = 'All';

  // Cart state management
  final Map<dynamic, int> _cart = {}; // medicineId -> quantity
  Map<String, dynamic>? _selectedStore;
  String _selectedDeliveryMode = 'pickup'; // 'pickup' (10m counter) or 'delivery' (30m home)
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

  // Catalog data for "All Medicines" (FastAPI /api/user/pharmacy/search)
  List<Map<String, dynamic>> _catalogMedicines = [];

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
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
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
      ]);
      if (!mounted) return;
      final stores = _pharmaciesFromPrescriptions(results[0]);
      setState(() {
        _prescriptions = results[0];
        _orders = results[1];
        _payments = results[2];
        _catalogMedicines = results[3];
        _nearbyPharmacies = stores;
        if (_selectedStore == null ||
            stores.every((s) => s['id'] != _selectedStore?['id'])) {
          _selectedStore = stores.isNotEmpty ? stores.first : null;
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

  Widget _buildMedicineImage(String? imageStr, {double width = 80, double height = 80}) {
    if (imageStr == null || imageStr.trim().isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.teal.shade50,
        child: const Icon(Icons.medication, color: AppColors.primary),
      );
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
          errorBuilder: (_, __, ___) => Container(
            width: width,
            height: height,
            color: Colors.teal.shade50,
            child: const Icon(Icons.medication, color: AppColors.primary),
          ),
        );
      } catch (_) {
        return Container(
          width: width,
          height: height,
          color: Colors.teal.shade50,
          child: const Icon(Icons.medication, color: AppColors.primary),
        );
      }
    }

    return Image.network(
      trimmed,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.teal.shade50,
        child: const Icon(Icons.medication, color: AppColors.primary),
      ),
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
                      : Border.all(color: Colors.grey.shade300),
                  color: isSelected ? Colors.teal.shade50 : null,
                ),
                child: ListTile(
                  leading: Icon(
                    store['isInHouse'] == true ? Icons.local_hospital : Icons.store,
                    color: isSelected ? AppColors.primary : Colors.grey,
                  ),
                  title: Text(
                    store['name']?.toString() ?? 'Pharmacy',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                      color: isSelected ? Colors.black87 : null,
                    ),
                  ),
                  subtitle: Text(
                    status.isEmpty ? 'Hospital mapped pharmacy' : status,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.black54 : null,
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final cartItems = _cart.entries.map((entry) {
              final med = _catalogMedicines.firstWhere(
                (m) => m['id'] == entry.key,
                orElse: () => {'id': entry.key, 'name': 'Medicine Item', 'price': 0.0},
              );
              return {
                'med': med,
                'qty': entry.value,
              };
            }).toList();

            final hasRxItems = cartItems.any((item) {
              final med = item['med'];
              if (med is! Map) return false;
              return med['requiresRx'] == true;
            });
            final subtotal = _cartTotalAmount;
            final deliveryFee = _selectedDeliveryMode == 'pickup' ? 0.0 : (subtotal > 500 ? 0.0 : 29.0);
            final grandTotal = subtotal + deliveryFee;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_cart, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(
                            'Your Cart (${_cartItemCount} Item${_cartItemCount > 1 ? 's' : ''})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Fulfilling Store Info Banner
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.storefront, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Fulfilling Store: ${_selectedStore?['name'] ?? 'Select a hospital pharmacy'}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showStoreSelectorDialog();
                          },
                          child: const Text('Change', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rx Warning Banner if applicable
                  if (hasRxItems)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.assignment_late, color: Colors.brown, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Prescription Required: One or more medicines require a valid doctor e-prescription.',
                              style: TextStyle(fontSize: 11, color: Colors.brown, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Cart Item List
                  Expanded(
                    child: ListView.separated(
                      itemCount: cartItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final med = item['med'] as Map<String, dynamic>;
                        final qty = item['qty'] as int;
                        final price = (med['price'] is num) ? (med['price'] as num).toDouble() : 0.0;

                        return Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildMedicineImage(med['image'], width: 48, height: 48),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med['name'] ?? 'Medicine',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    '₹$price x $qty = ₹${(price * qty).toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () {
                                    _removeFromCart(med);
                                    setSheetState(() {});
                                    setState(() {});
                                  },
                                ),
                                Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                  onPressed: () {
                                    _addToCart(med);
                                    setSheetState(() {});
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const Divider(),

                  // Delivery Option Selector
                  const Text('Fulfillment Option', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.storefront, size: 16),
                          label: const Text('Hospital Counter Pickup\n(10 Mins)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
                          selected: _selectedDeliveryMode == 'pickup',
                          onSelected: (val) {
                            if (val) {
                              setSheetState(() => _selectedDeliveryMode = 'pickup');
                              setState(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.two_wheeler, size: 16),
                          label: const Text('Express Home Delivery\n(30 Mins)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
                          selected: _selectedDeliveryMode == 'delivery',
                          onSelected: (val) {
                            if (val) {
                              setSheetState(() => _selectedDeliveryMode = 'delivery');
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bill Breakdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Items Subtotal:', style: TextStyle(color: Colors.grey)),
                      Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery Fee:', style: TextStyle(color: Colors.grey)),
                      Text(deliveryFee == 0.0 ? 'FREE' : '₹${deliveryFee.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: deliveryFee == 0.0 ? Colors.green : Colors.black)),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('₹${grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Place Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(_selectedDeliveryMode == 'pickup'
                          ? 'Place Order for Hospital Pickup'
                          : 'Place delivery order (₹${grandTotal.toStringAsFixed(2)})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _placeCartOrder(grandTotal);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _placeCartOrder(double totalAmount) async {
    // Cart checkout requires a prescription-linked pharmacy order API.
    // Do not invent fake #ORD ids or mark success when the backend rejects.
    if (_prescriptions.isEmpty) {
      AppSnackbar.showError(
        context,
        'Cart checkout needs an active prescription. Use the Prescriptions tab to order.',
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
      AppSnackbar.showError(
        context,
        'No in-house pharmacy mapped for your prescription.',
      );
      return;
    }

    try {
      final placed = await ref.read(pharmacyServiceProvider).placeOrder(
            consultationId: consultationId,
            pharmacyId: pharmacyId,
            fulfillment: _selectedDeliveryMode,
            notes:
                'Cart checkout · ${_selectedStore?['name'] ?? 'pharmacy'} · ₹$totalAmount',
          );
      if (!mounted) return;
      setState(() {
        _orders.insert(0, placed);
        _cart.clear();
      });
      AppSnackbar.showSuccess(
        context,
        _selectedDeliveryMode == 'pickup'
            ? 'Order placed! Show pickup QR at the hospital pharmacy counter.'
            : 'Order placed! Track delivery under Orders.',
      );
      _tabs.animateTo(2);
      await _load();
      if (!mounted) return;
      if (_selectedDeliveryMode == 'pickup' &&
          (placed['publicId'] ?? placed['public_id'] ?? '')
              .toString()
              .toUpperCase()
              .startsWith('PHO')) {
        await _showQrDialog(placed);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
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
      final amountPaise = (pay['amountPaise'] is num)
          ? (pay['amountPaise'] as num).toInt()
          : ((pay['amount'] is num)
              ? ((pay['amount'] as num) * 100).round()
              : 0);
      if (key.isEmpty || rzOrderId.isEmpty || amountPaise < 100) {
        throw Exception(pay['message']?.toString() ?? 'Could not start payment');
      }
      final checkout = RazorpayCheckoutService();
      final result = await checkout.openCheckout(
        key: key,
        orderId: rzOrderId,
        amountPaise: amountPaise,
        name: 'MedClues Pharmacy',
        description: 'Pharmacy order #$orderId',
      );
      await ref.read(pharmacyServiceProvider).verifyPayment(
            orderId: orderId,
            razorpayOrderId: result.orderId,
            razorpayPaymentId: result.paymentId,
            razorpaySignature: result.signature,
          );
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Payment successful.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
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
      backgroundColor: AppColors.background,
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
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_cartItemCount Item${_cartItemCount > 1 ? 's' : ''} | ₹${_cartTotalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Fulfilling via ${_selectedStore?['name'] ?? 'Select pharmacy'}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: const Text('View Cart & Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _openCartCheckoutSheet,
                  ),
                ],
              ),
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

  // 1️⃣ ALL MEDICINES TAB
  Widget _buildAllMedicinesTab() {
    final filtered = _catalogMedicines.where((item) {
      final matchesSearch = item['name']
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          item['brand']
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' ||
          item['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Fulfilling Pharmacy Store Selector Banner
        InkWell(
          onTap: _showStoreSelectorDialog,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.storefront, color: Colors.blue.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fulfilling Store: ${_selectedStore?['name'] ?? 'Select a hospital pharmacy'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      Text(
                        _selectedStore == null
                            ? 'Mapped from your prescriptions when available'
                            : ((_selectedStore!['address']?.toString().isNotEmpty ?? false)
                                ? _selectedStore!['address'].toString()
                                : 'Hospital mapped pharmacy'),
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.swap_horiz, color: Colors.blue.shade700),
              ],
            ),
          ),
        ),

        // Search Bar
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search medicines, tablets, supplements...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _searchController.clear()),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Categories Header
        const Text(
          'Shop by Categories',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),

        // Specialty Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Fever & Pain', 'Diabetes', 'Blood Pressure', 'Vitamins & Supplements', 'Stomach Care']
                .map((cat) {
              final selected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: selected,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  onSelected: (val) {
                    setState(() => _selectedCategory = cat);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Medicine Cards List
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text('No medicines found matching your search.')),
          )
        else
          ...filtered.map((item) {
            final qty = _cart[item['id']] ?? 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildMedicineImage(item['image']?.toString(), width: 80, height: 80),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'By ${item['brand']} · ${item['category']}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '₹${item['price']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '₹${item['mrp']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item['discount'],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (qty == 0)
                      ElevatedButton(
                        onPressed: () => _addToCart(item),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add'),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18, color: AppColors.primary),
                              onPressed: () => _removeFromCart(item),
                            ),
                            Text(
                              '$qty',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                              onPressed: () => _addToCart(item),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
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
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
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
        Card(
          color: Colors.indigo.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.indigo.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.note_add, color: AppColors.primary, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Have an External Paper Prescription?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Upload a picture to order medicines directly',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _showUploadCustomRxDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Upload Rx'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (_prescriptions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: Text(
                'No active hospital digital prescriptions.\nDoctor e-prescriptions appear here automatically after consultation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
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
                                  color: isOffline ? Colors.teal.shade50 : Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isOffline ? Colors.teal.shade200 : Colors.purple.shade200),
                                ),
                                child: Text(
                                  isOffline ? '🏥 Offline Visit' : '💻 Online Call',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isOffline ? Colors.teal.shade900 : Colors.purple.shade900,
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
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          ),
                          const Divider(height: 18),

                          if ((rx['prescriptionNotes'] as String?)?.isNotEmpty == true) ...[
                            Text(
                              'Doctor Notes: ${rx['prescriptionNotes']}',
                              style: TextStyle(color: Colors.grey.shade800, fontStyle: FontStyle.italic),
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
                              color: Colors.grey.shade100,
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
                                        color: isPickup ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: isPickup ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                                      ),
                                      child: Column(
                                        children: const [
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
                                        color: !isPickup ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: !isPickup ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                                      ),
                                      child: Column(
                                        children: const [
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
                        color: statusColor.withOpacity(0.1),
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 12),

                // Visual Live Order Tracker Steps
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
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
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
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
                                style: TextStyle(fontSize: 11, color: Colors.purple.shade900),
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
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.map, size: 160, color: Colors.blue.shade100),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.purple.withOpacity(0.4), blurRadius: 12, spreadRadius: 4),
                          ],
                        ),
                        child: const Icon(Icons.two_wheeler, color: Colors.white, size: 28),
                      ),
                      if (etaLine.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.key, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Doorstep Handover OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown)),
                        Text('Share with $riderName upon delivery', style: const TextStyle(fontSize: 11, color: Colors.brown)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$deliveryOtp',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 2, color: Colors.brown),
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
                      Text('Vehicle: $vehicleNo', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
    return Column(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: isDone ? Colors.green : Colors.grey.shade300,
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
            color: isDone ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackerLine(int stepNumber, int activeStep) {
    final isDone = activeStep > stepNumber;
    return Expanded(
      child: Container(
        height: 2,
        color: isDone ? Colors.green : Colors.grey.shade300,
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
            style: TextStyle(color: Colors.grey.shade700),
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

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 3 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isSelected ? const BorderSide(color: AppColors.primary, width: 1.5) : BorderSide.none,
          ),
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
                        store['name']?.toString() ?? 'Pharmacy',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    if (isInHouse)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Text(
                          'Hospital In-House',
                          style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    address,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.local_pharmacy, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(status, style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
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
                        label: Text(isSelected ? 'Selected' : 'Order From', style: const TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          backgroundColor: isSelected ? Colors.green : AppColors.primary,
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
          ),
        );
      },
    );
  }
}
