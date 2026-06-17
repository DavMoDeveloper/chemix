import 'package:go_router/go_router.dart';

import '../core/analytics/analytics_service.dart';
import '../features/elements/presentation/element_detail_page.dart';
import '../features/elements/presentation/home_page.dart';
import '../features/premium/presentation/paywall_page.dart';
import '../features/quiz/presentation/quiz_page.dart';
import '../features/quiz/presentation/quiz_result_page.dart';
import '../features/quiz/presentation/quiz_review_page.dart';

GoRouter buildRouter({required AnalyticsService analytics}) {
  return GoRouter(
    initialLocation: '/',
    observers: [analytics.navObserver],
    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            name: 'element_detail',
            path: 'element/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ElementDetailPage(elementId: id);
            },
          ),
          GoRoute(
            name: 'quiz',
            path: 'quiz',
            builder: (context, state) => const QuizPage(),
          ),
          GoRoute(
            name: 'quiz_result',
            path: 'quiz/result',
            builder: (context, state) {
              final score = (state.extra as Map?)?['score'] as int? ?? 0;
              final total = (state.extra as Map?)?['total'] as int? ?? 10;
              return QuizResultPage(score: score, total: total);
            },
          ),
          GoRoute(
            name: 'premium',
            path: 'premium',
            builder: (context, state) => const PaywallPage(),
          ),
          GoRoute(
            name: 'quiz_review',
            path: 'quiz/review',
            builder: (context, state) => const QuizReviewPage(),
          ),
        ],
      ),
    ],
  );
}
