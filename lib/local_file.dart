import 'dart:typed_data';

class LocalFile {
  LocalFile(this.name, this.mime, Uint8List bytes)
    : bytes = Uint8List.fromList(bytes).asUnmodifiableView();
  final String name, mime;
  final Uint8List bytes;
  static const maxSize = 10 * 1024 * 1024;

  static String mimeFor(String name) =>
      switch (name.split('.').last.toLowerCase()) {
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        'txt' => 'text/plain',
        _ => throw const FormatException('Поддерживаются PDF, PNG, JPG и TXT.'),
      };

  void validate() {
    if (bytes.isEmpty) {
      throw const FormatException('Файл пуст. Выберите другой файл.');
    }
    if (bytes.length > maxSize) {
      throw const FormatException('Файл больше 10 МБ. Выберите файл поменьше.');
    }
    final expected = mimeFor(name);
    final signature = switch (expected) {
      'application/pdf' => [37, 80, 68, 70, 45],
      'image/png' => [137, 80, 78, 71, 13, 10, 26, 10],
      'image/jpeg' => [255, 216, 255],
      _ => <int>[],
    };
    if (mime != expected ||
        bytes.length < signature.length ||
        signature.indexed.any((p) => bytes[p.$1] != p.$2)) {
      throw const FormatException('Содержимое не соответствует формату файла.');
    }
  }
}
