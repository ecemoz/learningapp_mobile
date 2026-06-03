import 'package:flutter/material.dart';
import 'package:mobile_app/core/models/app_models.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/core/theme/app_tokens.dart';
import 'package:mobile_app/core/widgets/app_components.dart';
import 'package:mobile_app/core/widgets/fairytale_background.dart';
import 'package:mobile_app/features/quiz/quiz_screen.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/core/state/app_state.dart';
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
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(
            title: 'Enigma Reflections',
            subtitle: 'Review your mastery of the realm.',
          ),
          const SizedBox(height: AppSpacing.sm),
          RealQuizFeedbackList(
            outcome: outcome,
          ),
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
            : 'Yanıt verilmedi';

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

class RealQuizFeedbackCard extends StatefulWidget {
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
  State<RealQuizFeedbackCard> createState() => _RealQuizFeedbackCardState();
}

class _RealQuizFeedbackCardState extends State<RealQuizFeedbackCard> {
  String? _explanation;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return GlowingAiContainer(
      isCorrect: widget.isCorrect,
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
                  color: widget.isCorrect
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isCorrect ? Icons.check_rounded : Icons.close_rounded,
                  color: widget.isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.question.prompt,
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
            label: 'Senin Cevabın',
            answer: widget.selectedAnswer,
            isCorrect: widget.isCorrect,
          ),
          if (!widget.isCorrect) ...[
            const SizedBox(height: 12),
            _RealAnswerRow(
              label: 'Doğru Cevap',
              answer: widget.correctAnswer,
              isCorrect: true,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFE7DECD), height: 1),
          ),
          if (_explanation != null) ...[
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFFD18E15), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Yapay Zeka Açıklaması ✨',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFFD18E15),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFE082)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFE082).withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _explanation!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B5C4A),
                      height: 1.5,
                    ),
              ),
            ),
          ] else if (_loading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD18E15)),
                  ),
                ),
              ),
            ),
          ] else if (!widget.isCorrect) ...[
            if (_error != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
            Center(
              child: OutlinedButton.icon(
                onPressed: () async {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  try {
                    final response = await context.read<AppState>().explainQuestion(
                          widget.question.prompt,
                          widget.selectedAnswer,
                        );
                    setState(() {
                      _explanation = response;
                    });
                  } catch (e) {
                    setState(() {
                      _error = 'Yapay zekadan açıklama alınamadı. Lütfen tekrar dene.';
                    });
                  } finally {
                    setState(() {
                      _loading = false;
                    });
                  }
                },
                icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFFB07100)),
                label: const Text(
                  'Yapay Zekaya Sor ✨',
                  style: TextStyle(color: Color(0xFFB07100), fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFDECB5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: const Color(0xFFFFEEBC).withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF2CA56E), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Harika! Doğru cevap.',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF2CA56E),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
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

