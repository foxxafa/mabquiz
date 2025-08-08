# MAB Quiz - Frontend Development Guide

Frontend-focused Flutter quiz app development with clear separation between UI and backend concerns.

## � Frontend Development Workflow

### Your Playground - Touch These Files ✅
```
lib/src/features/*/presentation/
├── screens/          # Ana ekranlar
├── widgets/          # Tekrar kullanılabilir UI bileşenleri
└── utils/           # UI yardımcı fonksiyonlar

lib/src/core/theme/
├── app_colors.dart      # Renk paleti
├── app_text_styles.dart # Tipografi stilleri
└── app_theme.dart       # Ana tema konfigürasyonu
```

### Backend - Don't Touch ❌
```
lib/src/features/*/data/        # Veritabanı işleri
lib/src/features/*/domain/      # Ham veri modelleri  
lib/src/core/config/           # Proje ayarları
lib/src/features/*/application/ # İş mantığı (providers.dart hariç)
```

## 🚀 4-Step Frontend Development Process

### 1. Hayal Et & Çiz
Yeni ekranını `features/{feature}/presentation/screens/` altında kodla
```dart
class YeniEkran extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // UI kodun buraya
  }
}
```

### 2. Veriye İhtiyacın Var mı?
`features/{feature}/application/providers.dart` dosyasına bak - ihtiyacın olan provider muhtemelen oradadır

### 3. Provider Yok mu? Kendi Sahte Verini Yarat!
```dart
// providers.dart içinde
final myDataProvider = StateProvider<List<String>>((ref) {
  return ['Sahte Veri 1', 'Sahte Veri 2', 'Sahte Veri 3'];
});
```

### 4. Kullan & Güzelleştir
```dart
final data = ref.watch(myDataProvider);
// Theme stilleriyle güzelleştir
```

## 🎨 Theme System (lib/src/core/theme/)

### Current Color Palette
- **Primary**: `#4F9CF9` (Modern blue)
- **Secondary**: `#2E5EAA` (Deep blue)
- **Background**: `#121212` (Dark)
- **Surface**: `#1E1E1E` (Card background)

### Text Styles Pattern
```dart
Text(
  'Başlık',
  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
    fontWeight: FontWeight.bold,
  ),
)
```

### Animation Standards
- **Entry transitions**: Slide + fade (600ms duration)
- **Curves**: `Curves.easeOutCubic` for consistency
- **Multiple controllers**: Always dispose properly

## 🔗 State Management Quick Reference

### Reading Data
```dart
final data = ref.watch(someProvider);       # Read once
final notifier = ref.read(someProvider.notifier); # Get notifier
```

### Common Providers Pattern
```dart
final loadingProvider = StateProvider<bool>((ref) => false);
final errorProvider = StateProvider<String?>((ref) => null);
final dataProvider = StateProvider<List<Item>>((ref) => []);
```

### Mock Data Creation
```dart
// Hızlı sahte veri için
final mockQuestions = [
  'Soru 1?',
  'Soru 2?', 
  'Soru 3?',
];
```

## 📱 UI Component Patterns

### Screen Structure
```dart
Scaffold(
  body: SafeArea(
    child: Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
          _buildFooter(),
        ],
      ),
    ),
  ),
)
```

### Loading States
```dart
if (isLoading) 
  CircularProgressIndicator()
else 
  YourContent()
```

### Error Handling UI
```dart
if (error != null)
  SnackBar(
    content: Text(error),
    backgroundColor: Colors.red,
  )
```

Frontend geliştirme odaklı bu kılavuz ile sadece UI/UX kısmına odaklanabilir, backend karmaşıklığı ile uğraşmadan hızla güzel arayüzler geliştirebilirsin!
