class Note {
  final String id;
  final String content;
  final String timestamp;

  Note({
    required this.id,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'id': id,
      'content': content,
      'timestamp': timestamp,
    };
  }

  factory Note.fromFirestore(Map<String, dynamic>? map) {
    return Note(
      id: map?['id'] ?? '',
      content: map?['content'] ?? '',
      timestamp: map?['timestamp'] ?? '',
    );
  }
}
