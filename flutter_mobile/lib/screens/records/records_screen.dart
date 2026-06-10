import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/l10n_extension.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_context.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_record_provider.dart';
import '../../providers/service_providers.dart';
import '../../services/app_permissions_service.dart';
import '../../services/health_record_service.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_loader.dart';
import '../../utils/report_file_opener.dart';
import '../../widgets/animations/upload_progress_button.dart';
import '../../widgets/common/app_snackbar.dart';

/// Health records + upload — styled to match MediChain+ (Poppins, teal/navy).
class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  final _title = TextEditingController();
  String _recordType = 'lab_report';
  bool _uploading = false;
  bool _uploadSuccess = false;
  bool _openingReport = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  String _reportFileName(HealthRecordItem record) {
    if (record.files.isNotEmpty) {
      final name = record.files.first['fileName']?.toString();
      if (name != null && name.isNotEmpty) return name;
    }
    return 'report.pdf';
  }

  String? _reportMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return null;
  }

  Future<void> _viewReport(HealthRecordItem record) async {
    final l10n = context.l10n;
    if (record.files.isEmpty) {
      AppSnackbar.show(context, l10n.recordsNoFile);
      return;
    }
    if (record.id.isEmpty) {
      AppSnackbar.show(context, l10n.recordsIdMissing);
      return;
    }
    if (_openingReport) return;

    setState(() => _openingReport = true);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(l10n.recordsOpening)),
            ],
          ),
        ),
      ),
    );

    try {
      final service = ref.read(healthRecordServiceProvider);
      if (kIsWeb) {
        final url = record.primaryFileUrl ??
            await service.fetchViewUrl(record.id);
        final uri = Uri.parse(url);
        final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!opened) {
          throw Exception(l10n.recordsOpenFailed);
        }
      } else {
        final bytes = await service.downloadReportFile(record.id);
        final fileName = _reportFileName(record);
        await openReportBytes(
          bytes,
          fileName,
          mimeType: _reportMimeType(fileName),
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _openingReport = false);
      }
    }
  }

  Future<void> _pickAndUpload() async {
    final l10n = context.l10n;
    final user = ref.read(authProvider).user;
    if (user == null) {
      AppSnackbar.show(context, l10n.recordsLoginRequired);
      return;
    }
    final titleError = Validators.reportTitle(_title.text, l10n);
    if (titleError != null) {
      AppSnackbar.show(context, titleError);
      return;
    }

    final photosOk = await AppPermissionsService.ensurePhotos();
    if (!photosOk && mounted) {
      AppSnackbar.show(context, l10n.permissionsFiles);
      await AppPermissionsService.openSettingsIfPermanentlyDenied(Permission.photos);
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (picked == null || picked.files.isEmpty) return;

    setState(() {
      _uploading = true;
      _uploadSuccess = false;
    });
    try {
      await ref.read(healthRecordServiceProvider).upload(
            userId: user.id,
            docId: '0',
            doctorName: 'General',
            title: _title.text.trim(),
            recordType: _recordType,
            files: picked.files,
          );
      ref.invalidate(healthRecordsProvider);
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadSuccess = true;
        });
        AppSnackbar.show(context, l10n.recordsUploadSuccess, success: true);
        _title.clear();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _uploadSuccess = false);
        });
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString());
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final records = ref.watch(healthRecordsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.logoTeal,
          onRefresh: () async => ref.invalidate(healthRecordsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                l10n.recordsTitle,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: context.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.recordsSubtitle,
                style: GoogleFonts.poppins(fontSize: 14, color: context.secondaryText),
              ),
              const SizedBox(height: 24),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.logoTeal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cloud_upload_outlined, color: AppColors.logoTeal, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.recordsUpload,
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _title,
                      style: GoogleFonts.poppins(fontSize: 15),
                      decoration: InputDecoration(
                        labelText: l10n.recordsTitleLabel,
                        hintText: l10n.recordsTitleHint,
                        labelStyle: GoogleFonts.poppins(color: context.secondaryText),
                        hintStyle: GoogleFonts.poppins(color: context.hintText, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _recordType,
                      style: GoogleFonts.poppins(fontSize: 15, color: context.primaryText),
                      decoration: InputDecoration(
                        labelText: l10n.recordsType,
                        labelStyle: GoogleFonts.poppins(color: context.secondaryText),
                      ),
                      items: [
                        DropdownMenuItem(value: 'lab_report', child: Text(l10n.recordsTypeLab)),
                        DropdownMenuItem(value: 'prescription', child: Text(l10n.recordsTypePrescription)),
                        DropdownMenuItem(value: 'xray', child: Text(l10n.recordsTypeXray)),
                        DropdownMenuItem(value: 'other', child: Text(l10n.recordsTypeOther)),
                      ],
                      onChanged: (v) => setState(() => _recordType = v ?? 'lab_report'),
                    ),
                    const SizedBox(height: 20),
                    UploadProgressButton(
                      state: _uploadSuccess
                          ? UploadButtonState.success
                          : _uploading
                              ? UploadButtonState.uploading
                              : UploadButtonState.idle,
                      onPressed: _pickAndUpload,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: context.secondaryText.withValues(alpha: 0.8)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.recordsFileTypesHint(l10n.recordsMaxSize),
                            style: GoogleFonts.poppins(fontSize: 12, color: context.secondaryText),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.recordsYourReports,
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              records.when(
                loading: () => const Padding(padding: EdgeInsets.all(32), child: AppLoader()),
                error: (e, _) => _emptyState(
                  icon: Icons.error_outline,
                  message: e.toString(),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return _emptyState(
                      icon: Icons.folder_open_outlined,
                      message: l10n.recordsEmpty,
                      subtitle: l10n.recordsEmptyUploadHint,
                    );
                  }
                  return Column(
                    children: list.map((r) => _reportTile(r)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportTile(HealthRecordItem r) {
    final hasFile = r.files.isNotEmpty;
    final fileName = r.files.isNotEmpty
        ? (r.files.first['fileName'] ?? 'Report file').toString()
        : r.title;
    final dateStr = r.date != null ? _formatRecordDate(r.date!) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: context.cardDecoration(radius: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasFile ? () => _viewReport(r) : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.highlightBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: Color(0xFF2563EB), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 12, color: context.secondaryText),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatType(r.recordType)}${dateStr != null ? ' · $dateStr' : ''}',
                        style: GoogleFonts.poppins(fontSize: 11, color: context.hintText),
                      ),
                      if (hasFile) ...[
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.recordsViewReport,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  hasFile ? Icons.open_in_new : Icons.check_circle,
                  color: hasFile ? AppColors.primaryBlue : const Color(0xFF16A34A),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _formatRecordDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.length > 10 ? raw.substring(0, 10) : raw;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: context.cardDecoration(radius: 20),
      child: child,
    );
  }

  Widget _emptyState({required IconData icon, required String message, String? subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: context.secondaryText.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 15, color: context.secondaryText, fontWeight: FontWeight.w500),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: context.secondaryText),
            ),
          ],
        ],
      ),
    );
  }

  String _formatType(String type) {
    final l10n = context.l10n;
    switch (type) {
      case 'lab_report':
        return l10n.recordsTypeLab;
      case 'prescription':
        return l10n.recordsTypePrescription;
      case 'xray':
        return l10n.recordsTypeXray;
      default:
        return l10n.recordsTypeOther;
    }
  }
}
