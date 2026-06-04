import 'package:flutter/material.dart';
import 'package:mobile_app/core/models/app_models.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/core/theme/app_tokens.dart';
import 'package:mobile_app/core/widgets/app_components.dart';
import 'package:mobile_app/core/widgets/fairytale_background.dart';
import 'package:mobile_app/features/quiz/quiz_screen.dart';
import 'package:mobile_app/features/ai_insights/presentation/widgets/glowing_ai_container.dart';

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key, required this.outcome});

  final QuizOutcome outcome;

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _rewardShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_rewardShown || widget.outcome.newlyUnlocked.isEmpty) return;

    _rewardShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final badge = widget.outcome.newlyUnlocked.first;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFFFFFDF8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFFDECB5)),
          ),
          title: const Text('Magical Relic Discovered!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEEBC),
                  shape: BoxShape.circle,
                ),
                child: Icon(badge.icon, size: 44, color: const Color(0xFFD18E15)),
              ),
              const SizedBox(height: 16),
              Text(badge.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(badge.description, textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Marvelous'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final outcome = widget.outcome;
    final percent = (outcome.scorePercent * 100).round();

    return FairytaleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Trial Results'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SoftSurfaceCard(
            child: Column(
              children: [
                Icon(
                  outcome.isPassed
                      ? Icons.emoji_events_rounded
                      : Icons.sentiment_neutral_rounded,
                  size: 56,
                  color: outcome.isPassed
                      ? AppColors.primaryStrong
                      : AppColors.ink,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  outcome.isPassed ? 'A Triumph of Wisdom!' : 'The Lore Demands More Study.',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'You scored ${outcome.correctAnswers}/${outcome.totalQuestions} ($percent%)',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  outcome.isPassed
                      ? 'You have proven your mastery. Carry this wisdom forward.'
                      : 'Consult the ancient texts and face the trial again.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (outcome.attemptCount >= 2) ...[
            const SizedBox(height: AppSpacing.md),
            const SectionHeader(
              title: 'Enigma Reflections',
              subtitle: 'Review your mastery of the realm.',
            ),
            const SizedBox(height: AppSpacing.sm),
            RealQuizFeedbackList(
              outcome: outcome,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppPrimaryButton(
            label: outcome.isPassed ? 'Continue Journey' : 'Face Trial Again',
            icon: outcome.isPassed
                ? Icons.arrow_forward_rounded
                : Icons.refresh_rounded,
            onPressed: () {
              if (outcome.isPassed) {
                Navigator.pop(context);
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => QuizScreen(topic: outcome.topic),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: 'Return to Lore',
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.pop(context),
          ),
          if (outcome.newlyUnlocked.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SoftSurfaceCard(
              backgroundColor: const Color(0xFFFFF3CD),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'New badge: ${outcome.newlyUnlocked.first.title}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class RealQuizFeedbackList extends StatelessWidget {
  const RealQuizFeedbackList({
    super.key,
    required this.outcome,
  });

  final QuizOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final questions = outcome.topic.quizQuestions;
    if (questions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: questions.map((question) {
        final selectedIndex = outcome.answers[question.id];
        final selectedText = (selectedIndex != null && selectedIndex < question.options.length)
            ? question.options[selectedIndex]
            : 'No answer';

        final isCorrect = outcome.questionResults?[question.id] ?? false;

        final correctOptId = outcome.correctOptionIds?[question.id];
        final correctIndex = (correctOptId != null && question.optionIds != null)
            ? question.optionIds!.indexOf(correctOptId)
            : question.correctIndex;
        final correctText = (correctIndex >= 0 && correctIndex < question.options.length)
            ? question.options[correctIndex]
            : (question.options.isNotEmpty ? question.options.first : '');

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: RealQuizFeedbackCard(
            question: question,
            selectedAnswer: selectedText,
            correctAnswer: correctText,
            isCorrect: isCorrect,
          ),
        );
      }).toList(),
    );
  }
}

class RealQuizFeedbackCard extends StatelessWidget {
  const RealQuizFeedbackCard({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });

  final QuizQuestion question;
  final String selectedAnswer;
  final String correctAnswer;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return GlowingAiContainer(
      isCorrect: isCorrect,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCorrect ? Icons.check_rounded : Icons.close_rounded,
                  color: isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.prompt,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4A3C2A),
                        height: 1.3,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _RealAnswerRow(
            label: 'Your Answer',
            answer: selectedAnswer,
            isCorrect: isCorrect,
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 12),
            _RealAnswerRow(
              label: 'Correct Answer',
              answer: correctAnswer,
              isCorrect: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _RealAnswerRow extends StatelessWidget {
  const _RealAnswerRow({
    required this.label,
    required this.answer,
    required this.isCorrect,
  });

  final String label;
  final String answer;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCorrect
            ? const Color(0xFFE8F5E9).withValues(alpha: 0.5)
            : const Color(0xFFFFEBEE).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? const Color(0xFFC8E6C9) : const Color(0xFFFFCDD2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isCorrect ? const Color(0xFF388E3C) : const Color(0xFFD32F2F),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  answer,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF4A3C2A),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

