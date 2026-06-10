import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import 'receipt_location_helper.dart';

/// Appointment receipt data for PDF / share actions.
class AppointmentReceiptData {
  const AppointmentReceiptData({
    required this.bookingId,
    this.tokenNumber,
    required this.patientName,
    required this.doctorName,
    required this.specialization,
    this.hospitalName,
    this.location,
    this.roomNo,
    required this.appointmentDate,
    required this.appointmentTime,
    this.visitType = 'In-clinic',
    this.status = 'Confirmed',
    this.amount,
  });

  final String bookingId;
  final int? tokenNumber;
  final String patientName;
  final String doctorName;
  final String specialization;
  final String? hospitalName;
  final String? location;
  final String? roomNo;
  final String appointmentDate;
  final String appointmentTime;
  final String visitType;
  final String status;
  final num? amount;

  String get qrData => bookingId.toUpperCase();

  String get tokenLabel {
    if (tokenNumber != null && tokenNumber! > 0) return 'A-$tokenNumber';
    return '-';
  }

  ReceiptLocationInfo get locationInfo => parseReceiptLocation(
        addressLine1: location,
        addressLine2: roomNo,
        hospitalName: hospitalName,
      );
}

/// Strip/replace characters Helvetica cannot render in PDF.
String pdfSafe(String? value) {
  if (value == null) return '';
  return value
      .replaceAll('\u2022', '|')
      .replaceAll('\u2014', '-')
      .replaceAll('\u2013', '-')
      .replaceAll('\u2713', '')
      .replaceAll('\u20b9', 'Rs.')
      .replaceAll(RegExp(r'[^\x09\x0A\x0D\x20-\x7E]'), '');
}

Future<Uint8List> buildAppointmentReceiptPdf(AppointmentReceiptData data, AppLocalizations l10n) async {
  final doc = pw.Document();

  final hospital = pdfSafe(
    data.hospitalName?.trim().isNotEmpty == true ? data.hospitalName : 'MediChain+ Network',
  );
  final loc = data.locationInfo;
  final dateTimeLine = pdfSafe('${data.appointmentDate} | ${data.appointmentTime}');
  final generated = pdfSafe(DateTime.now().toLocal().toString().substring(0, 16));

  const greenBanner = PdfColor.fromInt(0xFFECFDF5);
  const greenBorder = PdfColor.fromInt(0xFFA7F3D0);
  const greenText = PdfColor.fromInt(0xFF059669);
  const greenIconBg = PdfColor.fromInt(0xFFD1FAE5);
  const tokenBg = PdfColor.fromInt(0xFFEFF6FF);
  const tokenBlue = PdfColor.fromInt(0xFF2563EB);
  const tokenFooter = PdfColor.fromInt(0xFF1D4ED8);
  const labelColor = PdfColor.fromInt(0xFF64748B);
  const textColor = PdfColor.fromInt(0xFF0F172A);
  const border = PdfColor.fromInt(0xFFE2E8F0);

  final labelStyle = pw.TextStyle(fontSize: 9, color: labelColor);
  final titleStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: textColor);
  final subtitleStyle = pw.TextStyle(fontSize: 10, color: labelColor);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      build: (context) => [
        pw.Text(pdfSafe(AppConfig.appName), style: titleStyle.copyWith(fontSize: 18)),
        pw.SizedBox(height: 4),
        pw.Text(pdfSafe(l10n.receiptAppointmentReceipt), style: labelStyle.copyWith(fontSize: 11)),
        pw.SizedBox(height: 16),
        _confirmationBanner(
          bg: greenBanner,
          borderColor: greenBorder,
          textColor: greenText,
          iconBg: greenIconBg,
          titleStyle: titleStyle,
          labelStyle: labelStyle,
          l10n: l10n,
        ),
        pw.SizedBox(height: 16),
        _ticketCard(
          data: data,
          tokenBg: tokenBg,
          tokenBlue: tokenBlue,
          tokenFooter: tokenFooter,
          border: border,
          titleStyle: titleStyle,
          labelStyle: labelStyle,
          l10n: l10n,
        ),
        pw.SizedBox(height: 16),
        _detailCard(
          border: border,
          rows: [
            _detailRow(
              label: l10n.receiptDoctor,
              title: pdfSafe(data.doctorName),
              subtitle: pdfSafe(data.specialization),
              labelStyle: labelStyle,
              titleStyle: titleStyle,
              subtitleStyle: subtitleStyle,
            ),
            _detailRow(
              label: l10n.receiptDateTime,
              title: dateTimeLine,
              subtitle: pdfSafe('${l10n.receiptPatient}: ${data.patientName}'),
              labelStyle: labelStyle,
              titleStyle: titleStyle,
              subtitleStyle: subtitleStyle,
            ),
            _detailRow(
              label: l10n.receiptHospital,
              title: hospital,
              labelStyle: labelStyle,
              titleStyle: titleStyle,
              subtitleStyle: subtitleStyle,
            ),
            if (loc.hasRoom)
              _detailRow(
                label: l10n.receiptLocation,
                title: pdfSafe(loc.roomNo),
                labelStyle: labelStyle,
                titleStyle: titleStyle,
                subtitleStyle: subtitleStyle,
              ),
            if (loc.hasFloor)
              _detailRow(
                label: l10n.receiptLocation,
                title: pdfSafe(loc.floorOrLocation),
                labelStyle: labelStyle,
                titleStyle: titleStyle,
                subtitleStyle: subtitleStyle,
              ),
            if (data.amount != null)
              _detailRow(
                label: l10n.receiptAmount,
                title: 'Rs.${data.amount!.toStringAsFixed(0)}',
                subtitle: pdfSafe(data.status),
                labelStyle: labelStyle,
                titleStyle: titleStyle,
                subtitleStyle: subtitleStyle,
              ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          pdfSafe(l10n.receiptAppointmentReceipt),
          style: labelStyle.copyWith(fontSize: 10),
        ),
        pw.SizedBox(height: 4),
        pw.Text('Generated: $generated', style: labelStyle.copyWith(fontSize: 9)),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _confirmationBanner({
  required PdfColor bg,
  required PdfColor borderColor,
  required PdfColor textColor,
  required PdfColor iconBg,
  required pw.TextStyle titleStyle,
  required pw.TextStyle labelStyle,
  required AppLocalizations l10n,
}) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: bg,
      borderRadius: pw.BorderRadius.circular(12),
      border: pw.Border.all(color: borderColor),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 36,
          height: 36,
          decoration: pw.BoxDecoration(
            color: iconBg,
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: textColor, width: 1.5),
          ),
          child: pw.Center(
            child: pw.Text(
              'OK',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                pdfSafe(l10n.receiptConfirmed),
                style: titleStyle.copyWith(fontSize: 13, color: textColor),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                pdfSafe(l10n.receiptStatusConfirmed),
                style: labelStyle.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _dashedLinePdf(PdfColor color) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.center,
    children: List.generate(
      14,
      (i) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 2),
        child: pw.Container(width: 5, height: 1.2, color: color),
      ),
    ),
  );
}

pw.Widget _ticketCard({
  required AppointmentReceiptData data,
  required PdfColor tokenBg,
  required PdfColor tokenBlue,
  required PdfColor tokenFooter,
  required PdfColor border,
  required pw.TextStyle titleStyle,
  required pw.TextStyle labelStyle,
  required AppLocalizations l10n,
}) {
  final bookingId = pdfSafe(data.bookingId).toUpperCase();
  final dashColor = PdfColor.fromInt(0xFF93C5FD);

  return pw.Container(
    width: double.infinity,
    height: 200,
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: pw.BorderRadius.circular(12),
      border: pw.Border.all(color: border),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Expanded(
          flex: 11,
          child: pw.Container(
            color: tokenBg,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.fromLTRB(10, 14, 6, 6),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          pdfSafe(l10n.receiptToken),
                          style: labelStyle.copyWith(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: tokenBlue,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        _dashedLinePdf(dashColor),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          pdfSafe(data.tokenLabel),
                          style: titleStyle.copyWith(fontSize: 30, color: tokenBlue),
                        ),
                        pw.SizedBox(height: 8),
                        _dashedLinePdf(dashColor),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          pdfSafe(l10n.receiptToken),
                          style: labelStyle.copyWith(fontSize: 8),
                          textAlign: pw.TextAlign.center,
                        ),
                        if (bookingId.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            bookingId,
                            style: labelStyle.copyWith(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: tokenBlue,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  color: tokenFooter,
                  child: pw.Text(
                    pdfSafe(l10n.receiptDateTime),
                    style: titleStyle.copyWith(fontSize: 9, color: PdfColors.white),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(
          width: 22,
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: List.generate(
              7,
              (i) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Container(width: 1.5, height: 4, color: border),
              ),
            ),
          ),
        ),
        pw.Expanded(
          flex: 10,
          child: pw.Container(
            margin: const pw.EdgeInsets.fromLTRB(0, 10, 10, 10),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFBFDBFE), width: 1.2),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: pdfSafe(data.qrData),
                  width: 88,
                  height: 88,
                  drawText: false,
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  pdfSafe(l10n.receiptBookingId),
                  style: labelStyle.copyWith(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: tokenBlue,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: tokenBg,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFFBFDBFE)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        pdfSafe(l10n.receiptStatus),
                        style: labelStyle.copyWith(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: tokenBlue,
                        ),
                      ),
                      pw.Text(
                        pdfSafe(l10n.receiptAppointmentReceipt),
                        style: labelStyle.copyWith(fontSize: 7, color: tokenBlue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _detailCard({required PdfColor border, required List<pw.Widget> rows}) {
  return pw.Container(
    width: double.infinity,
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: pw.BorderRadius.circular(12),
      border: pw.Border.all(color: border),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) pw.Divider(color: border, height: 1, indent: 16, endIndent: 16),
          rows[i],
        ],
      ],
    ),
  );
}

pw.Widget _detailRow({
  required String label,
  required String title,
  String subtitle = '',
  required pw.TextStyle labelStyle,
  required pw.TextStyle titleStyle,
  required pw.TextStyle subtitleStyle,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: labelStyle),
        pw.SizedBox(height: 2),
        pw.Text(title, style: titleStyle),
        if (subtitle.isNotEmpty) pw.Text(subtitle, style: subtitleStyle),
      ],
    ),
  );
}
