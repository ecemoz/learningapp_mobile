import 'package:flutter/material.dart';

enum TopicCategory { all, cybersecurity, linux }

extension TopicCategoryX on TopicCategory {
  String get label => switch (this) {
    TopicCategory.all => 'All',
    TopicCategory.cybersecurity => 'Cybersecurity',
    TopicCategory.linux => 'Linux',
  };
}

enum TopicDifficulty { beginner, intermediate }

extension TopicDifficultyX on TopicDifficulty {
  String get label => switch (this) {
    TopicDifficulty.beginner => 'Beginner',
    TopicDifficulty.intermediate => 'Intermediate',
  };
}

enum ThemePreference { system, light }

class AppUser {
  const AppUser({
    required this.fullName,
    required this.email,
    required this.role,
  });

  final String fullName;
  final String email;
  final String role;

  String get initials {
    final parts = fullName.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.minutes,
    required this.order,
  });

  final String id;
  final String title;
  final String summary;
  final String content;
  final int minutes;
  final int order;
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.feedback,
    this.optionIds,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String feedback;
  final List<String>? optionIds;
}

class Topic {
  const Topic({
    required this.id,
    required this.title,
    required this.description,
    required this.shortDescription,
    required this.category,
    required this.difficulty,
    required this.order,
    required this.estimatedLessonCount,
    required this.iconKey,
    required this.illustrationHint,
    required this.categoryColorHex,
    required this.lessons,
    required this.quizQuestions,
  });

  final String id;
  final String title;
  final String description;
  final String shortDescription;
  final TopicCategory category;
  final TopicDifficulty difficulty;
  final int order;
  final int estimatedLessonCount;
  final String iconKey;
  final String illustrationHint;
  final String categoryColorHex;
  final List<Lesson> lessons;
  final List<QuizQuestion> quizQuestions;
}

class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.unlockHint,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final String unlockHint;
  final IconData icon;
}

class AchievementStatus {
  const AchievementStatus({required this.definition, required this.earnedAt});

  final AchievementDefinition definition;
  final DateTime? earnedAt;

  bool get isUnlocked => earnedAt != null;
}

class QuizOutcome {
  const QuizOutcome({
    required this.topic,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.answers,
    required this.newlyUnlocked,
    this.questionResults,
    this.correctOptionIds,
  });

  final Topic topic;
  final int correctAnswers;
  final int totalQuestions;
  final Map<String, int> answers;
  final List<AchievementDefinition> newlyUnlocked;
  final Map<String, bool>? questionResults;
  final Map<String, String>? correctOptionIds;

  bool get isPassed => scorePercent >= 0.6;

  double get scorePercent {
    if (totalQuestions == 0) return 0;
    return correctAnswers / totalQuestions;
  }
}
