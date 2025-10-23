# 🚀 Database Migration Guide for Railway

## ✅ Yapılanlar

1. **✅ Base import sorunu düzeltildi** - `question_metrics.py` artık ortak `Base` kullanıyor
2. **✅ Question modeli genişletildi** - Tüm gerekli alanlar eklendi
3. **✅ Yeni tablolar oluşturuldu**:
   - `UserQuizSession` - Quiz oturumlarını takip eder
   - `UserMABQuestionArm` - Kullanıcı bazında soru performansı
   - `UserMABTopicArm` - Kullanıcı bazında konu performansı

---

## 📋 Tablo Listesi (7 Tablo)

1. **users** - Kullanıcı bilgileri
2. **questions** - Sorular (genişletilmiş)
3. **question_metrics** - Soru zorluk metrikleri
4. **student_responses** - Öğrenci cevapları
5. **user_quiz_sessions** - Quiz oturumları (YENİ)
6. **user_mab_question_arms** - MAB soru state'leri (YENİ)
7. **user_mab_topic_arms** - MAB konu state'leri (YENİ)

---

## 🔧 Railway'de Migration Nasıl Çalıştırılır?

### Seçenek 1: Railway CLI ile (ÖNERİLEN)

```bash
# 1. Railway CLI'yi yükleyin (eğer yoksa)
npm i -g @railway/cli

# 2. Railway'e login olun
railway login

# 3. Projenize bağlanın
railway link

# 4. Migration scriptini çalıştırın
railway run python migrate_tables.py
```

### Seçenek 2: Manuel SSH ile

```bash
# Railway dashboard'da service'e gidin
# Settings > Deploy > Add Service Command

# Command olarak ekleyin:
python migrate_tables.py && python app/main.py
```

### Seçenek 3: Geçici Deploy ile

Railway'de yeni bir dosya oluşturun: `Procfile`

```
release: python migrate_tables.py
web: uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

---

## 🧪 Migration'u Test Etme

### 1. Local'de Test

```bash
# DATABASE_URL'yi Railway'den alın
export DATABASE_URL="postgresql://user:pass@host:port/dbname"

# Migration'u çalıştırın
python migrate_tables.py

# Sadece verify yapmak için
python migrate_tables.py --verify-only
```

### 2. Railway'de Test

```bash
# Railway environment'ında çalıştırın
railway run python migrate_tables.py --verify-only
```

---

## 📊 Migration Çıktısı Nasıl Olmalı?

Başarılı bir migration şöyle görünür:

```
============================================================
🚀 MAB Quiz Database Migration
============================================================
📍 Database: postgresql+asyncpg://****@****

📊 Checking existing tables...
  Found 2 existing tables: users, questions

📋 Migrating 'questions' table...
  📊 Found 8 existing columns
  ✅ Added column 'course'
  ✅ Added column 'topic'
  ✅ Added column 'knowledge_type'
  ✅ Added column 'tags'
  ✅ Added column 'correct_answer'
  ✅ Added column 'explanation'
  ✅ Renamed 'options_json' to 'options'
  ✅ Created indexes

🏗️  Creating new tables...
  ✅ All tables created/verified

✅ Database migration completed successfully!

📋 Final table list (7 tables):
  • question_metrics
  • questions
  • student_responses
  • user_mab_question_arms
  • user_mab_topic_arms
  • user_quiz_sessions
  • users
```

---

## ⚠️ Önemli Notlar

### Güvenlik
- Migration **mevcut verileri silmez**
- Sadece yeni kolonlar ve tablolar ekler
- Eğer hata olursa `*_backup_*` tabloları oluşturur

### Dikkat Edilmesi Gerekenler

1. **options_json → options**: Eski `options_json` kolonu `options` olarak yeniden adlandırılır ve JSON tipine dönüştürülür

2. **Yeni kolonlar default değerlerle eklenir**:
   - `course`: 'general'
   - `topic`: 'general'
   - `knowledge_type`: 'general'
   - `correct_answer`: '' (boş string)

3. **Mevcut sorular güncellenmeli**: Migration'dan sonra mevcut soruların yeni alanlarını doldurmalısınız

---

## 🔄 Migration Sonrası

### 1. Verify Schema

```bash
railway run python migrate_tables.py --verify-only
```

### 2. Mevcut Soruları Güncelle

Eğer veritabanında zaten sorular varsa:

```python
# update_existing_questions.py
import asyncio
from sqlalchemy import select, update
from app.db import get_session
from app.models.question import Question

async def update_questions():
    async with get_session() as session:
        # Tüm soruları al
        result = await session.execute(select(Question))
        questions = result.scalars().all()

        for q in questions:
            # Eksik alanları doldur
            if not q.course or q.course == 'general':
                q.course = q.subject  # subject'den course'a kopyala
            if not q.topic or q.topic == 'general':
                q.topic = 'Genel'  # Default topic
            # ... diğer güncellemeler

        await session.commit()

asyncio.run(update_questions())
```

---

## 🐛 Sorun Giderme

### "Table already exists" hatası
Migration zaten çalıştırılmış demektir. `--verify-only` ile kontrol edin.

### "Column already exists" hatası
Normal, migration script güvenli şekilde atlar.

### Connection timeout
Railway database'inin sleep mode'da olabilir. Tekrar deneyin.

### Migration sırasında hata
Script otomatik backup oluşturur. Backup tablolardan geri yükleyebilirsiniz.

---

## 📞 Yardım

Herhangi bir sorun olursa:

1. Logları kontrol edin: `railway logs`
2. Verify çalıştırın: `python migrate_tables.py --verify-only`
3. Railway dashboard'dan database'e bağlanın ve manuel kontrol edin

---

## ✅ Checklist

- [ ] Railway CLI kuruldu
- [ ] Railway'e login yapıldı
- [ ] Migration script çalıştırıldı
- [ ] Verify başarılı oldu
- [ ] 7 tablo görünüyor
- [ ] Mevcut sorular güncellendi (eğer varsa)
