# Firebase Setup Guide

Bu doküman MAB Quiz uygulaması için Firebase yapılandırmasını açıklar.

## Firebase Projesi Kurulumu

### 1. Firebase Projesi Oluşturma

1. [Firebase Console](https://console.firebase.google.com/) adresine gidin
2. "Create a project" butonuna tıklayın
3. Proje adını girin (örn: "mabquiz-app")
4. Google Analytics'i etkinleştirin (isteğe bağlı)
5. Projeyi oluşturun

### 2. Flutter App'i Firebase'e Ekleme

1. Firebase Console'da projenizi açın
2. "Add app" butonuna tıklayın ve Flutter'ı seçin
3. Package name'i girin: `com.example.mabquiz`
4. `google-services.json` dosyasını indirin
5. Dosyayı `android/app/` klasörüne koyun

### 3. Dependencies Ekleme

`pubspec.yaml` dosyasına aşağıdaki dependencies'leri ekleyin:

```yaml
dependencies:
  # Firebase Core
  firebase_core: ^2.24.0
  
  # Firebase Authentication
  firebase_auth: ^4.15.0
  
  # Cloud Firestore
  cloud_firestore: ^4.13.0
  
  # Firebase Storage (opsiyonel - medya dosyaları için)
  firebase_storage: ^11.5.0
  
  # Firebase Analytics (opsiyonel)
  firebase_analytics: ^10.7.0
```

### 4. Android Konfigürasyonu

#### `android/build.gradle` dosyasında:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

#### `android/app/build.gradle` dosyasında:

```gradle
// En üste ekleyin
apply plugin: 'com.google.gms.google-services'

android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### 5. iOS Konfigürasyonu (opsiyonel)

1. `ios/Runner/GoogleService-Info.plist` dosyasını Firebase'den indirin
2. Xcode'da projeye ekleyin
3. `ios/Runner/Info.plist` dosyasını güncelleyin

## Firestore Database Yapısı

### Collections Yapısı

#### 1. Questions Collection

```
questions/
├── {questionId}/
    ├── text: string
    ├── type: string ("multipleChoice" | "trueFalse" | "fillInBlank" | "matching")
    ├── difficulty: string ("beginner" | "intermediate" | "advanced")
    ├── options: array<string>
    ├── correctAnswer: string
    ├── explanation: string
    ├── tags: array<string>
    ├── subject: string
    ├── points: number
    ├── initialConfidence: number
    ├── createdAt: timestamp
    ├── updatedAt: timestamp
    └── isActive: boolean
```

#### 2. Subjects Collection

```
subjects/
├── {subjectId}/
    ├── name: string
    ├── description: string
    ├── icon: string
    ├── color: string
    ├── isActive: boolean
    └── questionCount: number
```

#### 3. Quiz Sessions Collection

```
quiz_sessions/
├── {sessionId}/
    ├── participantIds: array<string>
    ├── currentQuestionId: string
    ├── scores: map<string, number>
    ├── startTime: timestamp
    ├── endTime: timestamp
    ├── isActive: boolean
    ├── settings: object
    └── answers: map<string, map<string, string>>
```

#### 4. User Stats Collection

```
user_stats/
├── {userId}/
    ├── totalQuizzesCompleted: number
    ├── totalQuestionsAnswered: number
    ├── correctAnswers: number
    ├── totalPoints: number
    ├── averageScore: number
    ├── subjectStats: map<string, object>
    ├── difficultyStats: map<string, object>
    └── lastUpdated: timestamp
```

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Questions - sadece okuma izni
    match /questions/{questionId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      request.auth.token.admin == true;
    }
    
    // Subjects - sadece okuma izni
    match /subjects/{subjectId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      request.auth.token.admin == true;
    }
    
    // Quiz Sessions - kullanıcı kendi sessionlarını yönetebilir
    match /quiz_sessions/{sessionId} {
      allow read, write: if request.auth != null && 
                            request.auth.uid in resource.data.participantIds;
    }
    
    // User Stats - kullanıcı sadece kendi istatistiklerini görebilir
    match /user_stats/{userId} {
      allow read, write: if request.auth != null && 
                            request.auth.uid == userId;
    }
  }
}
```

### Firestore Indexes

Aşağıdaki composite indexleri oluşturun:

1. **Questions by Subject and Difficulty**
   - Collection: `questions`
   - Fields: `subject` (Ascending), `difficulty` (Ascending), `isActive` (Ascending)

2. **Questions by Subject**
   - Collection: `questions`
   - Fields: `subject` (Ascending), `isActive` (Ascending)

3. **Questions by Difficulty**
   - Collection: `questions`
   - Fields: `difficulty` (Ascending), `isActive` (Ascending)

4. **Active Questions**
   - Collection: `questions`
   - Fields: `isActive` (Ascending), `createdAt` (Descending)

## Kod Değişiklikleri

### 1. Firebase DataSource Aktifleştirme

`lib/src/features/quiz/data/data_sources/firebase_quiz_datasource.dart` dosyasını güncelleyin:

```dart
// TODO yorumlarını kaldırın ve gerçek Firebase implementasyonunu ekleyin
```

### 2. Dependency Injection

`lib/src/features/quiz/application/providers.dart` dosyasında:

```dart
final quizDataSourceProvider = Provider<QuizDataSource>((ref) {
  final useMockAuth = ref.watch(useMockAuthProvider);
  
  if (useMockAuth) {
    return MockQuizDataSource();
  } else {
    // Firebase datasource'u aktifleştirin
    return FirebaseQuizDataSourceImpl(FirebaseFirestore.instance);
  }
});
```

### 3. Firebase Initialization

`lib/main.dart` dosyasını güncelleyin:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i başlatın
  await Firebase.initializeApp();
  
  // Geliştirme ortamında emulator kullanın
  if (kDebugMode) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
  
  runApp(const MyApp());
}
```

## Test Verisi Ekleme

### Firebase Console Üzerinden

1. Firestore Database'e gidin
2. "Start collection" butonuna tıklayın
3. Collection ID: `questions`
4. İlk dokümanı oluşturun
5. `docs/firebase_structure.json` dosyasındaki örnek verileri kullanın

### Programatik Olarak

```dart
// Geliştirme ortamında test verileri eklemek için
Future<void> seedDatabase() async {
  final firestore = FirebaseFirestore.instance;
  
  // Örnek soru ekleme
  await firestore.collection('questions').doc('math_001').set({
    'text': '2 + 2 = ?',
    'type': 'multipleChoice',
    'difficulty': 'beginner',
    'options': ['3', '4', '5', '6'],
    'correctAnswer': '4',
    'explanation': '2 + 2 = 4. Temel toplama işlemi.',
    'tags': ['toplama', 'temel'],
    'subject': 'Matematik',
    'points': 5,
    'initialConfidence': 0.5,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'isActive': true,
  });
}
```

## Emulator Setup (Geliştirme için)

### 1. Firebase CLI Kurulumu

```bash
npm install -g firebase-tools
firebase login
```

### 2. Emulator Başlatma

```bash
firebase init emulators
firebase emulators:start
```

### 3. Flutter App'de Emulator Kullanımı

```dart
// main.dart veya firebase initialization kısmında
if (kDebugMode) {
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
}
```

## Production Deployment

### 1. Security Rules Güncelleme

Production'da güvenlik kurallarını sıkılaştırın.

### 2. Performance Monitoring

Firebase Performance ve Crashlytics'i entegre edin.

### 3. Backup Strategy

Firestore için düzenli backup planı oluşturun.

## Monitoring ve Analytics

### 1. Firebase Analytics

Kullanıcı davranışlarını izlemek için:

```dart
await FirebaseAnalytics.instance.logEvent(
  name: 'quiz_completed',
  parameters: {
    'subject': 'Matematik',
    'score': 85,
    'duration': 300,
  },
);
```

### 2. Crashlytics

Hata raporlaması için:

```dart
FirebaseCrashlytics.instance.recordError(
  error,
  stackTrace,
  reason: 'Quiz data loading failed',
);
```

## Troubleshooting

### Yaygın Sorunlar

1. **Gradle Sync Hatası**: Google Services plugin'in doğru yerde olduğundan emin olun
2. **Permission Denied**: Firestore security rules'ları kontrol edin
3. **Network Error**: İnternet bağlantısını ve Firebase config'i kontrol edin

### Debug Yöntemleri

```dart
// Firestore debug logging
FirebaseFirestore.setLoggingEnabled(true);

// Auth debug
FirebaseAuth.instance.setSettings(
  appVerificationDisabledForTesting: true,
);
```
