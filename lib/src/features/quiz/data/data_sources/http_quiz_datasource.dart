import '../../../../core/services/http_service.dart';
import '../../../../core/config/config.dart';
import '../../domain/entities/question.dart';
import 'mock_quiz_datasource.dart';

/// HTTP-based implementation of QuizDataSource
/// 
/// Communicates with the FastAPI backend to fetch quiz data
/// Falls back to mock data if API calls fail
class HttpQuizDataSource implements QuizDataSource {
  final HttpService _httpService;
  final MockQuizDataSource _mockDataSource;

  HttpQuizDataSource(this._httpService) : _mockDataSource = MockQuizDataSource();

  @override
  Future<List<Question>> getQuestionsBySubject(String subject) async {
    try {
      final response = await _httpService.get('/questions', queryParams: {
        'subject': subject,
      });

      final List<dynamic> questionsJson = response['questions'] ?? [];
      return questionsJson.map((json) => Question.fromJson(json)).toList();
    } catch (e) {
      // Fallback to mock data if API fails
      print('API call failed, falling back to mock data: $e');
      return await _mockDataSource.getQuestionsBySubject(subject);
    }
  }

  @override
  Future<List<Question>> getQuestionsByDifficulty(DifficultyLevel difficulty) async {
    try {
      final response = await _httpService.get('/questions', queryParams: {
        'difficulty': difficulty.name,
      });

      final List<dynamic> questionsJson = response['questions'] ?? [];
      return questionsJson.map((json) => Question.fromJson(json)).toList();
    } catch (e) {
      // Fallback to mock data if API fails
      print('API call failed, falling back to mock data: $e');
      return await _mockDataSource.getQuestionsByDifficulty(difficulty);
    }
  }

  @override
  Future<Question?> getQuestionById(String id) async {
    try {
      final response = await _httpService.get('/questions/$id');
      return Question.fromJson(response);
    } catch (e) {
      // Fallback to mock data if API fails
      print('API call failed, falling back to mock data: $e');
      return await _mockDataSource.getQuestionById(id);
    }
  }

  @override
  Future<List<Question>> getRandomQuestions({
    int limit = 10,
    String? subject,
    DifficultyLevel? difficulty,
    List<String>? excludeIds,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };

      if (subject != null) queryParams['subject'] = subject;
      if (difficulty != null) queryParams['difficulty'] = difficulty.name;
      if (excludeIds != null && excludeIds.isNotEmpty) {
        queryParams['exclude_ids'] = excludeIds.join(',');
      }

      final response = await _httpService.get('/quiz/questions', queryParams: queryParams);
      final List<dynamic> questionsJson = response['questions'] ?? [];
      return questionsJson.map((json) => Question.fromJson(json)).toList();
    } catch (e) {
      // Fallback to mock data if API fails
      print('API call failed, falling back to mock data: $e');
      return await _mockDataSource.getRandomQuestions(
        limit: limit,
        subject: subject,
        difficulty: difficulty,
        excludeIds: excludeIds,
      );
    }
  }

  @override
  Future<List<String>> getAvailableSubjects() async {
    try {
      final response = await _httpService.get('/subjects');
      final List<dynamic> subjects = response['subjects'] ?? [];
      return subjects.cast<String>();
    } catch (e) {
      // Fallback to mock data if API fails
      print('API call failed, falling back to mock data: $e');
      return await _mockDataSource.getAvailableSubjects();
    }
  }

  @override
  Future<List<Question>> getAllQuestions() async {
    try {
      final response = await _httpService.get('/questions/all');
      final List<dynamic> questionsJson = response['questions'] ?? [];
      return questionsJson.map((json) => Question.fromJson(json)).toList();
    } catch (e) {
      // Fallback to mock data if API fails
      print('API call failed, falling back to mock data: $e');
      return await _mockDataSource.getAllQuestions();
    }
  }
}
