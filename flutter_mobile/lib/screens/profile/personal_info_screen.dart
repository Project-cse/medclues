import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../constants/profile_options.dart';
import '../../l10n/l10n_extension.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../providers/patient_provider.dart';
import '../../services/app_permissions_service.dart';
import '../../providers/service_providers.dart';
import '../../themes/theme_form_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/avatar_image.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _addressLine1 = TextEditingController();
  final _addressLine2 = TextEditingController();
  String? _gender;
  DateTime? _dob;
  String? _bloodGroup;
  bool _editing = false;
  bool _loading = false;
  bool _uploadingPhoto = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    super.dispose();
  }

  void _loadFromProfile(dynamic p) {
    _name.text = p.name;
    _phone.text = p.phone ?? '';
    _gender = ProfileOptions.normalizeGender(p.gender);
    _bloodGroup = ProfileOptions.normalizeBloodGroup(p.bloodGroup);
    final lines = p.addressLines;
    _addressLine1.text = lines.line1;
    _addressLine2.text = lines.line2;
    final dobRaw = ProfileOptions.sanitize(p.dob);
    _dob = null;
    if (dobRaw != null) {
      _dob = DateTime.tryParse(dobRaw) ?? _tryParseDob(dobRaw);
    }
  }

  DateTime? _tryParseDob(String raw) {
    for (final pattern in ['yyyy-MM-dd', 'dd-MM-yyyy', 'dd/MM/yyyy']) {
      try {
        return DateFormat(pattern).parseStrict(raw);
      } catch (_) {}
    }
    return null;
  }

  String _genderLabel(String? value) {
    if (value == null) return context.l10n.profileNotSet;
    for (final item in ProfileOptions.genderItems) {
      if (item.$1 == value) return item.$2;
    }
    return value;
  }

  String _addressLabel(dynamic p) {
    final addr = p.address?.trim();
    if (addr == null || addr.isEmpty) return context.l10n.profileNotSet;
    return addr;
  }

  void _startEditing(dynamic p) {
    _loadFromProfile(p);
    setState(() => _editing = true);
  }

  void _cancelEditing(dynamic p) {
    _loadFromProfile(p);
    setState(() => _editing = false);
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final ok = await AppPermissionsService.ensurePhotos();
      if (!ok && mounted) {
        AppSnackbar.show(context, context.l10n.permissionsFiles);
        await AppPermissionsService.openSettingsIfPermanentlyDenied(Permission.photos);
        return;
      }
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      setState(() => _uploadingPhoto = true);
      await ref.read(patientRepositoryProvider).uploadPhoto(picked);
      ref.invalidate(patientProfileProvider);
      if (mounted) AppSnackbar.show(context, context.l10n.profilePhotoUpdated, success: true);
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString());
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1995),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save(dynamic current) async {
    setState(() => _loading = true);
    try {
      final updated = current.copyWith(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        gender: _gender,
        dob: _dob != null ? DateFormat('yyyy-MM-dd').format(_dob!) : null,
        bloodGroup: _bloodGroup,
      );
      await ref.read(patientRepositoryProvider).updateProfile(updated);
      await ref.read(patientRepositoryProvider).updateAddress(
            line1: _addressLine1.text.trim(),
            line2: _addressLine2.text.trim(),
          );
      ref.invalidate(patientProfileProvider);
      if (mounted) {
        AppSnackbar.show(context, context.l10n.profileSaved, success: true);
        setState(() => _editing = false);
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.profilePersonalInfo),
        actions: [
          profile.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (p) {
              if (_editing) {
                return TextButton(
                  onPressed: _loading ? null : () => _cancelEditing(p),
                  child: Text(
                    context.l10n.profileCancelEdit,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: cs.error),
                  ),
                );
              }
              return TextButton.icon(
                onPressed: () => _startEditing(p),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(
                  context.l10n.profileEdit,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (p) {
          if (!_editing) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(child: AvatarImage(uri: p.profilePicUrl, size: 100)),
                const SizedBox(height: 24),
                _viewRow(context, context.l10n.authFullName, p.name.trim().isEmpty ? context.l10n.profileNotSet : p.name),
                _viewRow(context, context.l10n.authEmail, p.email),
                _viewRow(context, context.l10n.authPhone, p.phone?.isNotEmpty == true ? p.phone! : context.l10n.profileNotSet),
                _viewRow(context, context.l10n.authGender, _genderLabel(ProfileOptions.normalizeGender(p.gender))),
                _viewRow(context, context.l10n.authDateOfBirth, _formatDobDisplay(p.dob)),
                _viewRow(
                  context,
                  context.l10n.profileBloodGroup,
                  ProfileOptions.normalizeBloodGroup(p.bloodGroup) ?? context.l10n.profileNotSet,
                ),
                _viewRow(context, context.l10n.profileAddress, _addressLabel(p)),
                const SizedBox(height: 16),
                Text(
                  context.l10n.profileEdit,
                  style: GoogleFonts.poppins(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      AvatarImage(uri: p.profilePicUrl, size: 100),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.brandBlue,
                          shape: BoxShape.circle,
                        ),
                        child: _uploadingPhoto
                            ? const Padding(
                                padding: EdgeInsets.all(7),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.camera_alt, size: 15, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  context.l10n.profileEdit,
                  style: GoogleFonts.poppins(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 24),
              _textField(context, label: context.l10n.authFullName, controller: _name),
              _readOnlyField(context, label: context.l10n.authEmail, value: p.email),
              _textField(
                context,
                label: context.l10n.authPhone,
                controller: _phone,
                keyboard: TextInputType.phone,
              ),
              const SizedBox(height: 4),
              _genderDropdown(context),
              const SizedBox(height: 16),
              _dobPicker(context),
              const SizedBox(height: 16),
              _bloodDropdown(context),
              const SizedBox(height: 24),
              Text(
                context.l10n.addressTitle,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
              const SizedBox(height: 12),
              _textField(context, label: context.l10n.profileAddressLine1, controller: _addressLine1, hint: context.l10n.profileAddressLine1),
              _textField(context, label: context.l10n.profileAddressLine2, controller: _addressLine2, hint: context.l10n.profileAddressLine2),
              const SizedBox(height: 8),
              Text(
                context.l10n.commonContinue,
                style: GoogleFonts.poppins(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              AppButton(label: context.l10n.profileSaveChanges, loading: _loading, onPressed: () => _save(p)),
            ],
          );
        },
      ),
    );
  }

  String _formatDobDisplay(String? dob) {
    final raw = ProfileOptions.sanitize(dob);
    if (raw == null) return context.l10n.profileNotSet;
    final parsed = DateTime.tryParse(raw) ?? _tryParseDob(raw);
    if (parsed == null) return raw;
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  Widget _viewRow(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: profileLabelStyle(context)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline),
            ),
            child: Text(
              value,
              style: profileFieldTextStyle(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyField(BuildContext context, {required String label, required String value}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: profileLabelStyle(context)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline),
            ),
            child: Text(value, style: profileFieldTextStyle(context).copyWith(color: cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  Widget _textField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    TextInputType? keyboard,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: profileLabelStyle(context)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            style: profileFieldTextStyle(context),
            decoration: profileInputDecoration(context, hint: hint),
          ),
        ],
      ),
    );
  }

  Widget _genderDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.authGender, style: profileLabelStyle(context)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey(_gender),
          initialValue: _gender,
          decoration: profileInputDecoration(context, hint: context.l10n.authGender),
          style: profileFieldTextStyle(context),
          items: ProfileOptions.genderItems
              .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
              .toList(),
          onChanged: (v) => setState(() => _gender = v),
        ),
      ],
    );
  }

  Widget _bloodDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.profileBloodGroup, style: profileLabelStyle(context)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey(_bloodGroup),
          initialValue: _bloodGroup,
          decoration: profileInputDecoration(context, hint: context.l10n.profileBloodGroup),
          style: profileFieldTextStyle(context),
          items: ProfileOptions.bloodGroups
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: (v) => setState(() => _bloodGroup = v),
        ),
      ],
    );
  }

  Widget _dobPicker(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = _dob == null ? null : DateFormat('dd MMM yyyy').format(_dob!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.authDateOfBirth, style: profileLabelStyle(context)),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickDob,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: profileInputDecoration(context, hint: context.l10n.authSelectDob),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label ?? context.l10n.authSelectDob,
                    style: profileFieldTextStyle(context).copyWith(
                      color: label == null ? cs.onSurfaceVariant : cs.onSurface,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_outlined, size: 20, color: cs.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
