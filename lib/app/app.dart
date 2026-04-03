import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/analytics/analytics_service.dart';

// Elements
import '../features/elements/data/elements_repository.dart';
import '../features/elements/bloc/elements_bloc.dart';
import '../features/elements/bloc/elements_event.dart';

// Premium
import '../features/premium/data/purchase_service.dart';
import '../features/premium/bloc/premium_bloc.dart';
import '../features/premium/bloc/premium_event.dart';

// Progress
import '../features/progress/data/progress_repository.dart';
import '../features/progress/bloc/progress_bloc.dart';
import '../features/progress/bloc/progress_event.dart';

// Quiz
import '../features/quiz/bloc/quiz_bloc.dart';
import '../features/quiz/data/review_service.dart';

// Router
import 'router.dart';

/// FIX Bug #10: instanciar servicios fuera del build() para evitar
/// recrearlos en cada reconstrucción. MyApp pasa a StatefulWidget.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Instanciados una única vez en el ciclo de vida
  late final AnalyticsService _analytics;
  late final ElementsRepository _elementsRepo;
  late final ProgressRepository _progressRepo;
  late final PurchaseService _purchaseService;
  late final ReviewService _reviewService;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _analytics = AnalyticsService();
    _elementsRepo = ElementsRepository();
    _progressRepo = ProgressRepository();
    _purchaseService = PurchaseService();
    _reviewService = ReviewService();
    _router = buildRouter(analytics: _analytics);
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AnalyticsService>.value(value: _analytics),
        RepositoryProvider<ElementsRepository>.value(value: _elementsRepo),
        RepositoryProvider<ProgressRepository>.value(value: _progressRepo),
        RepositoryProvider<PurchaseService>.value(value: _purchaseService),
        RepositoryProvider<ReviewService>.value(value: _reviewService),
      ],
      child: MultiBlocProvider(
        providers: [
          // Premium
          BlocProvider<PremiumBloc>(
            create: (_) =>
                PremiumBloc(purchaseService: _purchaseService)
                  ..add(PremiumStarted()),
          ),

          // Elements
          BlocProvider<ElementsBloc>(
            create: (_) =>
                ElementsBloc(repo: _elementsRepo)..add(ElementsStarted()),
          ),

          // Progress
          BlocProvider<ProgressBloc>(
            create: (_) =>
                ProgressBloc(repo: _progressRepo)..add(ProgressStarted()),
          ),

          // Quiz
          BlocProvider<QuizBloc>(
            create: (ctx) => QuizBloc(
              elementsRepo: ctx.read<ElementsRepository>(),
              premiumBloc: ctx.read<PremiumBloc>(),
              progressBloc: ctx.read<ProgressBloc>(),
              reviewService: ctx.read<ReviewService>(),
            ),
          ),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Chemix',
          // UX-12: Dark mode automático según preferencia del sistema
          // UX-13: Tipografía moderna — se puede cambiar a Google Fonts
          // agregando el paquete 'google_fonts' al pubspec.yaml
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.light,
            textTheme: GoogleFonts.outfitTextTheme(),
            cardTheme: const CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
            cardTheme: const CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          themeMode: ThemeMode.system,
          routerConfig: _router,
        ),
      ),
    );
  }
}
