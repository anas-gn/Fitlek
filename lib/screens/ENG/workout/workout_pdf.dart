import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import '../../../services/locale_service.dart';
import 'workout_ui.dart';

Future<Uint8List> workoutPlanPDF(WorkoutPlan plan,
    {PdfPageFormat format = PdfPageFormat.a4}) async {
  final regular = pw.Font.ttf(
      await rootBundle.load('assets/workout/fonts/Roboto-Regular.ttf'));
  final bold = pw.Font.ttf(
      await rootBundle.load('assets/workout/fonts/Roboto-Bold.ttf'));
  final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      title: 'SIRVYA Workout - ${plan.name}',
      author: 'SIRVYA');
  String label(String value) =>
      workoutTranslate(value, LocaleService.instance.locale.languageCode)
          .replaceAll('—', '-')
          .replaceAll('’', "'")
          .replaceAll('×', 'x');
  doc.addPage(pw.MultiPage(
      pageFormat: format,
      maxPages: 200,
      header: (_) => pw.Text('SIRVYA Workout',
          style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
              color: PdfColors.green800)),
      footer: (c) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('${c.pageNumber} / ${c.pagesCount}',
              style: const pw.TextStyle(fontSize: 9))),
      build: (_) => [
            pw.SizedBox(height: 16),
            pw.Text(label(plan.name),
                style: const pw.TextStyle(
                    fontSize: 26, fontWeight: pw.FontWeight.bold)),
            if (plan.description.isNotEmpty)
              pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10),
                  child: pw.Text(label(plan.description))),
            for (final day in plan.days) ...[
              pw.SizedBox(height: 20),
              pw.Text(label(day.name),
                  style: const pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                  headers: ['Exercise', 'Sets', 'Target', 'Rest']
                      .map(label)
                      .toList(),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  headerStyle: const pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.grey200),
                  data: day.exercises
                      .map((e) => [
                            label(
                                '${e.exercise.name}${e.supersetGroup.isEmpty ? '' : ' (${e.supersetGroup})'}'),
                            '${e.sets}',
                            label(e.exercise.isTimed
                                ? '${e.durationSeconds} sec'
                                : '${e.reps} reps / ${workoutValue(WorkoutService.displayWeight(e.weight ?? 0))} ${WorkoutService.unit}'),
                            label('${e.restSeconds} sec')
                          ])
                      .toList()),
              for (final e in day.exercises.where((e) => e.notes.isNotEmpty))
                pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 6),
                    child: pw.Text(label('${e.exercise.name}: ${e.notes}'),
                        style: const pw.TextStyle(fontSize: 10)))
            ]
          ]));
  return doc.save();
}

Future<void> printWorkoutPlan(WorkoutPlan plan) => Printing.layoutPdf(
    name: 'SIRVYA Workout.pdf',
    onLayout: (format) => workoutPlanPDF(plan, format: format));
