import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/ai_insights/presentation/providers/ai_insights_providers.dart';
import 'package:mobile_app/features/ai_insights/presentation/widgets/glowing_ai_container.dart';
import 'package:provider/provider.dart' as provider;
import 'package:mobile_app/core/state/app_state.dart';
import 'package:mobile_app/features/topics/topic_detail_screen.dart';

class AiRecommendationCard extends ConsumerWidget {
  const AiRecommendationCard({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationAsync = ref.watch(aiRecommendationProvider(userId));

    return recommendationAsync.when(
      data: (recommendation) {
        return GlowingAiContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFFD18E15), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'AI Recommendation',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFD18E15),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      recommendation.difficulty,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFB07100),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                recommendation.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A3C2A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                recommendation.reason,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B5C4A),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDECB5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.library_books_rounded, size: 16, color: Color(0xFFB07100)),
                        const SizedBox(width: 6),
                        Text(
                          '${recommendation.estimatedLessonCount} lessons',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF8B7E6A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      final appState = provider.Provider.of<AppState>(context, listen: false);
                      final matched = appState.topics.where(
                        (t) => t.title.toLowerCase().contains(recommendation.title.toLowerCase()) ||
                               recommendation.title.toLowerCase().contains(t.title.toLowerCase()),
                      );
                      final targetTopic = matched.isNotEmpty ? matched.first : appState.topics.first;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TopicDetailScreen(topic: targetTopic),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD18E15),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(recommendation.ctaLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const _AiRecommendationShimmer(),
      error: (error, stack) => _AiRecommendationError(
        onRetry: () => ref.refresh(aiRecommendationProvider(userId)),
      ),
    );
  }
}

class _AiRecommendationShimmer extends StatelessWidget {
  const _AiRecommendationShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDECB5), width: 1.5),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD18E15)),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Gelecek kehanetleri fısıldanıyor... 💫',
              style: TextStyle(
                color: Color(0xFF8B7E6A),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiRecommendationError extends StatelessWidget {
  const _AiRecommendationError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDECB5), width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFFD18E15), size: 32),
          const SizedBox(height: 8),
          Text(
            'Keşfedilecek yeni bir kehanet yok ✨',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF5D4830),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kâhin şu anda dinleniyor. Yolculuğuna yeni dersler ve sınavlar tamamlayarak devam et, yakında yeni bir kehanet belirecektir!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF8B7E6A),
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFFB07100)),
            label: const Text(
              'Kehanetleri Yenile',
              style: TextStyle(color: Color(0xFFB07100), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
