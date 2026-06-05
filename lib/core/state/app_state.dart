import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mobile_app/core/data/api_service.dart';
import 'package:mobile_app/core/data/mock_repository.dart';
import 'package:mobile_app/core/models/app_models.dart';

enum AppStage { splash, onboarding, auth, main }

class AppState extends ChangeNotifier {
  AppState() {
    unawaited(_runStartup());
  }

  final ApiService _apiService = ApiService();
  final List<Topic> _topics = [];
  final Map<String, String> _topicQuizId = {};
  final Map<String, int> _quizAttempts = {};

  bool _splashDone = false;
  bool _hasSeenOnboarding = false;
  AppUser? _currentUser;
  bool _notificationsEnabled = true;
  ThemePreference _themePreference = ThemePreference.system;

  final Set<String> _completedLessonIds = <String>{};
  final Map<String, int> _quizScores = <String, int>{};
  final Map<String, DateTime> _achievementUnlockedAt = <String, DateTime>{};

  Future<void> _runStartup() async {
    await Future<void>.delayed(const Duration(milliseconds: 1900));
    _splashDone = true;
    notifyListeners();
  }

  AppStage get stage {
    if (!_splashDone) return AppStage.splash;
    if (!_hasSeenOnboarding) return AppStage.onboarding;
    if (_currentUser == null) return AppStage.auth;
    return AppStage.main;
  }

  List<Topic> get topics {
    final sorted = [..._topics.isEmpty ? MockRepository.topics : _topics];
    sorted.sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }

  List<AchievementStatus> get achievements {
    final list = MockRepository.achievementDefinitions
        .map(
          (definition) => AchievementStatus(
            definition: definition,
            earnedAt: _achievementUnlockedAt[definition.id],
          ),
        )
        .toList();

    list.sort((a, b) {
      if (a.isUnlocked && !b.isUnlocked) return -1;
      if (!a.isUnlocked && b.isUnlocked) return 1;
      final aTime = a.earnedAt;
      final bTime = b.earnedAt;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });
    return list;
  }

  AppUser? get currentUser => _currentUser;
  bool get notificationsEnabled => _notificationsEnabled;
  ThemePreference get themePreference => _themePreference;

  ThemeMode get themeMode => switch (_themePreference) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
  };

  int get completedLessonsCount => _completedLessonIds.length;
  int get unlockedAchievementsCount =>
      achievements.where((item) => item.isUnlocked).length;

  double get overallProgress {
    final totalLessons = topics.fold<int>(
      0,
      (sum, topic) => sum + topic.lessons.length,
    );
    if (totalLessons == 0) return 0;
    return _completedLessonIds.length / totalLessons;
  }

  int get totalQuizzesTaken => _quizScores.length;

  double get averageQuizScore {
    if (_quizScores.isEmpty) return 0;
    final total = _quizScores.values.fold<int>(0, (sum, score) => sum + score);
    final totalQuestions = topics
        .where((topic) => _quizScores.containsKey(topic.id))
        .fold<int>(0, (sum, topic) => sum + topic.quizQuestions.length);
    if (totalQuestions == 0) return 0;
    return total / totalQuestions;
  }

  List<Topic> filteredTopics({
    required TopicCategory category,
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return topics.where((topic) {
      final categoryMatch =
          category == TopicCategory.all || topic.category == category;
      final queryMatch =
          normalizedQuery.isEmpty ||
          topic.title.toLowerCase().contains(normalizedQuery) ||
          topic.shortDescription.toLowerCase().contains(normalizedQuery);
      return categoryMatch && queryMatch;
    }).toList();
  }

  int completedLessonsForTopic(Topic topic) {
    return topic.lessons
        .where((lesson) => _completedLessonIds.contains(lesson.id))
        .length;
  }

  double topicProgress(Topic topic) {
    if (topic.lessons.isEmpty) return 0;
    return completedLessonsForTopic(topic) / topic.lessons.length;
  }

  bool isLessonCompleted(Lesson lesson) {
    return _completedLessonIds.contains(lesson.id);
  }

  bool isLessonUnlocked(Topic topic, Lesson lesson) {
    if (lesson.order <= 1) return true;

    final previous = topic.lessons.where(
      (item) => item.order == lesson.order - 1,
    );
    if (previous.isEmpty) return true;
    return _completedLessonIds.contains(previous.first.id);
  }

  Lesson? nextIncompleteLesson(Topic topic) {
    final sorted = [...topic.lessons]
      ..sort((a, b) => a.order.compareTo(b.order));
    for (final lesson in sorted) {
      if (!isLessonCompleted(lesson) && isLessonUnlocked(topic, lesson)) {
        return lesson;
      }
    }
    return null;
  }

  bool canStartQuiz(Topic topic) => topicProgress(topic) >= 1;

  void completeOnboarding() {
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      _currentUser = await _apiService.login(email, password);
      _hasSeenOnboarding = true;
      await syncAchievements();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      _currentUser = await _apiService.register(fullName, email, password);
      _hasSeenOnboarding = true;
      await syncAchievements();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void signOut() {
    _currentUser = null;
    _apiService.setToken(null);
    notifyListeners();
  }

  Future<List<AchievementDefinition>> markLessonCompleted({
    required Topic topic,
    required Lesson lesson,
  }) async {
    if (_completedLessonIds.contains(lesson.id)) return const [];

    try {
      await _apiService.completeLesson(lesson.id);
      _completedLessonIds.add(lesson.id);
      final newlyUnlocked = await syncAchievements();
      notifyListeners();
      return newlyUnlocked;
    } catch (e) {
      // Fallback locally
      _completedLessonIds.add(lesson.id);
      final unlocked = _evaluateAchievements(topic: topic, completedQuiz: false);
      notifyListeners();
      return unlocked;
    }
  }

  Future<QuizOutcome> submitQuiz({
    required Topic topic,
    required Map<String, int> answers,
  }) async {
    final dbTopic = _topics.firstWhere((t) => t.id == topic.id, orElse: () => topic);
    try {
      final quizId = _topicQuizId[dbTopic.id];
      if (quizId == null) {
        throw Exception("Quiz ID not found for topic ${dbTopic.id}");
      }

      final List<Map<String, String>> submitAnswers = [];
      for (final question in dbTopic.quizQuestions) {
        final selectedIndex = answers[question.id];
        if (selectedIndex != null &&
            question.optionIds != null &&
            selectedIndex < question.optionIds!.length) {
          final optionId = question.optionIds![selectedIndex];
          submitAnswers.add({
            'questionId': question.id,
            'selectedOptionId': optionId,
          });
        }
      }

      final result = await _apiService.submitQuiz(quizId, submitAnswers);
      final correctAnswers = result['correctCount'] as int? ?? 0;
      final totalQuestions = result['totalQuestionCount'] as int? ?? dbTopic.quizQuestions.length;
      final attemptCount = result['attemptCount'] as int? ?? 1;

      final qResultsList = result['questionResults'] as List? ?? [];
      final Map<String, bool?> questionResults = {};
      final Map<String, String?> correctOptionIds = {};

      for (final r in qResultsList) {
        final qId = r['questionId'] as String;
        final isCorrect = r['isCorrect'] as bool?;
        final correctOptId = r['correctOptionId'] as String?;
        questionResults[qId] = isCorrect;
        correctOptionIds[qId] = correctOptId;
      }

      _quizScores[dbTopic.id] = correctAnswers;
      _quizAttempts[dbTopic.id] = attemptCount;

      // Sync achievements
      final newlyUnlocked = await syncAchievements();
      notifyListeners();

      return QuizOutcome(
        quizId: quizId,
        topic: dbTopic,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
        answers: answers,
        newlyUnlocked: newlyUnlocked,
        questionResults: questionResults,
        correctOptionIds: correctOptionIds,
        attemptCount: attemptCount,
      );
    } catch (e) {
      // Local fallback
      var correctAnswers = 0;
      final Map<String, bool?> questionResults = {};
      final Map<String, String?> correctOptionIds = {};

      for (final question in dbTopic.quizQuestions) {
        final selected = answers[question.id];
        final isCorrect = selected == question.correctIndex;
        if (isCorrect) {
          correctAnswers += 1;
        }
        questionResults[question.id] = isCorrect;
        if (question.optionIds != null && question.correctIndex < question.optionIds!.length) {
          correctOptionIds[question.id] = question.optionIds![question.correctIndex];
        }
      }

      _quizScores[dbTopic.id] = correctAnswers;
      final unlocked = _evaluateAchievements(
        topic: dbTopic,
        completedQuiz: true,
        correctAnswers: correctAnswers,
        totalQuestions: dbTopic.quizQuestions.length,
      );

      final currentAttempts = _quizAttempts[dbTopic.id] ?? 0;
      final attemptCount = currentAttempts + 1;
      _quizAttempts[dbTopic.id] = attemptCount;

      notifyListeners();
      return QuizOutcome(
        quizId: _topicQuizId[dbTopic.id] ?? 'mock-quiz-id',
        topic: dbTopic,
        correctAnswers: correctAnswers,
        totalQuestions: dbTopic.quizQuestions.length,
        answers: answers,
        newlyUnlocked: unlocked,
        questionResults: questionResults,
        correctOptionIds: correctOptionIds,
        attemptCount: attemptCount,
      );
    }
  }

  Future<List<Topic>> loadTopicsFromBackend() async {
    try {
      final list = await _apiService.getTopics();
      _topics.clear();
      _topics.addAll(list);
      notifyListeners();
      return list;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Lesson>> loadLessonsForTopic(String topicId) async {
    try {
      final lessons = await _apiService.getLessons(topicId);
      final index = _topics.indexWhere((t) => t.id == topicId);
      if (index != -1) {
        final oldTopic = _topics[index];
        _topics[index] = Topic(
          id: oldTopic.id,
          title: oldTopic.title,
          description: oldTopic.description,
          shortDescription: oldTopic.shortDescription,
          category: oldTopic.category,
          difficulty: oldTopic.difficulty,
          order: oldTopic.order,
          estimatedLessonCount: oldTopic.estimatedLessonCount,
          iconKey: oldTopic.iconKey,
          illustrationHint: oldTopic.illustrationHint,
          categoryColorHex: oldTopic.categoryColorHex,
          lessons: List<Lesson>.unmodifiable(lessons),
          quizQuestions: oldTopic.quizQuestions,
        );
      }
      notifyListeners();
      return lessons;
    } catch (e) {
      rethrow;
    }
  }

  Future<Lesson> loadLessonDetail(String lessonId) async {
    try {
      final detail = await _apiService.getLessonById(lessonId);
      for (var i = 0; i < _topics.length; i++) {
        final topic = _topics[i];
        final lessonIndex = topic.lessons.indexWhere((l) => l.id == lessonId);
        if (lessonIndex != -1) {
          final updatedLessons = List<Lesson>.from(topic.lessons);
          updatedLessons[lessonIndex] = detail;
          _topics[i] = Topic(
            id: topic.id,
            title: topic.title,
            description: topic.description,
            shortDescription: topic.shortDescription,
            category: topic.category,
            difficulty: topic.difficulty,
            order: topic.order,
            estimatedLessonCount: topic.estimatedLessonCount,
            iconKey: topic.iconKey,
            illustrationHint: topic.illustrationHint,
            categoryColorHex: topic.categoryColorHex,
            lessons: List<Lesson>.unmodifiable(updatedLessons),
            quizQuestions: topic.quizQuestions,
          );
          break;
        }
      }
      notifyListeners();
      return detail;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<QuizQuestion>> loadQuizForTopic(String topicId) async {
    try {
      final data = await _apiService.getQuiz(topicId);
      final quizId = data['quizId'] as String;
      final List<QuizQuestion> questions = data['questions'] as List<QuizQuestion>;
      final attemptCount = data['attemptCount'] as int? ?? 0;

      _topicQuizId[topicId] = quizId;
      _quizAttempts[topicId] = attemptCount;

      final index = _topics.indexWhere((t) => t.id == topicId);
      if (index != -1) {
        final oldTopic = _topics[index];
        _topics[index] = Topic(
          id: oldTopic.id,
          title: oldTopic.title,
          description: oldTopic.description,
          shortDescription: oldTopic.shortDescription,
          category: oldTopic.category,
          difficulty: oldTopic.difficulty,
          order: oldTopic.order,
          estimatedLessonCount: oldTopic.estimatedLessonCount,
          iconKey: oldTopic.iconKey,
          illustrationHint: oldTopic.illustrationHint,
          categoryColorHex: oldTopic.categoryColorHex,
          lessons: oldTopic.lessons,
          quizQuestions: List<QuizQuestion>.unmodifiable(questions),
        );
      }
      notifyListeners();
      return questions;
    } catch (e) {
      rethrow;
    }
  }


  Future<String> explainQuestion(String quizId, String questionText, String selectedOptionText) async {
    return _apiService.explainQuestion(quizId, questionText, selectedOptionText);
  }

  Future<String> getDailyOracle() async {
    return _apiService.getDailyOracle();
  }

  Future<List<AchievementDefinition>> syncAchievements() async {
    try {
      final rawList = await _apiService.getMyAchievements();
      final newlyUnlocked = <AchievementDefinition>[];

      for (final raw in rawList) {
        final code = raw['code'] as String? ?? '';
        final earnedAtStr = raw['earnedAt'] as String?;
        if (code.isNotEmpty && earnedAtStr != null) {
          final earnedAt = DateTime.tryParse(earnedAtStr) ?? DateTime.now();

          if (!_achievementUnlockedAt.containsKey(code)) {
            final defIndex = MockRepository.achievementDefinitions.indexWhere((d) => d.id == code);
            if (defIndex != -1) {
              newlyUnlocked.add(MockRepository.achievementDefinitions[defIndex]);
            }
          }

          _achievementUnlockedAt[code] = earnedAt;
        }
      }

      // Proactively sync completed lesson count
      try {
        final summaryResponse = await http.get(
          Uri.parse('${_apiService.baseUrl}/api/progress/summary'),
          headers: _apiService.headers,
        );
        if (summaryResponse.statusCode == 200) {
          final summary = jsonDecode(summaryResponse.body);
          // Set completions size locally to align progress rings
          final count = summary['completedLessons'] as int? ?? 0;
          if (count > _completedLessonIds.length) {
            // Add filler mock IDs to represent completions if we don't know the exact IDs
            // This ensures overall progress ring displays the correct count fetched from backend
            for (var i = _completedLessonIds.length; i < count; i++) {
              _completedLessonIds.add('__sync_filler_$i');
            }
          }
        }
      } catch (_) {}

      return newlyUnlocked;
    } catch (e) {
      return const [];
    }
  }

  int? bestQuizScoreForTopic(String topicId) => _quizScores[topicId];

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void setThemePreference(ThemePreference preference) {
    _themePreference = preference;
    notifyListeners();
  }

  void resetLearningProgress() {
    _completedLessonIds.clear();
    _quizScores.clear();
    _achievementUnlockedAt.clear();
    notifyListeners();
  }

  List<AchievementDefinition> _evaluateAchievements({
    required Topic topic,
    required bool completedQuiz,
    int? correctAnswers,
    int? totalQuestions,
  }) {
    final unlocked = <AchievementDefinition>[];
    final isLinuxTopic = topic.category == TopicCategory.linux;
    final hasAnyLinuxLesson = _completedLessonIds.any(
      (id) => id.startsWith('linux-l'),
    );

    if (_completedLessonIds.isNotEmpty) {
      _unlock('first_lesson', unlocked);
    }

    if (completedLessonsForTopic(topic) == topic.lessons.length) {
      _unlock('topic_complete', unlocked);
    }

    if (completedQuiz) {
      _unlock('first_quiz', unlocked);
    }

    if (hasAnyLinuxLesson) {
      _unlock('first_linux_lesson', unlocked);
    }

    if (_completedLessonIds.contains('linux-l1')) {
      _unlock('linux_history_starter', unlocked);
    }

    if (_completedLessonIds.contains('linux-l3')) {
      _unlock('kernel_explorer', unlocked);
    }

    if (_completedLessonIds.contains('linux-l4')) {
      _unlock('process_tracker', unlocked);
    }

    if (_completedLessonIds.contains('linux-l5')) {
      _unlock('scheduler_starter', unlocked);
    }

    if (_completedLessonIds.contains('linux-l6')) {
      _unlock('memory_mapper', unlocked);
    }

    if (_completedLessonIds.contains('linux-l7')) {
      _unlock('file_system_explorer', unlocked);
    }

    if (_completedLessonIds.contains('linux-l8')) {
      _unlock('terminal_thinker', unlocked);
    }

    if (_completedLessonIds.contains('linux-l9')) {
      _unlock('ipc_novice', unlocked);
    }

    if (_completedLessonIds.contains('linux-l10')) {
      _unlock('linux_security_guard', unlocked);
    }

    final linuxTopics = topics
        .where((item) => item.category == TopicCategory.linux)
        .toList();
    final anyLinuxTopicCompleted = linuxTopics.any(
      (item) => topicProgress(item) >= 1,
    );
    if (anyLinuxTopicCompleted) {
      _unlock('linux_topic_complete', unlocked);
    }

    if (completedQuiz && isLinuxTopic) {
      _unlock('first_linux_quiz', unlocked);
    }

    final allLinuxTopicsCompleted =
        linuxTopics.isNotEmpty &&
        linuxTopics.every((item) => topicProgress(item) >= 1);
    final allLinuxQuizzesTaken =
        linuxTopics.isNotEmpty &&
        linuxTopics.every((item) => _quizScores.containsKey(item.id));
    if (allLinuxTopicsCompleted && allLinuxQuizzesTaken) {
      _unlock('linux_path_complete', unlocked);
    }

    if (completedQuiz &&
        correctAnswers != null &&
        totalQuestions != null &&
        totalQuestions > 0 &&
        correctAnswers == totalQuestions) {
      _unlock('perfect_score', unlocked);
    }

    final completedTopics = topics
        .where((item) => topicProgress(item) >= 1)
        .length;
    if (completedTopics >= 3) {
      _unlock('consistent_learner', unlocked);
    }

    if (_achievementUnlockedAt.length >= 4) {
      _unlock('badge_collector', unlocked);
    }

    return unlocked;
  }

  void _unlock(String achievementId, List<AchievementDefinition> unlocked) {
    if (_achievementUnlockedAt.containsKey(achievementId)) return;

    AchievementDefinition? achievement;
    for (final item in MockRepository.achievementDefinitions) {
      if (item.id == achievementId) {
        achievement = item;
        break;
      }
    }
    if (achievement == null) return;

    _achievementUnlockedAt[achievementId] = DateTime.now();
    unlocked.add(achievement);
  }
}
