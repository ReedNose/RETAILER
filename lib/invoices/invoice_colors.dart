import 'package:pdf/pdf.dart';

// The invoice palette, same hex values as the app and the reference page.
// PdfColor.fromHex is not const, so these are plain finals.
final invoice_ink = PdfColor.fromHex('#0F172A');
final invoice_soft = PdfColor.fromHex('#64748B');
final invoice_line = PdfColor.fromHex('#E2E8F0');
final invoice_blue = PdfColor.fromHex('#2563EB');
final invoice_tint = PdfColor.fromHex('#EFF6FF');
final invoice_green = PdfColor.fromHex('#10B981');
