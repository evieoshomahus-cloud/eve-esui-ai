import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'attachment_picker_types.dart';

Future<PickedAttachment?> pickAttachmentImpl() {
  final completer = Completer<PickedAttachment?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept =
        'image/*,.txt,.md,.csv,.json,.pdf,.doc,.docx,application/pdf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document';

  input.onchange = ((web.Event _) {
    final file = input.files?.item(0);
    if (file == null) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final reader = web.FileReader();
    reader.onload = ((web.Event _) {
      final result = reader.result;
      final dataUrl = result == null ? '' : (result as JSString).toDart;
      final commaIndex = dataUrl.indexOf(',');
      final base64Data = commaIndex == -1
          ? dataUrl
          : dataUrl.substring(commaIndex + 1);
      if (!completer.isCompleted) {
        completer.complete(
          PickedAttachment(
            name: file.name,
            contentType: file.type.isEmpty
                ? _contentTypeFromName(file.name)
                : file.type,
            size: file.size,
            base64Data: base64Data,
          ),
        );
      }
    }).toJS;
    reader.onerror = ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError('Could not read file.');
      }
    }).toJS;
    reader.readAsDataURL(file);
  }).toJS;

  input.click();
  return completer.future;
}

String _contentTypeFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.doc')) return 'application/msword';
  if (lower.endsWith('.docx')) {
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }
  if (lower.endsWith('.csv')) return 'text/csv';
  if (lower.endsWith('.json')) return 'application/json';
  if (lower.endsWith('.md')) return 'text/markdown';
  if (lower.endsWith('.txt')) return 'text/plain';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'application/octet-stream';
}
