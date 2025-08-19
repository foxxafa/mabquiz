import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/localization/localization_provider.dart';

/// Dil seçimi için özel widget
class LanguageSelectorDialog extends ConsumerStatefulWidget {
  const LanguageSelectorDialog({super.key});

  @override
  ConsumerState<LanguageSelectorDialog> createState() => _LanguageSelectorDialogState();
}

class _LanguageSelectorDialogState extends ConsumerState<LanguageSelectorDialog> {
  SupportedLanguage? _selectedLanguage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // İlk build'de mevcut dili ayarla (sadece bir kere)
    _selectedLanguage ??= LocalizationService.getCurrentLanguage(context);
    
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.language,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'select_language_dialog'.tr(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...LocalizationService.getSupportedLanguages().map((language) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _LanguageOption(
                  language: language,
                  isSelected: _selectedLanguage == language,
                  onTap: () {
                    setState(() {
                      _selectedLanguage = language;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'settings.cancel'.tr(),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    // Seçilen dili uygula
                    if (_selectedLanguage != null) {
                      await context.setLocale(_selectedLanguage!.locale);
                    }
                    // Dialog'u kapat
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('settings.confirm'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends ConsumerWidget {
  final SupportedLanguage language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        color: isSelected 
            ? theme.colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Text(
          language.flag,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          language.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
        ),
        subtitle: Text(
          language.countryCode,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected 
                ? theme.colorScheme.primary.withOpacity(0.8) 
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
