# MAB Quiz Backend API

FastAPI tabanlı quiz uygulaması backend servisi.

## 🚀 Özellikler

- **FastAPI** - Modern, hızlı web framework
- **SQLAlchemy** - ORM ve veritabanı yönetimi
- **MySQL** - Ana veritabanı (aiomysql ile async)
- **Pydantic** - Veri validasyonu
- **CORS** - Flutter frontend desteği

## 📁 Proje Yapısı

```
backend/
├── app/
│   ├── main.py          # Ana uygulama
│   ├── models.py        # Veritabanı modelleri
│   ├── routers.py       # API route'ları
│   └── db.py           # Veritabanı konfigürasyonu
├── requirements.txt     # Python bağımlılıkları
├── Procfile            # Heroku deployment
├── runtime.txt         # Python version
├── deploy.bat          # Windows deployment script
└── deploy.sh           # Linux/Mac deployment script
```

## �️ Kurulum

### Yerel Geliştirme

1. **Python 3.11+ gerekli**

2. **Bağımlılıkları yükle:**
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

3. **MySQL veritabanı ayarla:**
   ```sql
   CREATE DATABASE mabquiz;
   ```

4. **Çevre değişkenlerini ayarla:**
   ```bash
   export DATABASE_URL="mysql+aiomysql://root:password@localhost:3306/mabquiz"
   ```

5. **Uygulamayı çalıştır:**
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

6. **API dokümantasyonu:** http://localhost:8000/docs

## 🌐 Heroku Deployment

### Otomatik Deployment (Önerilen)

Windows için:
```cmd
deploy.bat
```

Linux/Mac için:
```bash
chmod +x deploy.sh
./deploy.sh
```

### Manuel Deployment

1. **Heroku CLI yükle:** https://devcenter.heroku.com/articles/heroku-cli

2. **Giriş yap:**
   ```bash
   heroku login
   ```

3. **Uygulama oluştur:**
   ```bash
   heroku create your-app-name
   ```

4. **MySQL addon ekle:**
   ```bash
   heroku addons:create cleardb:ignite
   ```

5. **Çevre değişkenlerini ayarla:**
   ```bash
   # Veritabanı URL'ini al
   heroku config:get CLEARDB_DATABASE_URL
   
   # MySQL+aiomysql formatına çevir ve ayarla
   heroku config:set DATABASE_URL="mysql+aiomysql://username:password@host:port/database"
   ```

6. **Deploy et:**
   ```bash
   git push heroku main
   ```

## 📊 API Endpoints

### Sağlık Kontrolü
- `GET /health` - Servis durumu

### Quiz Endpoints
- `GET /questions/{subject}` - Konu bazında sorular
- `GET /subjects` - Mevcut konular
- `POST /questions` - Yeni soru ekle
- `PUT /questions/{id}` - Soru güncelle
- `DELETE /questions/{id}` - Soru sil

### Kullanıcı Endpoints
- `POST /users` - Yeni kullanıcı
- `GET /users/{id}` - Kullanıcı bilgisi
- `POST /users/{id}/results` - Quiz sonucu kaydet

## 🔧 Konfigürasyon

### Çevre Değişkenleri

- `DATABASE_URL` - MySQL bağlantı string'i
- `DEBUG` - Debug modu (True/False)

### CORS Ayarları

Frontend adresleri `main.py` dosyasında:
```python
origins = [
    "http://localhost:8080",      # Flutter web
    "http://127.0.0.1:8080",      # Flutter web
    "http://10.0.2.2:8080",       # Android emulator
]
```

## 📱 Flutter Integration

Flutter uygulamanızda API base URL'ini ayarlayın:

```dart
// For local development
const String API_BASE_URL = 'http://localhost:8000';

// For Heroku production  
const String API_BASE_URL = 'https://your-app-name.herokuapp.com';
```

## 🐛 Troubleshooting

### Heroku Logs
```bash
heroku logs --tail -a your-app-name
```

### Veritabanı Sıfırlama
```bash
heroku config:get CLEARDB_DATABASE_URL
```

### Local Test
```bash
# Health check
curl http://localhost:8000/health

# API docs
open http://localhost:8000/docs
```

## 📝 Notlar

- **Free tier sınırları:** Heroku free tier 30 dakika inaktiviteden sonra uyku moduna geçer
- **Veritabanı:** ClearDB free tier 5MB ile sınırlı
- **Performance:** Production için paid tier önerilir

