import 'attachment_picker_stub.dart'
    if (dart.library.js_interop) 'attachment_picker_web.dart';
import 'attachment_picker_types.dart';

Future<PickedAttachment?> pickAttachment() => pickAttachmentImpl();
