# 🎯 MAB Quiz - Adaptive Learning Quiz System

**Multi-Armed Bandit (MAB) algoritması ile kişiselleştirilmiş öğrenme platformu**

---

## 📖 Proje Hakkında

MAB Quiz, **Thompson Sampling** algoritması kullanarak her kullanıcıya özel soru seçimi yapan akıllı bir quiz uygulamasıdır. Sistem, kullanıcının performansını anlayarak:

- ✅ **Zayıf konuları** daha sık sorar
- ✅ **Öğrenme hızına** göre zorluk ayarlar
- ✅ **Unutulan bilgileri** tekrar eder (forgetting curve)
- ✅ **Optimal öğrenme** deneyimi sağlar

---

## 🏗️ Teknoloji Stack

### 📱 Mobil (Flutter)
- **Flutter** 3.5.0+
- **Riverpod** - State management
- **Go Router** - Navigation
- **SQLite** - Local database
- **Easy Localization** - i18n

### 🖥️ Backend (Python)
- **FastAPI** - REST API
- **SQLAlchemy** - ORM
- **PostgreSQL** - Database
- **Railway** - Deployment

---

## 🧠 MAB Algoritması

### Thompson Sampling

Sistem, her soru ve konu için **Beta dağılımı** kullanır:

```
α (alpha) = 1 + başarılar
β (beta) = 1 + başarısızlıklar
```

**Prior Knowledge (Cold Start Çözümü):**
- Beginner: α=7, β=3 (70% başarı beklentisi)
- Intermediate: α=5, β=5 (50% başarı beklentisi)
- Advanced: α=3, β=7 (30% başarı beklentisi)

### Forgetting Curve

**Ebbinghaus Forgetting Curve** ile unutmayı modelliyor:

```dart
decay_factor = e^(-days / 30)  // 30 gün half-life
```

### Hierarchical MAB

İki seviyeli öğrenme:
1. **Topic Level** - Hangi konu seçilecek?
2. **Question Level** - O konudan hangi soru seçilecek?

---

## 📁 Proje Yapısı

```
mabquiz/
├── lib/                          # Flutter mobil uygulama
│   ├── main.dart                 # Uygulama giriş noktası
│   └── src/
│       ├── core/
│       │   ├── database/         # SQLite veritabanı
│       │   │   ├── database_helper.dart
│       │   │   ├── models/       # DB modelleri
│       │   │   └── repositories/ # CRUD işlemleri
│       │   ├── navigation/
│       │   ├── theme/
│       │   └── localization/
│       └── features/
│           ├── auth/             # Kimlik doğrulama
│           ├── quiz/
│           │   ├── application/  # MAB algoritması
│           │   │   └── bandit_manager.dart
│           │   ├── data/
│           │   │   └── repositories/
│           │   │       └── bandit_state_repository.dart
│           │   └── presentation/
│           ├── home/
│           ├── analysis/         # Performans analizi
│           └── settings/
│
├── backend/                      # Python FastAPI backend
│   ├── app/
│   │   ├── main.py              # FastAPI uygulama
│   │   ├── models/
│   │   │   ├── question.py
│   │   │   ├── mab_state.py     # MAB state modelleri
│   │   │   └── quiz_session.py
│   │   ├── routers/
│   │   └── db.py                # Database config
│   ├── requirements.txt
│   ├── Dockerfile
│   └── README.md
│
├── assets/
│   ├── questions/               # Soru bankası (JSON)
│   └── translations/            # i18n dosyaları
│
└── docs/
    ├── README.md               # Bu dosya
    └── ROADMAP.md              # Gelecek planları
```

---

## 🚀 Kurulum

### Mobil Uygulama

```bash
# 1. Bağımlılıkları yükle
flutter pub get

# 2. Uygulamayı çalıştır
flutter run

# Veritabanı otomatik oluşturulacak ve konsola şu mesajı yazdıracak:
# ✅ Database initialized successfully
# 📊 Database stats: {...}
```

### Backend (Opsiyonel - Local Development)

```bash
# 1. Virtual environment oluştur
cd backend
python -m venv venv
source venv/bin/activate  # Linux/Mac
# veya
venv\Scripts\activate     # Windows

# 2. Bağımlılıkları yükle
pip install -r requirements.txt

# 3. PostgreSQL veritabanı oluştur
# DATABASE_URL env variable ayarla

# 4. Migration çalıştır
python migrate_tables.py

# 5. Backend'i başlat
uvicorn app.main:app --reload
```

**Backend Railway'de deploy edilmiş durumda!** 🚀

---

## 💾 Veritabanı

### Mobil (SQLite)

5 tablo:
- `questions` - Soru bankası
- `user_responses` - Kullanıcı cevapları
- `mab_question_arms` - Soru bazlı MAB state
- `mab_topic_arms` - Konu bazlı MAB state
- `quiz_sessions` - Quiz oturumları

**Migration:** Otomatik (version 1 → 2)

### Backend (PostgreSQL)

7 tablo (mobil + ek tablolar):
- `users` - Kullanıcılar
- `question_metrics` - Global soru istatistikleri
- `student_responses` - Tüm cevaplar

---

## 🎨 Özellikler

### ✅ Tamamlanan

- ✅ **Thompson Sampling** MAB algoritması
- ✅ **Prior Knowledge** (Cold start çözümü)
- ✅ **Forgetting Curve** (Temporal decay)
- ✅ **Response Time Bonus** (Doğru ve düzeltilmiş)
- ✅ **Hierarchical MAB** (Topic + Question level)
- ✅ **SQLite local database**
- ✅ **Offline support** (is_synced flag'i)
- ✅ **Multi-user support**
- ✅ **Dark/Light theme**
- ✅ **Türkçe/İngilizce dil desteği**
- ✅ **Railway backend deployment**

### 🔄 Devam Eden

- ⏳ **Backend sync endpoint** (mobil ↔️ backend)
- ⏳ **Conflict resolution**
- ⏳ **Question metrics kullanımı**

### 📋 Planlanan

- 📅 **Analytics dashboard**
- 📅 **A/B testing framework**
- 📅 **ML-based difficulty prediction**
- 📅 **Personalized learning paths**

Detaylı roadmap için: [ROADMAP.md](ROADMAP.md)

---

## 🧪 Test

### Mobil

```bash
# Analiz
flutter analyze

# Widget testleri (gelecekte)
flutter test

# Integration testleri (gelecekte)
flutter drive --target=test_driver/app.dart
```

### Backend

```bash
# Unit testler
pytest

# API testleri
pytest tests/test_api.py

# Coverage
pytest --cov=app tests/
```

---

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'feat: add amazing feature'`)
4. Push yapın (`git push origin feature/amazing-feature`)
5. Pull Request açın

---

## 📄 Lisans

Bu proje özel bir projedir. Ticari kullanım için izin gereklidir.

---

## 📞 İletişim

**Proje Sahibi:** [Adınız]
**Email:** [Email'iniz]
**GitHub:** [GitHub profiliniz]

---

## 🙏 Teşekkürler

- Thompson Sampling algoritması için bilimsel literatür
- Flutter ve Dart topluluğu
- FastAPI ve Python topluluğu

---

**MAB Quiz ile daha akıllı öğrenme! 🚀**
