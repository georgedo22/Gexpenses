import 'package:flutter/material.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';

class AppColors {
  AppColors._();

  // ── LIGHT THEME ──────────────────────────────────────────────────────
  static const primaryLight = Color(0xFF6366F1); // Indigo
  static const onPrimaryLight = Color(0xFFFFFFFF);
  static const secondaryLight = Color(0xFF8B5CF6); // Purple
  static const backgroundLight = Color(0xFFF8FAFC);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceVariantLight = Color(0xFFF1F5F9);
  static const onSurfaceLight = Color(0xFF0F172A);
  static const onSurfaceVariantLight = Color(0xFF64748B);
  static const outlineLight = Color(0xFFE2E8F0);
  static const errorLight = Color(0xFFEF4444);
  static const successLight = Color(0xFF22C55E);
  static const warningLight = Color(0xFFF59E0B);

  // ── DARK THEME ───────────────────────────────────────────────────────
  static const primaryDark = Color(0xFF818CF8);
  static const onPrimaryDark = Color(0xFF1E1B4B);
  static const secondaryDark = Color(0xFFA78BFA);
  static const backgroundDark = Color(0xFF0F172A);
  static const surfaceDark = Color(0xFF1E293B);
  static const surfaceVariantDark = Color(0xFF334155);
  static const onSurfaceDark = Color(0xFFF1F5F9);
  static const onSurfaceVariantDark = Color(0xFF94A3B8);
  static const outlineDark = Color(0xFF334155);
  static const errorDark = Color(0xFFF87171);
  static const successDark = Color(0xFF4ADE80);
  static const warningDark = Color(0xFFFBBF24);

  // ── CATEGORY COLORS ──────────────────────────────────────────────────
  // Dark-theme variants (bright, readable on dark surfaces).
  static const foodDark = Color(0xFFFF6B6B);
  static const transportDark = Color(0xFF4ECDC4);
  static const billsDark = Color(0xFFFFE66D);
  static const shoppingDark = Color(0xFFA78BFA);
  static const healthDark = Color(0xFF22C55E);
  static const entertainmentDark = Color(0xFFFF9F43);
  static const otherDark = Color(0xFF94A3B8);

  // Light-theme variants: darker shades that reach at least ~3:1 contrast
  // against white (WCAG AA for icons and graphical objects).
  static const foodLight = Color(0xFFDC2626);
  static const transportLight = Color(0xFF0D9488);
  static const billsLight = Color(0xFFD97706);
  static const shoppingLight = Color(0xFF7C3AED);
  static const healthLight = Color(0xFF16A34A);
  static const entertainmentLight = Color(0xFFEA580C);
  static const otherLight = Color(0xFF64748B);

  // Bright defaults (used where no context is available).
  static const food = foodDark;
  static const transport = transportDark;
  static const bills = billsDark;
  static const shopping = shoppingDark;
  static const health = healthDark;
  static const entertainment = entertainmentDark;
  static const other = otherDark;

  // ── GRADIENT for balance card ────────────────────────────────────────
  static const balanceGradientLight = [Color(0xFF6366F1), Color(0xFF8B5CF6)];
  static const balanceGradientDark = [Color(0xFF4338CA), Color(0xFF6D28D9)];
  static const balanceGradientWarning = [Color(0xFFEF4444), Color(0xFFF97316)];

  /// Returns the color associated with the given [category].
  ///
  /// Pass [isDark] so light surfaces get the darker, contrast-safe variants.
  static Color categoryColor(ExpenseCategory category, {bool isDark = false}) {
    switch (category) {
      case ExpenseCategory.food:
        return isDark ? foodDark : foodLight;
      case ExpenseCategory.transport:
        return isDark ? transportDark : transportLight;
      case ExpenseCategory.bills:
        return isDark ? billsDark : billsLight;
      case ExpenseCategory.shopping:
        return isDark ? shoppingDark : shoppingLight;
      case ExpenseCategory.health:
        return isDark ? healthDark : healthLight;
      case ExpenseCategory.entertainment:
        return isDark ? entertainmentDark : entertainmentLight;
      case ExpenseCategory.other:
        return isDark ? otherDark : otherLight;
    }
  }
}
