import 'package:flutter/material.dart';

/// Like This 컬러 시스템 — Dark Mode Only, OLED Black 기반
abstract final class AppColors {
  // ── Backgrounds ─────────────────────────────────────────────────────────────
  static const Color background     = Color(0xFF000000); // OLED Black
  static const Color surface        = Color(0xFF111111); // Near Black
  static const Color surfaceElevated= Color(0xFF1A1A1A); // Elevated Surface
  static const Color surfaceHigh    = Color(0xFF222222); // High Elevation

  // ── Accent ──────────────────────────────────────────────────────────────────
  static const Color silver         = Color(0xFFC0C0C0); // Primary Accent
  static const Color white          = Color(0xFFFFFFFF); // Pure White
  static const Color silverLight    = Color(0xFFE8E8E8); // Light Silver
  static const Color silverDark     = Color(0xFF888888); // Dark Silver

  // ── Text ────────────────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFFFFFFFF); // White
  static const Color textSecondary  = Color(0xFF888888); // Mid Gray
  static const Color textDisabled   = Color(0xFF444444); // Dark Gray
  static const Color textHint       = Color(0xFF555555); // Hint

  // ── Borders & Dividers ──────────────────────────────────────────────────────
  static const Color border         = Color(0xFF333333); // Default Border
  static const Color borderSelected = Color(0xFFC0C0C0); // Silver Selected

  // ── Shutter Button ──────────────────────────────────────────────────────────
  static const Color shutterOuter1  = Color(0xFFE8E8E8); // Silver Light
  static const Color shutterOuter2  = Color(0xFF888888); // Silver Dark
  static const Color shutterInner   = Color(0xFFFFFFFF); // Pure White

  // ── Overlays & Glass ────────────────────────────────────────────────────────
  static const Color glassLight     = Color(0x14FFFFFF); // 8% White
  static const Color glassBorder    = Color(0x1AFFFFFF); // 10% White
  static const Color overlayDark    = Color(0x80000000); // 50% Black
  static const Color overlayLight   = Color(0x33FFFFFF); // 20% White

  // ── Status ──────────────────────────────────────────────────────────────────
  static const Color error          = Color(0xFFE57373);
  static const Color success        = Color(0xFF81C784);
  static const Color warning        = Color(0xFFFFB74D);

  // ── Filter UI ───────────────────────────────────────────────────────────────
  static const Color filterBarBg    = Color(0xFF000000); // 필터바 배경
  static const Color filterSelected = Color(0xFFC0C0C0); // 선택된 필터 테두리
  static const Color filterThumb    = Color(0xFF1A1A1A); // 썸네일 배경 fallback

  // ── Gradients ───────────────────────────────────────────────────────────────
  static const LinearGradient shutterGradient = LinearGradient(
    colors: [shutterOuter1, shutterOuter2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient silverGradient = LinearGradient(
    colors: [silverLight, silverDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient bottomFade = LinearGradient(
    colors: [Color(0x00000000), Color(0xCC000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient lightLeakBW = LinearGradient(
    colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.centerRight,
  );
}
