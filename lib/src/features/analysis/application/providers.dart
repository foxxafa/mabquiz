import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mock analiz verileri için provider'lar

// Genel istatistikler
final analysisStatsProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'totalQuestions': 1247,
    'correctAnswers': 956,
    'successRate': 76.7,
    'totalStudyTime': '42.5 saat',
    'streakDays': 12,
    'currentRank': 156,
  };
});

// Haftalık performans grafiği
final weeklyPerformanceProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  return [
    {'day': 'Pzt', 'score': 85, 'questions': 45},
    {'day': 'Sal', 'score': 92, 'questions': 38},
    {'day': 'Çar', 'score': 78, 'questions': 52},
    {'day': 'Per', 'score': 88, 'questions': 41},
    {'day': 'Cum', 'score': 95, 'questions': 33},
    {'day': 'Cmt', 'score': 82, 'questions': 28},
    {'day': 'Paz', 'score': 90, 'questions': 35},
  ];
});

// Konu bazlı performans
final subjectPerformanceProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  return [
    {
      'subject': 'Farmakoloji',
      'progress': 0.85,
      'correctAnswers': 342,
      'totalQuestions': 402,
      'color': 0xFF58CC02,
    },
    {
      'subject': 'Terminoloji',
      'progress': 0.72,
      'correctAnswers': 289,
      'totalQuestions': 401,
      'color': 0xFF1CB0F6,
    },
    {
      'subject': 'Anatomi',
      'progress': 0.68,
      'correctAnswers': 195,
      'totalQuestions': 287,
      'color': 0xFFFF9600,
    },
    {
      'subject': 'Fizyoloji',
      'progress': 0.79,
      'correctAnswers': 130,
      'totalQuestions': 165,
      'color': 0xFF9013FE,
    },
  ];
});

// Son aktiviteler
final recentActivitiesProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  return [
    {
      'title': 'Farmakoloji Quiz',
      'score': 92,
      'questions': 25,
      'date': '2 saat önce',
      'type': 'multiple_choice',
    },
    {
      'title': 'Terminoloji Test',
      'score': 87,
      'questions': 18,
      'date': '5 saat önce',
      'type': 'fill_blank',
    },
    {
      'title': 'Karma Quiz',
      'score': 95,
      'questions': 30,
      'date': 'Dün',
      'type': 'mixed',
    },
    {
      'title': 'Anatomi Quiz',
      'score': 78,
      'questions': 22,
      'date': '2 gün önce',
      'type': 'true_false',
    },
  ];
});

// Loading durumu
final analysisLoadingProvider = StateProvider<bool>((ref) => false);
