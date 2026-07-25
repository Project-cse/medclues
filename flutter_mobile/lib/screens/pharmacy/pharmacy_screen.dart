import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Catalog data for "All Medicines" (loads live from Express Backend MongoDB via FastAPI)
  List<Map<String, dynamic>> _catalogMedicines = [
    {
      'id': 1,
      'name': 'Dolo 650mg Tablet',
      'brand': 'Micro Labs',
      'category': 'Fever & Pain',
      'specialty': 'General',
      'price': 32.50,
      'mrp': 40.00,
      'discount': '18% OFF',
      'requiresRx': false,
      'rating': 4.8,
      'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=300'
    },
    {
      'id': 2,
      'name': 'Glycomet 500mg Tablet',
      'brand': 'USV Ltd',
      'category': 'Diabetes',
      'specialty': 'Endocrinology',
      'price': 45.00,
      'mrp': 55.00,
      'discount': '18% OFF',
      'requiresRx': true,
      'rating': 4.9,
      'image': 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=300'
    },
    {
      'id': 3,
      'name': 'Telmikind 40mg Tablet',
      'brand': 'Mankind Pharma',
      'category': 'Blood Pressure',
      'specialty': 'Cardiology',
      'price': 68.00,
      'mrp': 85.00,
      'discount': '20% OFF',
      'requiresRx': true,
      'rating': 4.7,
      'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=300'
    },
    {
      'id': 4,
      'name': 'Becosules Z Capsules',
      'brand': 'Pfizer',
      'category': 'Vitamins & Supplements',
      'specialty': 'General',
      'price': 42.00,
      'mrp': 50.00,
      'discount': '16% OFF',
      'requiresRx': false,
      'rating': 4.9,
      'image': 'https://images.unsplash.com/photo-1550572017-edd951aa8f72?w=300'
    },
    {
      'id': 5,
      'name': 'Pantocid 40mg Tablet',
      'brand': 'Sun Pharma',
      'category': 'Stomach Care',
      'specialty': 'Gastroenterology',
      'price': 115.00,
      'mrp': 140.00,
      'discount': '17% OFF',
      'requiresRx': true,
      'rating': 4.6,
      'image': 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=300'
    },
    {
      'id': 6,
      'name': 'Calpol 120mg Suspension (Pediatric)',
      'brand': 'GSK',
      'category': 'Fever & Pain',
      'specialty': 'Pediatrics',
      'price': 38.00,
      'mrp': 45.00,
      'discount': '15% OFF',
      'requiresRx': false,
      'rating': 4.8,
      'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=300'
    },
  ];

  // Nearby Pharmacies sample data
  final List<Map<String, dynamic>> _nearbyPharmacies = [
    {
      'id': 101,
      'name': 'KIMS Hospital In-House Pharmacy',
      'address': 'Ground Floor, KIMS Hospital, Main Road, Guntur',
      'distance': '0.1 km',
      'status': 'OPEN 24/7',
      'phone': '+91 863 2345678',
      'isInHouse': true,
    },
    {
      'id': 102,
      'name': 'Apollo Pharmacy - Brodipet',
      'address': 'D.No 4-5-23, Brodipet 2nd Line, Guntur',
      'distance': '1.2 km',
      'status': 'OPEN (Closes 10:30 PM)',
      'phone': '+91 863 2223344',
      'isInHouse': false,
    },
    {
      'id': 103,
      'name': 'MedPlus Pharmacy - Arundelpet',
      'address': 'Main Road, Opposite SBI, Arundelpet, Guntur',
      'distance': '2.4 km',
      'status': 'OPEN (Closes 11:00 PM)',
      'phone': '+91 863 2556677',
      'isInHouse': false,
    },
  ];

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
        svc.getPrescriptions(),
        svc.getOrders(),
        svc.getPayments(),
        svc.searchMedicines(_searchController.text),
      ]);
      if (!mounted) return;
      setState(() {
        _prescriptions = results[0];
        _orders = results[1];
        _payments = results[2];
        final liveMeds = results[3];
        if (liveMeds.isNotEmpty) {
          _catalogMedicines = liveMeds;
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

  int? _asInt(dynamic v) => v is int ? v : int.tryParse('$v');

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
      await ref.read(pharmacyServiceProvider).placeOrder(
            consultationId: consultationId,
            pharmacyId: pharmacyId,
            fulfillment: 'pickup',
          );
      if (!mounted) return;
      AppSnackbar.show(context, 'Prescription order sent to In-House Hospital Pharmacy!');
      _tabs.animateTo(2); // Switch to Orders tab
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _showQrDialog(Map<String, dynamic> rx) async {
    final rxId = rx['consultationId'] ?? 'RX-9842';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.qr_code_scanner, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Hospital Pickup QR'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Show this QR code at the Hospital In-House Pharmacy Counter to collect your packed medicines.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(
                Icons.qr_code_2,
                size: 160,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              'Prescription ID: #$rxId',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                          'Fulfilling via ${_selectedStore['name']}',
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
                        'Fulfilling Store: ${_selectedStore['name']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      Text(
                        'Single pharmacy delivery point · ${_selectedStore['address']}',
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
                      child: Image.network(
                        item['image'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.blue.shade50,
                          child: const Icon(Icons.medical_services, color: AppColors.primary),
                        ),
                      ),
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
              AppSnackbar.show(context, 'Paper prescription uploaded! Pharmacy team is verifying.');
            },
            child: const Text('Upload & Submit'),
          ),
        ],
      ),
    );
  }

  // 2️⃣ PRESCRIPTIONS TAB (Strict In-House Hospital Pharmacy Routing)
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
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Upload a picture to order medicines directly',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
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
                'No active hospital digital prescriptions.\nDoctor prescriptions appear here automatically after consultation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._prescriptions.map((rx) {
            final items = (rx['items'] as List?) ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
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
                            'Consultation #${rx['consultationId']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Hospital In-House Routing',
                              style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.qr_code),
                              label: const Text('Hospital Pickup QR'),
                              onPressed: () => _showQrDialog(rx),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.send),
                              label: const Text('Order to Counter'),
                              onPressed: () => _orderMeds(rx),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
        final publicId = o['publicId'] ?? '#ORD-$orderId';

        Color statusColor = Colors.blue;
        int currentStep = 1;
        if (rawStatus == 'packed' || rawStatus == 'verified') {
          statusColor = Colors.orange;
          currentStep = 2;
        } else if (rawStatus == 'out_for_delivery' || rawStatus == 'dispatched' || rawStatus == 'ready_for_pickup') {
          statusColor = Colors.purple;
          currentStep = 3;
        } else if (rawStatus == 'delivered' || rawStatus == 'completed') {
          statusColor = Colors.green;
          currentStep = 4;
        }

        // Mock delivery executive info for out_for_delivery orders
        final riderName = o['riderName'] ?? 'Ramesh Kumar';
        final riderPhone = o['riderPhone'] ?? '+91 98765 43210';
        final vehicleNo = o['vehicleNo'] ?? 'KA 05 EQ 8821';

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
                  'Order ID: $publicId ${total != null ? '· Total: ₹$total' : ''}',
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

                // Assigned Delivery Partner Card
                if (currentStep >= 3) ...[
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
                                'Vehicle: $vehicleNo · Mobile: $riderPhone',
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
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text('Invoice'),
                        onPressed: () => _downloadInvoice(orderId),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.autorenew, size: 16),
                        label: const Text('1-Click Refill'),
                        onPressed: () => _refillOrder(orderId),
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

  // 4️⃣ NEARBY PHARMACIES TAB
  Widget _buildNearbyPharmaciesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _nearbyPharmacies.length,
      itemBuilder: (_, i) {
        final store = _nearbyPharmacies[i];
        final isInHouse = store['isInHouse'] == true;
        final isSelected = store['name'] == _selectedStore['name'];

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
                        store['name'],
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
                const SizedBox(height: 6),
                Text(
                  store['address'],
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.near_me, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(store['distance'], style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(store['status'], style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.phone, size: 14),
                        label: const Text('Call Store', style: TextStyle(fontSize: 12)),
                        onPressed: () => launchUrl(Uri.parse('tel:${store['phone']}')),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.directions, size: 14),
                        label: const Text('Directions', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          final query = Uri.encodeComponent('${store['name']} ${store['address']}');
                          launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'));
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
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
                            _tabs.animateTo(0); // Switch to All Medicines tab
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
