import 'dart:html' as html;
import 'dart:convert';

Future<void> saveAndShareFile(
  String fileName,
  String content,
  String mimeType, {
  String? subject,
  String? text,
}) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName;
    
  html.document.body?.children.add(anchor);
  anchor.click();
  
  // Cleanup
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
