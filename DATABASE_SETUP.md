# SQLite Database Setup - MAB Quiz System

## Genel Bakış

MAB Quiz uygulamasına **SQLite veritabanı** entegrasyonu eklendi. Artık tüm MAB (Multi-Armed Bandit) state'leri, kullanıcı cevapları, quiz oturumları ve sorular yerel veritabanında saklanıyor.

---

## Neler Eklendi?

### 1. Paketler
- `sqflite: ^2.3.0` - SQLite veritabanı

### 2. Veritabanı Yapısı

#### **5 Ana Tablo:**

1. **questions** - Sorular ve içerikleri
   - Kurs, konu, zorluk seviyesi
   - Seçenekler ve doğru cevaplar
   - Açıklamalar ve etiketler

2. **user_responses** - Kullanıcı cevapları
   - Seçilen cevap
   - Doğru/yanlış durumu
   - Cevap süresi
   - Güven seviyesi

3. **mab_question_arms** - Soru bazlı MAB state'leri
   - Thompson Sampling parametreleri (alpha, beta)
   - Deneme, başarı, başarısızlık sayıları
   - Kullanıcı güven seviyesi
   - Ortalama cevap süresi

4. **mab_topic_arms** - Konu bazlı MAB state'leri
   - Hiyerarşik MAB için konu performansı
   - Thompson Sampling parametreleri
   - Konu bazlı istatistikler

5. **quiz_sessions** - Quiz oturumları
   - Başlangıç/bitiş zamanları
   - Toplam soru ve doğru cevap sayısı
   - Oturum süresi

---

## Dosya Yapısı

```
lib/
└── src/
    └── core/
        └── database/
            ├── database_helper.dart              # Ana veritabanı yöneticisi
            ├── models/                           # Veritabanı modelleri
            │   ├── question_db_model.dart
            │   ├── user_response_db_model.dart
            │   ├── mab_question_arm_db_model.dart
            │   ├── mab_topic_arm_db_model.dart
            │   └── quiz_session_db_model.dart
            └── repositories/                     # CRUD operasyonları
                └── mab_repository.dart
```

---

## Kurulum Adımları

### 1. Bağımlılıkları Yükle

```bash
flutter pub get
```

### 2. Veritabanı Otomatik Oluşturulacak

İlk çalıştırmada veritabanı otomatik olarak oluşturulur:
- Tüm tablolar
- İndeksler
- İlişkiler

### 3. Kullanım Örnekleri

#### Veritabanı İstatistikleri

```dart
import 'package:mabquiz/src/core/database/database_helper.dart';

final dbHelper = DatabaseHelper.instance;
final stats = await dbHelper.getDatabaseStats();
print('Toplam soru sayısı: ${stats['questions']}');
print('Toplam cevap sayısı: ${stats['responses']}');
```

#### MAB State Kaydetme

```dart
import 'package:mabquiz/src/features/quiz/data/repositories/bandit_state_repository.dart';

final stateRepo = BanditStateRepository();

// Soru arm'ını kaydet
await stateRepo.saveQuestionArmState(questionId, banditArm);

// Konu arm'ını kaydet
await stateRepo.saveTopicArmState(topicKey, topicArm);
```

#### MAB State Yükleme

```dart
// Tek bir soru arm'ı yükle
final questionArm = await stateRepo.loadQuestionArmState(questionId);

// Tüm soru arm'larını yükle
final allArms = await stateRepo.loadAllQuestionArms();

// Zayıf konuları bul (pratik gerektiren)
final weakTopics = await stateRepo.getWeakTopicKeys(
  threshold: 0.6,    // %60'ın altında başarı oranı
  minAttempts: 5,    // En az 5 deneme
);
```

#### İstatistikler

```dart
final mabRepo = MabRepository();

// Genel MAB istatistikleri
final stats = await mabRepo.getMabStats(userId);

// Zayıf performans gösteren sorular
final weakQuestions = await mabRepo.getWeakQuestions(
  userId,
  threshold: 0.6,
  minAttempts: 3,
);

// En iyi performans gösteren konular
final bestTopics = await mabRepo.getBestTopics(
  userId,
  minAttempts: 5,
  limit: 5,
);
```

---

## Özellikler

### ✅ Performans
- **İndekslenmiş tablolar** - Hızlı sorgular
- **Lazy loading** - Veritabanı sadece gerektiğinde açılır
- **Connection pooling** - Otomatik bağlantı yönetimi

### ✅ Veri Tutarlılığı
- **UNIQUE constraints** - Duplicate veri önleme
- **Foreign keys** - İlişkisel bütünlük
- **Transactions** - Atomik işlemler

### ✅ Senkronizasyon Desteği
- `is_synced` flag'i - Hangi veriler senkronize edilmedi
- `synced_at` timestamp - Son senkronizasyon zamanı
- `getUnsyncedCounts()` - Bekleyen kayıt sayıları

### ✅ Kullanıcı Bazlı Veri
- Tüm veriler `user_id` ile ilişkilendirilmiş
- Multi-user desteği hazır
- Kullanıcıya özel veri temizleme

---

## Migration Sistemi

Veritabanı versiyonu yönetimi mevcut:

```dart
// database_helper.dart içinde
static const int _databaseVersion = 1;

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  // Version 2'ye geçiş
  if (oldVersion < 2) {
    // await db.execute('ALTER TABLE ...');
  }
}
```

Gelecekte şema değişiklikleri için bu metod kullanılacak.

---

## Veritabanı Yönetimi

### Veritabanını Temizle

```dart
// Sadece kullanıcı verilerini temizle
await dbHelper.clearUserData(userId);

// Tüm verileri temizle (sorular hariç)
await dbHelper.clearAllData();
```

### Veritabanını Sil (Dikkatli!)

```dart
await dbHelper.deleteDatabase();
```

### Bağlantıyı Kapat

```dart
await dbHelper.close();
```

---

## Senkronizasyon

Offline-first mimari için hazır:

```dart
// Senkronize edilmemiş kayıtları al
final unsyncedCounts = await dbHelper.getUnsyncedCounts();
print('Bekleyen kayıtlar: ${unsyncedCounts['total']}');

// Senkronizasyon sonrası işaretle
await dbHelper.markAsSynced('user_responses', [1, 2, 3]);
```

---

## TODO: Sonraki Adımlar

### 1. User ID Entegrasyonu
Şu anda `BanditStateRepository._getCurrentUserId()` sabit bir değer döndürüyor:

```dart
String _getCurrentUserId() {
  // TODO: Get from actual auth service
  return 'default_user';
}
```

**Bunu gerçek auth service'den alacak şekilde güncelle:**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/application/providers.dart';

String _getCurrentUserId(WidgetRef ref) {
  final user = ref.watch(authStateProvider).value;
  return user?.uid ?? 'anonymous';
}
```

### 2. Backend Senkronizasyonu
- Offline verileri backend'e gönder
- Backend'den güncellemeleri çek
- Conflict resolution ekle

### 3. Question Repository Ekle
Sorular için ayrı bir repository oluştur:

```dart
class QuestionRepository {
  Future<void> saveQuestion(QuestionDbModel question);
  Future<List<QuestionDbModel>> getQuestionsByCourse(String course);
  Future<void> syncQuestionsFromBackend();
}
```

### 4. Session Repository Ekle
Quiz oturumları için:

```dart
class QuizSessionRepository {
  Future<String> startSession(...);
  Future<void> endSession(...);
  Future<List<QuizSessionDbModel>> getRecentSessions(String userId);
}
```

---

## Test Senaryoları

### 1. Veritabanı Oluşturma Testi

```bash
flutter run
# Uygulamayı başlat ve veritabanının oluşturulduğunu kontrol et
```

Beklenen:
- `mabquiz.db` dosyası oluşturulmalı
- 5 tablo oluşturulmalı
- İndeksler kurulmalı

### 2. MAB State Kaydetme Testi

```dart
// Quiz ekranında bir soruyu cevapla
// BanditManager'ın state'i kaydettiğini kontrol et
```

### 3. State Yükleme Testi

```dart
// Uygulamayı kapat ve tekrar aç
// Önceki MAB state'lerinin yüklendiğini kontrol et
```

---

## Sorun Giderme

### "Table already exists" Hatası
Veritabanını sil ve tekrar oluştur:

```dart
await DatabaseHelper.instance.deleteDatabase();
```

### "No such table" Hatası
Version numarasını artır ve yeniden çalıştır.

### Performans Sorunları
İndekslerin oluşturulduğunu kontrol et:

```sql
SELECT name FROM sqlite_master WHERE type='index';
```

---

## Veritabanı Dosyası Konumu

- **Android:** `/data/data/com.example.mabquiz/databases/mabquiz.db`
- **iOS:** `Library/Application Support/mabquiz.db`
- **Windows:** `%APPDATA%/mabquiz/databases/mabquiz.db`

---

## Katkıda Bulunanlar

Bu SQLite entegrasyonu, MAB Quiz sisteminin offline-first mimarisine geçişinin ilk adımıdır.

**Özellikler:**
- ✅ Veritabanı şeması
- ✅ CRUD operasyonları
- ✅ MAB state persistence
- ✅ İndeksler ve optimizasyon
- ⏳ Backend senkronizasyonu (TODO)
- ⏳ Conflict resolution (TODO)

---

## Ek Kaynaklar

- [sqflite Documentation](https://pub.dev/packages/sqflite)
- [SQLite Best Practices](https://www.sqlite.org/bestpractice.html)
- [Flutter Database Tutorial](https://docs.flutter.dev/cookbook/persistence/sqlite)
