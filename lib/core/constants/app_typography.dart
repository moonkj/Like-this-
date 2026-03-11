import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Like This 타이포그래피 시스템 — Pretendard 기반
abstract final class AppTypography {
  static const String _fontFamily = 'Pretendard';

  // ── Headings ──────────────────────────────────────────────────────────────────
  static const TextStyle h1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Body ──────────────────────────────────────────────────────────────────────
  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ── Caption ───────────────────────────────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ── Filter Labels ─────────────────────────────────────────────────────────────
  static const TextStyle filterName = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  static const TextStyle filterNameSelected = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.silver,
    letterSpacing: 0.2,
  );

  // ── Overlay / Camera UI ───────────────────────────────────────────────────────
  static const TextStyle filterOverlay = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: 1.0,
    shadows: [
      Shadow(color: Color(0x99000000), blurRadius: 8, offset: Offset(0, 2)),
    ],
  );

  static const TextStyle indicator = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.silver,
    letterSpacing: 0.5,
  );

  // ── Button ────────────────────────────────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}
