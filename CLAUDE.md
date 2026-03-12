# CLAUDE.md — Like This (Black & White Camera)

## 프로젝트 개요

**앱 이름**: Like This
**번들 ID**: com.likethis.likethis
**설명**: 흑백 전용 필름 카메라 앱. Like It(moodfilm) 아키텍처를 계승하여 무채색 감성의 차별화된 카메라 경험을 제공.
**타겟**: 1020 Z세대, 인스타그램 피드 통일성을 중시하는 무채색 OOTD 사용자

---

## 아키텍처 원칙

### 기술 스택
- **Flutter** 3.41+ / **Dart** 3.11+
- **상태관리**: flutter_riverpod ^2.6+
- **라우팅**: go_router ^14+
- **로컬 저장**: hive_flutter ^1.1+
- **카메라**: 네이티브 MethodChannel (iOS: AVFoundation/Metal, Android: CameraX/OpenGL)

### 폴더 구조
```
lib/
├── core/
│   ├── constants/       # app_colors, app_dimensions, app_typography
│   ├── models/          # filter_model, effect_model, user_preferences
│   ├── services/        # storage_service, router, camera_engine, filter_engine
│   └── theme/           # app_theme (Dark Only)
├── features/
│   ├── camera/          # 메인 카메라 화면 + 위젯 + 프로바이더
│   ├── editor/          # 흑백 전용 에디터
│   ├── filter_library/  # 7종 B&W 필터 라이브러리
│   ├── gallery/         # 갤러리 및 이미지 선택
│   ├── onboarding/      # 온보딩 & 페이월
│   └── settings/        # 설정
└── native_plugins/
    ├── camera_engine/   # MethodChannel 브릿지
    └── filter_engine/   # B&W 렌더링 파이프라인 브릿지
```

### 핵심 설계 결정

1. **Dark Mode Only**: `ThemeMode.dark` 고정, Light theme 미구현
2. **OLED Black 배경**: `#000000` 적극 활용 (배터리 절약 + 힙 감성)
3. **B&W 렌더링**: 단순 채도 -100 아닌 채널 믹서 기반 Luminance 변환
   - `L = R×0.299 + G×0.587 + B×0.114`
4. **필터**: 7종 흑백 전용 LUT (.cube) — 컬러 필터 완전 제거
5. **제스처 재매핑**:
   - 수직 스와이프 → 노출(Exposure) 조절
   - 수평 스와이프 → 대비(Contrast) 조절
   - 더블탭 → 7종 필터 프리셋 순차 변경

---

## 컬러 시스템

| 용도 | 색상 | Hex |
|------|------|-----|
| Background | OLED Black | `#000000` |
| Surface | Near Black | `#111111` |
| Elevated Surface | Dark Gray | `#1A1A1A` |
| Primary Accent | Silver | `#C0C0C0` |
| Text Primary | Pure White | `#FFFFFF` |
| Text Secondary | Mid Gray | `#888888` |
| Text Disabled | Dark Gray | `#444444` |
| Border/Divider | Dark Silver | `#333333` |
| Shutter Ring | Silver Gradient | `#E8E8E8 → #888888` |
| Filter Selected | Silver Border | `#C0C0C0` |
| Error | Red | `#E57373` |
| Success | Green | `#81C784` |

---

## 7종 필터 프리셋

| ID | 이름 | LUT 파일 | 특성 |
|----|------|---------|------|
| `bw_pure` | Pure This | `bw_pure.cube` | Mid-tone +15, 화사한 기본 흑백 |
| `bw_noir` | Deep Noir | `bw_noir.cube` | Shadow -40, Blacks -20, Contrast +60 |
| `bw_soft` | Soft Grey | `bw_soft.cube` | Contrast -30, 연필 소묘 질감 |
| `bw_2k` | 2000s BY2K | `bw_2k.cube` | Sharpness -15, CCD 특성 블러 |
| `bw_dust` | Film Dust | `bw_dust.cube` | 랜덤 노이즈 + 먼지 텍스처 |
| `bw_glow` | Silver Glow | `bw_glow.cube` | Highlights Bloom +35, 금속 광택 |
| `bw_paper` | Paper Log | `bw_paper.cube` | 비네팅 내장, 베이지 오프셋 |

---

## 이펙트 파라미터 (B&W 전용)

| 파라미터 | 범위 | 기본값 | 설명 |
|---------|------|--------|------|
| `grain` | 0~100 | 20 | 아날로그 입자감 |
| `lightLeak` | 0~100 | 0 | 흰색 오버레이 빛 번짐 |
| `contrast` | -100~100 | 0 | 수평 스와이프로 실시간 조절 |
| `exposure` | -100~100 | 0 | 수직 스와이프로 실시간 조절 |
| `vignette` | 0~100 | 15 | 주변부 어둡게 |

---

## 네이티브 렌더링 파이프라인

```
Input Frame
  → BW Conversion (채널 믹서: R×0.299 + G×0.587 + B×0.114)
  → B&W LUT 적용 (7종 커스텀 커브, trilinear interpolation)
  → Deep Contrast (스킨톤 High-key + 머리카락 Deep)
  → Grain Engine (CIRandomGenerator / GL noise, 0~100)
  → Light Leak B&W (흰색 방향성 그라디언트 오버레이)
  → Vignette
  → Output (Texture → Flutter UI)
```

---

## TDD 방침

### Red → Green → Refactor 사이클
1. 🔴 **RED**: 테스트 먼저 작성 → `flutter test` 실행 → 실패 확인
2. 🟢 **GREEN**: 테스트를 통과하는 최소한의 코드 작성 → 재실행 확인
3. 🔵 **REFACTOR**: 테스트가 통과한 상태에서 코드 품질 개선

### 커버리지 목표: 70%+
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 테스트 파일 구조
```
test/
├── core/
│   ├── models/
│   │   ├── filter_model_test.dart
│   │   └── user_preferences_test.dart
│   └── services/
│       └── storage_service_test.dart
├── features/
│   ├── camera/
│   │   └── camera_provider_test.dart
│   └── editor/
│       └── editor_provider_test.dart
└── helpers/
    └── test_helpers.dart
```

### 테스트 작성 규칙
- 모든 Model 클래스: 단위 테스트 필수
- Provider 로직: `ProviderContainer`로 격리 테스트
- UI 위젯: `WidgetTester`로 핵심 인터랙션 테스트
- 네이티브 플러그인: Mock 사용 (`flutter_test` + `mockito`)

---

## 중요 주의사항

### 절대 하지 말 것
- Light Mode 테마 코드 추가 금지 (Dark Only)
- 컬러 필터(warm/cool/film/aesthetic) 코드 유지 금지
- 단순 채도 조절로 흑백 구현 금지 (채널 믹서 필수)
- 테스트 없이 핵심 비즈니스 로직 구현 금지

### 반드시 할 것
- 모든 색상은 `AppColors` 상수 참조 (하드코딩 금지)
- Riverpod Provider는 `ref.watch` / `ref.read` 패턴 준수
- 네이티브 코드 변경 시 iOS + Android 양쪽 동시 업데이트
- LUT 파일은 항상 `assets/luts/` 경로에서 로드

### 성능 기준
- 카메라 프리뷰: 30fps 유지
- LUT 적용: 16ms 이하 (1 frame)
- 앱 시작 → 카메라 활성화: 2초 이내
- 메모리: 200MB 이하 (카메라 활성 시)

---

## 작업 워크플로우 (필수 준수)

모든 작업은 아래 단계 역할을 순서대로 수행한다.
**평상시 기본 흐름**: (1) → (2) → (3) → (4) → (5) → (6)
**선택 단계**: (7) 성능·최적화, (8) 문서화 — 해당 요청이 있을 때만 수행.

### (1) UX 설계자 (UX Designer)
- 사용자 시나리오와 유저 플로우를 정의한다.
- 각 화면의 목표, 필요한 정보, 주요 액션을 와이어프레임 수준으로 설명한다.
- 빈 상태·로딩·에러 등 예외적인 UX 상태를 미리 정의한다.
- 사용자가 가장 쉽게 수행해야 할 핵심 행동의 우선순위를 정한다.
- **UX 설계가 필요 없을 시 이 단계를 건너뛰고 바로 (2) 설계자로 이동한다.**
- 산출물: "UX 설계 요약 (유저 플로우 / 화면 정의 / 예외 상태)"

### (2) 설계자 (Architect)
- 사용자의 요청을 분석한다.
- 핵심 기능, 요구사항, 입·출력 정의, 기술 스택, 구현 단계를 계획한다.
- 구체적이고 실행 가능한 설계안을 목록 형태로 작성한다.
- 산출물: "설계 요약"

### (3) 코드 작성자 (Coder)
- 설계자의 계획에 따라 실제 코드를 작성한다.
- 코드는 완전하게 실행 가능한 형태로 제시하며, 필요 시 간단한 주석만 포함한다.
- 기존 컨벤션(AppColors, Riverpod 패턴 등) 준수.
- 산출물: 코드 블록 (Swift / Dart 등)

### (4) 코드 디버거 (Debugger)
- 코드 작성자의 결과를 세밀히 점검한다.
- 논리 오류, 실행 오류, 예외 상황, 미처 처리되지 않은 조건 등을 분석한다.
- 문제점을 목록화하고, 수정이 필요한 부분을 제안한다. 수정 후 (3) 코드 작성자 단계로 복귀.
- 오류 없으면 이 단계 생략.
- 산출물: "버그 리포트 및 수정 제안"

### (5) 테스트 작성자 (Test Engineer) — 선택
- 버그 가능성이 높거나 중요한 로직을 테스트 대상으로 선정한다.
- 단위 테스트, 위젯 테스트, 통합 테스트 중 적합한 방식을 제안한다.
- 핵심 시나리오에 대한 테스트 코드 예시 또는 테스트 케이스(입력–기대 결과)를 작성한다.
- 향후 리팩터링 시 동작을 보장할 수 있는 안전망을 설계한다.
- 테스트 실패 시 (4) 디버거로 복귀한다.
- 산출물: "테스트 코드 / 테스트 케이스 목록"

### (6) 리뷰어 (Reviewer)
- 최종 코드를 품질 관점(가독성, 유지보수성, 확장성)에서 검토한다.
- "좋은 점"과 "개선할 부분"을 각각 항목별로 정리한다.
- **개선할 부분이 존재하면 즉시 (2) 설계자로 복귀하여 개선 사이클을 다시 수행한다.**
  - 개선 사이클 재진입 시 출력 헤더에 `(개선 R2)`, `(개선 R3)` 등 라운드를 표기한다.
  - 개선할 부분이 없을 때만 최종 완료로 처리한다.
- 산출물: "코드 리뷰 결과"

### (7) 성능·최적화 담당 (Performance Engineer) — 선택
- **성능·최적화 관련 요청이 있을 때만 수행. (6) 리뷰어 전에 실행.**
- 렌더링/리빌드 횟수, 비동기 처리, 캐싱 전략 등을 점검한다.
  - Flutter: `ListView.builder`, `const` 위젯, 상태 범위 최소화 등.
  - API: 디바운싱, pagination, lazy loading, 캐시.
- 산출물: "성능 분석 및 최적화 제안"

### (8) 문서화 담당 (Doc Writer) — 선택
- **최종 정리 요청이 있을 때만 수행. 모든 단계 완료 후 마지막에 실행.**
- 클래스/위젯 역할, 주요 의존성, 설정 방법, 주의사항을 짧게 정리한다.
- GitHub README 또는 Notion에 그대로 복붙 가능한 형태로 작성한다.
- 산출물: "기술 문서 / README 초안"

> **출력 형식**: 항상 아래 순서로 헤더를 구분하여 답변한다.
> ```
> 1️⃣ [UX 설계자 출력]          ← UX 설계 필요 시에만
> 2️⃣ [설계자 출력]
> 3️⃣ [코드 작성자 출력]
> 4️⃣ [코드 디버거 출력]         ← 오류 있을 때만
> 5️⃣ [테스트 작성자 출력]        ← 선택
> 6️⃣ [리뷰어 출력]
> 7️⃣ [성능·최적화 담당 출력]     ← 선택, 6️⃣ 전에 삽입
> 8️⃣ [문서화 담당 출력]          ← 선택, 최종 단계
>
> — 리뷰어에서 개선 발견 시 —
> 2️⃣ [설계자 출력 (개선 R2)]
> 3️⃣ [코드 작성자 출력 (개선 R2)]
> 4️⃣ [코드 디버거 출력 (개선 R2)]
> 6️⃣ [리뷰어 출력 (개선 R2)]
> ```

---

## 브랜드 가이드

- **폰트**: Pretendard (한국어 UI), 영문 서브 텍스트는 SF Pro 시스템 폰트
- **아이콘 스타일**: 선형(Outlined), 두께 1.5~2.0
- **애니메이션**: 셔터 클릭 1.0→0.92 스케일 (150ms spring), 필터 전환 fade 200ms
- **햅틱**: 필터 전환 `selectionClick()`, 촬영 `mediumImpact()`
