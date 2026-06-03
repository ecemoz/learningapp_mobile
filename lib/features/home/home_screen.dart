import 'package:flutter/material.dart';
import 'package:mobile_app/core/state/app_state.dart';
import 'package:mobile_app/core/theme/app_tokens.dart';
import 'package:mobile_app/core/widgets/app_components.dart';
import 'package:mobile_app/features/topics/topic_detail_screen.dart';
import 'package:mobile_app/features/shell/main_shell.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final userName = appState.currentUser?.fullName ?? 'Learner';

        final continueTopic = appState.topics.firstWhere(
          (topic) => appState.nextIncompleteLesson(topic) != null,
          orElse: () => appState.topics.first,
        );
        final nextLesson = appState.nextIncompleteLesson(continueTopic);

        final unlocked = appState.achievements
            .where((item) => item.isUnlocked)
            .take(3)
            .toList();

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Welcome, $userName',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFFF0B328),
                              size: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Your magical journey awaits.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      MainShell.navigateTo(context, 4);
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF0B328), width: 2),
                        color: const Color(0xFFFFEEB6),
                      ),
                      child: Center(
                        child: Text(
                          appState.currentUser?.initials ?? 'L',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4830), fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: AppRadii.md,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for spells and lessons...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD18E15)),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SoftSurfaceCard(
                child: Row(
                  children: [
                    ProgressRing(
                      value: appState.overallProgress,
                      label: '${(appState.overallProgress * 100).round()}%',
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Progress',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${appState.completedLessonsCount} lessons completed',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${appState.unlockedAchievementsCount} badges earned',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(
                title: 'Continue your Quest',
                subtitle: 'Pick up your next magical lesson.',
              ),
              const SizedBox(height: AppSpacing.sm),
              SoftSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      continueTopic.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      nextLesson == null
                          ? 'Topic complete. Ready for quiz.'
                          : 'Next: ${nextLesson.title}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    LinearProgressIndicator(
                      value: appState.topicProgress(continueTopic),
                      borderRadius: AppRadii.pill,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppPrimaryButton(
                      label: nextLesson == null
                          ? 'Open Topic'
                          : 'Continue Lesson',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                TopicDetailScreen(topic: continueTopic),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(
                title: 'The Oracle Speaks',
                subtitle: 'AI personalized path for your journey.',
              ),
              const SizedBox(height: AppSpacing.sm),
              // AiRecommendationCard(userId: appState.currentUser?.email ?? 'user_123'),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(
                title: 'Magical Treasures',
                subtitle: 'Celebrate your enchanted milestones.',
              ),
              const SizedBox(height: AppSpacing.sm),
              if (unlocked.isEmpty)
                const AppEmptyState(
                  title: 'No badges yet',
                  description: 'Complete lessons and quizzes to earn badges.',
                  icon: Icons.workspace_premium_outlined,
                )
              else
                ...unlocked.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AchievementPill(
                      icon: item.definition.icon,
                      title: item.definition.title,
                      earnedAt: item.earnedAt,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}


