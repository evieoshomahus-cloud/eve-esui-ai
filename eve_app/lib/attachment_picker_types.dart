class PickedAttachment {
  const PickedAttachment({
    required this.name,
    required this.contentType,
    required this.size,
    required this.base64Data,
  });

  final String name;
  final String contentType;
  final int size;
  final String base64Data;

  String get displayType {
    if (contentType.startsWith('image/')) return 'Image';
    if (contentType == 'application/pdf') return 'PDF';
    if (contentType.contains('word')) return 'Word';
    if (contentType.startsWith('text/')) return 'Text';
    return 'File';
  }
}
