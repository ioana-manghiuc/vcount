import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_flags/country_flags.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../localization/app_localizations.dart';

class AppBarWidget extends StatefulWidget implements PreferredSizeWidget {
  final String titleKey;
  final String? backTooltipKey;

  const AppBarWidget({super.key, required this.titleKey, this.backTooltipKey});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<AppBarWidget> createState() => _AppBarWidgetState();
}

class _AppBarWidgetState extends State<AppBarWidget> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String _getBackTooltip(BuildContext context, String? customKey) {
    if (customKey != null) {
      return AppLocalizations.of(context)!.translate(customKey);
    }

    final routeName = ModalRoute.of(context)?.settings.name ?? '';
    final localizations = AppLocalizations.of(context)!;

    switch (routeName) {
      case '/about':
        return localizations.translate('drawDirections');
      case '/model-info':
        return localizations.translate('drawDirections');
      case '/results':
        return localizations.translate('drawDirections');
      case '/directions':
        return localizations.translate('appTitle');
      default:
        return localizations.translate('back');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      foregroundColor: Theme.of(context).colorScheme.onSecondary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.maybePop();
          } else {
            navigator.pushReplacementNamed('/start');
          }
        },
        tooltip: _getBackTooltip(context, widget.backTooltipKey),
      ),
      title: Text(AppLocalizations.of(context)!.translate(widget.titleKey)),
      actions: [
        IconButton(
          tooltip: AppLocalizations.of(context)!.userManual,
          icon: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
          onPressed: () {
            Navigator.of(context).pushNamed('/about');
          },
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: DropdownButton<String>(
            focusNode: _focusNode,
            value: languageProvider.locale.languageCode,
            iconEnabledColor: Theme.of(context).colorScheme.primary,  
            iconDisabledColor: Theme.of(context).colorScheme.onSecondaryFixed,  
            items: [
              DropdownMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    CountryFlag.fromCountryCode(
                      'GB',
                      theme: const ImageTheme(
                        shape: RoundedRectangle(2),
                        width: 30,
                        height: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('EN', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'ro',
                child: Row(
                  children: [
                    CountryFlag.fromCountryCode(
                      'RO',
                      theme: const ImageTheme(
                        shape: RoundedRectangle(2),
                        width: 30,
                        height: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('RO', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
              ),
            ],
            onChanged: (String? value) {
              if (value != null) {
                languageProvider.setLanguage(value);
                _focusNode.unfocus(); 
              }
            },
          ),
        ),

        IconButton(
          icon: Icon(
            themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
            color: Theme.of(context).colorScheme.primary
          ),
          onPressed: themeProvider.toggleTheme,
          tooltip: themeProvider.isDark ? 'Light Mode' : 'Dark Mode',
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
