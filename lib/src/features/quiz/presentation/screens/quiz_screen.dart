import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/sync_provider.dart';
import '../../../auth/application/providers.dart' show currentUserProvider;
import '../../domain/entities/question.dart';
import '../../application/bandit_manager.dart';
import '../../application/providers.dart';
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

  // Use global BanditManager from provider
  BanditManager? _banditManager;

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

  // Response time tracking
  DateTime? _questionStartTime;

  final List<String> _answeredQuestionIds = [];
  List<Question> _availableQuestions = [];
  bool _questionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeBanditManager();

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

  Future<void> _initializeBanditManager() async {
    // Get initialized BanditManager from provider (with userId loaded)
    final banditManagerAsync = ref.read(banditManagerInitProvider);

    banditManagerAsync.when(
      data: (manager) {
        _banditManager = manager;
        _loadQuestions();
      },
      loading: () {
        // Wait for the provider to load, then retry
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _initializeBanditManager();
          }
        });
      },
      error: (_, __) {
        // On error, use base provider without userId (offline mode)
        _banditManager = ref.read(banditManagerProvider);
        _loadQuestions();
      },
    );
  }

  void _loadQuestions() async {
    if (_banditManager == null || widget.subject == null) {
      setState(() {
        _availableQuestions = [];
        _questionsLoaded = true;
      });
      return;
    }

    try {
      // Load questions directly from assets for mock mode
      final questions =
          await AssetQuestionLoader.loadAllQuestionsForSubject(widget.subject!);
      _banditManager!.initializeQuestions(questions); // Initialize BanditManager
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
  }

  void _initializeAnimations() {
    _questionController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _questionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _questionController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _questionController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
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
    if (!_questionsLoaded || _banditManager == null) return;

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
          _banditManager!.selectNextQuestion(availableQuestions);

      if (recommendedQuestion != null) {
        setState(() {
          _currentQuestion = recommendedQuestion;
          _isAnswered = false;
          _selectedAnswer = null;
          _questionIndex++;
          _fillInBlankController.clear();
          _hasTypedAnswer = false;
          _questionStartTime = DateTime.now(); // Start timer for response time
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

  void _answerQuestion(String answer) async {
    if (_isAnswered || _currentQuestion == null || _banditManager == null) return;

    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      _totalQuestions++;
    });

    final isCorrect = answer == _currentQuestion!.correctAnswer;

    if (isCorrect) {
      _correctAnswers++;
    }

    // Calculate actual response time
    final responseTime = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!)
        : const Duration(seconds: 5); // Fallback if timer not set

    // BanditManager'a sonucu bildir ve veritabanına kaydet
    await _banditManager!.updatePerformance(
      questionId: _currentQuestion!.id,
      isCorrect: isCorrect,
      responseTime: responseTime,
      question: _currentQuestion, // Pass question for database save
    );
    _answeredQuestionIds.add(_currentQuestion!.id);
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
              // Trigger sync when exiting quiz
              final user = ref.read(currentUserProvider);
              if (user != null) {
                // ignore: avoid_print
                print('🔄 QuizScreen: Triggering sync on exit...');
                ref.read(syncNotifierProvider.notifier).sync(user.uid);
              }
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
              Color(0xFF0a0a0a),
              Color(0xFF1a1645),
              Color(0xFF2E5EAA),
              Color(0xFF1a1a1a),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
            offset: const Offset(0, -1),
            blurRadius: 2,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => _showExitDialog(),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Text(
              widget.subject ?? 'Quiz',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Soru $_questionIndex',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_correctAnswers doğru',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(ThemeData theme) {
    if (_currentQuestion == null) {
      return const Center(child: Text('Soru yükleniyor...'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Soru kutusu - Flexible ile ekranın üst kısmını kullan
                  Flexible(
                    flex: 2,
                    child: Center(
                      child: FadeTransition(
                        opacity: _questionAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.15),
                                  Colors.white.withValues(alpha: 0.08),
                                  Colors.white.withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  offset: const Offset(0, 12),
                                  blurRadius: 30,
                                  spreadRadius: -8,
                                ),
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                  offset: const Offset(0, 0),
                                  blurRadius: 20,
                                  spreadRadius: -6,
                                ),
                              ],
                            ),
                            child: Center(child: _buildQuestionText(theme)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Cevap seçenekleri - Flexible ile ekranın kalan kısmını kullan
                  Flexible(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_currentQuestion!.type == QuestionType.fillInBlank)
                          _buildFillInBlankInput(theme)
                        else
                          Expanded(
                            child: ListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: _buildAnswerOptions(theme),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // İleri butonu - sabit boyutta
                  _buildNextButton(theme),
                ],
              ),
            ),
          ),
        );
      },
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
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.headlineMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 19,
        height: 1.4,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildFillInBlankInput(ThemeData theme) {
    // Cevap kontrolü
    final isCorrect = _isAnswered && 
        _currentQuestion != null && 
        _currentQuestion!.isCorrectAnswer(_fillInBlankController.text.trim());
    
    // Renk belirleme
    Color borderColor;
    Color shadowColor;
    List<Color> gradientColors;
    
    if (_isAnswered) {
      if (isCorrect) {
        // Doğru cevap - yeşil
        borderColor = Colors.green;
        shadowColor = Colors.green;
        gradientColors = [
          Colors.green.withValues(alpha: 0.2),
          Colors.green.withValues(alpha: 0.15),
          Colors.green.withValues(alpha: 0.1),
        ];
      } else {
        // Yanlış cevap - kırmızı
        borderColor = Colors.red;
        shadowColor = Colors.red;
        gradientColors = [
          Colors.red.withValues(alpha: 0.2),
          Colors.red.withValues(alpha: 0.15),
          Colors.red.withValues(alpha: 0.1),
        ];
      }
    } else {
      // Henüz cevap verilmedi - mavi (varsayılan)
      borderColor = theme.colorScheme.primary.withValues(alpha: 0.6);
      shadowColor = theme.colorScheme.primary;
      gradientColors = [
        Colors.white.withValues(alpha: 0.12),
        Colors.white.withValues(alpha: 0.08),
        Colors.white.withValues(alpha: 0.04),
      ];
    }
    
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
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: borderColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(0, 8),
                  blurRadius: 20,
                  spreadRadius: -6,
                ),
                BoxShadow(
                  color: shadowColor.withValues(alpha: 0.3),
                  offset: const Offset(0, 0),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  offset: const Offset(0, -1),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _fillInBlankController,
                  focusNode: _fillInBlankFocusNode,
                  enabled: !_isAnswered,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
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
                  onTap: () {
                    // TextField'a tıklandığında da focus iste
                    _fillInBlankFocusNode.requestFocus();
                  },
                ),
                // Yanlış cevap durumunda doğru cevabı göster
                if (_isAnswered && !isCorrect && _currentQuestion != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Doğru cevap: ${_currentQuestion!.correctAnswer}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              backgroundColor.withValues(alpha: 0.9),
              backgroundColor.withValues(alpha: 0.7),
              backgroundColor.withValues(alpha: 0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 8),
              blurRadius: 20,
              spreadRadius: -6,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.1),
              offset: const Offset(0, -1),
              blurRadius: 2,
              spreadRadius: 0,
            ),
            if (_isAnswered && (isSelected || isCorrect))
              BoxShadow(
                color: (iconColor ?? Colors.white).withValues(alpha: 0.3),
                offset: const Offset(0, 0),
                blurRadius: 16,
                spreadRadius: -2,
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            onTap: _isAnswered ? null : () => _answerQuestion(option),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.3),
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 6,
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index), // A, B, C, D
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      option,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (trailingIcon != null)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: iconColor?.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: iconColor?.withValues(alpha: 0.4) ?? Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        trailingIcon,
                        color: iconColor,
                        size: 22,
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

  Widget _buildNextButton(ThemeData theme) {
    // Butonun aktif olup olmayacağını kontrol et
    bool isEnabled = false;
    String buttonText = 'İleri';
    
    if (_currentQuestion != null) {
      if (_currentQuestion!.type == QuestionType.fillInBlank) {
        // Boşluk doldurma: metin yazıldıysa aktif
        isEnabled = _hasTypedAnswer;
        if (!_isAnswered && _hasTypedAnswer) {
          buttonText = 'Cevabı Gönder';
        }
      } else {
        // Çoktan seçmeli: bir şık seçildiyse aktif
        isEnabled = _isAnswered;
      }
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600),
      child: AnimatedOpacity(
        opacity: isEnabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 300),
        child: ElevatedButton(
          onPressed: isEnabled ? () {
            // Boşluk doldurma sorularında eğer henüz cevap verilmemişse, cevabı gönder
            if (_currentQuestion!.type == QuestionType.fillInBlank && !_isAnswered) {
              _answerQuestion(_fillInBlankController.text.trim());
            } else {
              // Diğer durumlarda sonraki soruya geç
              _loadNextQuestion();
            }
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.3),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: isEnabled ? 12 : 2,
            shadowColor: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                buttonText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                buttonText == 'İleri' ? Icons.arrow_forward_rounded : Icons.send_rounded,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
