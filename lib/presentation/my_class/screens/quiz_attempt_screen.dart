// 🆕 NEW FILE
// lib/presentation/my_class/screens/quiz_attempt_screen.dart  [Mobile App]
// My Class — Quiz Attempt.
// Student takes the quiz; submits answers; sees graded result immediately.
// Multiple attempts allowed. Past-year quizzes are blocked (isReadOnly=true).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/my_class/my_class_models.dart';
import '../../../providers/my_class_provider.dart';

class QuizAttemptScreen extends ConsumerStatefulWidget {
  const QuizAttemptScreen({
    super.key,
    required this.quizId,
    required this.isReadOnly,
    this.childId,
  });

  final String quizId;
  final bool isReadOnly;
  final String? childId;

  @override
  ConsumerState<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends ConsumerState<QuizAttemptScreen> {
  // Map: questionId → selected answer
  final Map<String, String> _answers = {};
  bool _submitted = false;
  bool _submitting = false;
  AttemptResultModel? _result;
  String? _error;

  // Timer
  Timer? _timer;
  int _secondsLeft = 0;

  void _startTimer(int durationMinutes) {
    _secondsLeft = durationMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        if (!_submitted) _submit();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ref.read(myClassRepositoryProvider).submitAttempt(
            quizId: widget.quizId,
            answers: _answers,
            childId: widget.childId,
          );
      _timer?.cancel();
      setState(() {
        _result = result;
        _submitted = true;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isReadOnly) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(
          child: Text('Quiz attempts are not available for past academic years.'),
        ),
      );
    }

    final quizAsync = ref.watch(myClassQuizProvider((
      quizId: widget.quizId,
      childId: widget.childId,
    )));

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppBar(
        title: const Text('Quiz'),
        backgroundColor: AppColors.surface50,
        elevation: 0,
        actions: [
          if (_secondsLeft > 0 && !_submitted)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  _timerLabel,
                  style: AppTypography.labelLarge.copyWith(
                    color: _secondsLeft < 60
                        ? AppColors.errorRed
                        : AppColors.navyMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: quizAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text(e.toString(),
                style: AppTypography.bodySmall.copyWith(color: AppColors.errorRed))),
        data: (quiz) {
          // Start timer on first data load
          if (quiz.durationMinutes != null && _secondsLeft == 0 && !_submitted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startTimer(quiz.durationMinutes!);
            });
          }

          if (_submitted && _result != null) {
            return _ResultView(result: _result!, quiz: quiz);
          }

          return _QuizView(
            quiz: quiz,
            answers: _answers,
            onAnswerChanged: (qId, answer) =>
                setState(() => _answers[qId] = answer),
            onSubmit: _submit,
            submitting: _submitting,
            error: _error,
          );
        },
      ),
    );
  }
}

// ── Quiz View ─────────────────────────────────────────────────────────────────

class _QuizView extends StatelessWidget {
  const _QuizView({
    required this.quiz,
    required this.answers,
    required this.onAnswerChanged,
    required this.onSubmit,
    required this.submitting,
    this.error,
  });

  final QuizModel quiz;
  final Map<String, String> answers;
  final void Function(String qId, String answer) onAnswerChanged;
  final VoidCallback onSubmit;
  final bool submitting;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(quiz.title,
                  style: AppTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.bold)),
              if (quiz.instructions != null) ...[
                const SizedBox(height: 8),
                Text(quiz.instructions!,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.grey600)),
              ],
              Text(
                '${quiz.totalMarks} marks · ${quiz.questionCount} questions',
                style: AppTypography.caption.copyWith(color: AppColors.grey500),
              ),
              const SizedBox(height: 16),
              if (error != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(error!,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.errorRed)),
                ),
              ...quiz.questions.asMap().entries.map((entry) {
                final i = entry.key;
                final q = entry.value;
                return _QuestionCard(
                  index: i + 1,
                  question: q,
                  selectedAnswer: answers[q.id],
                  onAnswerChanged: (a) => onAnswerChanged(q.id, a),
                );
              }),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyMedium,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Submit Quiz',
                        style: AppTypography.labelLarge
                            .copyWith(color: Colors.white)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.selectedAnswer,
    required this.onAnswerChanged,
  });

  final int index;
  final QuestionModel question;
  final String? selectedAnswer;
  final void Function(String) onAnswerChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Q$index. ${question.questionText}',
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            Text('${question.marks} mark${question.marks == 1 ? '' : 's'}',
                style: AppTypography.caption.copyWith(color: AppColors.grey500)),
            const SizedBox(height: 10),
            if (question.questionType == 'mcq' ||
                question.questionType == 'true_false')
              ...(question.options ?? (question.questionType == 'true_false' ? ['True', 'False'] : []))
                  .map((opt) => RadioListTile<String>(
                        value: opt,
                        groupValue: selectedAnswer,
                        onChanged: (v) => onAnswerChanged(v ?? ''),
                        title: Text(opt, style: AppTypography.bodySmall),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ))
            else
              TextFormField(
                initialValue: selectedAnswer,
                decoration: InputDecoration(
                  hintText: 'Type your answer...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                ),
                onChanged: onAnswerChanged,
                style: AppTypography.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Result View ───────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, required this.quiz});
  final AttemptResultModel result;
  final QuizModel quiz;

  @override
  Widget build(BuildContext context) {
    final isPassing = result.percentage >= 50;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Icon(
            isPassing ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 64,
            color: isPassing ? AppColors.successGreen : AppColors.errorRed,
          ),
          const SizedBox(height: 12),
          Text(
            isPassing ? 'Well done!' : 'Better luck next time!',
            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${result.score} / ${result.totalMarks}  (${result.percentage.toStringAsFixed(1)}%)',
            style: AppTypography.titleMedium.copyWith(color: AppColors.grey700),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Question Breakdown',
                style: AppTypography.labelLarge
                    .copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          ...result.questionsWithResults.map((qr) {
            final isCorrect = qr['is_correct'] as bool? ?? false;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                      color: isCorrect
                          ? AppColors.successGreen.withOpacity(0.4)
                          : AppColors.errorRed.withOpacity(0.4))),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          size: 18,
                          color: isCorrect
                              ? AppColors.successGreen
                              : AppColors.errorRed,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            qr['question_text']?.toString() ?? '',
                            style: AppTypography.bodySmall
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${qr['earned']}/${qr['marks']}',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.grey600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your answer: ${qr['student_answer'] ?? '-'}',
                      style: AppTypography.caption.copyWith(
                          color: isCorrect
                              ? AppColors.successGreen
                              : AppColors.errorRed),
                    ),
                    if (!isCorrect)
                      Text(
                        'Correct: ${qr['correct_answer']}',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.grey600),
                      ),
                    if (qr['explanation'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Explanation: ${qr['explanation']}',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.grey500),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Content'),
            ),
          ),
        ],
      ),
    );
  }
}