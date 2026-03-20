import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../models/question_model.dart';
import '../models/submission_model.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/submission_provider.dart';

class TakeQuizScreen extends ConsumerStatefulWidget {
  final TaskModel task;

  const TakeQuizScreen({super.key, required this.task});

  @override
  ConsumerState<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends ConsumerState<TakeQuizScreen> {
  // Maps the Question ID to the selected choice index
  final Map<String, int> _selectedAnswers = {};
  bool _isSubmitting = false;

  Future<void> _submitQuiz(List<QuestionModel> questions) async {
    // 1. Validation: Ensure all questions are answered
    if (_selectedAnswers.length < questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions before submitting.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 2. Instant Grading Logic
      int correctAnswers = 0;
      for (var question in questions) {
        if (_selectedAnswers[question.id] == question.correctAnswerIndex) {
          correctAnswers++;
        }
      }

      // Calculate final score based on the Task's maxScore
      double rawScore = (correctAnswers / questions.length) * widget.task.maxScore;
      String finalGrade = rawScore.round().toString();

      // 3. Get Current Student Info
      final user = ref.read(authControllerProvider).currentUser;
      if (user == null) throw Exception("User not logged in");

      // 4. Create Submission Model
      final submission = SubmissionModel(
        id: '', // Firestore auto-generates this
        taskId: widget.task.id,
        studentId: user.uid,
        studentEmail: user.email ?? 'Unknown',
        submittedAt: DateTime.now(),
        grade: finalGrade,
      );

      // 5. Save to Firestore
      await ref.read(submissionRepositoryProvider).createSubmission(submission);

      // 6. Show Results & Exit
      if (mounted) {
        _showResultsDialog(correctAnswers, questions.length, finalGrade);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showResultsDialog(int correct, int total, String finalGrade) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Submitted!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You got $correct out of $total correct.', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text(
              'Final Score: $finalGrade / ${widget.task.maxScore}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text('Return to Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsByTaskProvider(widget.task.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.title),
      ),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(child: Text('No questions available for this quiz.'));
          }

          return Column(
            children: [
              // Header Instructions
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.task.description,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),

              // Questions List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ${question.questionText}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),

                            // Generate Radio Buttons for Choices
                            ...List.generate(question.choices.length, (choiceIndex) {
                              return RadioListTile<int>(
                                title: Text(question.choices[choiceIndex]),
                                value: choiceIndex,
                                groupValue: _selectedAnswers[question.id],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedAnswers[question.id] = value;
                                    });
                                  }
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Submit Button Area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                  ],
                ),
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isSubmitting ? null : () => _submitQuiz(questions),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Answers', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}