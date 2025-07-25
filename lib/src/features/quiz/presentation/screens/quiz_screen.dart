import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/question.dart';
import '../../application/bandit_manager.dart';
import '../../application/providers.dart';

/// Modern quiz screen with adaptive learning
class QuizScreen extends ConsumerStatefulWidget {
  final String? subject;
  
  const QuizScreen({
    super.key,
    this.subject,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with TickerProviderStateMixin {
  late AnimationController _questionController;
  late AnimationController _progressController;
  late AnimationController _feedbackController;

  late Animation<double> _questionAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _feedbackAnimation;
  late Animation<Offset> _slideAnimation;

  final BanditManager _banditManager = BanditManager();

  Question? _currentQuestion;
  int _questionIndex = 0;
  int _correctAnswers = 0;
  int _totalQuestions = 0;
  bool _showingFeedback = false;
  bool _isAnswered = false;
  String? _selectedAnswer;
  String? _feedback;
  Color _feedbackColor = Colors.green;

  final List<String> _answeredQuestionIds = [];
  List<Question> _availableQuestions = [];
  bool _questionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadQuestions();
  }

  void _loadQuestions() async {
    if (widget.subject != null) {
      try {
        final quizService = ref.read(quizServiceProvider);
        final questions = await quizService.getQuestionsBySubject(widget.subject!);
        setState(() {
          _availableQuestions = questions;
          _questionsLoaded = true;
        });
        _loadNextQuestion();
      } catch (e) {
        // Fallback to default questions or show error
        setState(() {
          _availableQuestions = [];
          _questionsLoaded = true;
        });
      }
    } else {
      // No subject specified, show error or navigate back
      setState(() {
        _availableQuestions = [];
        _questionsLoaded = true;
      });
    }
  }

  void _initializeAnimations() {
    _questionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _questionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _questionController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    ));

    _feedbackAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _questionController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _questionController.dispose();
    _progressController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _loadNextQuestion() {
    if (!_questionsLoaded) return;

    var availableQuestions = _availableQuestions
        .where((q) => !_answeredQuestionIds.contains(q.id))
        .toList();

    if (availableQuestions.isEmpty && _availableQuestions.isNotEmpty) {
      _answeredQuestionIds.clear();
      availableQuestions = _availableQuestions;
    }

    if (availableQuestions.isNotEmpty) {
      final questionTypeGroups = <QuestionType, List<Question>>{};
      for (var q in availableQuestions) {
        (questionTypeGroups[q.type] ??= []).add(q);
      }

      final availableTypes = questionTypeGroups.keys.toList();
      if (availableTypes.isNotEmpty) {
        availableTypes.shuffle();
        final selectedType = availableTypes.first;
        final questionsOfType = questionTypeGroups[selectedType]!;
        questionsOfType.shuffle();
        final recommendedQuestion = questionsOfType.first;

        setState(() {
          _currentQuestion = recommendedQuestion;
          _isAnswered = false;
          _selectedAnswer = null;
          _showingFeedback = false;
          _questionIndex++;
        });

        _questionController.reset();
        _questionController.forward();

        _progressController.animateTo((_questionIndex % 10) / 10);
      }
    }
  }

  void _answerQuestion(String answer) {
    if (_isAnswered || _currentQuestion == null) return;

    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      _totalQuestions++;
    });

    final isCorrect = answer == _currentQuestion!.correctAnswer;

    if (isCorrect) {
      _correctAnswers++;
      _feedback = 'Doğru! 🎉';
      _feedbackColor = Colors.green;
    } else {
      _feedback = 'Yanlış. Doğru cevap: ${_currentQuestion!.correctAnswer}';
      _feedbackColor = Colors.red;
    }

    // BanditManager'a sonucu bildir
    _banditManager.reportResult(_currentQuestion!.id, isCorrect);
    _answeredQuestionIds.add(_currentQuestion!.id);

    setState(() {
      _showingFeedback = true;
    });

    _feedbackController.forward().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _feedbackController.reverse();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _loadNextQuestion(); // Sonsuz devam et
            }
          });
        }
      });
    });
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Quiz\'den Çık'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Quiz\'i sonlandırmak istediğinizden emin misiniz?'),
            const SizedBox(height: 16),
            if (_totalQuestions > 0) ...[
              Text(
                'Şu ana kadar $_correctAnswers/$_totalQuestions doğru cevap verdiniz.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Devam Et'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Çık'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4facfe),
              Color(0xFF00f2fe),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildQuizHeader(),
              Expanded(
                child: _currentQuestion == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildQuestionContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _showExitDialog(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: Text(
                  widget.subject ?? 'Quiz',
                  style: AppTextStyles.h3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Soru $_questionIndex',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$_correctAnswers doğru',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: (_questionIndex % 10) / 10, // Döngüsel progress
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent() {
    return AnimatedBuilder(
      animation: _questionAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _questionAnimation,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildQuestionCard(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildAnswerOptions(),
                  ),
                  if (_showingFeedback) _buildFeedback(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getDifficultyColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _currentQuestion!.difficulty.name.toUpperCase(),
              style: AppTextStyles.bodySmall.copyWith(
                color: _getDifficultyColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentQuestion!.text,
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (_currentQuestion!.difficulty) {
      case DifficultyLevel.beginner:
        return Colors.green;
      case DifficultyLevel.intermediate:
        return Colors.orange;
      case DifficultyLevel.advanced:
        return Colors.red;
    }
  }

  Widget _buildAnswerOptions() {
    return ListView.builder(
      itemCount: _currentQuestion!.options.length,
      itemBuilder: (context, index) {
        final option = _currentQuestion!.options[index];
        final isSelected = _selectedAnswer == option;
        final isCorrect = option == _currentQuestion!.correctAnswer;

        Color backgroundColor = Colors.white;
        Color borderColor = AppColors.border;

        if (_isAnswered) {
          if (isCorrect) {
            backgroundColor = Colors.green.withValues(alpha: 0.1);
            borderColor = Colors.green;
          } else if (isSelected && !isCorrect) {
            backgroundColor = Colors.red.withValues(alpha: 0.1);
            borderColor = Colors.red;
          }
        } else if (isSelected) {
          backgroundColor = AppColors.primary.withValues(alpha: 0.1);
          borderColor = AppColors.primary;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _answerQuestion(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(color: borderColor, width: 2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index), // A, B, C, D
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_isAnswered && isCorrect)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  if (_isAnswered && isSelected && !isCorrect)
                    const Icon(
                      Icons.cancel,
                      color: Colors.red,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedback() {
    return AnimatedBuilder(
      animation: _feedbackAnimation,
      builder: (context, child) {
        return ScaleTransition(
          scale: _feedbackAnimation,
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _feedbackColor.withValues(alpha: 0.1),
              border: Border.all(color: _feedbackColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _feedbackColor == Colors.green
                      ? Icons.check_circle
                      : Icons.error,
                  color: _feedbackColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _feedback ?? '',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _feedbackColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
