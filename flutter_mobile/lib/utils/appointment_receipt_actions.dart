import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import 'appointment_receipt_pdf.dart';

class AppointmentReceiptActions {
  const AppointmentReceiptActions._();

  static Future<void> downloadOrSharePdf(AppointmentReceiptData receipt, AppLocalizations l10n) async {
    final bytes = await buildAppointmentReceiptPdf(receipt, l10n);
    final name = 'MediChain_Receipt_${receipt.bookingId}.pdf';
    if (kIsWeb) {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
      return;
    }
    await Printing.sharePdf(bytes: bytes, filename: name);
  }

  static Future<void> shareReceipt(AppointmentReceiptData receipt, AppLocalizations l10n) async {
    final bytes = await buildAppointmentReceiptPdf(receipt, l10n);
    final text =
        'MediChain+ Appointment\nBooking ID: ${receipt.bookingId.toUpperCase()}\n'
        'Token: ${receipt.tokenNumber ?? '—'}\n'
        'Doctor: ${receipt.doctorName}\n'
        '${receipt.appointmentDate} at ${receipt.appointmentTime}';

    if (kIsWeb) {
      await Share.share(text);
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/MediChain_${receipt.bookingId}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: text);
  }

  static String _shareText(AppointmentReceiptData receipt) {
    return 'MediChain+ Appointment Receipt\n'
        'Booking ID: ${receipt.bookingId.toUpperCase()}\n'
        'Token: ${receipt.tokenNumber != null ? 'A-${receipt.tokenNumber}' : '—'}\n'
        'Doctor: ${receipt.doctorName}\n'
        '${receipt.specialization}\n'
        '${receipt.appointmentDate} • ${receipt.appointmentTime}\n'
        '${receipt.hospitalName ?? ''}';
  }

  static Future<void> shareWhatsApp(AppointmentReceiptData receipt) async {
    final text = Uri.encodeComponent(_shareText(receipt));
    final uri = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await Share.share(_shareText(receipt));
    }
  }

  static Future<void> shareEmail(AppointmentReceiptData receipt) async {
    final subject = Uri.encodeComponent('MediChain+ Appointment ${receipt.bookingId.toUpperCase()}');
    final body = Uri.encodeComponent(_shareText(receipt));
    final uri = Uri.parse('mailto:?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await Share.share(_shareText(receipt));
    }
  }

  static Future<void> printReceipt(AppointmentReceiptData receipt, AppLocalizations l10n) async {
    final bytes = await buildAppointmentReceiptPdf(receipt, l10n);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}
