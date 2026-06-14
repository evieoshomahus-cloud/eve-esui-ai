enum EveRole {
  guest,
  student,
  lecturer,
  admin;

  String get value => name;

  String get label {
    switch (this) {
      case EveRole.guest:
        return 'Guest';
      case EveRole.student:
        return 'Student';
      case EveRole.lecturer:
        return 'Lecturer';
      case EveRole.admin:
        return 'Admin';
    }
  }
}

class EveUser {
  const EveUser({
    required this.userId,
    required this.name,
    required this.role,
    this.department,
    this.level,
  });

  final String userId;
  final String name;
  final EveRole role;
  final String? department;
  final String? level;

  factory EveUser.fromJson(Map<String, dynamic> json) {
    return EveUser(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      role: EveRole.values.firstWhere((role) => role.value == json['role']),
      department: json['department'] as String?,
      level: json['level'] as String?,
    );
  }
}

class EveSource {
  const EveSource({
    required this.title,
    required this.category,
    required this.audience,
    this.sourceUrl,
    this.sourceLabel = 'Curated ESUI Knowledge',
    this.verified = true,
    this.updated,
  });

  final String title;
  final String category;
  final List<String> audience;
  final String? sourceUrl;
  final String sourceLabel;
  final bool verified;
  final String? updated;

  factory EveSource.fromJson(Map<String, dynamic> json) {
    return EveSource(
      title: json['title'] as String,
      category: json['category'] as String,
      audience: (json['audience'] as List<dynamic>).cast<String>(),
      sourceUrl: json['source_url'] as String?,
      sourceLabel: json['source_label'] as String? ?? 'Curated ESUI Knowledge',
      verified: json['verified'] as bool? ?? true,
      updated: json['updated'] as String?,
    );
  }
}

class EveChatResponse {
  const EveChatResponse({
    required this.answer,
    required this.intent,
    required this.blocked,
    required this.confidence,
    required this.sources,
    required this.nextActions,
    required this.audit,
  });

  final String answer;
  final String intent;
  final bool blocked;
  final double confidence;
  final List<EveSource> sources;
  final List<String> nextActions;
  final Map<String, dynamic> audit;

  factory EveChatResponse.fromJson(Map<String, dynamic> json) {
    return EveChatResponse(
      answer: json['answer'] as String,
      intent: json['intent'] as String,
      blocked: json['blocked'] as bool,
      confidence: (json['confidence'] as num).toDouble(),
      sources: (json['sources'] as List<dynamic>)
          .map((source) => EveSource.fromJson(source as Map<String, dynamic>))
          .toList(),
      nextActions: (json['next_actions'] as List<dynamic>).cast<String>(),
      audit: json['audit'] as Map<String, dynamic>,
    );
  }
}

class EveAttachment {
  const EveAttachment({
    required this.id,
    required this.filename,
    required this.contentType,
    required this.kind,
    required this.size,
    required this.createdAt,
    this.preview = '',
  });

  final String id;
  final String filename;
  final String contentType;
  final String kind;
  final int size;
  final String createdAt;
  final String preview;

  factory EveAttachment.fromJson(Map<String, dynamic> json) {
    return EveAttachment(
      id: json['id'] as String,
      filename: json['filename'] as String,
      contentType: json['content_type'] as String,
      kind: json['kind'] as String,
      size: json['size'] as int,
      createdAt: json['created_at'] as String,
      preview: json['preview'] as String? ?? '',
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.fromUser,
    this.blocked = false,
    this.intent,
    this.confidence,
    this.sources = const [],
    this.nextActions = const [],
    this.modelMode,
  });

  final String text;
  final bool fromUser;
  final bool blocked;
  final String? intent;
  final double? confidence;
  final List<EveSource> sources;
  final List<String> nextActions;
  final String? modelMode;
}

class AdmissionEstimate {
  const AdmissionEstimate({
    required this.course,
    required this.readinessScore,
    required this.band,
    required this.reasons,
    required this.recommendations,
  });

  final String course;
  final int readinessScore;
  final String band;
  final List<String> reasons;
  final List<String> recommendations;

  factory AdmissionEstimate.fromJson(Map<String, dynamic> json) {
    return AdmissionEstimate(
      course: json['course'] as String,
      readinessScore: json['readiness_score'] as int,
      band: json['band'] as String,
      reasons: (json['reasons'] as List<dynamic>).cast<String>(),
      recommendations: (json['recommendations'] as List<dynamic>)
          .cast<String>(),
    );
  }
}
