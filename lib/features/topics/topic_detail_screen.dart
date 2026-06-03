import 'package:flutter/material.dart';
import 'package:mobile_app/core/models/app_models.dart';
import 'package:mobile_app/core/state/app_state.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/core/theme/app_tokens.dart';
import 'package:mobile_app/core/widgets/app_components.dart';
import 'package:mobile_app/core/widgets/fairytale_background.dart';
import 'package:mobile_app/features/lesson/lesson_detail_screen.dart';
import 'package:mobile_app/features/quiz/quiz_screen.dart';
import 'package:provider/provider.dart';

class TopicDetailScreen extends StatefulWidget {
  const TopicDetailScreen({super.key, required this.topic});

  final Topic topic;

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  Future<List<Lesson>>? _lessonsFuture;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = context.read<AppState>().loadLessonsForTopic(widget.topic.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Lesson>>(
      future: _lessonsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return FairytaleBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(widget.topic.title),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: AppLoadingState(label: 'Unrolling chapters...'),
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
                title: Text(widget.topic.title),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppErrorState(
                    title: 'Chapters Lost in Mist',
                    description: 'We could not reach the server to fetch chapters.',
                    onRetry: () {
                      setState(() {
                        _lessonsFuture = context.read<AppState>().loadLessonsForTopic(widget.topic.id);
                      });
                    },
                  ),
                ),
              ),
            ),
          );
        }

        return Consumer<AppState>(
          builder: (context, appState, _) {
            final currentTopic = appState.topics.firstWhere((t) => t.id == widget.topic.id, orElse: () => widget.topic);
            final sortedLessons = [...currentTopic.lessons]
              ..sort((a, b) => a.order.compareTo(b.order));
            final canStartQuiz = appState.canStartQuiz(currentTopic);
            final nextLesson = appState.nextIncompleteLesson(currentTopic);

            return FairytaleBackground(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text(currentTopic.title),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                body: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    IllustrationPanel(
                      title: currentTopic.title,
                      subtitle: currentTopic.shortDescription,
                      icon: topicIconFromKey(currentTopic.iconKey),
                      height: 140,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SoftSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'The Lore of this Realm',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            currentTopic.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Level: ${currentTopic.difficulty.label} • ${currentTopic.estimatedLessonCount} lessons',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          LinearProgressIndicator(
                            value: appState.topicProgress(currentTopic),
                            borderRadius: AppRadii.pill,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${appState.completedLessonsForTopic(currentTopic)} / ${currentTopic.lessons.length} lessons complete',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const SectionHeader(
                      title: 'Chapters of the Journey',
                      subtitle: 'Complete in order to unlock the Trial of Wisdom.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...sortedLessons.map(
                      (lesson) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _LessonListTile(topic: currentTopic, lesson: lesson),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (nextLesson != null)
                      AppPrimaryButton(
                        label: 'Continue Next Chapter',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => LessonDetailScreen(
                                topic: currentTopic,
                                lesson: nextLesson,
                              ),
                            ),
                          );
                        },
                      ),
                    if (nextLesson != null) const SizedBox(height: AppSpacing.sm),
                    AppSecondaryButton(
                      label: canStartQuiz
                          ? 'Begin Trial of Wisdom'
                          : 'Trial unlocks after all chapters',
                      icon: canStartQuiz
                          ? Icons.auto_awesome_rounded
                          : Icons.lock_outline_rounded,
                      onPressed: canStartQuiz
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => QuizScreen(topic: currentTopic),
                                ),
                              );
                            }
                          : null,
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

class _LessonListTile extends StatelessWidget {
  const _LessonListTile({required this.topic, required this.lesson});

  final Topic topic;
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isCompleted = appState.isLessonCompleted(lesson);
    final isUnlocked = appState.isLessonUnlocked(topic, lesson);

    return InkWell(
      borderRadius: AppRadii.lg,
      onTap: isUnlocked
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      LessonDetailScreen(topic: topic, lesson: lesson),
                ),
              );
            }
          : null,
      child: SoftSurfaceCard(
        backgroundColor: isUnlocked
            ? Colors.white.withValues(alpha: 0.65)
            : Colors.white.withValues(alpha: 0.35),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFFEADBCE)
                    : (isUnlocked
                          ? const Color(0xFFFFEEBC)
                          : Colors.white.withValues(alpha: 0.5)),
                borderRadius: AppRadii.md,
              ),
              child: Icon(
                isCompleted
                    ? Icons.check_rounded
                    : (isUnlocked
                          ? Icons.menu_book_rounded
                          : Icons.lock_rounded),
                color: isCompleted ? AppColors.success : AppColors.ink,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lesson.order}. ${lesson.title}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    lesson.summary,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${lesson.minutes} min read',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              isUnlocked
                  ? Icons.chevron_right_rounded
                  : Icons.lock_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
