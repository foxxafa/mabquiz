import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/question.dart';
import '../../application/bandit_manager.dart';
import '../../data/services/asset_question_loader.dart';

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

  late Animation<double> _questionAnimation;
  late Animation<Offset> _slideAnimation;

  final BanditManager _banditManager = BanditManager();

  Question? _currentQuestion;
  int _questionIndex = 0;
  int _correctAnswers = 0;
  int _totalQuestions = 0;
  bool _isAnswered = false;
  String? _selectedAnswer;
  
  // Fill in blank specific
  final TextEditingController _fillInBlankController = TextEditingController();
  final FocusNode _fillInBlankFocusNode = FocusNode();
  bool _hasTypedAnswer = false;

  final List<String> _answeredQuestionIds = [];
  List<Question> _availableQuestions = [];
  bool _questionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadQuestions();
    
    // TextField listener for fill in blank questions
    _fillInBlankController.addListener(() {
      final hasText = _fillInBlankController.text.trim().isNotEmpty;
      if (hasText != _hasTypedAnswer) {
        setState(() {
          _hasTypedAnswer = hasText;
        });
      }
    });
  }

  void _loadQuestions() async {
    if (widget.subject != null) {
      try {
        // Load questions directly from assets for mock mode
        // print('[QuizScreen] Loading questions for subject: ${widget.subject}');
        final questions =
            await AssetQuestionLoader.loadAllQuestionsForSubject(widget.subject!);
        // print('Questions loaded successfully: ${questions.length} questions');
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

    _questionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _questionController,
      curve: Curves.easeInOut,
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
    _fillInBlankController.dispose();
    _fillInBlankFocusNode.dispose();
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
          _questionIndex++;
          _fillInBlankController.clear();
          _hasTypedAnswer = false;
        });
        
        // Fill in blank için focus'u yeniden ayarla
        if (recommendedQuestion.type == QuestionType.fillInBlank) {
          // Hemen focus iste
          Future.microtask(() {
            if (mounted) {
              _fillInBlankFocusNode.requestFocus();
            }
          });
          
          // Ek olarak frame sonrası da dene
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_fillInBlankFocusNode.hasFocus) {
              _fillInBlankFocusNode.requestFocus();
            }
          });
        }

        _questionController.reset();
        _questionController.forward();
      } else {
        // Handle case where bandit couldn't select a question
        // For now, just load another question randomly.
        availableQuestions.shuffle();
        setState(() {
          _currentQuestion = availableQuestions.first;
          _isAnswered = false;
          _selectedAnswer = null;
          _questionIndex++;
          _fillInBlankController.clear();
          _hasTypedAnswer = false;
        });
        
        // Fill in blank için focus'u yeniden ayarla
        if (availableQuestions.first.type == QuestionType.fillInBlank) {
          // Hemen focus iste
          Future.microtask(() {
            if (mounted) {
              _fillInBlankFocusNode.requestFocus();
            }
          });
          
          // Ek olarak frame sonrası da dene
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_fillInBlankFocusNode.hasFocus) {
              _fillInBlankFocusNode.requestFocus();
            }
          });
        }
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
    }

    // BanditManager'a sonucu bildir
    _banditManager.updatePerformance(
      questionId: _currentQuestion!.id,
      isCorrect: isCorrect,
      responseTime: const Duration(seconds: 5), // Placeholder
    );
    _answeredQuestionIds.add(_currentQuestion!.id);

    // Kısa bir süre bekleyip bir sonraki soruya geç
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _loadNextQuestion();
      }
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0f0f0f),
              Color(0xFF1a1a1a),
              Color(0xFF1a1a1a),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildQuizHeader(theme),
              Expanded(
                child: !_questionsLoaded
                    ? const Center(child: CircularProgressIndicator())
                    : _availableQuestions.isEmpty
                        ? const Center(
                            child: Text(
                              'Sorular yüklenemedi.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : _currentQuestion == null
                            ? const Center(child: CircularProgressIndicator())
                            : _buildQuestionContent(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3a3a3a),
            Color(0xFF2d2d2d),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
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
    );
  }

  Widget _buildQuestionContent(ThemeData theme) {
    if (_currentQuestion == null) {
      return const Center(child: Text('Soru yükleniyor...'));
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _questionAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF2a2a2a),
                              Color(0xFF1f1f1f),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              offset: const Offset(0, 8),
                              blurRadius: 32,
                              spreadRadius: -8,
                            ),
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              offset: const Offset(0, 0),
                              blurRadius: 16,
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: _buildQuestionText(theme),
                      ),
                      const SizedBox(height: 40),
                      if (_currentQuestion!.type == QuestionType.fillInBlank)
                        _buildFillInBlankInput(theme)
                      else
                        ..._buildAnswerOptions(theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionText(ThemeData theme) {
    if (_currentQuestion!.type == QuestionType.fillInBlank) {
      // Boşlukları özel olarak göster
      final text = _currentQuestion!.text;
      final parts = text.split('____'); // Boşluk işaretleyicisi
      
      if (parts.length > 1) {
        return RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
              height: 1.4,
            ),
            children: [
              for (int i = 0; i < parts.length; i++) ...[
                TextSpan(text: parts[i]),
                if (i < parts.length - 1)
                  WidgetSpan(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '____',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      }
    }
    
    return Text(
      _currentQuestion!.text,
      textAlign: TextAlign.center,
      style: theme.textTheme.headlineMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 20,
        height: 1.4,
      ),
    );
  }

  Widget _buildFillInBlankInput(ThemeData theme) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (!_isAnswered) {
              _fillInBlankFocusNode.requestFocus();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2a2a2a),
                  Color(0xFF1f1f1f),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  offset: const Offset(0, 0),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: TextField(
              controller: _fillInBlankController,
              focusNode: _fillInBlankFocusNode,
              enabled: !_isAnswered,
              autofocus: true,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Cevabınızı buraya yazın...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(0),
              ),
              textAlign: TextAlign.center,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _answerQuestion(value.trim());
                }
              },
              onTap: () {
                // TextField'a tıklandığında da focus iste
                _fillInBlankFocusNode.requestFocus();
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isAnswered || !_hasTypedAnswer
                ? null
                : () => _answerQuestion(_fillInBlankController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Cevabı Gönder',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAnswerOptions(ThemeData theme) {
    if (_currentQuestion == null) return [];

    final options = _currentQuestion!.options;
    return options.asMap().entries.map((entry) {
      final index = entry.key;
      final option = entry.value;
      final isSelected = _selectedAnswer == option;
      final isCorrect = option == _currentQuestion!.correctAnswer;

      Color backgroundColor = const Color(0xFF2a2a2a);
      Color borderColor = Colors.white.withValues(alpha: 0.1);
      Color textColor = Colors.white;
      IconData? trailingIcon;
      Color? iconColor;

      if (_isAnswered) {
        if (isSelected) {
          if (isCorrect) {
            backgroundColor = Colors.green.withValues(alpha: 0.2);
            borderColor = Colors.green;
            trailingIcon = Icons.check_circle;
            iconColor = Colors.green;
          } else {
            backgroundColor = Colors.red.withValues(alpha: 0.2);
            borderColor = Colors.red;
            trailingIcon = Icons.cancel;
            iconColor = Colors.red;
          }
        } else if (isCorrect) {
          backgroundColor = Colors.green.withValues(alpha: 0.2);
          borderColor = Colors.green;
          trailingIcon = Icons.check_circle;
          iconColor = Colors.green;
        }
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              backgroundColor,
              backgroundColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: -4,
            ),
            if (_isAnswered && (isSelected || isCorrect))
              BoxShadow(
                color: (iconColor ?? Colors.white).withValues(alpha: 0.2),
                offset: const Offset(0, 0),
                blurRadius: 8,
                spreadRadius: -2,
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _isAnswered ? null : () => _answerQuestion(option),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index), // A, B, C, D
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (trailingIcon != null)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconColor?.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        trailingIcon,
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
