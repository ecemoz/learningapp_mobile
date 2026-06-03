import 'package:flutter/material.dart';
import 'package:mobile_app/core/models/app_models.dart';
import 'package:mobile_app/core/state/app_state.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/core/theme/app_tokens.dart';
import 'package:mobile_app/core/widgets/app_components.dart';
import 'package:mobile_app/core/widgets/fairytale_background.dart';
import 'package:mobile_app/features/quiz/quiz_result_screen.dart';
import 'package:provider/provider.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.topic});

  final Topic topic;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  final Map<String, int> _answers = <String, int>{};
  Future<List<QuizQuestion>>? _quizFuture;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _quizFuture = context.read<AppState>().loadQuizForTopic(widget.topic.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuizQuestion>>(
      future: _quizFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return FairytaleBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text('${widget.topic.title} Trial'),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: AppLoadingState(label: 'Summoning trial enigmas...'),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return FairytaleBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text('${widget.topic.title} Trial'),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppErrorState(
                    title: 'Trial Unavailable',
                    description: 'We could not fetch the trial from server.',
                    onRetry: () {
                      setState(() {
                        _quizFuture = context.read<AppState>().loadQuizForTopic(widget.topic.id);
                      });
                    },
                  ),
                ),
              ),
            ),
          );
        }

        final questions = snapshot.data ?? [];
        if (questions.isEmpty) {
          return FairytaleBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text('${widget.topic.title} Trial'),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: AppEmptyState(
                    title: 'No Enigmas Found',
                    description: 'There are no questions in this trial yet.',
                  ),
                ),
              ),
            ),
          );
        }

        final current = questions[_index];
        final selected = _answers[current.id];
        final progress = (_index + 1) / questions.length;

        return FairytaleBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text('${widget.topic.title} Trial'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: _submitting
                    ? const Center(
                        child: AppLoadingState(label: 'Oracle evaluating answers...'),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enigma ${_index + 1} of ${questions.length}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          LinearProgressIndicator(
                            value: progress,
                            borderRadius: AppRadii.pill,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SoftSurfaceCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  current.prompt,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                ...current.options.asMap().entries.map((entry) {
                                  final optionIndex = entry.key;
                                  final optionText = entry.value;
                                  final isSelected = selected == optionIndex;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: InkWell(
                                      borderRadius: AppRadii.md,
                                      onTap: () {
                                        setState(() {
                                          _answers[current.id] = optionIndex;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(AppSpacing.md),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFFFEEBC)
                                              : Colors.white.withValues(alpha: 0.65),
                                          borderRadius: AppRadii.md,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primaryStrong
                                                : Colors.white.withValues(alpha: 0.8),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: isSelected
                                                  ? AppColors.primaryStrong
                                                  : const Color(0xFFE7DECD),
                                              child: Text(
                                                String.fromCharCode(65 + optionIndex),
                                                style: Theme.of(context).textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: isSelected
                                                          ? Colors.white
                                                          : AppColors.ink,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                            Expanded(
                                              child: Text(
                                                optionText,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const Spacer(),
                          AppPrimaryButton(
                            label: _index == questions.length - 1 ? 'Seal Answers' : 'Next Enigma',
                            icon: _index == questions.length - 1
                                ? Icons.auto_awesome_rounded
                                : Icons.arrow_forward_rounded,
                            enabled: selected != null,
                            onPressed: () async {
                              if (_index < questions.length - 1) {
                                setState(() => _index += 1);
                                return;
                              }

                              setState(() => _submitting = true);
                              final navigator = Navigator.of(context);
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              try {
                                final outcome = await context.read<AppState>().submitQuiz(
                                  topic: widget.topic,
                                  answers: _answers,
                                );

                                if (mounted) {
                                  navigator.pushReplacement(
                                    MaterialPageRoute<void>(
                                      builder: (_) => QuizResultScreen(outcome: outcome),
                                    ),
                                  );
                                }
                              } catch (e) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to submit quiz: $e'),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _submitting = false);
                                }
                              }
                            },
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
