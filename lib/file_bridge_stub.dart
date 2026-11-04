import 'dart:typed_data';
import 'local_file.dart';

Future<LocalFile?> pick() async => null;
void download(String name, String mime, Uint8List bytes) =>
    throw UnsupportedError('Скачивание доступно в веб-версии.');
void preview(LocalFile file) =>
    throw UnsupportedError('Просмотр PDF доступен в веб-версии.');
