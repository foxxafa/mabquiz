/// Auth (Kimlik Doğrulama) özelliğinin ana export dosyası (Barrel File).
/// Bu özellik ile ilgili dışarıya açılacak tüm arayüzler ve servisler buradan export edilir.
/// Bu sayede, başka bir özellik bu dosyayı import ederek tüm auth bileşenlerine erişebilir.
library;

// Application Katmanı: İş mantığı ve servisler
export 'application/providers.dart';
export 'application/auth_service.dart';

// Presentation Katmanı: Arayüz (UI) ekranları ve widget'ları
export 'presentation/screens/auth_gate.dart';
export 'presentation/screens/login_screen.dart';
export 'presentation/screens/register_screen.dart';
export 'presentation/widgets/auth_form.dart';

// Domain Katmanı: Temel veri modelleri (Entity'ler)
// Genellikle AppUser gibi modeller diğer özellikler tarafından da kullanılabilir.
export 'data/models/app_user.dart';
