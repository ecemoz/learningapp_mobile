import 'package:flutter/material.dart';
import 'package:mobile_app/core/models/app_models.dart';
import 'package:mobile_app/core/state/app_state.dart';
import 'package:mobile_app/core/theme/app_tokens.dart';
import 'package:mobile_app/core/widgets/app_components.dart';
import 'package:mobile_app/core/widgets/fairytale_background.dart';
import 'package:mobile_app/features/quiz/quiz_screen.dart';
import 'package:provider/provider.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({
    super.key,
    required this.topic,
    required this.lesson,
  });

  final Topic topic;
  final Lesson lesson;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  bool _showSuccess = false;
  Future<Lesson>? _lessonDetailFuture;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _lessonDetailFuture = context.read<AppState>().loadLessonDetail(widget.lesson.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Lesson>(
      future: _lessonDetailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return FairytaleBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(widget.lesson.title),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: AppLoadingState(label: 'Translating ancient texts...'),
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
                title: Text(widget.lesson.title),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppErrorState(
                    title: 'Chapter Sealed',
                    description: 'We could not load the chapter from archives.',
                    onRetry: () {
                      setState(() {
                        _lessonDetailFuture = context.read<AppState>().loadLessonDetail(widget.lesson.id);
                      });
                    },
                  ),
                ),
              ),
            ),
          );
        }

        final fullLesson = snapshot.data ?? widget.lesson;

        return Consumer<AppState>(
          builder: (context, appState, _) {
            final topic = appState.topics.firstWhere((t) => t.id == widget.topic.id, orElse: () => widget.topic);
            final isCompleted = appState.isLessonCompleted(fullLesson);
            final progress = appState.topicProgress(topic);
            final nextLesson = appState.nextIncompleteLesson(topic);

            return FairytaleBackground(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text(fullLesson.title),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                body: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Text(
                      'Chapter ${fullLesson.order} of ${topic.lessons.length}',
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
                            fullLesson.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${fullLesson.minutes} min read',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            fullLesson.content,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_showSuccess)
                      SoftSurfaceCard(
                        backgroundColor: const Color(0xFFF3FAF6).withValues(alpha: 0.8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF2CA56E),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Excellent! Chapter inscribed in your spellbook.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_showSuccess) const SizedBox(height: AppSpacing.md),
                    _completing
                        ? const AppLoadingState(label: 'Inscribing progress...')
                        : AppPrimaryButton(
                            label: isCompleted ? 'Chapter Mastered' : 'Complete Chapter',
                            icon: isCompleted
                                ? Icons.auto_awesome_rounded
                                : Icons.done_rounded,
                            enabled: !isCompleted,
                            onPressed: () async {
                              setState(() => _completing = true);
                              try {
                                final unlocked = await appState.markLessonCompleted(
                                  topic: topic,
                                  lesson: fullLesson,
                                );
                                setState(() => _showSuccess = true);

                                if (unlocked.isNotEmpty && mounted) {
                                  showDialog<void>(
                                    context: context,
                                    builder: (context) {
                                      final badge = unlocked.first;
                                      return AlertDialog(
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
                                              child: Icon(badge.icon, size: 42, color: const Color(0xFFD18E15)),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              badge.title,
                                              style: Theme.of(context).textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              badge.description,
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Nice!'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to complete chapter: $e'),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _completing = false);
                                }
                              }
                            },
                          ),
                    const SizedBox(height: AppSpacing.sm),
                    if (nextLesson != null && nextLesson.id != fullLesson.id)
                      AppSecondaryButton(
                        label: 'Begin Next Chapter',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => LessonDetailScreen(
                                topic: topic,
                                lesson: nextLesson,
                              ),
                            ),
                          );
                        },
                      ),
                    if (nextLesson == null ||
                        (nextLesson.id == fullLesson.id && isCompleted))
                      AppSecondaryButton(
                        label: appState.canStartQuiz(topic)
                            ? 'Realm Complete, Begin Trial'
                            : 'Return to Lore',
                        icon: appState.canStartQuiz(topic)
                            ? Icons.auto_awesome_rounded
                            : Icons.arrow_back_rounded,
                        onPressed: () {
                          if (appState.canStartQuiz(topic)) {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => QuizScreen(topic: topic),
                              ),
                            );
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
