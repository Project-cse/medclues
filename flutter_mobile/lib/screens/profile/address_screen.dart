import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n_extension.dart';
import '../../providers/patient_provider.dart';
import '../../providers/service_providers.dart';
import '../../themes/theme_form_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_snackbar.dart';

/// Matches mobile/app/(patient)/address.tsx
class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _line1.dispose();
    _line2.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(patientRepositoryProvider).updateAddress(
            line1: _line1.text.trim(),
            line2: _line2.text.trim(),
          );
      ref.invalidate(patientProfileProvider);
      if (mounted) {
        AppSnackbar.show(context, context.l10n.addressSaved, success: true);
        context.pop();
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(patientProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.addressTitle)),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (p) {
          if (!_initialized) {
            final lines = p.addressLines;
            _line1.text = lines.line1;
            _line2.text = lines.line2;
            _initialized = true;
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _field(context, context.l10n.profileAddressLine1, _line1, context.l10n.profileAddressLine1),
              const SizedBox(height: 16),
              _field(context, context.l10n.profileAddressLine2, _line2, context.l10n.profileAddressLine2),
              const SizedBox(height: 24),
              AppButton(label: context.l10n.commonSave, loading: _loading, onPressed: _save),
            ],
          );
        },
      ),
    );
  }

  Widget _field(BuildContext context, String label, TextEditingController c, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: profileLabelStyle(context)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          style: profileFieldTextStyle(context),
          decoration: profileInputDecoration(context, hint: hint),
        ),
      ],
    );
  }
}
