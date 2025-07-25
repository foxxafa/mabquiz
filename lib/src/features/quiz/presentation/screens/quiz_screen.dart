import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        final questions =
            await quizService.getQuestionsBySubject(widget.subject!);
        _banditManager.initializeQuestions(questions); // Initialize BanditManager
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
      // All questions answered, reset for infinite mode
      _answeredQuestionIds.clear();
      availableQuestions = _availableQuestions;
    }

    if (availableQuestions.isNotEmpty) {
      // Use BanditManager to select the next question
      final recommendedQuestion =
          _banditManager.selectNextQuestion(availableQuestions);

      if (recommendedQuestion != null) {
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
      } else {
        // Handle case where bandit couldn't select a question
        // For now, just load another question randomly.
        availableQuestions.shuffle();
        setState(() {
          _currentQuestion = availableQuestions.first;
          _isAnswered = false;
          _selectedAnswer = null;
          _showingFeedback = false;
          _questionIndex++;
        });
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
    _banditManager.updatePerformance(
      questionId: _currentQuestion!.id,
      isCorrect: isCorrect,
      responseTime: const Duration(seconds: 5), // Placeholder
    );
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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('Quiz\'den Çık', style: theme.textTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quiz\'i sonlandırmak istediğinizden emin misiniz?',
                style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            if (_totalQuestions > 0) ...[
              Text(
                'Şu ana kadar $_correctAnswers/$_totalQuestions doğru cevap verdiniz.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Devam Et', style: TextStyle(color: theme.colorScheme.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              context.go('/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildQuizHeader(theme),
            Expanded(
              child: _questionsLoaded
                  ? _currentQuestion == null
                      ? const Center(child: CircularProgressIndicator())
                      : _buildQuestionContent(theme)
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizHeader(ThemeData theme) {
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
                  style: theme.textTheme.headlineSmall?.copyWith(
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '$_correctAnswers doğru',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
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
                value: _progressAnimation.value,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(ThemeData theme) {
    if (_currentQuestion == null) {
      return const Center(child: Text('Soru yükleniyor...'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          FadeTransition(
            opacity: _questionAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  Text(
                    _currentQuestion!.text,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),
                  ..._buildAnswerOptions(theme),
                ],
              ),
            ),
          ),
          if (_showingFeedback)
            ScaleTransition(
              scale: _feedbackAnimation,
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _feedbackColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _feedback ?? '',
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildAnswerOptions(ThemeData theme) {
    if (_currentQuestion == null) return [];

    final options = _currentQuestion!.options;
    return options.map((option) {
      final isSelected = _selectedAnswer == option;
      final isCorrect = option == _currentQuestion!.correctAnswer;

      Color tileColor = theme.colorScheme.surface;
      Color borderColor = theme.colorScheme.surface;
      IconData? trailingIcon;

      if (_isAnswered) {
        if (isSelected) {
          tileColor = isCorrect
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3);
          borderColor = isCorrect ? Colors.green : Colors.red;
          trailingIcon = isCorrect ? Icons.check_circle : Icons.cancel;
        } else if (isCorrect) {
          tileColor = Colors.green.withOpacity(0.3);
          borderColor = Colors.green;
        }
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: ListTile(
          title: Text(option, style: theme.textTheme.bodyLarge),
          trailing: trailingIcon != null
              ? Icon(trailingIcon,
                  color: isCorrect ? Colors.green : Colors.red)
              : null,
          onTap: () => _answerQuestion(option),
        ),
      );
    }).toList();
  }
}
