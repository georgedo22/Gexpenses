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
  static const food = Color(0xFFFF6B6B);
  static const transport = Color(0xFF4ECDC4);
  static const bills = Color(0xFFFFE66D);
  static const shopping = Color(0xFFA78BFA);
  static const health = Color(0xFF22C55E);
  static const entertainment = Color(0xFFFF9F43);
  static const other = Color(0xFF94A3B8);

  // ── GRADIENT for balance card ────────────────────────────────────────
  static const balanceGradientLight = [Color(0xFF6366F1), Color(0xFF8B5CF6)];
  static const balanceGradientDark = [Color(0xFF4338CA), Color(0xFF6D28D9)];
  static const balanceGradientWarning = [Color(0xFFEF4444), Color(0xFFF97316)];

  /// Returns the color associated with the given [category].
  static Color categoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return food;
      case ExpenseCategory.transport:
        return transport;
      case ExpenseCategory.bills:
        return bills;
      case ExpenseCategory.shopping:
        return shopping;
      case ExpenseCategory.health:
        return health;
      case ExpenseCategory.entertainment:
        return entertainment;
      case ExpenseCategory.other:
        return other;
    }
  }
}
