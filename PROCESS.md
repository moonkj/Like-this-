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

### ⏳ 대기

- [ ] 앱 아이콘 교체 (OLED Black + Silver)
- [ ] 스플래시 화면 (Pure Black + "Like This" 텍스트)
- [ ] 햅틱 피드백 최적화
- [ ] 셔터 애니메이션 (1.0→0.92, 150ms spring)
- [ ] `flutter test --coverage` 커버리지 70%+ 달성
- [ ] iOS TestFlight 빌드
- [ ] Android 내부 테스트 트랙 빌드

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

---

## 참고 링크

- Like It 원본: https://github.com/moonkj/moodfilm
- Flutter 공식 문서: https://docs.flutter.dev
- Riverpod 문서: https://riverpod.dev
- GoRouter 문서: https://pub.dev/packages/go_router
