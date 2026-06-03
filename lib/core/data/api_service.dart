import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:mobile_app/core/models/app_models.dart';

class ApiService {
  ApiService({String? baseUrl})
      : baseUrl = baseUrl ??
            (_defaultBaseUrl());

  final String baseUrl;
  String? _token;

  static String _defaultBaseUrl() {
    if (kIsWeb) return 'http://localhost:5253';
    return Platform.isAndroid ? 'http://10.0.2.2:5253' : 'http://localhost:5253';
  }

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Map<String, String> get headers => _headers;

  Future<AppUser> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      setToken(token);
      return AppUser(
        fullName: data['userName'] as String? ?? 'Learner',
        email: data['email'] as String? ?? email,
        role: data['role'] as String? ?? 'Student',
      );
    } else {
      final msg = _parseErrorMessage(response);
      throw Exception(msg);
    }
  }

  Future<AppUser> register(String fullName, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'userName': fullName,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      setToken(token);
      return AppUser(
        fullName: data['userName'] as String? ?? fullName,
        email: data['email'] as String? ?? email,
        role: data['role'] as String? ?? 'Student',
      );
    } else {
      final msg = _parseErrorMessage(response);
      throw Exception(msg);
    }
  }

  Future<List<Topic>> getTopics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/topics'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) {
        final id = json['id'] as String;
        final title = json['title'] as String? ?? '';
        final description = json['description'] as String? ?? '';
        final order = json['order'] as int? ?? 0;
        final lessonCount = json['lessonCount'] as int? ?? 0;

        // Dynamic properties mapping
        final isLinux = _isLinuxTopic(title, description);
        final category = isLinux ? TopicCategory.linux : TopicCategory.cybersecurity;
        final categoryColorHex = isLinux ? '#F0B328' : '#2CA56E';
        final difficulty = (title.toLowerCase().contains('intro') ||
                title.toLowerCase().contains('basic') ||
                order <= 2)
            ? TopicDifficulty.beginner
            : TopicDifficulty.intermediate;

        final iconKey = _getIconKey(title);
        final illustrationHint = title.toLowerCase().replaceAll(RegExp(r'\s+'), '_');

        // Truncate description for shortDescription
        final sentences = description.split('.');
        var shortDesc = sentences.isNotEmpty && sentences.first.trim().isNotEmpty
            ? '${sentences.first.trim()}.'
            : title;
        if (shortDesc.length > 80) {
          shortDesc = '${shortDesc.substring(0, 77)}...';
        }

        return Topic(
          id: id,
          title: title,
          description: description,
          shortDescription: shortDesc,
          category: category,
          difficulty: difficulty,
          order: order,
          estimatedLessonCount: lessonCount,
          iconKey: iconKey,
          illustrationHint: illustrationHint,
          categoryColorHex: categoryColorHex,
          lessons: const [], // Will be loaded dynamically
          quizQuestions: const [], // Will be loaded dynamically
        );
      }).toList();
    } else {
      final msg = _parseErrorMessage(response);
      throw Exception(msg);
    }
  }

  Future<List<Lesson>> getLessons(String topicId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/topics/$topicId/lessons'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) {
        final id = json['id'] as String;
        final title = json['title'] as String? ?? '';
        final order = json['order'] as int? ?? 0;

        return Lesson(
          id: id,
          title: title,
          summary: 'Read chapter $order of this learning journey.',
          content: '', // Load full content on demand
          minutes: 5,
          order: order,
        );
      }).toList();
    } else {
      final msg = _parseErrorMessage(response);
      throw Exception(msg);
    }
  }

  Future<Lesson> getLessonById(String lessonId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/lessons/$lessonId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final id = data['id'] as String;
      final title = data['title'] as String? ?? '';
      final content = data['content'] as String? ?? '';
      final order = data['order'] as int? ?? 0;

      // Extract summary and estimate read time
      final sentences = content.split('.');
      final summary = sentences.isNotEmpty && sentences.first.trim().isNotEmpty
          ? '${sentences.first.trim()}.'
          : 'Read chapter $order of this learning journey.';

      final words = content.split(RegExp(r'\s+')).length;
      final minutes = (words / 150).ceil().clamp(2, 20);

      return Lesson(
        id: id,
        title: title,
        summary: summary,
        content: content,
        minutes: minutes,
        order: order,
      );
    } else {
      final msg = _parseErrorMessage(response);
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> getQuiz(String topicId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/topics/$topicId/quiz'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final quizId = data['id'] as String;
      final title = data['title'] as String? ?? '';
      final List questionsRaw = data['questions'] as List? ?? [];

      final List<QuizQuestion> questions = questionsRaw.map((q) {
        final qId = q['id'] as String;
        final prompt = q['questionText'] as String? ?? '';
        final List optionsRaw = q['options'] as List? ?? [];

        final List<String> options = [];
        final List<String> optionIds = [];

        for (final opt in optionsRaw) {
          options.add(opt['optionText'] as String? ?? '');
          optionIds.add(opt['id'] as String);
        }

        return QuizQuestion(
          id: qId,
          prompt: prompt,
          options: options,
          correctIndex: 0, // Server-evaluated, so fallback to 0 locally
          feedback: 'Trial evaluated by the Oracle.',
          optionIds: optionIds,
        );
      }).toList();

      return {
        'quizId': quizId,
        'title': title,
        'questions': questions,
      };
    } else {
      final msg = _parseErrorMessage(response);
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> submitQuiz(
    String quizId,
    List<Map<String, String>> answers,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/quizzes/$quizId/submit'),
      headers: _headers,
      body: jsonEncode({
        'answers': answers,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final msg = _parseErrorMessage(response);
      throw Exception(msg);
    }
  }

  Future<String> explainQuestion(String questionText, String selectedOptionText) async {
    debugPrint('[explainQuestion] Request URL: $baseUrl/api/quiz/explain-question');
    debugPrint('[explainQuestion] Request Headers: $_headers');
    debugPrint('[explainQuestion] Request Body: questionText="$questionText", selectedOptionText="$selectedOptionText"');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/quiz/explain-question'),
        headers: _headers,
        body: jsonEncode({
          'questionText': questionText,
          'selectedOptionText': selectedOptionText,
        }),
      );

      debugPrint('[explainQuestion] Response Status: ${response.statusCode}');
      debugPrint('[explainQuestion] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['explanation'] as String? ?? '';
      } else {
        final msg = _parseErrorMessage(response);
        throw Exception(msg);
      }
    } catch (e, stack) {
      debugPrint('[explainQuestion] Exception caught: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  Future<void> completeLesson(String lessonId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/lessons/$lessonId/complete'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      final msg = _parseErrorMessage(response);
      throw Exception(msg);
    }
  }

  Future<List<Map<String, dynamic>>> getMyAchievements() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/achievements'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      final msg = _parseErrorMessage(response);
      throw Exception(msg);
    }
  }

  // Helpers
  bool _isLinuxTopic(String title, String description) {
    final t = title.toLowerCase();
    final d = description.toLowerCase();
    return t.contains('linux') ||
        d.contains('linux') ||
        t.contains('kernel') ||
        t.contains('process') ||
        t.contains('scheduler') ||
        t.contains('file system') ||
        t.contains('terminal');
  }

  String _getIconKey(String title) {
    final t = title.toLowerCase();
    if (t.contains('cryptography') || t.contains('crypto')) return 'lock_person_rounded';
    if (t.contains('network')) return 'router_rounded';
    if (t.contains('incident') || t.contains('response')) return 'wifi_protected_setup_rounded';
    if (t.contains('application') || t.contains('app')) return 'https_rounded';
    if (t.contains('intro') && t.contains('cyber')) return 'shield_rounded';
    if (t.contains('intro') && (t.contains('linux') || t.contains('system'))) return 'terminal_rounded';
    if (t.contains('kernel')) return 'settings_input_component_rounded';
    if (t.contains('process')) return 'account_tree_rounded';
    if (t.contains('schedule') || t.contains('scheduler')) return 'schedule_rounded';
    if (t.contains('memory')) return 'memory_rounded';
    if (t.contains('file system') || t.contains('file-system')) return 'folder_open_rounded';
    if (t.contains('ipc') || t.contains('inter-process') || t.contains('communication')) return 'compare_arrows_rounded';
    if (t.contains('security')) return 'admin_panel_settings_rounded';
    return 'shield_rounded';
  }

  String _parseErrorMessage(http.Response response) {
    try {
      final body = response.body;
      if (body.startsWith('{') || body.startsWith('[')) {
        final decoded = jsonDecode(body);
        if (decoded is Map && decoded.containsKey('message')) {
          return decoded['message'] as String;
        }
      }
      return body.isNotEmpty ? body : 'HTTP ${response.statusCode} error';
    } catch (_) {
      return 'HTTP ${response.statusCode} error';
    }
  }
}
