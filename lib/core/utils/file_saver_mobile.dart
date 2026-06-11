import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndShareFile(
  String fileName,
  String content,
  String mimeType, {
  String? subject,
  String? text,
}) async {
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/$fileName';
  
  final file = File(filePath);
  await file.writeAsString(content, flush: true);
  
  final xFile = XFile(filePath, mimeType: mimeType);
  await Share.shareXFiles(
    [xFile],
    subject: subject,
    text: text,
  );
}
