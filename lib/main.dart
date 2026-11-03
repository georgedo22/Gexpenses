import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/branding/brand_mark.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/theme/app_colors.dart';
import 'package:gexpenses/core/theme/app_motion.dart';
import 'package:gexpenses/core/theme/app_typography.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/balance_providers.dart';
import 'package:gexpenses/presentation/screens/main_screen.dart';
import 'package:gexpenses/presentation/screens/onboarding/set_balance_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore the user's chosen currency before the first frame is built.
  final prefs = await SharedPreferences.getInstance();
  CurrencyFormatter.symbol = prefs.getString('currency_symbol') ?? r'$';
  runApp(const ProviderScope(child: GExpensesApp()));
}

class GExpensesApp extends ConsumerWidget {
  const GExpensesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBalanceAsync = ref.watch(hasBalanceProvider);

    return MaterialApp(
      title: 'GExpenses',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
      home: hasBalanceAsync.when(
        loading: () => const _SplashScreen(),
        error: (error, _) => _ErrorScreen(
          error: error,
          onRetry: () => ref.invalidate(hasBalanceProvider),
        ),
        // First launch: ask for the starting balance before showing the app.
        // Returning users go straight to the dashboard.
        data: (hasBalance) =>
            hasBalance ? const MainScreen() : const SetBalanceScreen(),
      ),
    );
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
    brightness: brightness,
  );
  final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
  final onSurface = isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight;
  final onSurfaceVariant = isDark
      ? AppColors.onSurfaceVariantDark
      : AppColors.onSurfaceVariantLight;
  final outline = isDark ? AppColors.outlineDark : AppColors.outlineLight;

  const transitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
      TargetPlatform.fuchsia: FadeSlidePageTransitionsBuilder(),
      TargetPlatform.linux: FadeSlidePageTransitionsBuilder(),
      TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight,
    pageTransitionsTheme: transitions,
    textTheme: AppTypography.textTheme.apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 2,
      highlightElevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: AppConstants.cardElevation,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(color: outline.withValues(alpha: 0.7)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? AppColors.surfaceVariantDark.withValues(alpha: 0.4)
          : AppColors.surfaceVariantLight.withValues(alpha: 0.7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: BorderSide(color: outline.withValues(alpha: 0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppConstants.spacing16,
        vertical: AppConstants.spacing16,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colorScheme.primary.withValues(
        alpha: isDark ? 0.3 : 0.12,
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? colorScheme.primary : onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected ? colorScheme.primary : onSurfaceVariant,
        );
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: surface,
      indicatorColor: colorScheme.primary.withValues(
        alpha: isDark ? 0.3 : 0.12,
      ),
      selectedIconTheme: IconThemeData(color: colorScheme.primary),
      unselectedIconTheme: IconThemeData(color: onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: onSurfaceVariant,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark
          ? AppColors.surfaceVariantDark.withValues(alpha: 0.5)
          : AppColors.surfaceVariantLight,
      selectedColor: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.14),
      side: BorderSide(color: outline.withValues(alpha: 0.7)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      showCheckmark: false,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppConstants.spacing8,
        vertical: AppConstants.spacing8,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusLarge),
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: outline.withValues(alpha: 0.7),
      space: 1,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark
          ? AppColors.surfaceVariantDark
          : AppColors.onSurfaceLight,
      contentTextStyle: TextStyle(color: isDark ? onSurface : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: outline.withValues(alpha: 0.4),
    ),
  );
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppConstants.spacing16),
              Text(
                AppLocalizations.of(context).errorTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppConstants.spacing8),
              Text(
                AppLocalizations.of(context).errorGeneric,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppConstants.spacing16),
              if (onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(AppLocalizations.of(context).retry),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.85, end: 1),
          duration: AppMotion.slow,
          curve: AppMotion.emphasized,
          builder: (context, scale, child) => Opacity(
            opacity: ((scale - 0.85) / 0.15).clamp(0.0, 1.0),
            child: Transform.scale(scale: scale, child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 96),
              const SizedBox(height: AppConstants.spacing20),
              Text(
                'GExpenses',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppConstants.spacing24),
              const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
