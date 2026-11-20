import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:fitlek1/l10n/app_localizations.dart';
import 'package:fitlek1/services/locale_service.dart';

/// Localizations for code running without a BuildContext.
AppLocalizations get svcL10n => lookupAppLocalizations(
    LocaleService.locale.value ?? PlatformDispatcher.instance.locale);
