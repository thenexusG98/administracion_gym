import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

/// Datos necesarios para generar un recibo
class ReceiptData {
  final String receiptNumber;
  final String studentName;
  final String studentPhone;
  final String plan;
  final double amount;
  final DateTime paymentDate;
  final DateTime? nextPaymentDate;
  final String concept;

  ReceiptData({
    required this.receiptNumber,
    required this.studentName,
    required this.studentPhone,
    required this.plan,
    required this.amount,
    required this.paymentDate,
    this.nextPaymentDate,
    this.concept = 'Mensualidad',
  });
}

class ReceiptService {
  static final ReceiptService _instance = ReceiptService._internal();
  factory ReceiptService() => _instance;
  ReceiptService._internal();

  Uint8List? _logoBytes;

  /// Carga el logo una sola vez
  Future<Uint8List?> _loadLogo() async {
    if (_logoBytes != null) return _logoBytes;
    try {
      final data = await rootBundle.load('assets/images/logo_valhalla_192.png');
      _logoBytes = data.buffer.asUint8List();
      return _logoBytes;
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════
  // COLORES del PDF (Valhalla theme)
  // ═══════════════════════════════════════════
  static const _gold = PdfColor.fromInt(0xFFD4A843);
  static const _darkBg = PdfColor.fromInt(0xFF1A1A2E);
  static const _cardBg = PdfColor.fromInt(0xFF1E1E32);
  static const _white = PdfColor.fromInt(0xFFF5F5F5);
  static const _grey = PdfColor.fromInt(0xFFB0B0B0);
  static const _divider = PdfColor.fromInt(0xFF2A2A4A);
  static const _success = PdfColor.fromInt(0xFF4CAF50);
  static const _red = PdfColor.fromInt(0xFFC62828);

  // ═══════════════════════════════════════════
  // GENERAR PDF
  // ═══════════════════════════════════════════

  Future<Uint8List> generateReceipt(ReceiptData data) async {
    final pdf = pw.Document();
    final logoBytes = await _loadLogo();
    pw.ImageProvider? logoImage;

    if (logoBytes != null) {
      logoImage = pw.MemoryImage(logoBytes);
    }

    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (context) {
          return pw.Container(
            color: _darkBg,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // ═══ HEADER ═══
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      color: _cardBg,
                      borderRadius: pw.BorderRadius.circular(12),
                      border: pw.Border.all(color: _divider),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Row(
                          children: [
                            if (logoImage != null)
                              pw.Container(
                                width: 50,
                                height: 50,
                                child: pw.ClipOval(
                                  child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                                ),
                              ),
                            pw.SizedBox(width: 12),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'VALHALLA BJJ',
                                  style: pw.TextStyle(
                                    color: _gold,
                                    fontSize: 22,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'Academia de Jiu-Jitsu Brasileño',
                                  style: const pw.TextStyle(
                                    color: _grey,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: pw.BoxDecoration(
                                color: _success,
                                borderRadius: pw.BorderRadius.circular(8),
                              ),
                              child: pw.Text(
                                'PAGADO',
                                style: pw.TextStyle(
                                  color: _white,
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              'Recibo #${data.receiptNumber}',
                              style: const pw.TextStyle(
                                color: _grey,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 16),

                  // ═══ TÍTULO ═══
                  pw.Center(
                    child: pw.Text(
                      'RECIBO DE PAGO',
                      style: pw.TextStyle(
                        color: _white,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // ═══ DATOS DEL ALUMNO ═══
                  _buildSection(
                    title: 'DATOS DEL ALUMNO',
                    icon: '🥋',
                    children: [
                      _buildInfoRow('Nombre', data.studentName),
                      _buildInfoRow('Teléfono', data.studentPhone),
                      _buildInfoRow('Plan', data.plan),
                    ],
                  ),

                  pw.SizedBox(height: 16),

                  // ═══ DETALLE DEL PAGO ═══
                  _buildSection(
                    title: 'DETALLE DEL PAGO',
                    icon: '💰',
                    children: [
                      _buildInfoRow('Concepto', data.concept),
                      _buildInfoRow('Fecha de pago', dateTimeFormat.format(data.paymentDate)),
                      if (data.nextPaymentDate != null)
                        _buildInfoRow(
                          'Próximo pago',
                          dateFormat.format(data.nextPaymentDate!),
                        ),
                    ],
                  ),

                  pw.SizedBox(height: 16),

                  // ═══ MONTO ═══
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      color: _cardBg,
                      borderRadius: pw.BorderRadius.circular(12),
                      border: pw.Border.all(color: _gold, width: 1.5),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'TOTAL PAGADO',
                          style: pw.TextStyle(
                            color: _grey,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.Text(
                          currencyFormat.format(data.amount),
                          style: pw.TextStyle(
                            color: _gold,
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 24),

                  // ═══ SEPARADOR ═══
                  pw.Container(
                    width: double.infinity,
                    height: 1,
                    color: _divider,
                  ),

                  pw.SizedBox(height: 16),

                  // ═══ FOOTER ═══
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Gracias por ser parte de Valhalla BJJ',
                          style: pw.TextStyle(
                            color: _gold,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Este recibo es un comprobante de pago válido',
                          style: const pw.TextStyle(
                            color: _grey,
                            fontSize: 9,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Generado el ${dateTimeFormat.format(DateTime.now())}',
                          style: const pw.TextStyle(
                            color: _divider,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════
  // WIDGETS AUXILIARES DEL PDF
  // ═══════════════════════════════════════════

  pw.Widget _buildSection({
    required String title,
    required String icon,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _cardBg,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _divider),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$icon  $title',
            style: pw.TextStyle(
              color: _gold,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(height: 1, color: _divider),
          pw.SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(color: _grey, fontSize: 11),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: _white,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ACCIONES
  // ═══════════════════════════════════════════

  /// Muestra vista previa del PDF con opciones de imprimir/compartir
  Future<void> previewReceipt(ReceiptData data) async {
    final pdfBytes = await generateReceipt(data);
    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: 'Recibo_${data.studentName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(data.paymentDate)}',
    );
  }

  /// Comparte el recibo como PDF vía WhatsApp, etc.
  Future<void> shareReceipt(ReceiptData data) async {
    final pdfBytes = await generateReceipt(data);
    final dir = await getTemporaryDirectory();
    final fileName = 'Recibo_${data.studentName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(data.paymentDate)}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '🥋 Recibo de pago - Valhalla BJJ\n'
          '${data.studentName} - ${DateFormat('dd/MM/yyyy').format(data.paymentDate)}',
    );
  }

  /// Guarda el PDF en el directorio de documentos
  Future<String> saveReceipt(ReceiptData data) async {
    final pdfBytes = await generateReceipt(data);
    final dir = await getApplicationDocumentsDirectory();
    final receiptDir = Directory('${dir.path}/recibos');
    if (!await receiptDir.exists()) {
      await receiptDir.create(recursive: true);
    }
    final fileName = 'Recibo_${data.receiptNumber}_${data.studentName.replaceAll(' ', '_')}.pdf';
    final file = File('${receiptDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }
}
