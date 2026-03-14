# PROCESS.md — Like This 개발 진행 일지

## 프로젝트 정보
- **시작일**: 2026-03-11
- **플랫폼**: iOS + Android (Flutter 3.41)
- **번들 ID**: com.likethis.likethis
- **기반**: Like It (moodfilm) 아키텍처 계승

---

## 진행 상황 개요

| Sprint | 내용 | 상태 |
|--------|------|------|
| Sprint 1 | 기반 설정 (컬러, 모델, LUT) | ✅ 완료 |
| Sprint 2 | 렌더링 엔진 & 카메라 UI | ✅ 완료 |
| Sprint 3 | UI/UX 컴포넌트 | ✅ 완료 |
| Sprint 4 | Polish & QA | 🔄 진행 중 |
| Sprint 13 | 카메라 UI/UX 개선 (오디오/비교/제스처) | ✅ 완료 |
| Sprint 14 | 에디터 크롭 & 카메라 센서 버그 수정 | ✅ 완료 |

---

## Sprint 1 — 핵심 기반 설정

### ✅ 완료

#### [2026-03-11] Flutter 프로젝트 생성
- `flutter create --org com.likethis --platforms ios,android likethis`
- Flutter 3.41.2 / Dart 3.11.0 확인
- CLAUDE.md 및 PROCESS.md 생성

---

### ✅ Sprint 1 완료 (2026-03-11)

#### Sprint 1-1: 앱 식별자 & pubspec.yaml 설정 ✅
- [x] pubspec.yaml 의존성 추가 (riverpod 2.6.1, go_router 14.8.1, hive 2.2.3 등)
- [x] 앱 이름 "Like This" 설정
- [x] 번들 ID: com.likethis.likethis

#### Sprint 1-2: 컬러 시스템 & 테마 교체 ✅
- [x] `lib/core/constants/app_colors.dart` — OLED Black #000000 / Silver #C0C0C0 팔레트
- [x] `lib/core/constants/app_dimensions.dart` — 셔터(76/64dp), 필터바(112dp) 등
- [x] `lib/core/constants/app_typography.dart` — Pretendard 7종 스타일
- [x] `lib/core/theme/app_theme.dart` — Dark Only, Material 3

#### Sprint 1-3: 7종 B&W LUT 파일 생성 ✅
- [x] `assets/luts/bw_pure.cube` — Gamma 0.85, Mid-tone 화사함
- [x] `assets/luts/bw_noir.cube` — S-curve, Shadow 강조
- [x] `assets/luts/bw_soft.cube` — 0.1~0.9 Contrast 압축
- [x] `assets/luts/bw_2k.cube` — Flat 커브, CCD 특성
- [x] `assets/luts/bw_dust.cube` — Faded 베이스 (런타임 텍스처 추가)
- [x] `assets/luts/bw_glow.cube` — Highlights Bloom, Gamma 0.8
- [x] `assets/luts/bw_paper.cube` — 베이지 오프셋 (+R+G)
- LUT 크기: 17×17×17 = 4,913 포인트, 파일당 ~130KB

#### Sprint 1-4: filter_model.dart & 데이터 레지스트리 ✅
- [x] `FilterCategory.blackwhite` 단일 카테고리
- [x] 7종 FilterModel 데이터 (BWFilters.all)
- [x] `BWEffectType` (grain, lightLeak, vignette, dust, bloom)
- [x] `UserPreferences` 경량 구현

---

## Sprint 2 — 렌더링 엔진 & 카메라 UI

### ✅ Sprint 2 완료 (2026-03-11)

#### Sprint 2-1: 프로젝트 구조 & 핵심 파일 스캐폴딩 ✅
- [x] 전체 features/ 폴더 구조 생성
- [x] `lib/main.dart` — Riverpod ProviderScope, 화면 방향 고정, OLED 상태바
- [x] `lib/app.dart` — GoRouter, ThemeMode.dark 고정
- [x] `lib/core/services/router.dart` — /splash → / → /settings 라우팅
- [x] `native_plugins/camera_engine` & `filter_engine` MethodChannel 브릿지

#### Sprint 2-2: 카메라 제스처 재매핑 ✅
- [x] 수직 드래그 → Exposure (-100 ~ +100, 민감도 0.3)
- [x] 수평 드래그 → Contrast (-100 ~ +100, 민감도 0.3)
- [x] 탭 250ms 딜레이 더블탭 감지 → 7종 필터 순차 변경
- [x] FilterNameOverlay — 더블탭 시 1.2초 표시 후 fade out
- [x] 인디케이터 2초 후 자동 숨김

#### Sprint 2-3: B&W 렌더링 파이프라인 ✅
- [x] iOS `MFBWEngine.swift` — 채널믹서→LUT→Exposure→Contrast→Grain→LightLeak→Vignette
- [x] iOS `MFCameraSession.swift` — AVFoundation + FlutterTexture
- [x] iOS `CameraEnginePlugin.swift` — 듀얼 MethodChannel (camera + filter)
- [x] Android `MFBWShader.kt` — GL ES 2.0 채널믹서 + Grain 인라인 노이즈
- [x] Android `CameraEnginePlugin.kt` — MethodChannel 핸들러

---

## Sprint 3 — UI/UX 컴포넌트

### ✅ Sprint 3 완료 (2026-03-11)

#### Sprint 3-1: 카메라 화면 & 위젯 ✅
- [x] `camera_screen.dart` — Stack 레이아웃, OLED Black, Silver 포인트
- [x] `shutter_button.dart` — Silver gradient (#E8E8E8→#888888), White 내부, spring 애니메이션
- [x] `filter_scroll_bar.dart` — 7종 B&W 캐러셀, Silver 선택 테두리
- [x] `contrast_indicator.dart` — LinearProgressIndicator + 라벨
- [x] `exposure_indicator.dart` — EV 표시 + 해/달 아이콘
- [x] `filter_name_overlay.dart` — scale + fade 복합 애니메이션
- [x] `splash_screen.dart` — OLED Black + "LIKE THIS" 텍스트
- [x] `settings_screen.dart` — Dark 설정 화면

#### TDD 결과 ✅
- **55개 테스트 전체 통과** (filter_model, camera_state, user_preferences)
- flutter pub get 성공 (92개 패키지)
- Pretendard 폰트 다운로드 완료 (Regular/Medium/SemiBold/Bold)

---

## Sprint 4 — Polish & QA

### 🔄 진행 중

- [x] 앱 아이콘 교체 (OLED Black + Silver) ← **2026-03-13 완료**
- [ ] 스플래시 화면 (Pure Black + "Like This" 텍스트)
- [ ] 햅틱 피드백 최적화
- [ ] 셔터 애니메이션 (1.0→0.92, 150ms spring)
- [ ] `flutter test --coverage` 커버리지 70%+ 달성
- [ ] iOS TestFlight 빌드
- [ ] Android 내부 테스트 트랙 빌드

#### [2026-03-13] 앱 아이콘 생성 ✅
- `tools/generate_icon.py` — Pillow 4× 슈퍼샘플링으로 1024×1024 마스터 PNG 생성
  - OLED Black (#000000) 배경
  - Silver (#C0C0C0) 원형 테두리 (반지름 40%, 스트로크 2.1%)
  - camera_alt_outlined 아이콘 (Silver, 40% 크기)
- `flutter_launcher_icons: ^0.14.3` dev_dependency 추가
  - `remove_alpha_ios: true` (App Store 제출 대응)
  - Android adaptive icon (`adaptive_icon_background: "#000000"`)
- iOS AppIcon.appiconset 전체 사이즈 생성 완료
- Android mipmap-mdpi ~ mipmap-xxxhdpi + anydpi-v26 생성 완료

---

## Sprint 5 — UI 재설계 & 카메라 기능 구현 (2026-03-11)

### ✅ 완료

#### Sprint 5-1: iOS AVFoundation 카메라 완전 구현
- [x] `MFCameraSession.swift` — AVCaptureSession, FlutterTexture, 30fps 프리뷰
- [x] `CameraEnginePlugin.swift` — FlutterTextureRegistry 연동, 실제 카메라 핸들러
- [x] `SceneDelegate.swift` — textureRegistry FlutterViewController에서 전달
- [x] 노출(EV bias), 줌, 플립, 사진 촬영 동작 확인

#### Sprint 5-2: Like It 인터페이스 구조로 전면 재설계
- [x] **Column 레이아웃** — 카메라 프리뷰 + 하단 패널 분리 (Stack 중첩 제거)
- [x] **3:4 비율 프리뷰** — AspectRatio(3/4) + ClipRect
- [x] **우측 플로팅 버튼 4개** — 타이머 / 효과 / 비교 / 설정 (Like It 동일 위치)
- [x] **하단 5버튼 행** — 갤러리 | 효과 | 셔터 | 보정 | 카메라전환
- [x] **모드 탭** — 사진 / 동영상 (• 인디케이터)
- [x] **셔터 버튼** — Silver 아웃라인 링 스타일 (Like It 참조)
- [x] **필터 썸네일** — 7종 B&W 그레이스케일 그래디언트 이미지 생성

---

## Sprint 6 — B&W 뷰티 기능 (2026-03-11, 진행 중)

### 목표: 흑백 전용 피부 보정 기능 추가

#### 기능 분석 결과

| 기능 | 기존 겹침 | 우선순위 | 방법 |
|------|-----------|----------|------|
| Porcelain B&W 필터 | bw_soft와 부분 겹침이나 차별화 가능 | 🔴 High | LUT 신규 생성 |
| Silky B&W 필터 | 없음 (셀카 전용) | 🔴 High | LUT 신규 생성 |
| Beauty Mode 슬라이더 UI | 없음 | 🔴 High | Flutter UI + 파라미터 매핑 |
| 얼굴 밝기 슬라이더 | 없음 | 🟡 Medium | VisionKit face detection |
| 다크서클 리프트 | 없음 | 🟡 Medium | 저명도 대비 감소 LUT |
| Skin Focus (배경 어둡게) | vignette와 부분 겹침 | 🟡 Medium | 얼굴 마스크 + 배경 노출↓ |
| Soft Depth (배경 블러) | 없음 | 🟢 Low | AVDepthData / CoreML |

#### Sprint 6-1: 신규 LUT 필터 2종 (진행 예정)
- [ ] `bw_porcelain.cube` — 미드톤↑, 하이라이트↓, 블랙 리프트
- [ ] `bw_silky.cube` — 미드톤 대비↓, 클래리티↓, 극소 그레인

#### Sprint 6-2: Beauty Mode UI (진행 예정)
- [ ] 효과 패널에 Beauty 탭 추가
- [ ] Soft / Glow / Silky 모드 선택 (HorizontalTab)
- [ ] 강도 슬라이더 0~100
- [ ] 각 모드별 파라미터 조합 매핑

#### Sprint 6-3: 얼굴 인식 기반 효과 (예정)
- [ ] VisionKit `VNDetectFaceRectanglesRequest` 구현
- [ ] 얼굴 영역 마스크 → Metal compute shader
- [ ] 얼굴 전용 밝기 (+0.2~+0.5 stop)
- [ ] 다크서클·입가 저명도 영역 대비 감소

#### Sprint 6-4: Soft Depth (예정)
- [ ] AVDepthData (iPhone X+ 듀얼렌즈) 깊이 데이터 추출
- [ ] 또는 Vision-based segmentation (CoreML)
- [ ] Metal 배경 블러 패스

---

## Sprint 7 — UI 개선 & 갤러리 화면 (2026-03-11)

### ✅ 완료

#### Sprint 7-1: 카메라 레이아웃 수정
- [x] 카메라 프리뷰 상태바 아래부터 시작 — `SizedBox(height: topPad)` + `AspectRatio(3/4)`
- [x] 상단 바 padding을 고정값(10)으로 변경
- [x] 우측 4개 버튼 하단 고정 — `Positioned(right: 12, bottom: 80)`
- [x] 필터 강도 컨트롤을 수직 팝업 → 카메라뷰 하단 가로 pill 바로 변경 (`bottom: 20`)

#### Sprint 7-2: Beauty Panel 개선
- [x] 효과 버튼 아이콘 `Icons.auto_fix_high`로 수정
- [x] BeautyPanel `AnimatedSwitcher` 생성 시 즉시 표시 버그 수정 — `initState`에 `_anim.forward()` 추가
- [x] `SizeTransition` → `FadeTransition` 전환으로 부드러운 등장 효과
- [x] Beauty Panel 배경을 `AppColors.background`로 변경 (기존 surfaceElevated + 테두리 제거)

#### Sprint 7-3: FilterScrollBar 개선
- [x] 필터 썸네일 상단 구분선 제거

#### Sprint 7-4: ShutterButton 햅틱 최적화
- [x] 누를 때 `heavyImpact` + 뗄 때 `lightImpact`으로 변경

#### Sprint 7-5: 에디터 화면 구현
- [x] `lib/features/editor/presentation/editor_screen.dart` 신규 생성
- [x] `ColorFilter.matrix` 기반 B&W 노출/대비 실시간 보정
- [x] 노출/대비/그레인/비네팅 탭 슬라이더
- [x] `/editor` 라우트 추가 (fade 전환, `state.extra` imagePath 전달)

#### Sprint 7-6: 필터 라이브러리 화면 구현
- [x] `lib/features/filter_library/presentation/filter_library_screen.dart` 신규 생성
- [x] 9종 필터 2컬럼 그리드, 색상 스와치 + 효과 타입 뱃지
- [x] `/filters` 라우트 추가 (slide-up 전환)

#### Sprint 7-7: 갤러리 화면 구현
- [x] `lib/features/gallery/presentation/gallery_screen.dart` 신규 생성 (Like It 구조 기반)
- [x] `photo_manager` 3컬럼 그리드, 다중선택 모드 (공유/삭제)
- [x] 동영상 재생시간 뱃지, 하단 탭바 (앨범/카메라)
- [x] `/gallery` 라우트 추가 (오른쪽→왼쪽 slide 전환)
- [x] 카메라 갤러리 버튼 → `/gallery` 연결

#### Sprint 7-8: 카메라 세션 라이프사이클
- [x] GoRouter 라우트 변경 감지 → 카메라 밖 이동 시 `pauseSession()`, 복귀 시 `resumeSession()`
- [x] Android `MainActivity.kt` — `CameraEnginePlugin` 등록

#### Sprint 7-9: 실기기 배포
- [x] iOS Release 빌드 및 xcrun devicectl 설치 (device: 00008150-001128391EF0401C)
- [x] `ios/ExportOptions.plist` 생성 (development, team: QN975MTM7H)

---

## Sprint 8 — 필터 엔진 버그 수정 & 사진 저장 (2026-03-11)

### ✅ 완료

#### Sprint 8-1: 필터 파이프라인 버그 전면 수정
- [x] `loadLUT` 키 불일치 수정: Dart `assetPath` ↔ Swift `path` → `assetPath`로 통일
- [x] grain/vignette 값 정규화 체크 수정: `> 1.0` → `> 0.01` (Dart가 /100 정규화 후 전송)
- [x] 효과 강도 계산 이중 정규화 제거: `/ 100.0 * 2.5` → `* 2.5`, `/ 100.0 * 0.18` → `* 0.18`
- [x] 노출/대비 스케일 수정: `/ 500.0` → `* 0.5`, `/ 200.0` → `* 0.5`

#### Sprint 8-2: 필터 강도 슬라이더 연결
- [x] `CameraState.filterIntensity` 필드 추가 (0.0~1.0)
- [x] `CameraNotifier.setFilterIntensity()` 메서드 추가
- [x] `FilterEngine.updateParams` → `lutIntensity: state.filterIntensity` 연결
- [x] iOS `MFBWEngine`: `CIDissolveTransition`으로 B&W ↔ 필터 블렌딩 (lutIntensity 기반)
- [x] 카메라 화면 슬라이더 `onChanged` → `setFilterIntensity()` 연결

#### Sprint 8-3: 사진 촬영 저장
- [x] `capturePhoto()` 후 `PhotoManager.editor.saveImageWithPath()` 갤러리 저장
- [x] iOS `photoOutput` 에서 B&W 엔진 적용 후 JPEG 저장 (`bwEngine.buildImage(from ciImage:)`)
- [x] `MFBWEngine.buildImage(from:)` CIImage 오버로드 추가 (캡처용)

#### Sprint 8-4: 초기 실행 검은 화면 버그 수정
- [x] `MFBWEngine` 초기값 raw(10.0/15.0) → 정규화(0.0)으로 수정 (37.5 강도 비네팅 방지)
- [x] `CameraEnginePlugin` updateParams 기본값 정규화 (10.0→0.0, 15.0→0.0)
- [x] `initialize()` 시 `_syncFilterParams()` 호출 추가 (필터 파라미터 즉시 적용)

---

## Sprint 9 — UI 마이너 수정 (2026-03-11)

### ✅ 완료

#### Sprint 9-1: 카메라 UI 정리
- [x] 카메라 상단 "LIKE THIS" 텍스트 제거 (상자처럼 보이는 문제 해결)
- [x] 필터 강도 슬라이더 높이 44 → 56, thumb 10, overlay 20으로 터치 면적 확대
- [x] 카메라 제스처 감지 영역을 강도 바 위쪽으로 제한 (슬라이더 터치 충돌 해결)

---

## Sprint 10 — 미구현 기능 전면 구현 & 버그 수정 (2026-03-11)

### ✅ 완료

#### Sprint 10-1: 플래시 / 타이머 기능
- [x] `FlashMode` enum (off/on/auto) — `camera_state.dart`
- [x] `CameraEngine.setFlash(mode)` MethodChannel 브릿지
- [x] `CameraNotifier.setFlashMode()` — 상태 변경 + 네이티브 동기화
- [x] 카메라 상단 플래시 버튼: flash_off / flash_on / flash_auto 아이콘 순환
- [x] 타이머 버튼: 0→3→5→10초 순환, 촬영 시 카운트다운 오버레이 (중앙 대형 숫자)
- [x] 카운트다운 중 셔터 비활성화

#### Sprint 10-2: 비교 모드 (Compare)
- [x] `CameraEngine.setCompareMode(enable)` MethodChannel
- [x] `CameraNotifier.setCompareMode()` 추가
- [x] iOS `bwEngine.setCompareMode(_)` Swift 연동
- [x] Android `session?.setCompareMode(enable)` Kotlin 연동
- [x] 우측 비교 버튼 long-press → 원본 화면 표시, 손 뗌 → 필터 복귀
- [x] "ORIGINAL" 뱃지 오버레이 표시

#### Sprint 10-3: 동영상 모드
- [x] `CameraEngine.startRecording()` / `stopRecording()` MethodChannel
- [x] `CameraNotifier.toggleRecording()` — 녹화 시작/종료, 저장
- [x] `_VideoShutterButton` — 빨간 원형, 녹화 중 정지(◼) 아이콘
- [x] `_RecordingBadge` — AnimationController repeat(reverse:true) 블링크 REC 뱃지

#### Sprint 10-4: 핀치 줌
- [x] `CameraState.zoom` (1.0~8.0) + `CameraNotifier.setZoom()`
- [x] `onScaleStart/Update/End` 통합 제스처 (기존 수직/수평 드래그와 공존)
- [x] `_ZoomBadge` — "1.0×" 형식으로 1.5초 후 자동 숨김
- [x] `CameraEngine.setZoom()` 네이티브 연결

#### Sprint 10-5: 에디터 저장 기능
- [x] `RepaintBoundary` + `RenderRepaintBoundary.toImage()` → PNG 저장
- [x] `PhotoManager.editor.saveImageWithPath()` 갤러리 저장
- [x] 저장 중 CircularProgressIndicator 표시

#### Sprint 10-6: 설정 화면 UserPreferences 연결
- [x] `preferences_service.dart` 신규 — JSON 영속화 (path_provider)
- [x] `preferencesProvider` (Riverpod StateNotifier)
- [x] 설정 화면 스위치 → saveToGallery / hapticEnabled 실시간 반영
- [x] "통계" 섹션 — 총 촬영 수 표시

#### Sprint 10-7: 갤러리 페이지네이션
- [x] 60장 단위 페이지 로드 (`_pageSize = 60`)
- [x] ScrollController 하단 400px 이전 트리거 → `_loadMorePhotos()`
- [x] SliverGrid + SliverToBoxAdapter 로딩 인디케이터

#### Sprint 10-8: dust / bloom 효과 파이프라인
- [x] `CameraState.dust` / `bloom` 필드 (0~100)
- [x] `FilterModel.defaultDust` / `defaultBloom` (Film Dust: 40.0, Silver Glow: 30.0)
- [x] `FilterEngine.updateParams` dust/bloom 파라미터 추가
- [x] `CameraNotifier._syncFilterParams()` dust/bloom 전달
- [x] iOS `CameraEnginePlugin.swift` updateParams에 dust/bloom 처리
- [x] Android `CameraEnginePlugin.kt` updateParams에 dust/bloom 처리, `BWRenderParams` 필드 추가

#### Sprint 10-9: iOS 네이티브 추가 핸들러
- [x] `CameraEnginePlugin.swift` — setFlash / startRecording / stopRecording / setCompareMode 케이스 추가

#### Sprint 10-10: Android 네이티브 추가 핸들러
- [x] `CameraEnginePlugin.kt` — setFlash / startRecording / stopRecording / setCompareMode 케이스 추가
- [x] `MFCameraSession` stub에 동일 4개 메서드 추가

## Sprint 11 — 뷰티 기능 전면 구현 (2026-03-12)

### ✅ 완료

#### Sprint 11-1: 뷰티 엔진 확장 (MFBeautyEngine.swift)
- [x] `BeautyMode` enum 7종: `soft`, `glow`, `silky`, `faceBright`, `shadowLift`, `skinFocus`, `softDepth`
- [x] VisionKit `VNDetectFaceRectanglesRequest` 얼굴 감지 (매 프레임)
- [x] `faceMask(for:softEdge:)` — `CIRadialGradient` 다중 얼굴 마스크 생성
- [x] `applySoftSkin` — `CIGaussianBlur` + `CIBlendWithMask` 얼굴 영역만 부드럽게
- [x] `applyGlowMono` — `CIBloom` radius 8.0 전체 글로우
- [x] `applySilky` — `CIToneCurve` 쉐도우 리프트
- [x] `applyFaceBrightness` — 얼굴 영역 밝기 +0.2 boost
- [x] `applyShadowLift` — 다크서클 쉐도우 리프트 (눈 아래 밝게)
- [x] `applySkinFocus` — 배경 어둡게 + 얼굴 마스크 블렌드
- [x] `applySoftDepth` — 배경 가우시안 블러 (역 얼굴 마스크 사용)

#### Sprint 11-2: 카메라 파이프라인 연결
- [x] `MFBWEngine.applyBeauty(_:)` — `buildProcessed` 에 뷰티 패스 추가
- [x] `MFCameraSession.captureOutput` — `bwEngine.detectFaces(in: rawBuffer)` 호출
- [x] `CameraEnginePlugin.swift` `setBeauty` 케이스 추가
- [x] `CameraEngine.dart` `setBeauty(mode, intensity)` 브릿지 추가
- [x] `CameraNotifier.setBeauty()` 상태 업데이트 + 네이티브 동기화

#### Sprint 11-3: 뷰티 패널 UI 개선
- [x] `BeautyMode` enum 7종으로 확장 (soft/glow/silky/faceBright/shadowLift/skinFocus/softDepth)
- [x] 수평 스크롤 `ListView` 탭 (고정 Row → 스크롤 가능)
- [x] 슬라이더 레이아웃 간소화

#### Sprint 11-4: 버그 수정
- [x] MFBeautyEngine.swift Xcode project.pbxproj PBXFileReference 누락 수정
- [x] editor_screen.dart `import flutter/rendering.dart` 추가 (RenderRepaintBoundary 오류)
- [x] 필터 강도 슬라이더 터치 안되는 문제 — GestureDetector bottom 80→100으로 수정
- [x] 타이머 버튼 텍스트 투명 문제 — Colors.white 텍스트 + 검정 배경으로 수정
- [x] 비교 모드 좌우 구분선 안보이는 문제 — `MFBWEngine.makeSplitImage()` 50:50 분할 + Flutter `_CompareSplitOverlay` 위젯 구현

---

## Sprint 12 — 동영상 녹화 저장 구현 (2026-03-12)

### ✅ 완료

#### Sprint 12-1: MFVideoRecorder.swift 완전 구현
- [x] `AVAssetWriter` + `AVAssetWriterInput` + `AVAssetWriterInputPixelBufferAdaptor` 기반
- [x] `startRecording()` — 지연 초기화 (첫 프레임 크기 기반 writer 생성)
- [x] `append(ciImage:context:at:)` — 처리된 B&W CIImage를 픽셀 버퍼로 변환 후 기록
- [x] `stopRecording(completion:)` — `markAsFinished()` + `finishWriting` 비동기 완료

#### Sprint 12-2: MFCameraSession 연결
- [x] `videoRecorder: MFVideoRecorder` 프로퍼티 추가
- [x] `startRecording()` stub → `videoRecorder.startRecording()` 연결
- [x] `stopRecording(completion:)` stub → `videoRecorder.stopRecording(completion:)` 연결
- [x] `captureOutput` 델리게이트에 B&W 처리된 프레임 → `videoRecorder.append()` 파이프

#### Sprint 12-3: Flutter 저장 방식 수정
- [x] `camera_provider.dart` `toggleRecording()` — `saveImageWithPath` → `PhotoManager.editor.saveVideo(File(path))` 변경

---

## Sprint 13 — 카메라 UI/UX 개선 (2026-03-12)

### ✅ 완료

#### Sprint 13-1: 오디오 녹음 추가
- [x] `MFCameraSession` — `AVCaptureAudioDataOutput` + 마이크 입력 추가
- [x] `MFVideoRecorder` — AAC 44100Hz 모노 오디오 트랙 + `appendAudio()` 구현
- [x] PTS 오프셋 보정 (`CMSampleBufferCreateCopyWithNewTiming`)

#### Sprint 13-2: 전면 카메라 플립 버그 수정
- [x] `flipCamera()` — 오디오 입력 재추가 누락 수정
- [x] `fixVideoOrientation()` — iOS 17+ `videoRotationAngle = 90` + 하위호환 fallback
- [x] CIImage 레벨 landscape 보정 (`oriented(.right)`)
- [x] `outputBufferPool = nil` 리셋 (카메라 전환 후 치수 불일치 방지)

#### Sprint 13-3: 비교(Compare) 기능 완성
- [x] 비교 버튼 토글 방식으로 변경 (탭 on/off)
- [x] `MFBWEngine.makeSplitImage()` — 동적 분할 위치 (`splitPosition` 0.0~1.0)
- [x] Flutter → 네이티브 `setSplitPosition` 채널 연결
- [x] 수평 스와이프 시 분할선 + 필터 경계 동시 이동
- [x] 분할선 핸들 좌우에 "원본" / 현재 필터명 레이블 표시
- [x] 비교 오버레이 `IgnorePointer` 처리 (강도 슬라이더 터치 보장)

#### Sprint 13-4: 제스처 개선
- [x] EV/대비 동시 표시 버그 수정 (전환 시 반대쪽 즉시 숨김)
- [x] Dead zone 6px 추가 (살짝 터치 오반응 방지)
- [x] EV/대비 민감도 0.3 → 0.15
- [x] 비교 모드 수평 스와이프 → 분할선 이동 (대비 조절 비활성)

#### Sprint 13-5: UI 정리
- [x] 사이드 버튼 크기 44 → 36px
- [x] 필터 강도 슬라이더 높이 56 → 40px, bottom 20 → 8
- [x] EV/대비 인디케이터 강도 바 위로 이동 (겹침 방지)
- [x] 사이드 버튼 5초 자동 숨김 + 터치 시 타이머 리셋
- [x] 사이드 버튼 투명 시 `IgnorePointer` (슬라이더 간섭 제거)
- [x] 사진/동영상 전환 시 버튼 흔들림 수정 (SizedBox 84px 고정)
- [x] 상단 바 그라디언트 제거
- [x] 필터 바 기본값 열림, 필터/효과 버튼 상호 전환(닫힘 없음)
- [x] 필터 목록 맨 앞 "없음" 아이템 추가

#### Sprint 13-6: 비교 모드 캡처 분할선 제거
- [x] `MFBWEngine.buildImageForCapture(from:)` 추가 — 비교 분할선 없이 필터만 적용
- [x] `MFCameraSession.photoOutput` — `buildImage` → `buildImageForCapture` 전환 (사진 캡처 시 분할선 제외)
- [x] `MFCameraSession.captureOutput` 녹화 경로 — `buildImageForCapture` 사용 (동영상 프레임 분할선 제외)
- 비교 모드 ON 상태에서 촬영/녹화해도 저장 파일에는 필터만 적용됨 (분할선 없음)

---

## Sprint 14 — 에디터 크롭 & 카메라 센서 버그 수정 (2026-03-12)

### ✅ 완료

#### Sprint 14-1: 에디터 9:16 크롭 비율 추가
- [x] `editor_screen.dart` `_buildCropContent` — `'9:16': 9/16` 비율 추가
- [x] 기존 `'자유' / '1:1' / '3:4' / '4:3' / '16:9'` 에 이어 세로 숏폼 비율 완성

#### Sprint 14-2: 카메라 센서 상시 활성 버그 수정 (핵심)
- **증상**: 갤러리/에디터 화면 진입 후에도 녹색 LED(카메라 센서) 켜짐
- **원인 분석**:
  - `RouteObserver` / `RouteAware` mixin — go_router 14 Pages API에서 `didPushNext`/`didPopNext` 보장 안 됨
  - `WidgetsBindingObserver.didChangeAppLifecycleState` — 네비게이터 스택에 가려진 화면에도 전달됨
  - 앱 백그라운드 → 포그라운드 복귀 시 갤러리가 위에 있어도 CameraScreen의 `resumed` 이벤트 → `resumeSession()` 호출 → LED ON
- **해결**:
  - `RouteAware` 완전 제거
  - `bool _isCurrentRoute = true` 플래그 도입
  - `didChangeDependencies`에서 `ModalRoute.of(context)?.isCurrent` 체크
    - `_ModalScopeStatus` InheritedWidget 의존 → push/pop 시 100% 신뢰 호출
    - `addPostFrameCallback`으로 부작용 지연 (빌드 중 채널 호출 방지)
  - `didChangeAppLifecycleState`에 `if (!_isCurrentRoute) return` 가드 추가
- [x] `camera_screen.dart` — `RouteAware` 제거, `_isCurrentRoute` 플래그 + `didChangeDependencies` 재작성
- [x] `core/services/router.dart` — `appRouteObserver` 제거 (클린업)

#### Sprint 14-3: Timer dispose 누락 수정
- **증상**: 화면 전환 후 "setState called after dispose" 경고 가능성
- [x] `camera_screen.dart` `dispose()` — `_sideButtonTimer`, `_intensityPanelTimer` 취소 추가 (Reviewer 단계에서 발견)

---

## Sprint 15 — 갤러리 일괄 필터 / 에디터 스와이프 / 동영상 크롭 (2026-03-12)

### ✅ 완료

#### Sprint 15-1: 갤러리 일괄 필터 기능
- [x] 다중 선택 모드 상단 바 버튼: 공유 → 필터(Icons.auto_fix_high_rounded) → 삭제 순서
- [x] `_showFilterPanel()` — `showModalBottomSheet` 직사각형 필터 썸네일(52×70/58×78, radius 8) + 강도 슬라이더
- [x] `_applyFilterToSelected()` — `ImmutableBuffer` + `ImageDescriptor` 기반 배치 처리
  - `ColorFilter.matrix` B&W 렌더링 + 비네팅 적용
  - 비디오 자동 스킵 + 스낵바 알림
  - 처리 중 상단 진행 카운트 + `LinearProgressIndicator`
  - 완료 후 다중 선택 모드 자동 종료
- [x] `_FilterPickerSheet` 위젯 — 에디터와 동일한 `_filterTone()` / `_buildColorFilter()` 파이프라인

#### Sprint 15-2: 에디터 사진 스와이프 탐색
- [x] `EditorScreen` — `assetList: List<AssetEntity>?` + `initialIndex: int?` 파라미터 추가
- [x] `PageView.builder` — 갤러리 전체 에셋 스와이프 탐색
- [x] 크롭 탭·비교 모드에서 PageView 스와이프 비활성 (`NeverScrollableScrollPhysics`)
- [x] 페이지 변경 시 이전 비디오 컨트롤러 dispose + 새 에셋 초기화
- [x] `_NoThumbScrollBehavior` — PageView 오버스크롤 인디케이터 제거
- [x] GoRouter `/editor` 라우트 — `assetList` + `index` 파싱 추가

#### Sprint 15-3: 갤러리 동영상 재생 수정
- [x] `video_player_screen.dart` 신규 생성 — 독립형 전체화면 재생, 슬라이더, 공유, 삭제
- [x] GoRouter `/video` 라우트 추가
- [x] `gallery_screen.dart` — 동영상 탭 시 `/video` 라우트로 이동 (기존 검은 화면 수정)

#### Sprint 15-4: 에디터 동영상 지원
- [x] `EditorScreen` — `AssetType.video` 감지 → `VideoPlayerController` 초기화
- [x] `ColorFiltered` + `VideoPlayer` — 실시간 필터 미리보기
- [x] `bool get _isVideo` — 비디오 전용 분기 처리
- [x] 비교 버튼 비디오 시 비활성
- [x] 저장 버튼 비디오 시 비활성 (크롭 전까지)

#### Sprint 15-5: 동영상 크롭 기능
- [x] `CameraEngine.cropVideo()` Dart 브릿지 추가 (정규화 좌표 0~1)
- [x] iOS `CameraEnginePlugin.swift` `cropVideo` 케이스:
  - `AVURLAsset` + `AVAssetExportSession(presetName: .highestQuality)`
  - `preferredTransform` 보정 → 실제 표시 크기(displayW/H) 계산
  - `AVMutableVideoComposition` + 크롭 translate 변환
  - `.mp4` 내보내기, 기존 파일 삭제 후 덮어쓰기
- [x] Android `CameraEnginePlugin.kt` `cropVideo` — `NOT_IMPLEMENTED` 에러 반환 (iOS 전용)
- [x] `editor_screen.dart` 크롭 탭에서 비디오 위에 `_CropOverlay` 표시
- [x] 비율 프리셋 `_applyRatio()` — 비디오 크기 `_videoCtrl?.value.size` 지원
- [x] 저장 버튼 — 비디오 + `_cropChanged` 시 활성, `CameraEngine.cropVideo()` → `PhotoManager.editor.saveVideo()` 저장
- [x] 크롭 탭 진입 시 재생/일시정지 탭 제스처 비활성

---

## Sprint 16 — 에디터 동영상 비교 & 카메라 전환 애니메이션 수정 (2026-03-12)

### ✅ 완료

#### Sprint 16-1: CLAUDE.md 워크플로우 8단계 확장
- [x] 기존 4단계(설계자/코더/디버거/리뷰어) → 8단계로 재작성
- [x] 추가 단계: (1) UX 설계자, (5) 테스트 작성자, (7) 성능·최적화, (8) 문서화
- [x] (7)(8)은 요청 시에만 수행 명시

#### Sprint 16-2: 에디터 동영상 비교 모드 버그 수정
- [x] 비교 버튼 `onTap`에서 `_isVideo ? null` 조건 제거 → 동영상 비교 활성화
- [x] `_buildPhotoContent()`에서 `_isComparing` 블록을 `_isVideo` 블록 앞으로 이동 (구조적 버그 해결)
- [x] `_CompareOverlay`에 `videoController` / `afterLabel` 파라미터 추가
- [x] Before(원본) / After(필터명) VideoPlayer 동일 컨트롤러로 프레임 동기화 렌더링
- [x] 비교 레이블: 왼쪽 "원본" / 오른쪽 현재 필터 이름 (`BWFilters.all.firstWhere`)

#### Sprint 16-3: 카메라 뷰 전환 끊김 수정
- **증상**: 필터 상자 ↔ 효과 아이콘 전환 시 화면이 끊겨 보임
- **원인**: `AnimatedSwitcher`(200ms) + `BeautyPanel` 내부 `FadeTransition`(280ms) 이중 opacity 애니메이션
- [x] `BeautyPanel` 내부 `AnimationController` + `FadeTransition` + `visible` 파라미터 완전 제거
- [x] `SingleTickerProviderStateMixin` 제거
- [x] `camera_screen.dart` `visible: true` 파라미터 제거
- [x] `AnimatedSwitcher`(200ms) 단독으로 fade 전환 담당 → 부드러운 전환 보장

---

## Sprint 17 — 에디터 버그 수정 & 네이티브 저장 파이프라인 (2026-03-12)

### ✅ 완료

#### Sprint 17-1: 에디터 UI 버그 4종 수정

- [x] **필터 박스 위치 이동 버그** — `_FilterItem` 외곽 `SizedBox` 너비를 `selected ? 58 : 52` → 고정 `width: 64`로 변경, `crossAxisAlignment: CrossAxisAlignment.center` 추가
- [x] **효과 슬라이더 드래그 후 탭 무응답** — 효과 아이콘 `GestureDetector`에 `behavior: HitTestBehavior.opaque` 추가 (Slider의 HorizontalDragGestureRecognizer 충돌 해결)
- [x] **letterbox 영역에 효과 적용** — 비네팅·그레인 오버레이를 `Center + AspectRatio(_imageSize!.width/_imageSize!.height)`로 감싸 실제 이미지 영역에만 적용
- [x] **사진 3:4 비율 저장 불일치** — `MFCameraSession.swift` photo capture 경로에 center-crop 추가: `(targetH = width * 4/3, yOffset = (height - targetH) / 2)`

#### Sprint 17-2: 네이티브 CIImage 저장 파이프라인 (핵심)

- **문제**: Flutter `picture.toImage()` (Impeller)가 대용량 HEIC 이미지에서 무음 다운스케일 or OOM → 갤러리 이미지 저장 시 작은 사이즈로 저장되는 버그
- **해결**: Flutter Canvas 저장 제거 → iOS 네이티브 CIImage 파이프라인으로 전면 교체

- [x] `CameraEnginePlugin.swift` — `processAndSaveImage` 케이스 추가:
  - `UIImage(contentsOfFile:)` — HEIC/JPEG/PNG 전체 해상도 로드 + EXIF 방향 자동 보정
  - `CIColorMatrix` — Flutter 4×5 ColorFilter 행렬 그대로 적용 (bias /255 변환)
  - `CIVignette` 비네팅 적용
  - `CIRandomGenerator + CISoftLightBlendMode` 그레인 적용
  - 크롭: Flutter top-left Y → CIImage bottom-left Y 좌표 변환 `(1 - cropY - cropH) * height`
  - `CIContext.createCGImage` + `UIImage.jpegData(compressionQuality: 0.92)` → JPEG 파일 저장
- [x] `CameraEnginePlugin.kt` — `processAndSaveImage` NOT_IMPLEMENTED stub 추가
- [x] `camera_engine.dart` — `processAndSaveImage()` static 메서드 추가 (sourcePath, colorMatrix 20개, vignette, grain, 크롭 좌표)
- [x] `editor_screen.dart`:
  - `_buildFilterMatrix()` 추출 — `_buildFilter()`와 내부 분리, 네이티브 저장에 행렬 값 직접 전달
  - `_save()` 완전 교체 — `_loadSaveImage()` 제거, `CameraEngine.processAndSaveImage()` 단일 경로로 통합
  - 소스 파일: `list[_currentIndex].originFile` 우선, 없으면 `_currentPath` 폴백
  - 저장 포맷 PNG → JPEG (`.jpg`) 변경

---

## Sprint 18 — 에디터 동영상 효과 & 프리뷰 버그 수정 (2026-03-12)

### ✅ 완료

#### Sprint 18-1: 동영상 효과 저장 파이프라인 완성

- **문제**: `processAndSaveVideo` / `processAndSaveImage` 호출 시 lightLeak·bloom 파라미터 누락 → 저장 파일에 두 효과 미반영
- [x] `camera_engine.dart` — `processAndSaveImage` / `processAndSaveVideo` 에 `lightLeak`, `bloom` required 파라미터 추가
- [x] `editor_screen.dart` `_save()` — 두 호출에 `lightLeak: _lightLeak / 100.0`, `bloom: _bloom / 100.0` 전달
- [x] `CameraEnginePlugin.swift` `processAndSaveImage` — step 5(lightLeak: CIRadialGradient + CIScreenBlendMode), step 6(bloom: CIBloom) 추가
- [x] `CameraEnginePlugin.swift` `processAndSaveVideo` — `clampedToExtent()` → `cropped(to: extent)` 전면 교체 (무한 extent로 Metal 렌더러 오작동 방지), lightLeak·bloom 필터 추가

#### Sprint 18-2: 동영상 프리뷰 letterbox 효과 침범 수정

- **문제**: 16:9 비디오에서 grain·lightLeak·bloom 오버레이가 AspectRatio 밖 검정 여백까지 덮음
- [x] `editor_screen.dart` `_buildPhotoContent()` — 오버레이를 `Center > AspectRatio > Stack` 내부로 이동, `ColorFiltered(child: VideoPlayer)` 와 함께 한 Stack으로 묶음
- [x] 이미지 프리뷰도 동일하게 `Center > AspectRatio(_imageSize)` 구조로 오버레이 제한

#### Sprint 18-3: MFBWEngine lightLeak 실시간 적용 누락 수정

- **문제**: `_lightLeak` 값이 `MFBWEngine`에 저장되나 `applyEffects()` 파이프라인에서 호출 안 됨
- [x] `MFBWEngine.swift` `applyLightLeak()` private 함수 구현 (CIRadialGradient + CIScreenBlendMode)
- [x] `applyEffects()` — `_lightLeak > 0.01` 조건으로 `applyLightLeak()` 호출 추가

#### Sprint 18-4: 글로우(Bloom) 프리뷰 가시성 개선

- **문제**: `_BloomOverlay` RadialGradient 방식이 너무 약해 프리뷰에서 효과가 안 보임 (저장 파일의 CIBloom과 시각 차이 큼)
- [x] `_BloomOverlay` — RadialGradient → `BackdropFilter(ImageFilter.blur, sigmaX/Y: intensity × 10)` + BlendMode.screen + 흰색 오버레이로 교체
- [x] 프리뷰가 네이티브 CIBloom과 유사한 블러+글로우 효과로 표시됨

#### Sprint 18-5: 효과 탭 슬라이더 전환 후 터치 불가 버그 수정

- **문제**: 효과 아이콘 탭으로 다른 효과 선택 시 새 슬라이더가 터치에 응답 안 함
- **원인**: `_EditorSlider`(StatelessWidget)에 key 없음 → Flutter가 이전 `Slider` 위젯 재사용, 이전 드래그 제스처 상태 잔류
- [x] `_EditorSlider` 생성자에 `super.key` 추가
- [x] 효과 탭 `_EditorSlider` 호출부에 `key: ValueKey(_selectedEffect)` 전달 → 효과 전환 시 슬라이더 위젯 새로 생성

#### Sprint 18-6: 효과 탭 PageView 스와이프 충돌 수정

- [x] `canSwipe` 조건 `_tab != 2 && !_isComparing` → `_tab == 0 && !_isComparing` 변경
- [x] 효과 탭(tab=1)에서 PageView 스와이프 완전 비활성 → 슬라이더 수평 드래그 100% 슬라이더로 전달

---

## Sprint 19 — 필터 파라미터 튜닝 & UI 버그 수정 (2026-03-14)

### ✅ 완료

#### Sprint 19-1: 필터 기본값 전면 튜닝
- [x] 9종 필터 `defaultIntensity` / `defaultGrain` / `defaultVignette` 재조정 + 각 값에 의도 주석 추가
  - Pure This: grain 0 / vignette 0 (순수 B&W)
  - Deep Noir: intensity 1.0 / grain 38 / vignette 48 (느와르 극대화)
  - Soft Grey: grain 6 / vignette 6 (에어리한 느낌)
  - BY2K: grain 45 / vignette 22 (디지털 노이즈 + 렌즈 열화)
  - Film Dust: grain 60 / dust 55 (heavy grain + 먼지 텍스처)
  - Silver Glow: grain 3 / bloom 28 (글로우 주연, grain 조연)
  - Paper Log: grain 18 / vignette 40 (인쇄 질감)
  - Porcelain B&W: intensity 0.95 / grain 2 (피부 최적화)
  - Silky B&W: grain 0 / vignette 3 (완전 무결점 셀카)

#### Sprint 19-2: 필터 이름 변경
- [x] `'2000s BY2K'` → `'BY2K'` (긴 이름 짤림 방지 + 브랜드 일관성)

#### Sprint 19-3: 에디터 필터 아이템 이름 짤림 버그 수정
- [x] `_FilterItem` 텍스트 컨테이너 width `58` → `64` (외부 SizedBox와 통일)
- [x] `fontSize: 11` → `10` (긴 이름 2줄 수용 여유 확보)
- [x] `overflow: TextOverflow.ellipsis` 추가 (2줄도 초과 시 말줄임표)

#### Sprint 19-4: 필터 썸네일 고화질 업데이트
- [x] 9종 `.jpg` 썸네일 전면 교체 (bw_2k, bw_dust, bw_glow, bw_noir, bw_paper, bw_porcelain, bw_pure, bw_silky, bw_soft)
- 파일 크기 대폭 증가 (예: bw_pure 2.8KB → 19KB) — 실제 촬영본 기반 고품질 썸네일

#### Sprint 19-5: processAndSaveVideo 백그라운드 처리 & renderSize 보정 (iOS)
- [x] `CameraEnginePlugin.swift` `processAndSaveVideo` — `DispatchQueue.global(qos: .userInitiated).async` 로 이동 (메인 스레드 블록 방지)
- [x] `videoTrack.preferredTransform` 기반 실제 renderW/H 계산 → 세로 영상 렌더 사이즈 오류 방지
- [x] `tRect.width/height` 유효성 체크 후 `naturalSize` 폴백

#### Sprint 19-6: 에디터 비교 모드 제거
- [x] 에디터 화면(`editor_screen.dart`)에서 `_isComparing` 상태 및 비교 버튼 완전 제거 (카메라 전용 기능으로 역할 분리)

---

## Sprint 20 — 카메라 사이드바 타이머 연동

### ✅ 완료 (2026-03-14)

#### Sprint 20-1: 필터 강도 슬라이더 사용 중 사이드바 유지
- [x] `_resetIntensityPanelTimer()` 내에서 `_sideButtonTimer?.cancel()` 추가
  - 슬라이더 드래그 중 사이드바 독립 타이머가 사이드바를 숨기지 않도록 방지
- [x] intensity panel 5초 타임아웃 시 `_showSideButtons = false` 동시 처리
  - 사이드바와 강도 패널이 동시에 사라지는 일관된 UX
- [x] tune 버튼으로 intensity panel 수동 닫을 때 `_resetSideButtonTimer()` 호출
  - 패널 닫힌 후 사이드바가 독립적으로 5초 카운트다운 재개

---

## 기술 결정 로그 (ADR)

### ADR-001: 클론 대신 flutter create 사용
- **날짜**: 2026-03-11
- **결정**: GitHub 클론 네트워크 불안정으로 `flutter create`로 신규 생성
- **이유**: 안정적인 시작, Like It 분석 내용을 바탕으로 구조 재현
- **결과**: 더 깔끔한 베이스에서 Like This 전용 구조로 시작 가능

### ADR-002: B&W 변환 방식
- **날짜**: 2026-03-11
- **결정**: 채널 믹서 기반 Luminance 변환 (채도 -100 방식 거부)
- **이유**: 피부톤 High-key + 머리카락 Deep 효과를 위한 파장 조절 필요
- **공식**: `L = R×0.299 + G×0.587 + B×0.114`

### ADR-003: Dark Only 테마
- **날짜**: 2026-03-11
- **결정**: Light Mode 완전 미지원
- **이유**: OLED 절전 효과 + 브랜드 컨셉(차갑고 힙한 감성) 일관성
- **구현**: `ThemeMode.dark` 고정, `systemTheme` 무시

---

## 이슈 & 해결 로그

| 날짜 | 이슈 | 해결 |
|------|------|------|
| 2026-03-11 | GitHub clone 네트워크 오류 (curl 56) | flutter create로 신규 생성으로 전환 |
| 2026-03-12 | 갤러리/에디터 진입 후 카메라 LED 상시 ON | ModalRoute.isCurrent + _isCurrentRoute 가드로 해결 |
| 2026-03-12 | RouteObserver go_router 14 Pages API 비호환 | didChangeDependencies + InheritedWidget 방식으로 교체 |

---

## 참고 링크

- Like It 원본: https://github.com/moonkj/moodfilm
- Flutter 공식 문서: https://docs.flutter.dev
- Riverpod 문서: https://riverpod.dev
- GoRouter 문서: https://pub.dev/packages/go_router
