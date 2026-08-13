import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../utils/theme_context.dart';
import '../healthcare/premium_healthcare_theme.dart';

/// Blinkit / Instamart–inspired pharmacy commerce UI.
abstract final class PharmacyUi {
  static const double cardRadius = 16;
  static const double controlRadius = 12;
  static const Color accent = AppColors.primary;
  static const Color priceGreen = Color(0xFF0F8A4B);

  static Color surface(BuildContext context) => context.cardColor;
  static Color hairline(BuildContext context) => context.borderColor;
  static Color imageBg(BuildContext context) =>
      context.isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF3F4F6);

  static List<BoxShadow> cardShadow(BuildContext context) =>
      PremiumHealthcareTheme.cardShadow(context);

  static BoxDecoration panel(
    BuildContext context, {
    double radius = cardRadius,
    Color? color,
    bool elevated = true,
  }) {
    return BoxDecoration(
      color: color ?? surface(context),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: hairline(context)),
      boxShadow: elevated ? cardShadow(context) : null,
    );
  }

  static ButtonStyle primaryButton({double height = 44}) {
    return FilledButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      minimumSize: Size(0, height),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(controlRadius),
      ),
      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13.5),
    );
  }
}

class PharmacySectionTitle extends StatelessWidget {
  const PharmacySectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: context.primaryText,
      ),
    );
  }
}

class PharmacyStoreBanner extends StatelessWidget {
  const PharmacyStoreBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PharmacyUi.surface(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PharmacyUi.hairline(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: PharmacyUi.accent.withValues(alpha: context.isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.storefront_outlined, color: PharmacyUi.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: context.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(fontSize: 11, color: context.secondaryText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}

class PharmacyCategoryChip extends StatelessWidget {
  const PharmacyCategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: PharmacyUi.accent,
        backgroundColor: PharmacyUi.surface(context),
        side: BorderSide(
          color: selected ? PharmacyUi.accent : PharmacyUi.hairline(context),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : context.primaryText,
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

/// Blinkit-style ADD / qty control.
class PharmacyAddControl extends StatelessWidget {
  const PharmacyAddControl({
    super.key,
    required this.qty,
    required this.onAdd,
    required this.onMinus,
    required this.onPlus,
    this.compact = false,
  });

  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 32.0 : 36.0;
    if (qty <= 0) {
      return SizedBox(
        height: h,
        child: OutlinedButton(
          onPressed: onAdd,
          style: OutlinedButton.styleFrom(
            foregroundColor: PharmacyUi.accent,
            side: const BorderSide(color: PharmacyUi.accent, width: 1.4),
            backgroundColor: context.isDark
                ? PharmacyUi.accent.withValues(alpha: 0.12)
                : PharmacyUi.accent.withValues(alpha: 0.06),
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
            minimumSize: Size(compact ? 64 : 72, h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            'ADD',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: compact ? 12 : 13,
              letterSpacing: 0.4,
            ),
          ),
        ),
      );
    }

    return Container(
      height: h,
      decoration: BoxDecoration(
        color: PharmacyUi.accent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(Icons.remove, onMinus),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$qty',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          _stepBtn(Icons.add, onPlus),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: compact ? 30 : 34,
        height: compact ? 32 : 36,
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

/// Alias used by checkout sheet.
class PharmacyQtyStepper extends StatelessWidget {
  const PharmacyQtyStepper({
    super.key,
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return PharmacyAddControl(
      qty: qty,
      onAdd: onPlus,
      onMinus: onMinus,
      onPlus: onPlus,
      compact: true,
    );
  }
}

/// Blinkit-style product tile (grid cell). Entire card is tappable.
class PharmacyProductCard extends StatelessWidget {
  const PharmacyProductCard({
    super.key,
    required this.name,
    required this.brand,
    required this.salt,
    required this.category,
    required this.priceLabel,
    required this.image,
    required this.qty,
    required this.stock,
    required this.requiresRx,
    required this.onOpen,
    required this.onAdd,
    required this.onMinus,
    required this.onPlus,
    this.mrpLabel,
    this.discountLabel,
  });

  final String name;
  final String brand;
  final String salt;
  final String category;
  final String priceLabel;
  final Widget image;
  final int qty;
  final int stock;
  final bool requiresRx;
  final VoidCallback onOpen;
  final VoidCallback onAdd;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final String? mrpLabel;
  final String? discountLabel;

  @override
  Widget build(BuildContext context) {
    final unitLine = salt.trim().isNotEmpty
        ? salt.trim()
        : (category.trim().isNotEmpty ? category : 'Medicine');

    return Material(
      color: PharmacyUi.surface(context),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PharmacyUi.hairline(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image stage
              Expanded(
                flex: 55,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: PharmacyUi.imageBg(context),
                      padding: const EdgeInsets.all(10),
                      child: Center(child: image),
                    ),
                    if (discountLabel != null && discountLabel!.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF166534),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            discountLabel!,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (requiresRx)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade800,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Rx',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: PharmacyAddControl(
                        qty: qty,
                        onAdd: onAdd,
                        onMinus: onMinus,
                        onPlus: onPlus,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ),
              // Meta
              Expanded(
                flex: 45,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (brand.trim().isNotEmpty)
                        Text(
                          brand.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: context.secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.2,
                          color: context.primaryText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        unitLine,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: context.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            priceLabel,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: context.primaryText,
                            ),
                          ),
                          if (mrpLabel != null && mrpLabel!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              mrpLabel!,
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                decoration: TextDecoration.lineThrough,
                                color: context.secondaryText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full product detail sheet (Swiggy/Blinkit style).
Future<void> showPharmacyProductDetail({
  required BuildContext context,
  required Map<String, dynamic> item,
  required int Function() getQty,
  required Widget image,
  required VoidCallback onAdd,
  required VoidCallback onMinus,
  required VoidCallback onPlus,
}) {
  final name = item['name']?.toString() ?? 'Medicine';
  final brand = item['brand']?.toString() ?? '';
  final salt = item['salt']?.toString() ?? '';
  final category = item['category']?.toString() ?? 'General';
  final stock = (item['stock'] is num) ? (item['stock'] as num).toInt() : 0;
  final requiresRx = item['requiresRx'] == true;
  final price = (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0;
  final mrp = (item['mrp'] is num) ? (item['mrp'] as num).toDouble() : price;
  final discount = item['discount']?.toString() ?? '';

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: PharmacyUi.surface(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          final qty = getQty();
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            builder: (_, scrollCtrl) {
              return Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: PharmacyUi.imageBg(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: PharmacyUi.hairline(context)),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Center(child: image),
                        ),
                        const SizedBox(height: 16),
                        if (brand.isNotEmpty)
                          Text(
                            brand.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: PharmacyUi.accent,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: context.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _metaChip(context, category),
                            if (requiresRx) _metaChip(context, 'Prescription required', warn: true),
                            _metaChip(context, stock > 0 ? 'In stock · $stock' : 'Out of stock'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${price.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: context.primaryText,
                              ),
                            ),
                            if (mrp > price) ...[
                              const SizedBox(width: 10),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '₹${mrp.toStringAsFixed(0)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    decoration: TextDecoration.lineThrough,
                                    color: context.secondaryText,
                                  ),
                                ),
                              ),
                            ],
                            if (discount.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  discount,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: PharmacyUi.priceGreen,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Product details',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: context.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _detailRow(context, 'Composition / Salt', salt.isEmpty ? 'Not specified' : salt),
                        _detailRow(context, 'Brand', brand.isEmpty ? '—' : brand),
                        _detailRow(context, 'Category', category),
                        _detailRow(
                          context,
                          'Usage note',
                          requiresRx
                              ? 'This medicine may require a valid doctor prescription. Follow your physician’s advice.'
                              : 'Over-the-counter retail item. Read label directions before use.',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap ADD to place in your cart. Choose Home delivery (COD / UPI) or Hospital counter at checkout.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            height: 1.4,
                            color: context.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₹${price.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  qty > 0 ? '$qty in cart' : 'Not in cart yet',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    color: context.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PharmacyAddControl(
                            qty: qty,
                            onAdd: () {
                              onAdd();
                              setLocal(() {});
                            },
                            onMinus: () {
                              onMinus();
                              setLocal(() {});
                            },
                            onPlus: () {
                              onPlus();
                              setLocal(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}

Widget _metaChip(BuildContext context, String label, {bool warn = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: warn
          ? Colors.orange.withValues(alpha: context.isDark ? 0.22 : 0.12)
          : (context.isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6)),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: warn ? Colors.orange.shade200 : context.primaryText,
      ),
    ),
  );
}

Widget _detailRow(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: context.secondaryText),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: context.primaryText,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class PharmacyStickyCartBar extends StatelessWidget {
  const PharmacyStickyCartBar({
    super.key,
    required this.itemCount,
    required this.totalLabel,
    required this.subtitle,
    required this.onCheckout,
  });

  final int itemCount;
  final String totalLabel;
  final String subtitle;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 10 + bottom),
        child: Material(
          color: PharmacyUi.accent,
          borderRadius: BorderRadius.circular(16),
          elevation: 8,
          shadowColor: Colors.black54,
          child: InkWell(
            onTap: onCheckout,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$itemCount',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View cart · $totalLabel',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
