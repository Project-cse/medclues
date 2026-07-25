import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants/app_colors.dart';
import '../../models/medicine_model.dart';
import '../../providers/service_providers.dart';
import '../../widgets/common/app_snackbar.dart';
import 'medicine_widgets.dart';

class MedicineDetailScreen extends ConsumerStatefulWidget {
  const MedicineDetailScreen({super.key, required this.medicineName});

  final String medicineName;

  @override
  ConsumerState<MedicineDetailScreen> createState() =>
      _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends ConsumerState<MedicineDetailScreen> {
  MedicineDetails? _details;
  bool _loading = true;
  String? _error;
  bool _favorited = false;
  bool _favBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final details =
          await ref.read(medicineServiceProvider).details(widget.medicineName);
      if (!mounted) return;
      setState(() {
        _details = details;
        _loading = false;
      });
      _checkFavorite(details.medicineKey);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _checkFavorite(String key) async {
    try {
      final favs = await ref.read(medicineServiceProvider).favorites();
      if (!mounted) return;
      setState(() => _favorited = favs.any((f) => f.medicineKey == key));
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    final d = _details;
    if (d == null || _favBusy) return;
    setState(() => _favBusy = true);
    try {
      final svc = ref.read(medicineServiceProvider);
      if (_favorited) {
        await svc.removeFavorite(d.medicineKey);
        if (!mounted) return;
        setState(() => _favorited = false);
        AppSnackbar.show(context, 'Removed from favorites');
      } else {
        await svc.addFavorite(d.toCard());
        if (!mounted) return;
        setState(() => _favorited = true);
        AppSnackbar.show(context, 'Saved to favorites');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _favBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? _DetailShimmer(title: widget.medicineName)
          : _error != null
              ? _ErrorBody(message: _error!, onRetry: _load)
              : _DetailBody(
                  details: _details!,
                  favorited: _favorited,
                  favBusy: _favBusy,
                  onToggleFavorite: _toggleFavorite,
                ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.details,
    required this.favorited,
    required this.favBusy,
    required this.onToggleFavorite,
  });

  final MedicineDetails details;
  final bool favorited;
  final bool favBusy;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: AppColors.medcluesNavy,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: favBusy ? null : onToggleFavorite,
              icon: Icon(
                favorited ? Icons.favorite : Icons.favorite_border,
                color: favorited ? Colors.redAccent : Colors.white,
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 56),
            title: Text(
              details.medicineName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.medcluesNavy, Color(0xFF004D5A)],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, bottom: 48),
                  child: MedicinePlaceholder(
                    placeholderType: details.placeholderType,
                    size: 72,
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _ManufacturerCard(details: details),
              if (details.activeIngredients.isNotEmpty) ...[
                const SizedBox(height: 12),
                const _Label('Active ingredients'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: details.activeIngredients
                      .map(
                        (i) => Chip(
                          label: Text(i, style: const TextStyle(fontSize: 12)),
                          backgroundColor: const Color(0xFFECFDF5),
                          side: const BorderSide(color: Color(0xFFA7F3D0)),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 8),
              if (_has(details.boxedWarning))
                _InfoSection(
                  title: 'Boxed warning',
                  body: details.boxedWarning!,
                  accent: const Color(0xFF991B1B),
                  background: const Color(0xFFFEE2E2),
                  initiallyExpanded: true,
                ),
              if (_has(details.warnings))
                _InfoSection(
                  title: 'Warnings',
                  body: details.warnings!,
                  accent: const Color(0xFFDC2626),
                  background: const Color(0xFFFEF2F2),
                ),
              if (_has(details.doNotUse))
                _InfoSection(
                  title: 'Do not use',
                  body: details.doNotUse!,
                  accent: const Color(0xFFB91C1C),
                  background: const Color(0xFFFEE2E2),
                ),
              if (_has(details.stopUse))
                _InfoSection(
                  title: 'Stop use',
                  body: details.stopUse!,
                  accent: const Color(0xFFB91C1C),
                  background: const Color(0xFFFEE2E2),
                ),
              if (_has(details.askDoctor))
                _InfoSection(
                  title: 'Ask a doctor',
                  body: details.askDoctor!,
                  accent: const Color(0xFFC2410C),
                  background: const Color(0xFFFFF7ED),
                ),
              if (_has(details.sideEffects))
                _InfoSection(
                  title: 'Side effects',
                  body: details.sideEffects!,
                  accent: const Color(0xFFEA580C),
                  background: const Color(0xFFFFF7ED),
                ),
              if (_has(details.pregnancyWarning))
                _InfoSection(
                  title: 'Pregnancy',
                  body: details.pregnancyWarning!,
                  accent: const Color(0xFFBE185D),
                  background: const Color(0xFFFDF2F8),
                ),
              if (_has(details.pediatricUse))
                _InfoSection(
                  title: 'Pediatric use',
                  body: details.pediatricUse!,
                  accent: const Color(0xFF7C3AED),
                  background: const Color(0xFFF5F3FF),
                ),
              if (_has(details.geriatricUse))
                _InfoSection(
                  title: 'Geriatric use',
                  body: details.geriatricUse!,
                  accent: const Color(0xFF6D28D9),
                  background: const Color(0xFFF5F3FF),
                ),
              if (_has(details.purpose))
                _InfoSection(title: 'Purpose', body: details.purpose!),
              if (_has(details.indications))
                _InfoSection(title: 'Indications & uses', body: details.indications!),
              if (_has(details.dosageAndAdministration))
                _InfoSection(
                  title: 'Dosage & administration',
                  body: details.dosageAndAdministration!,
                ),
              if (_has(details.contraindications))
                _InfoSection(
                  title: 'Contraindications',
                  body: details.contraindications!,
                ),
              if (_has(details.drugInteractions))
                _InfoSection(
                  title: 'Drug interactions',
                  body: details.drugInteractions!,
                ),
              if (_has(details.drugAbuse))
                _InfoSection(
                  title: 'Drug abuse & dependence',
                  body: details.drugAbuse!,
                ),
              if (_has(details.storage))
                _InfoSection(
                  title: 'Storage',
                  body: details.storage!,
                  accent: const Color(0xFF2563EB),
                  background: const Color(0xFFEFF6FF),
                ),
              if (_has(details.howSupplied))
                _InfoSection(title: 'How supplied', body: details.howSupplied!),
              if (_has(details.packageLabel))
                _InfoSection(
                  title: 'Package label',
                  body: details.packageLabel!,
                ),
              const SizedBox(height: 16),
              Text(
                'Label data from openFDA for educational reference. '
                'Not a substitute for professional medical advice.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  height: 1.35,
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  bool _has(String? v) => v != null && v.trim().isNotEmpty;
}

class _ManufacturerCard extends StatelessWidget {
  const _ManufacturerCard({required this.details});
  final MedicineDetails details;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((details.genericName ?? '').isNotEmpty)
            _MetaRow(label: 'Generic', value: details.genericName!),
          if ((details.brandName ?? '').isNotEmpty)
            _MetaRow(label: 'Brand', value: details.brandName!),
          if ((details.manufacturer ?? '').isNotEmpty)
            _MetaRow(label: 'Manufacturer', value: details.manufacturer!),
          if ((details.dosageForm ?? '').isNotEmpty)
            _MetaRow(label: 'Dosage form', value: details.dosageForm!),
          if ((details.route ?? '').isNotEmpty)
            _MetaRow(label: 'Route', value: details.route!),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.body,
    this.accent = AppColors.medcluesNavy,
    this.background = Colors.white,
    this.initiallyExpanded = false,
  });

  final String title;
  final String body;
  final Color accent;
  final Color background;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(14),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: accent,
                fontSize: 14,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textPrimary,
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

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.medcluesNavy,
          foregroundColor: Colors.white,
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Shimmer.fromColors(
              baseColor: const Color(0xFFE2E8F0),
              highlightColor: const Color(0xFFF8FAFC),
              child: Column(
                children: List.generate(
                  5,
                  (i) => Container(
                    height: i == 0 ? 120 : 72,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine details'),
        backgroundColor: AppColors.medcluesNavy,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
