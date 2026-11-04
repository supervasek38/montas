import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'local_file.dart';

Future<LocalFile?> pick() async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.pdf,.png,.jpg,.jpeg,.txt';
  final result = Completer<LocalFile?>();
  input.addEventListener(
    'cancel',
    ((web.Event _) {
      if (!result.isCompleted) result.complete(null);
    }).toJS,
  );
  input.addEventListener(
    'change',
    ((web.Event _) {
      () async {
        try {
          final file = input.files?.item(0);
          if (file == null) {
            result.complete(null);
            return;
          }
          if (file.size > LocalFile.maxSize) {
            throw const FormatException(
              'Файл больше 10 МБ. Выберите файл поменьше.',
            );
          }
          final mime = LocalFile.mimeFor(file.name);
          final buffer = await file.arrayBuffer().toDart;
          final value = LocalFile(file.name, mime, buffer.toDart.asUint8List());
          value.validate();
          result.complete(value);
        } catch (error, stack) {
          result.completeError(error, stack);
        }
      }();
    }).toJS,
  );
  input.click();
  return result.future;
}

String _url(String mime, Uint8List bytes) => web.URL.createObjectURL(
  web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime)),
);

void download(String name, String mime, Uint8List bytes) {
  final url = _url(mime, bytes);
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = name;
  link.click();
  Timer(const Duration(seconds: 60), () => web.URL.revokeObjectURL(url));
}

void preview(LocalFile file) {
  final url = _url(file.mime, file.bytes);
  final link = web.HTMLAnchorElement()
    ..href = url
    ..target = '_blank'
    ..rel = 'noopener noreferrer';
  link.click();
  Timer(const Duration(minutes: 5), () => web.URL.revokeObjectURL(url));
}
