import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:medtrace/data/models/medication_log_model.dart';
import 'package:medtrace/data/models/medication_model.dart';
import 'package:medtrace/data/models/profile_model.dart';
import 'package:medtrace/data/models/therapy_model.dart';

class PdfReportService {
  static Future<void> generateTreatmentSummary({
    required UserModel patient,
    required TreatmentModel treatment,
    required List<MedicationModel> medications,
    required double adherence,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Header(level: 0, text: 'MedTrace - Treatment Summary'),
          pw.SizedBox(height: 16),
          _buildSection('Patient Information', [
            'Name: ${patient.fullName.isEmpty ? 'N/A' : patient.fullName}',
            'Email: ${patient.email}',
            'Role: ${patient.role}',
          ]),
          pw.SizedBox(height: 16),
          _buildSection('Treatment Details', [
            'Phase: ${treatment.phase.toUpperCase()}',
            'Status: ${treatment.status.toUpperCase()}',
            'Start Date: ${_formatDate(treatment.startDate)}',
            'Days Elapsed: ${treatment.treatmentDaysElapsed}',
            'Adherence: ${adherence.toStringAsFixed(1)}%',
          ]),
          pw.SizedBox(height: 16),
          pw.Text('Medications',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'Dosage', 'Frequency'],
            data: medications
                .map((m) => [m.name, '${m.dosage} ${m.unit}', m.frequency])
                .toList(),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Generated: ${_formatDate(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    ));

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  static Future<void> generateAdherenceReport({
    required UserModel patient,
    required List<MedicationLogModel> logs,
    required double adherence,
  }) async {
    final pdf = pw.Document();
    final taken = logs.where((l) => l.isTaken).length;
    final missed = logs.where((l) => l.isMissed).length;
    final pending = logs.where((l) => l.isPending).length;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Header(level: 0, text: 'MedTrace - Adherence Report'),
        pw.SizedBox(height: 16),
        _buildSection('Patient', [
          'Name: ${patient.fullName.isEmpty ? 'N/A' : patient.fullName}',
          'Email: ${patient.email}',
        ]),
        pw.SizedBox(height: 16),
        _buildSection('Summary', [
          'Overall Adherence: ${adherence.toStringAsFixed(1)}%',
          'Total Logs: ${logs.length}',
          'Taken: $taken',
          'Missed: $missed',
          'Pending: $pending',
        ]),
        pw.SizedBox(height: 16),
        pw.Text('Daily Log',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'Status', 'Notes'],
          data: logs
              .take(50)
              .map((l) => [
                    _formatDate(l.scheduledDate),
                    l.status.toUpperCase(),
                    l.notes ?? '-',
                  ])
              .toList(),
        ),
        pw.SizedBox(height: 24),
        pw.Text(
          'Generated: ${_formatDate(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
      ],
    ));

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  static pw.Widget _buildSection(String title, List<String> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        ...items.map((item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(item, style: const pw.TextStyle(fontSize: 11)),
            )),
      ],
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}
