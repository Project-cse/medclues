import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/api_config.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';

/// Public (no-login) visit summary opened from a signed appointment QR URL.
class AppointmentSummaryQrScreen extends ConsumerStatefulWidget {
  const AppointmentSummaryQrScreen({
    super.key,
    required this.bookingId,
    this.sig,
  });

  final String bookingId;
  final String? sig;

  @override
  ConsumerState<AppointmentSummaryQrScreen> createState() =>
      _AppointmentSummaryQrScreenState();
}

class _AppointmentSummaryQrScreenState
    extends ConsumerState<AppointmentSummaryQrScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _appointment;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sig = widget.sig?.trim();
    if (sig == null || sig.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Missing signature. Scan the Visit Summary QR again.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.dio.get(
        ApiConfig.publicAppointmentSummary(widget.bookingId, sig),
      );
      final data = res.data;
      if (data is Map && data['success'] == true && data['appointment'] is Map) {
        setState(() {
          _appointment = Map<String, dynamic>.from(data['appointment'] as Map);
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = (data is Map ? data['message'] : null)?.toString() ??
              'Unable to load visit summary';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Visit summary',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? _errorBody()
              : _summaryBody(),
    );
  }

  Widget _errorBody() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_2, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          Text(
            'Visit summary unavailable',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _summaryBody() {
    final a = _appointment!;
    final rows = <(String, String)>[
      ('Booking ID', '${a['bookingId'] ?? widget.bookingId}'.toUpperCase()),
      if (a['publicId'] != null) ('Public ID', '${a['publicId']}'),
      ('Patient', '${a['patientName'] ?? '—'}'),
      ('Doctor', '${a['doctorName'] ?? '—'}'),
      if (a['specialization'] != null) ('Specialty', '${a['specialization']}'),
      if (a['hospitalName'] != null) ('Hospital', '${a['hospitalName']}'),
      ('Date', '${a['slotDate'] ?? '—'}'),
      ('Time', '${a['slotTime'] ?? '—'}'),
      if (a['tokenNumber'] != null) ('Token', 'A-${a['tokenNumber']}'),
      (
        'Status',
        '${a['lifecycleStatus'] ?? a['status'] ?? '—'}',
      ),
      if (a['completedAt'] != null) ('Completed', '${a['completedAt']}'),
      (
        'Prescription ready',
        a['prescriptionReady'] == true ? 'Yes' : 'No',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          'MEDCLUES',
          style: GoogleFonts.poppins(
            letterSpacing: 2,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF38BDF8),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Scanned appointment details',
          style: GoogleFonts.poppins(
            color: const Color(0xFF94A3B8),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          row.$1,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          row.$2,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Safe summary only — full records stay in your MedClues account.',
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
