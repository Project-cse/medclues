import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/service_providers.dart';
import '../../widgets/common/app_snackbar.dart';

class HpEmergencyCardScreen extends ConsumerStatefulWidget {
  const HpEmergencyCardScreen({super.key});

  @override
  ConsumerState<HpEmergencyCardScreen> createState() =>
      _HpEmergencyCardScreenState();
}

class _HpEmergencyCardScreenState extends ConsumerState<HpEmergencyCardScreen> {
  final _blood = TextEditingController();
  final _policy = TextEditingController();
  final _company = TextEditingController();
  final _coverage = TextEditingController();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _qr;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _blood.dispose();
    _policy.dispose();
    _company.dispose();
    _coverage.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final card =
          await ref.read(healthProtectionServiceProvider).emergencyCard();
      if (!mounted) return;
      if (card != null) {
        _blood.text = '${card['bloodGroup'] ?? ''}';
        _policy.text = '${card['policyNumber'] ?? ''}';
        _company.text = '${card['company'] ?? ''}';
        _coverage.text = '${card['coverage'] ?? ''}';
        _contactName.text = '${card['emergencyContactName'] ?? ''}';
        _contactPhone.text = '${card['emergencyContactPhone'] ?? ''}';
        _qr = card['qrPayload']?.toString();
      }
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final saved =
          await ref.read(healthProtectionServiceProvider).saveEmergencyCard({
        'bloodGroup': _blood.text.trim(),
        'policyNumber': _policy.text.trim(),
        'company': _company.text.trim(),
        'coverage': _coverage.text.trim(),
        'emergencyContactName': _contactName.text.trim(),
        'emergencyContactPhone': _contactPhone.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _qr = saved['qrPayload']?.toString();
        _saving = false;
      });
      AppSnackbar.show(context, 'Emergency card saved', success: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _sharePdf() async {
    try {
      final bytes =
          await ref.read(healthProtectionServiceProvider).emergencyCardPdf();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'medclues_emergency_card.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _shareText() {
    Share.share(
      'MEDCLUES Emergency Card\n'
      'Blood: ${_blood.text}\nPolicy: ${_policy.text}\n'
      'Insurer: ${_company.text}\nCoverage: ${_coverage.text}\n'
      'Emergency: ${_contactName.text} ${_contactPhone.text}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.hpEmergencyCard),
        backgroundColor: AppColors.medcluesNavy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              onPressed: _sharePdf, icon: const Icon(Icons.picture_as_pdf)),
          IconButton(onPressed: _shareText, icon: const Icon(Icons.share)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.medcluesNavy, Color(0xFF0F766E)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.shield, color: Colors.white, size: 36),
                      const SizedBox(height: 8),
                      Text(l10n.hpDigitalEmergencyCard,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      const SizedBox(height: 12),
                      if ((_qr ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.white,
                          child: QrImageView(data: _qr!, size: 140),
                        ),
                      if (kIsWeb)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('PDF share works on mobile & desktop too',
                              style:
                                  TextStyle(color: Colors.white70, fontSize: 11)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _field(_blood, l10n.hpBloodGroup),
                _field(_policy, l10n.hpPolicyNumber),
                _field(_company, l10n.hpInsuranceCompany),
                _field(_coverage, 'Coverage'),
                _field(_contactName, 'Emergency contact name'),
                _field(_contactPhone, 'Emergency contact phone',
                    keyboard: TextInputType.phone),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save card'),
                ),
              ],
            ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
