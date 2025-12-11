import '../../data/exceptions.dart';

/// Centralized error message localization for authentication
class AuthErrorMessages {
  /// Turkish error messages for authentication exceptions
  static const Map<String, String> _turkishMessages = {
    // Authentication errors
    'invalid-credentials': 'Geçersiz email veya şifre. Lütfen bilgilerinizi kontrol edin.',
    'user-not-found': 'Bu email adresi ile kayıtlı kullanıcı bulunamadı.',
    'wrong-password': 'Şifre yanlış. Lütfen tekrar deneyin.',
    'weak-password': 'Şifre çok zayıf. En az 6 karakter kullanın ve güçlü bir şifre seçin.',
    'email-already-in-use': 'Bu email adresi zaten kullanımda. Farklı bir email deneyin veya giriş yapmayı deneyin.',
    'invalid-email': 'Geçersiz email adresi formatı. Lütfen geçerli bir email adresi girin.',
    'user-disabled': 'Bu hesap devre dışı bırakılmış. Destek ekibi ile iletişime geçin.',
    'too-many-requests': 'Çok fazla deneme yapıldı. Lütfen birkaç dakika bekleyip tekrar deneyin.',
    'operation-not-allowed': 'Bu işlem şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.',
    'network-error': 'İnternet bağlantısı sorunu. Bağlantınızı kontrol edip tekrar deneyin.',
    'service-unavailable': 'Servis şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.',
    'google-signin-cancelled': 'Google ile giriş iptal edildi.',
    'google-token-error': 'Google kimlik doğrulama hatası. Lütfen tekrar deneyin.',
    'google-auth-failed': 'Google ile giriş başarısız oldu. Lütfen tekrar deneyin.',
    'timeout': 'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.',
    'unknown-error': 'Bilinmeyen bir hata oluştu. Lütfen tekrar deneyin.',

    // Form validation errors
    'email-required': 'Email adresi gereklidir',
    'email-invalid': 'Geçerli bir email adresi girin',
    'password-required': 'Şifre gereklidir',
    'password-too-short': 'Şifre en az 6 karakter olmalıdır',
    'password-weak': 'Şifre çok zayıf. Daha güçlü bir şifre seçin',
    'password-confirmation-required': 'Şifre tekrarı gereklidir',
    'passwords-not-match': 'Şifreler eşleşmiyor',
    'display-name-too-short': 'İsim en az 2 karakter olmalıdır',
    'display-name-too-long': 'İsim en fazla 50 karakter olabilir',
    'display-name-invalid': 'İsim sadece harf, boşluk, tire ve nokta içerebilir',
    'phone-invalid': 'Geçerli bir telefon numarası girin (örn: 05XXXXXXXXX)',

    // Success messages
    'login-success': 'Başarıyla giriş yapıldı',
    'registration-success': 'Hesap başarıyla oluşturuldu',
    'logout-success': 'Başarıyla çıkış yapıldı',
    'password-reset-sent': 'Şifre sıfırlama bağlantısı email adresinize gönderildi',

    // General messages
    'loading': 'Yükleniyor...',
    'please-wait': 'Lütfen bekleyin...',
    'try-again': 'Tekrar deneyin',
    'cancel': 'İptal',
    'ok': 'Tamam',
    'yes': 'Evet',
    'no': 'Hayır',
    'confirm': 'Onayla',
    'save': 'Kaydet',
    'delete': 'Sil',
    'edit': 'Düzenle',
    'close': 'Kapat',

    // Confirmation messages
    'logout-confirmation': 'Çıkış yapmak istediğinizden emin misiniz?',
    'delete-account-confirmation': 'Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
  };

  /// English error messages (fallback)
  static const Map<String, String> _englishMessages = {
    'invalid-credentials': 'Invalid email or password. Please check your credentials.',
    'user-not-found': 'No user found with this email address.',
    'wrong-password': 'Wrong password. Please try again.',
    'weak-password': 'Password is too weak. Use at least 6 characters and choose a strong password.',
    'email-already-in-use': 'This email address is already in use. Try a different email or sign in.',
    'invalid-email': 'Invalid email address format. Please enter a valid email address.',
    'user-disabled': 'This account has been disabled. Please contact support.',
    'too-many-requests': 'Too many attempts. Please wait a few minutes and try again.',
    'operation-not-allowed': 'This operation is not currently available. Please try again later.',
    'network-error': 'Network connection problem. Check your connection and try again.',
    'service-unavailable': 'Service is currently unavailable. Please try again later.',
    'timeout': 'Request timed out. Please try again.',
    'unknown-error': 'An unknown error occurred. Please try again.',
    'login-success': 'Successfully signed in',
    'registration-success': 'Account created successfully',
    'logout-success': 'Successfully signed out',
    'loading': 'Loading...',
    'please-wait': 'Please wait...',
    'try-again': 'Try again',
    'cancel': 'Cancel',
    'ok': 'OK',
    'yes': 'Yes',
    'no': 'No',
    'confirm': 'Confirm',
  };

  /// Current language (default: Turkish)
  static String _currentLanguage = 'tr';

  /// Sets the current language
  static void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
  }

  /// Gets the current language
  static String get currentLanguage => _currentLanguage;

  /// Gets a localized message by key
  static String getMessage(String key) {
    final messages = _currentLanguage == 'tr' ? _turkishMessages : _englishMessages;
    return messages[key] ?? key;
  }

  /// Gets a localized error message for an AuthException
  static String getAuthExceptionMessage(AuthException exception) {
    return getMessage(exception.code);
  }

  /// Gets a localized error message for any exception
  static String getExceptionMessage(Object exception) {
    if (exception is AuthException) {
      return getAuthExceptionMessage(exception);
    }

    // Try to extract error code from exception string
    final exceptionString = exception.toString().toLowerCase();

    for (final key in _turkishMessages.keys) {
      if (exceptionString.contains(key)) {
        return getMessage(key);
      }
    }

    // Fallback to generic error message
    return getMessage('unknown-error');
  }

  /// Gets a success message
  static String getSuccessMessage(String action) {
    switch (action) {
      case 'login':
        return getMessage('login-success');
      case 'registration':
        return getMessage('registration-success');
      case 'logout':
        return getMessage('logout-success');
      default:
        return 'İşlem başarıyla tamamlandı';
    }
  }

  /// Gets a confirmation message
  static String getConfirmationMessage(String action) {
    switch (action) {
      case 'logout':
        return getMessage('logout-confirmation');
      case 'delete-account':
        return getMessage('delete-account-confirmation');
      default:
        return 'Bu işlemi yapmak istediğinizden emin misiniz?';
    }
  }

  /// Gets form validation error messages
  static Map<String, String> getValidationMessages() {
    return {
      'email-required': getMessage('email-required'),
      'email-invalid': getMessage('email-invalid'),
      'password-required': getMessage('password-required'),
      'password-too-short': getMessage('password-too-short'),
      'password-weak': getMessage('password-weak'),
      'password-confirmation-required': getMessage('password-confirmation-required'),
      'passwords-not-match': getMessage('passwords-not-match'),
      'display-name-too-short': getMessage('display-name-too-short'),
      'display-name-too-long': getMessage('display-name-too-long'),
      'display-name-invalid': getMessage('display-name-invalid'),
      'phone-invalid': getMessage('phone-invalid'),
    };
  }

  /// Gets UI text messages
  static Map<String, String> getUIMessages() {
    return {
      'loading': getMessage('loading'),
      'please-wait': getMessage('please-wait'),
      'try-again': getMessage('try-again'),
      'cancel': getMessage('cancel'),
      'ok': getMessage('ok'),
      'yes': getMessage('yes'),
      'no': getMessage('no'),
      'confirm': getMessage('confirm'),
      'save': getMessage('save'),
      'delete': getMessage('delete'),
      'edit': getMessage('edit'),
      'close': getMessage('close'),
    };
  }
}

/// Extension for easier access to error messages
extension AuthExceptionMessages on AuthException {
  /// Gets the localized message for this exception
  String get localizedMessage => AuthErrorMessages.getAuthExceptionMessage(this);
}

