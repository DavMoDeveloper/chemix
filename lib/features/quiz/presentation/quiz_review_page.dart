import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'quiz_page.dart';
import '../bloc/quiz_bloc.dart';
import '../bloc/quiz_event.dart';

class QuizReviewPage extends StatefulWidget {
  const QuizReviewPage({super.key});

  @override
  State<QuizReviewPage> createState() => _QuizReviewPageState();
}

class _QuizReviewPageState extends State<QuizReviewPage> {
  @override
  void initState() {
    super.initState();
    // FIX Bug #4: disparar evento en initState, no en build()
    context.read<QuizBloc>().add(ReviewQuizStarted());
  }

  @override
  Widget build(BuildContext context) {
    return const QuizPage(isReviewMode: true);
  }
}
