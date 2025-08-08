@echo off
echo 🚀 MAB Quiz Backend Deployment to Heroku
echo ========================================

REM Heroku CLI kurulu mu kontrol et
where heroku >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Heroku CLI bulunamadı. Lütfen yükleyin: https://devcenter.heroku.com/articles/heroku-cli
    pause
    exit /b 1
)

REM Backend klasörüne git
cd /d %~dp0

echo 📁 Backend klasöründe...

REM Heroku'ya giriş yap
echo 🔐 Heroku'ya giriş yapılıyor...
call heroku login

REM Uygulama oluştur
set /p APP_NAME="Uygulama adını girin (örn: mab-quiz-api): "

call heroku create %APP_NAME%

REM MySQL addon ekle (ClearDB)
echo 🗄️ MySQL veritabanı ekleniyor...
call heroku addons:create cleardb:ignite -a %APP_NAME%

REM Environment variables ayarla
echo ⚙️ Çevre değişkenleri ayarlanıyor...
for /f "tokens=*" %%i in ('heroku config:get CLEARDB_DATABASE_URL -a %APP_NAME%') do set DATABASE_URL=%%i
set MYSQL_URL=%DATABASE_URL:mysql:=mysql+aiomysql:%

call heroku config:set DATABASE_URL="%MYSQL_URL%" -a %APP_NAME%
call heroku config:set DEBUG=False -a %APP_NAME%

REM Git repository başlat (eğer yoksa)
if not exist ".git" (
    git init
    git add .
    git commit -m "Initial commit"
)

REM Heroku remote ekle
call heroku git:remote -a %APP_NAME%

REM Deploy et
echo 🚀 Deployment başlatılıyor...
git push heroku main

echo ✅ Deployment tamamlandı!
echo 🌐 Uygulama URL'i: https://%APP_NAME%.herokuapp.com
echo 🔧 Logs için: heroku logs --tail -a %APP_NAME%
pause
