import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../models/inspection_report.dart';

class PdfService {
  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;

  static Future<Uint8List> _loadAssetImage(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  static Future<pw.Font> _loadArabicFont({bool bold = false}) async {
    if (bold && _cachedBoldFont != null) return _cachedBoldFont!;
    if (!bold && _cachedRegularFont != null) return _cachedRegularFont!;

    // Using local Amiri font for Arabic text
    try {
      final data = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      final font = pw.Font.ttf(data);
      if (bold) {
        _cachedBoldFont = font;
      } else {
        _cachedRegularFont = font;
      }
      return font;
    } catch (e) {
      print('Error loading local Amiri font: $e');
    }

    // Fallback to network font if local fails
    try {
      final fontUrl = 'https://github.com/google/fonts/raw/main/ofl/amiri/Amiri-Regular.ttf';
      final response = await http.get(Uri.parse(fontUrl));
      if (response.statusCode == 200) {
        final font = pw.Font.ttf(ByteData.view(response.bodyBytes.buffer));
        if (bold) {
          _cachedBoldFont = font;
        } else {
          _cachedRegularFont = font;
        }
        return font;
      }
    } catch (e) {
      print('Error loading font from network: $e');
      // Return default font as last resort
      return pw.Font.helvetica();
    }

    return pw.Font.helvetica();
  }

  static Future<File> generatePdf(InspectionReport report) async {
    final pdf = pw.Document();

    // Load fonts
    final ttfRegular = await _loadArabicFont(bold: false);
    final ttfBold = await _loadArabicFont(bold: true);

    // Load logos
    Uint8List? dacLogo;
    Uint8List? municipalityLogo;
    try {
      dacLogo = await _loadAssetImage('assets/images/dac_logo.png');
      municipalityLogo = await _loadAssetImage('assets/images/municipality_logo.png');
    } catch (e) {
      print('Error loading logos: $e');
    }

    // Load images
    Uint8List? beforeImageBytes;
    Uint8List? afterImageBytes;
    if (report.beforeImage != null) {
      beforeImageBytes = await report.beforeImage!.readAsBytes();
    }
    if (report.afterImage != null) {
      afterImageBytes = await report.afterImage!.readAsBytes();
    }

    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue900, width: 3),
                borderRadius: pw.BorderRadius.circular(20),
              ),
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                children: [
                  // Header with logos
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // Municipality logo (right side in RTL)
                      municipalityLogo != null
                          ? pw.Image(pw.MemoryImage(municipalityLogo), width: 80, height: 80)
                          : pw.Container(width: 80, height: 80),
                      // Header text
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            pw.Text('امانة حفر الباطن',
                                style: pw.TextStyle(font: ttfBold, fontSize: 14)),
                            pw.Text('وكالة الخدمات',
                                style: pw.TextStyle(font: ttfRegular, fontSize: 12)),
                            pw.Text('ادارة التشغيل و الصيانة',
                                style: pw.TextStyle(font: ttfRegular, fontSize: 12)),
                            pw.Text('ادارة صيانة الطرق',
                                style: pw.TextStyle(font: ttfRegular, fontSize: 12)),
                          ],
                        ),
                      ),
                      // DAC logo (left side in RTL)
                      dacLogo != null
                          ? pw.Image(pw.MemoryImage(dacLogo), width: 80, height: 80)
                          : pw.Container(width: 80, height: 80),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  // Title
                  pw.Text('نموذج معاينة',
                      style: pw.TextStyle(font: ttfBold, fontSize: 18)),
                  pw.SizedBox(height: 10),

                  // Images Row - Before on right, After on left
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Before image (right side in RTL)
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            pw.Container(
                              height: 280,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey400, width: 1.5),
                                borderRadius: pw.BorderRadius.circular(8),
                              ),
                              child: pw.ClipRRect(
                                horizontalRadius: 8,
                                verticalRadius: 8,
                                child: beforeImageBytes != null
                                    ? pw.Image(pw.MemoryImage(beforeImageBytes), fit: pw.BoxFit.cover)
                                    : pw.Center(child: pw.Text('قبل', style: pw.TextStyle(font: ttfRegular, fontSize: 16))),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text('قبل', style: pw.TextStyle(font: ttfBold, fontSize: 12)),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 15),
                      // After image (left side in RTL)
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            pw.Container(
                              height: 280,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey400, width: 1.5),
                                borderRadius: pw.BorderRadius.circular(8),
                              ),
                              child: pw.ClipRRect(
                                horizontalRadius: 8,
                                verticalRadius: 8,
                                child: afterImageBytes != null
                                    ? pw.Image(pw.MemoryImage(afterImageBytes), fit: pw.BoxFit.cover)
                                    : pw.Center(child: pw.Text('بعد', style: pw.TextStyle(font: ttfRegular, fontSize: 16))),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text('بعد', style: pw.TextStyle(font: ttfBold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  // Data table (RTL order: right to left)
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey600),
                    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1.5),
                      1: const pw.FlexColumnWidth(1.2),
                      2: const pw.FlexColumnWidth(1.5),
                      3: const pw.FlexColumnWidth(1.2),
                    },
                    children: [
                      // Row 1: Report number and Report date
                      pw.TableRow(
                        children: [
                          _buildTableCell(report.reportNumber ?? '', ttfRegular),
                          _buildTableCell('رقم البلاغ:', ttfBold),
                          _buildTableCell(dateFormat.format(report.reportDate), ttfRegular),
                          _buildTableCell('تاريخ البلاغ :', ttfBold),
                        ],
                      ),
                      // Row 2: Asphalt quantity and Report type
                      pw.TableRow(
                        children: [
                          _buildTableCell('${report.asphaltQuantity?.toStringAsFixed(2) ?? ''} M²', ttfRegular),
                          _buildTableCell('كمية الاسفلت:', ttfBold),
                          _buildTableCell(report.reportType, ttfRegular),
                          _buildTableCell('نوع البلاغ:', ttfBold),
                        ],
                      ),
                      // Row 3: Neighborhood and Closure date
                      pw.TableRow(
                        children: [
                          _buildTableCell(report.neighborhood ?? '', ttfRegular),
                          _buildTableCell('الحي:', ttfBold),
                          _buildTableCell(dateFormat.format(report.closureDate), ttfRegular),
                          _buildTableCell('تاريخ اقفال البلاغ :', ttfBold),
                        ],
                      ),
                      // Row 4: Notes and Day
                      pw.TableRow(
                        children: [
                          _buildTableCell(report.notes ?? '', ttfRegular),
                          _buildTableCell('الملاحظات:', ttfBold),
                          _buildTableCell(report.dayName, ttfRegular),
                          _buildTableCell('اليوم :', ttfBold),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 15),

                  // Coordinates section with QR code (RTL order)
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey600),
                    ),
                    child: pw.Row(
                      children: [
                        // Coordinates table (RTL order)
                        pw.Expanded(
                          child: pw.Table(
                            border: pw.TableBorder.all(color: PdfColors.grey600),
                            columnWidths: {
                              0: const pw.FlexColumnWidth(1.5),
                              1: const pw.FlexColumnWidth(1),
                              2: const pw.FlexColumnWidth(2),
                            },
                            children: [
                              pw.TableRow(
                                children: [
                                  _buildTableCell('', ttfRegular),
                                  _buildTableCell('N', ttfBold),
                                  _buildTableCell('${report.latitude?.toStringAsFixed(5) ?? ''}°', ttfRegular),
                                ],
                              ),
                              pw.TableRow(
                                children: [
                                  _buildTableCell('احداثيات\nالموقع', ttfBold),
                                  _buildTableCell('E', ttfBold),
                                  _buildTableCell('${report.longitude?.toStringAsFixed(6) ?? ''}°', ttfRegular),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // QR Code (right side in RTL)
                        pw.Container(
                          width: 100,
                          height: 100,
                          padding: const pw.EdgeInsets.all(5),
                          child: report.latitude != null && report.longitude != null
                              ? pw.BarcodeWidget(
                                  barcode: pw.Barcode.qrCode(),
                                  data: report.qrData,
                                  width: 90,
                                  height: 90,
                                )
                              : pw.Container(),
                        ),
                      ],
                    ),
                  ),

                  // Signatures text
                  // pw.SizedBox(height: 30),
                  pw.Table(
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Text('الموظف المختص', style: pw.TextStyle(font: ttfBold, fontSize: 12), textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Text('مراقب الأمانة', style: pw.TextStyle(font: ttfBold, fontSize: 12), textAlign: pw.TextAlign.center),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/inspection_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static pw.Widget _buildTableCell(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 11),
        textAlign: pw.TextAlign.center,
        softWrap: true,
        maxLines: 3,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }
}
