import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  static Future<Uint8List> buildMedicalRecordPdf(Map<String, dynamic> record) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    Map<String, dynamic> patient = (record['patient'] ?? {}) as Map<String, dynamic>;
    Map<String, dynamic> medical = (record['medical'] ?? {}) as Map<String, dynamic>;
    Map<String, dynamic> vitals = (record['vitals'] ?? {}) as Map<String, dynamic>;
    Map<String, dynamic> appointments = (record['appointments'] ?? {}) as Map<String, dynamic>;
    Map<String, dynamic> insurance = (record['insurance'] ?? {}) as Map<String, dynamic>;
    Map<String, dynamic> medicalHistory = (record['medicalHistory'] ?? {}) as Map<String, dynamic>;

    pw.Widget sectionTitle(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
    );

    pw.Widget labeledRow(String label, String? value) => pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(flex: 3, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(width: 8),
        pw.Expanded(flex: 7, child: pw.Text(value ?? '-')),
      ],
    );

    String _safe(dynamic v) => v?.toString() ?? '-';

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TouchHealth Medical Record', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('Generated: ${dateFmt.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.Divider(),

          // Record meta
          labeledRow('Record ID', _safe(record['recordId'])),
          labeledRow('Patient ID', _safe(record['patientId'])),
          labeledRow('Timestamp', _safe(record['timestamp'])),

          // Patient Information
          sectionTitle('Patient Information'),
          labeledRow('Name', _safe(patient['name'])),
          labeledRow('Email', _safe(patient['email'])),
          labeledRow('Phone', _safe(patient['phone'])),
          labeledRow('Username', _safe(patient['username'])),
          labeledRow('Website', _safe(patient['website'])),
          labeledRow('Address', [
            patient['address']?['street'],
            patient['address']?['suite'],
            patient['address']?['city'],
            patient['address']?['zipcode']
          ].where((e) => e != null && e.toString().isNotEmpty).join(', ')),

          // Medical Information
          sectionTitle('Medical Information'),
          labeledRow('Age', _safe(medical['age'])),
          labeledRow('Gender', _safe(medical['gender'])),
          labeledRow('Blood Type', _safe(medical['bloodType'])),
          labeledRow('Height', _safe(medical['height'])),
          labeledRow('Weight', _safe(medical['weight'])),
          labeledRow('Emergency Contact', _safe(medical['emergencyContact']?['name'])),
          labeledRow('Emergency Phone', _safe(medical['emergencyContact']?['phone'])),
          labeledRow('Relationship', _safe(medical['emergencyContact']?['relationship'])),

          // Vitals
          sectionTitle('Vital Signs'),
          labeledRow('Blood Pressure',
              medical['bloodType'] != null // avoid clash with same key
                  ? _safe('${vitals['bloodPressure']?['systolic']}/${vitals['bloodPressure']?['diastolic']} ${vitals['bloodPressure']?['unit']}')
                  : _safe('${vitals['bloodPressure']?['systolic']}/${vitals['bloodPressure']?['diastolic']} ${vitals['bloodPressure']?['unit']}')),
          labeledRow('Heart Rate', _safe('${vitals['heartRate']?['value']} ${vitals['heartRate']?['unit']}')),
          labeledRow('Temperature', _safe('${(vitals['temperature']?['value'])?.toStringAsFixed(1) ?? vitals['temperature']?['value']} ${vitals['temperature']?['unit']}')),
          labeledRow('Oxygen Saturation', _safe('${vitals['oxygenSaturation']?['value']} ${vitals['oxygenSaturation']?['unit']}')),
          labeledRow('Respiratory Rate', _safe('${vitals['respiratoryRate']?['value']} ${vitals['respiratoryRate']?['unit']}')),

          // Medical history lists
          sectionTitle('Medical History'),
          labeledRow('Allergies', ((medicalHistory['allergies'] as List?)?.join(', ')) ?? '-'),
          labeledRow('Chronic Conditions', ((medicalHistory['chronicConditions'] as List?)?.join(', ')) ?? '-'),
          labeledRow('Surgeries', ((medicalHistory['surgeries'] as List?)?.map((e) => e.toString()).join('; ')) ?? '-'),
          labeledRow('Family History', ((medicalHistory['familyHistory'] as List?)?.join(', ')) ?? '-'),

          // Medications
          sectionTitle('Medications'),
          if ((record['medications'] as List?)?.isNotEmpty == true)
            pw.Table(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Dosage')),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Frequency')),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Prescribed By')),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Start Date')),
                  ],
                ),
                ...((record['medications'] as List).map<pw.TableRow>((m) => pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_safe(m['name']))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_safe(m['dosage']))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_safe(m['frequency']))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_safe(m['prescribedBy']))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_safe(m['startDate']))),
                    ])))
              ],
            )
          else
            pw.Text('-'),

          // Lab Results
          sectionTitle('Recent Lab Results'),
          labeledRow('Date', _safe(record['labResults']?['date'])),
          if ((record['labResults']?['results'] as Map?) != null)
            ...((record['labResults']['results'] as Map).entries.map((e) {
              final k = e.key.toString();
              final v = e.value as Map<String, dynamic>;
              final unit = v['unit']?.toString() ?? '';
              final valueStr = v.containsKey('value')
                  ? '${v['value']} $unit'
                  : v.containsKey('total')
                      ? 'Total ${v['total']} $unit, HDL ${v['hdl']} $unit, LDL ${v['ldl']} $unit'
                      : '-';
              final status = v['status']?.toString();
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text('- $k: $valueStr${status != null ? ' ($status)' : ''}'),
              );
            })),

          // Appointments
          sectionTitle('Appointments'),
          labeledRow('Last Visit', _safe(appointments['last']?['date'])),
          labeledRow('Last Doctor', _safe(appointments['last']?['doctor'])),
          labeledRow('Last Department', _safe(appointments['last']?['department'])),
          labeledRow('Next Visit', _safe(appointments['next']?['date'])),
          labeledRow('Next Doctor', _safe(appointments['next']?['doctor'])),
          labeledRow('Next Department', _safe(appointments['next']?['department'])),

          // Insurance
          sectionTitle('Insurance Information'),
          labeledRow('Provider', _safe(insurance['provider'])),
          labeledRow('Policy Number', _safe(insurance['policyNumber'])),
          labeledRow('Group Number', _safe(insurance['groupNumber'])),
          labeledRow('Effective Date', _safe(insurance['effectiveDate'])),
        ],
      ),
    );

    return pdf.save();
  }
}
