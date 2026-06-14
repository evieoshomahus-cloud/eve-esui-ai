import 'dart:convert';

import 'package:http/http.dart' as http;

import 'attachment_picker_types.dart';
import 'eve_models.dart';

class EveApi {
  EveApi({List<String>? baseUrls}) : baseUrls = baseUrls ?? _defaultBaseUrls();

  final List<String> baseUrls;
  String? _activeBaseUrl;
  static const Duration requestTimeout = Duration(seconds: 120);
  static const Map<String, String> browserTunnelHeaders = {
    'ngrok-skip-browser-warning': 'true',
  };
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  static List<String> _defaultBaseUrls() {
    final origin = _currentOrigin();
    return [
      ?origin,
      'http://127.0.0.1:8010',
      'http://localhost:8010',
      'http://10.0.2.2:8010',
    ];
  }

  static String? _currentOrigin() {
    final base = Uri.base;
    if (base.scheme == 'http' || base.scheme == 'https') {
      return '${base.scheme}://${base.authority}';
    }
    return null;
  }

  Future<http.Response> _request(
    Future<http.Response> Function(String baseUrl) operation,
  ) async {
    final candidates = [
      ?_activeBaseUrl,
      ...baseUrls.where((url) => url != _activeBaseUrl),
    ];

    Object? lastError;
    for (final baseUrl in candidates) {
      try {
        final response = await operation(baseUrl).timeout(requestTimeout);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          _activeBaseUrl = baseUrl;
          return response;
        }
        lastError = 'HTTP ${response.statusCode}: ${response.body}';
      } catch (error) {
        lastError = error;
      }
    }
    throw Exception('Eve API unavailable: $lastError');
  }

  Future<List<EveUser>> users() async {
    final response = await _request(
      (baseUrl) => http.get(
        Uri.parse('$baseUrl/api/users'),
        headers: browserTunnelHeaders,
      ),
    );
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((item) => EveUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<EveChatResponse> chat({
    required EveRole role,
    required String userId,
    required String message,
    required List<Map<String, String>> history,
    List<String> attachmentIds = const [],
  }) async {
    final response = await _request(
      (baseUrl) => http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: jsonHeaders,
        body: jsonEncode({
          'role': role.value,
          'user_id': userId,
          'message': message,
          'history': history,
          'attachment_ids': attachmentIds,
        }),
      ),
    );
    return EveChatResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<EveAttachment> uploadAttachment({
    required EveRole role,
    required String userId,
    required PickedAttachment file,
  }) async {
    final response = await _request(
      (baseUrl) => http.post(
        Uri.parse('$baseUrl/api/uploads'),
        headers: jsonHeaders,
        body: jsonEncode({
          'role': role.value,
          'user_id': userId,
          'filename': file.name,
          'content_type': file.contentType,
          'base64_data': file.base64Data,
        }),
      ),
    );
    return EveAttachment.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<EveAttachment>> uploads({
    required EveRole role,
    required String userId,
  }) async {
    final response = await _request(
      (baseUrl) => http.get(
        Uri.parse('$baseUrl/api/uploads?role=${role.value}&user_id=$userId'),
        headers: browserTunnelHeaders,
      ),
    );
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((item) => EveAttachment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdmissionEstimate> estimateAdmission({
    required String course,
    required int jambScore,
    required String english,
    required String mathematics,
    required String science,
    required String fourthSubject,
  }) async {
    final response = await _request(
      (baseUrl) => http.post(
        Uri.parse('$baseUrl/api/admissions/estimate'),
        headers: jsonHeaders,
        body: jsonEncode({
          'course': course,
          'jamb_score': jambScore,
          'english': english,
          'mathematics': mathematics,
          'science': science,
          'fourth_subject': fourthSubject,
        }),
      ),
    );
    return AdmissionEstimate.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> studentDashboard(String userId) async {
    final response = await _request(
      (baseUrl) => http.get(
        Uri.parse('$baseUrl/api/student/$userId/dashboard'),
        headers: browserTunnelHeaders,
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> learningProfile(String userId) async {
    final response = await _request(
      (baseUrl) => http.get(
        Uri.parse('$baseUrl/api/student/$userId/learning-profile'),
        headers: browserTunnelHeaders,
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> progressHistory(String userId) async {
    final response = await _request(
      (baseUrl) => http.get(
        Uri.parse('$baseUrl/api/student/$userId/progress-history'),
        headers: browserTunnelHeaders,
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startLearningSession({
    required String userId,
    required String courseCode,
    String? topic,
  }) async {
    final response = await _request(
      (baseUrl) => http.post(
        Uri.parse('$baseUrl/api/learning-sessions'),
        headers: jsonHeaders,
        body: jsonEncode({
          'user_id': userId,
          'course_code': courseCode,
          'topic': topic,
        }),
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitLearningAnswer({
    required String sessionId,
    required String answer,
  }) async {
    final response = await _request(
      (baseUrl) => http.post(
        Uri.parse('$baseUrl/api/learning-sessions/$sessionId/answer'),
        headers: jsonHeaders,
        body: jsonEncode({'answer': answer}),
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> lecturerInsights(String userId) async {
    final response = await _request(
      (baseUrl) => http.get(
        Uri.parse('$baseUrl/api/lecturer/$userId/insights'),
        headers: browserTunnelHeaders,
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> knowledgeStats() async {
    final response = await _request(
      (baseUrl) => http.get(
        Uri.parse('$baseUrl/api/admin/knowledge/stats'),
        headers: browserTunnelHeaders,
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> validateKnowledge() async {
    final response = await _request(
      (baseUrl) => http.get(
        Uri.parse('$baseUrl/api/admin/knowledge/validate'),
        headers: browserTunnelHeaders,
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reloadKnowledge() async {
    final response = await _request(
      (baseUrl) => http.post(
        Uri.parse('$baseUrl/api/admin/knowledge/reload'),
        headers: browserTunnelHeaders,
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Uri _knowledgeUri(
    String baseUrl,
    String path, {
    EveRole? actorRole,
    String? actorUserId,
  }) {
    final uri = Uri.parse('$baseUrl$path');
    if (actorRole == null || actorUserId == null) return uri;
    return uri.replace(
      queryParameters: {
        'actor_role': actorRole.value,
        'actor_user_id': actorUserId,
      },
    );
  }

  Map<String, dynamic> _withActor(
    Map<String, dynamic> payload,
    EveRole actorRole,
    String actorUserId,
  ) {
    return {
      ...payload,
      'actor_role': actorRole.value,
      'actor_user_id': actorUserId,
    };
  }

  Future<Map<String, dynamic>> createKnowledgeEntry(
    Map<String, dynamic> entry, {
    required EveRole actorRole,
    required String actorUserId,
  }) async {
    final response = await _request(
      (baseUrl) => http.post(
        Uri.parse('$baseUrl/api/admin/knowledge/entries'),
        headers: jsonHeaders,
        body: jsonEncode(_withActor(entry, actorRole, actorUserId)),
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> knowledgeEntries({
    EveRole? actorRole,
    String? actorUserId,
  }) async {
    final response = await _request(
      (baseUrl) => http.get(
        _knowledgeUri(
          baseUrl,
          '/api/admin/knowledge/entries',
          actorRole: actorRole,
          actorUserId: actorUserId,
        ),
        headers: browserTunnelHeaders,
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateKnowledgeEntry(
    String entryId,
    Map<String, dynamic> entry, {
    required EveRole actorRole,
    required String actorUserId,
  }) async {
    final response = await _request(
      (baseUrl) => http.put(
        Uri.parse('$baseUrl/api/admin/knowledge/entries/$entryId'),
        headers: jsonHeaders,
        body: jsonEncode(_withActor(entry, actorRole, actorUserId)),
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteKnowledgeEntry(
    String entryId, {
    required EveRole actorRole,
    required String actorUserId,
  }) async {
    final response = await _request(
      (baseUrl) => http.delete(
        _knowledgeUri(
          baseUrl,
          '/api/admin/knowledge/entries/$entryId',
          actorRole: actorRole,
          actorUserId: actorUserId,
        ),
        headers: browserTunnelHeaders,
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> knowledgeGaps({
    EveRole? actorRole,
    String? actorUserId,
  }) async {
    final response = await _request(
      (baseUrl) => http.get(
        _knowledgeUri(
          baseUrl,
          '/api/admin/knowledge/gaps',
          actorRole: actorRole,
          actorUserId: actorUserId,
        ),
        headers: browserTunnelHeaders,
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> knowledgeAudit({
    EveRole? actorRole,
    String? actorUserId,
  }) async {
    final response = await _request(
      (baseUrl) => http.get(
        _knowledgeUri(
          baseUrl,
          '/api/admin/knowledge/audit',
          actorRole: actorRole,
          actorUserId: actorUserId,
        ),
        headers: browserTunnelHeaders,
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateKnowledgeGap(
    String gapId,
    Map<String, dynamic> updates, {
    required EveRole actorRole,
    required String actorUserId,
  }) async {
    final response = await _request(
      (baseUrl) => http.patch(
        Uri.parse('$baseUrl/api/admin/knowledge/gaps/$gapId'),
        headers: jsonHeaders,
        body: jsonEncode(_withActor(updates, actorRole, actorUserId)),
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> studentPeerNotes(String userId) async {
    final response = await _request(
      (baseUrl) => http.get(
        Uri.parse('$baseUrl/api/student/$userId/peer-notes'),
        headers: browserTunnelHeaders,
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitPeerNote({
    required String userId,
    required String courseCode,
    required String title,
    required String summary,
    required String content,
  }) async {
    final response = await _request(
      (baseUrl) => http.post(
        Uri.parse('$baseUrl/api/student/peer-notes'),
        headers: jsonHeaders,
        body: jsonEncode({
          'user_id': userId,
          'course_code': courseCode,
          'title': title,
          'summary': summary,
          'content': content,
        }),
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> peerNoteReviewQueue({
    required EveRole actorRole,
    required String actorUserId,
  }) async {
    final response = await _request(
      (baseUrl) => http.get(
        Uri.parse('$baseUrl/api/admin/peer-notes').replace(
          queryParameters: {
            'actor_role': actorRole.value,
            'actor_user_id': actorUserId,
          },
        ),
        headers: browserTunnelHeaders,
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reviewPeerNote({
    required String noteId,
    required EveRole actorRole,
    required String actorUserId,
    required String status,
    String reviewNotes = '',
  }) async {
    final response = await _request(
      (baseUrl) => http.patch(
        Uri.parse('$baseUrl/api/admin/peer-notes/$noteId'),
        headers: jsonHeaders,
        body: jsonEncode({
          'actor_role': actorRole.value,
          'actor_user_id': actorUserId,
          'status': status,
          'review_notes': reviewNotes,
        }),
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
