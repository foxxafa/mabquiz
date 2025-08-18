#!/bin/bash

# MAB Quiz Backend Deployment Script for Heroku

echo "🚀 MAB Quiz Backend Deployment to Heroku"
echo "========================================"

# Heroku CLI kurulu mu kontrol et
if ! command -v heroku &> /dev/null; then
    echo "❌ Heroku CLI bulunamadı. Lütfen yükleyin: https://devcenter.heroku.com/articles/heroku-cli"
    exit 1
fi

# Backend klasörüne git
cd backend

echo "📁 Backend klasöründe..."

# Heroku'ya giriş yap
echo "🔐 Heroku'ya giriş yapılıyor..."
heroku login

# Uygulama oluştur
echo "📱 Heroku uygulaması oluşturuluyor..."
read -p "Uygulama adını girin (örn: mab-quiz-api): " APP_NAME

heroku create $APP_NAME

# MySQL addon ekle (ClearDB)
echo "🗄️ MySQL veritabanı ekleniyor..."
heroku addons:create cleardb:ignite -a $APP_NAME

# Veritabanı URL'ini al
DATABASE_URL=$(heroku config:get CLEARDB_DATABASE_URL -a $APP_NAME)

# MySQL URL'ini doğru formata çevir
MYSQL_URL=$(echo $DATABASE_URL | sed 's/mysql:/mysql+aiomysql:/')

# Environment variables ayarla
echo "⚙️ Çevre değişkenleri ayarlanıyor..."
heroku config:set DATABASE_URL="$MYSQL_URL" -a $APP_NAME
heroku config:set DEBUG=False -a $APP_NAME

# Git repository başlat (eğer yoksa)
if [ ! -d ".git" ]; then
    git init
    git add .
    git commit -m "Initial commit"
fi

# Heroku remote ekle
heroku git:remote -a $APP_NAME

# Deploy et
echo "🚀 Deployment başlatılıyor..."
git push heroku main

echo "✅ Deployment tamamlandı!"
echo "🌐 Uygulama URL'i: https://$APP_NAME.herokuapp.com"
echo "🔧 Logs için: heroku logs --tail -a $APP_NAME"
