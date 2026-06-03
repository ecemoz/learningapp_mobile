import 'package:flutter/material.dart';
import 'package:mobile_app/core/models/app_models.dart';
import 'package:mobile_app/core/state/app_state.dart';
import 'package:mobile_app/core/theme/app_tokens.dart';
import 'package:mobile_app/core/widgets/app_components.dart';
import 'package:mobile_app/features/topics/topic_detail_screen.dart';
import 'package:provider/provider.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  TopicCategory _category = TopicCategory.all;
  final _searchController = TextEditingController();
  Future<List<Topic>>? _topicsFuture;

  @override
  void initState() {
    super.initState();
    _topicsFuture = context.read<AppState>().loadTopicsFromBackend();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Topic>>(
      future: _topicsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: AppLoadingState(label: 'Unveiling magical realms...'),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppErrorState(
                title: 'Realms Lost in Mist',
                description: 'We could not reach the server. Make sure the API is active.',
                onRetry: () {
                  setState(() {
                    _topicsFuture = context.read<AppState>().loadTopicsFromBackend();
                  });
                },
              ),
            ),
          );
        }

        return Consumer<AppState>(
          builder: (context, appState, _) {
            final topics = appState.filteredTopics(
              category: _category,
              query: _searchController.text,
            );

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
                  Text(
                    'Explore Realms',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Journey through enchanted domains of cybersecurity and Linux.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: AppRadii.md,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search the magical archives...',
                        prefixIcon: Icon(Icons.search_rounded, color: Color(0xFFD18E15)),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: TopicCategory.values.map((category) {
                      final selected = _category == category;
                      return ChoiceChip(
                        label: Text(category.label),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _category = category);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (topics.isEmpty)
                    const AppEmptyState(
                      title: 'No topics match your search',
                      description: 'Try another keyword or category.',
                      icon: Icons.search_off_rounded,
                    )
                  else
                    ...topics.map(
                      (topic) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _TopicCard(topic: topic),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic});

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final progress = appState.topicProgress(topic);

    return InkWell(
      borderRadius: AppRadii.lg,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TopicDetailScreen(topic: topic),
          ),
        );
      },
      child: SoftSurfaceCard(
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: topicColorFromHex(topic.categoryColorHex),
                borderRadius: AppRadii.md,
              ),
              child: Icon(topicIconFromKey(topic.iconKey)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF5D4830),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    topic.shortDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF9E8D76),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${topic.estimatedLessonCount} lessons • ${topic.difficulty.label}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  LinearProgressIndicator(
                    value: progress,
                    borderRadius: AppRadii.pill,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
