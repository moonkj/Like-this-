import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/filter_model.dart';
import '../../../native_plugins/camera_engine/camera_engine.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.imagePath,
    this.assetId,
    this.assetList,
    this.initialIndex,
  });

  final String imagePath;
  final String? assetId;
  /// 갤러리에서 전달된 전체 에셋 목록 (스와이프 탐색용)
  final List<AssetEntity>? assetList;
  /// assetList 내 현재 사진 인덱스
  final int? initialIndex;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  // 효과 값
  double _grain      = 0.0;
  double _vignette   = 0.0;
  double _exposure   = 0.0;
  double _contrast   = 0.0;
  double _lightLeak  = 0.0;
  double _bloom      = 0.0;

  // 필터
  String? _selectedFilterId;
  double  _filterIntensity = 1.0;

  // 탭: 0=필터, 1=효과, 2=자르기
  int _tab = 1;

  // 효과 탭에서 선택된 효과 인덱스
  int _selectedEffect = 0;

  // 크롭
  Rect   _cropRect     = const Rect.fromLTWH(0, 0, 1, 1); // 정규화 (이미지 비례)
  bool   _cropChanged  = false;
  String _cropRatioKey = '자유';
  ui.Image? _decodedImage;
  Size?     _imageSize;

  // 비교 모드
  bool _isComparing   = false;
  bool _isSaving      = false;

  // 스와이프 탐색
  late String _currentPath;
  String? _currentAssetId;
  late PageController _pageCtrl;
  late int _currentIndex;
  AssetType _currentAssetType = AssetType.image;

  // 비디오 재생 (비디오 에셋 전환 시 사용)
  VideoPlayerController? _videoCtrl;

  final GlobalKey     _previewKey  = GlobalKey();
  final GlobalKey     _shareKey    = GlobalKey();

  bool get _isVideo => _currentAssetType == AssetType.video;

  @override
  void initState() {
    super.initState();
    _currentPath    = widget.imagePath;
    _currentAssetId = widget.assetId;
    _currentIndex   = widget.initialIndex ?? 0;
    _pageCtrl = PageController(initialPage: _currentIndex);
    // 초기 에셋 타입 결정
    final list = widget.assetList;
    if (list != null && _currentIndex < list.length) {
      _currentAssetType = list[_currentIndex].type;
    }
    _initCurrentAsset();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  Future<void> _initCurrentAsset() async {
    if (_isVideo) {
      await _initVideo(_currentPath);
    } else {
      await _loadImage(_currentPath);
    }
  }

  Future<void> _initVideo(String path) async {
    await _videoCtrl?.dispose();
    final ctrl = VideoPlayerController.file(File(path));
    await ctrl.initialize();
    ctrl.setLooping(true);
    if (mounted) {
      setState(() => _videoCtrl = ctrl);
      ctrl.play();
    } else {
      ctrl.dispose();
    }
  }

  Future<void> _loadImage([String? path]) async {
    try {
      final bytes = await File(path ?? _currentPath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _decodedImage = frame.image;
          _imageSize = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
        });
      }
    } catch (_) {}
  }

  // ── 효과 정의 ────────────────────────────────────────────────────────────

  List<_EffectDef> get _effects => [
    _EffectDef(label: '노출',   icon: Icons.wb_sunny_outlined,          value: _exposure,  min: -100, max: 100, onChanged: (v) => setState(() => _exposure  = v)),
    _EffectDef(label: '대비',   icon: Icons.contrast,                   value: _contrast,  min: -100, max: 100, onChanged: (v) => setState(() => _contrast  = v)),
    _EffectDef(label: '그레인', icon: Icons.grain_rounded,              value: _grain,     min: 0,    max: 100, onChanged: (v) => setState(() => _grain     = v)),
    _EffectDef(label: '비네팅', icon: Icons.vignette_rounded,           value: _vignette,  min: 0,    max: 100, onChanged: (v) => setState(() => _vignette  = v)),
    _EffectDef(label: '빛번짐', icon: Icons.flare_rounded,              value: _lightLeak, min: 0,    max: 100, onChanged: (v) => setState(() => _lightLeak = v)),
    _EffectDef(label: '글로우', icon: Icons.blur_on_rounded,            value: _bloom,     min: 0,    max: 100, onChanged: (v) => setState(() => _bloom     = v)),
  ];

  bool get _hasChanges =>
      _exposure != 0 || _contrast != 0 || _grain != 0 ||
      _vignette != 0 || _lightLeak != 0 || _bloom != 0 ||
      _selectedFilterId != null || _cropChanged;

  // ── ColorFilter ───────────────────────────────────────────────────────────

  /// 4×5 행렬 값 (20개) — 화면 표시와 네이티브 저장 모두 사용
  List<double> _buildFilterMatrix() {
    final ev   = _exposure / 100.0 * 0.8;
    final c    = 1.0 + _contrast / 100.0 * 1.0;
    final bias = ev * 255 + (1.0 - c) * 127.5;

    if (_selectedFilterId == null) {
      return [
        c, 0, 0, 0, bias,
        0, c, 0, 0, bias,
        0, 0, c, 0, bias,
        0, 0, 0, 1, 0,
      ];
    }

    final tone = _filterTone(_selectedFilterId);
    final fc   = tone[0] * _filterIntensity + (1.0 - _filterIntensity);
    final fb   = tone[1] * _filterIntensity;
    final bwR  = 0.299 * _filterIntensity;
    final bwG  = 0.587 * _filterIntensity;
    final bwB  = 0.114 * _filterIntensity;
    final keep = 1.0 - _filterIntensity;
    return [
      (bwR + keep) * c * fc, bwG * c * fc,          bwB * c * fc,          0, bias + fb,
      bwR * c * fc,          (bwG + keep) * c * fc, bwB * c * fc,          0, bias + fb,
      bwR * c * fc,          bwG * c * fc,          (bwB + keep) * c * fc, 0, bias + fb,
      0, 0, 0, 1, 0,
    ];
  }

  ColorFilter _buildFilter() => ColorFilter.matrix(_buildFilterMatrix());

  List<double> _filterTone(String? id) {
    switch (id) {
      case 'bw_noir':      return [1.35, -18.0];
      case 'bw_soft':      return [0.80,   8.0];
      case 'bw_2k':        return [1.15,  -8.0];
      case 'bw_dust':      return [1.20, -10.0];
      case 'bw_glow':      return [0.90,  15.0];
      case 'bw_paper':     return [1.10,  -5.0];
      case 'bw_porcelain': return [0.85,  12.0];
      case 'bw_silky':     return [0.75,  10.0];
      case 'bw_pure':
      default:             return [1.00,   0.0];
    }
  }

  void _resetAll() {
    setState(() {
      _exposure = 0; _contrast = 0; _grain = 0;
      _vignette = 0; _lightLeak = 0; _bloom = 0;
      _selectedFilterId = null; _filterIntensity = 1.0;
      _cropRect = const Rect.fromLTWH(0, 0, 1, 1);
      _cropChanged = false; _cropRatioKey = '자유';
    });
  }

  // ── 크롭 헬퍼 ────────────────────────────────────────────────────────────

  /// 비율 프리셋 적용
  void _applyRatio(double? ratio) {
    if (ratio == null) return;
    final sz = _imageSize ?? (_isVideo ? _videoCtrl?.value.size : null);
    if (sz == null) return;
    final imgAspect = sz.width / sz.height;
    double nW, nH;
    if (ratio > imgAspect) { nW = 1.0; nH = imgAspect / ratio; }
    else                   { nH = 1.0; nW = ratio / imgAspect; }
    setState(() {
      _cropRect = Rect.fromLTWH((1 - nW) / 2, (1 - nH) / 2, nW, nH);
      _cropChanged = true;
    });
  }

  // ── 저장 / 공유 / 삭제 ────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      // ── 동영상 저장 ─────────────────────────────────────────────────────
      if (_isVideo && !_cropChanged) {
        // 효과 적용 후 프레임별 렌더링 저장 (네이티브 CIFilter 파이프라인)
        final dir  = await getTemporaryDirectory();
        final name = 'likethis_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final outputPath = '${dir.path}/$name';
        final resultPath = await CameraEngine.processAndSaveVideo(
          sourcePath:  _currentPath,
          colorMatrix: _buildFilterMatrix(),
          vignette:    _vignette   / 100.0,
          grain:       _grain      / 100.0,
          lightLeak:   _lightLeak  / 100.0,
          bloom:       _bloom      / 100.0,
          outputPath:  outputPath,
        );
        if (resultPath == null) throw Exception('영상 처리 실패');
        await PhotoManager.editor.saveVideo(File(resultPath), title: name);
        HapticFeedback.lightImpact();
        if (mounted) context.pop();
        return;
      }
      if (_isVideo && _cropChanged) {
        final dir  = await getTemporaryDirectory();
        final name = 'likethis_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final outputPath = '${dir.path}/$name';
        final croppedPath = await CameraEngine.cropVideo(
          inputPath:  _currentPath,
          outputPath: outputPath,
          x:      _cropRect.left,
          y:      _cropRect.top,
          width:  _cropRect.width,
          height: _cropRect.height,
        );
        if (croppedPath == null) throw Exception('Video crop failed');
        await PhotoManager.editor.saveVideo(File(croppedPath), title: name);
        HapticFeedback.lightImpact();
        if (mounted) context.pop();
        return;
      }

      final dir  = await getTemporaryDirectory();
      final name = 'likethis_edit_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outputPath = '${dir.path}/$name';

      // 소스 파일: originFile(원본 해상도) 우선, 없으면 현재 경로
      String sourcePath = _currentPath;
      final list = widget.assetList;
      if (list != null && _currentIndex < list.length) {
        final originFile = await list[_currentIndex].originFile;
        if (originFile != null) sourcePath = originFile.path;
      }

      // 네이티브 CIImage 파이프라인으로 처리 (HEIC/JPEG/PNG 전체 해상도 보장)
      final resultPath = await CameraEngine.processAndSaveImage(
        sourcePath:  sourcePath,
        colorMatrix: _buildFilterMatrix(),
        vignette:    _vignette   / 100.0,
        grain:       _grain      / 100.0,
        lightLeak:   _lightLeak  / 100.0,
        bloom:       _bloom      / 100.0,
        outputPath:  outputPath,
        cropX: _cropChanged ? _cropRect.left   : 0.0,
        cropY: _cropChanged ? _cropRect.top    : 0.0,
        cropW: _cropChanged ? _cropRect.width  : 1.0,
        cropH: _cropChanged ? _cropRect.height : 1.0,
      );
      if (resultPath == null) throw Exception('네이티브 처리 실패');

      await PhotoManager.editor.saveImageWithPath(resultPath, title: name);
      HapticFeedback.lightImpact();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _share() async {
    try {
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final boundary = _previewKey.currentContext!
          .findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/likethis_share_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path)],
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      );
    } catch (_) {
      // 렌더링 실패 시 원본 공유 fallback
      final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(_currentPath)],
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      );
    }
  }

  Future<void> _delete() async {
    if (_currentAssetId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('사진을 삭제하시겠습니까?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: const Text('삭제된 사진은 복구할 수 없습니다.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('취소', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    // 쓰기 권한 확인
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth && !perm.hasAccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진 접근 권한이 필요합니다.'),
              behavior: SnackBarBehavior.floating));
      }
      return;
    }
    final deleted = await PhotoManager.editor.deleteWithIds([_currentAssetId!]);
    if (!mounted) return;
    if (deleted.isNotEmpty) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제에 실패했습니다. iCloud 사진은 사진 앱에서 삭제해주세요.'),
            behavior: SnackBarBehavior.floating));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            SizedBox(height: topPad),
            _buildTopBar(),
            // 사진: Expanded로 남은 공간 채움
            _buildPhotoArea(),
            // 하단 컨트롤 (고정 152dp)
            SizedBox(
              height: 152,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: switch (_tab) {
                  0 => _buildFilterContent(),
                  1 => _buildEffectsContent(),
                  _ => _buildCropContent(),
                },
              ),
            ),
            // 탭 바
            _buildBottomTabBar(botPad),
          ],
        ),
      ),
    );
  }

  // ── 상단 바 ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      child: Row(
        children: [
          // 뒤로가기
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.textPrimary, size: 20),
            onPressed: () => context.pop(),
          ),
          // 리셋 (변경 있을 때)
          if (_hasChanges) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); _resetAll(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: const Text('reset',
                    style: TextStyle(color: AppColors.textSecondary,
                        fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
          const Spacer(),
          // 비교
          _CircleBtn(
            icon: Icons.compare_rounded,
            active: _isComparing,
            onTap: () { HapticFeedback.selectionClick(); setState(() => _isComparing = !_isComparing); },
          ),
          const SizedBox(width: 8),
          // 삭제
          if (_currentAssetId != null) ...[
            _CircleBtn(icon: Icons.delete_outline_rounded,
                iconColor: Colors.red, onTap: _delete),
            const SizedBox(width: 8),
          ],
          // 공유
          _CircleBtn(key: _shareKey, icon: Icons.ios_share_rounded, onTap: _share),
          const SizedBox(width: 8),
          // 저장 (변경 사항 없을 때만 비활성)
          _CircleBtn(
            icon: Icons.download_rounded,
            onTap: (_isVideo && !_hasChanges) ? null : (_isSaving ? null : _save),
            loading: _isSaving,
          ),
        ],
      ),
    );
  }

  // ── 사진 영역 (스와이프 탐색 포함) ──────────────────────────────────────────

  Widget _buildPhotoArea() {
    Widget photoWidget = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: RepaintBoundary(
          key: _previewKey,
          child: _buildPhotoContent(),
        ),
      ),
    );

    final list = widget.assetList;
    if (list == null || list.length <= 1) {
      return Expanded(child: photoWidget);
    }

    // 스와이프 탐색: 필터 탭에서만 활성 (효과 탭은 슬라이더 제스처 충돌 방지, 크롭·비교 모드도 비활성)
    final canSwipe = _tab == 0 && !_isComparing;

    return Expanded(
      child: PageView.builder(
        controller: _pageCtrl,
        physics: canSwipe
            ? const PageScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        scrollBehavior: const _NoThumbScrollBehavior(),
        onPageChanged: (i) async {
          final asset = list[i];
          final file = await asset.file;
          if (file == null || !mounted) return;
          HapticFeedback.selectionClick();
          // 이전 비디오 컨트롤러 정리
          final oldCtrl = _videoCtrl;
          setState(() {
            _currentIndex      = i;
            _currentPath       = file.path;
            _currentAssetId    = asset.id;
            _currentAssetType  = asset.type;
            _decodedImage      = null;
            _imageSize         = null;
            _videoCtrl         = null;
          });
          oldCtrl?.dispose();
          _resetAll();
          if (asset.type == AssetType.video) {
            await _initVideo(file.path);
          } else {
            await _loadImage(file.path);
          }
        },
        itemBuilder: (ctx, i) {
          // 현재 페이지만 실제 콘텐츠, 나머지는 placeholder
          if (i == _currentIndex) {
            return photoWidget;
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: const ColoredBox(color: AppColors.surface),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoContent() {
    // ── 비교 모드 (이미지·비디오 공통) ──────────────────────────────────────
    // 비디오는 컨트롤러 초기화 완료 후에만 비교 모드 진입
    if (_isComparing && (!_isVideo || (_videoCtrl?.value.isInitialized == true))) {
      final filterName = _selectedFilterId == null
          ? '현재'
          : BWFilters.all.firstWhere((f) => f.id == _selectedFilterId,
              orElse: () => BWFilters.all.first).name;
      return _CompareOverlay(
        imagePath: _currentPath,
        colorFilter: _buildFilter(),
        vignetteIntensity: _vignette / 100,
        grainIntensity: _grain / 100,
        videoController: _isVideo ? _videoCtrl : null,
        afterLabel: filterName,
      );
    }

    // ── 비디오 ──────────────────────────────────────────────────────────────
    if (_isVideo) {
      final ctrl = _videoCtrl;
      if (ctrl == null || !ctrl.value.isInitialized) {
        return const ColoredBox(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.silver),
              strokeWidth: 1.5,
            ),
          ),
        );
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: _tab == 2 ? null : () {
              HapticFeedback.selectionClick();
              if (ctrl.value.isPlaying) {
                ctrl.pause();
              } else {
                ctrl.play();
              }
              setState(() {});
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Colors.black),
                Center(
                  child: AspectRatio(
                    aspectRatio: ctrl.value.aspectRatio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColorFiltered(
                          colorFilter: _buildFilter(),
                          child: VideoPlayer(ctrl),
                        ),
                        if (_vignette > 0)
                          IgnorePointer(child: _VignetteOverlay(intensity: _vignette / 100)),
                        if (_grain > 0)
                          IgnorePointer(child: CustomPaint(painter: _GrainPainter(intensity: _grain / 100))),
                        if (_lightLeak > 0)
                          IgnorePointer(child: _LightLeakOverlay(intensity: _lightLeak / 100)),
                        if (_bloom > 0)
                          IgnorePointer(child: _BloomOverlay(intensity: _bloom / 100)),
                      ],
                    ),
                  ),
                ),
                // 크롭 탭이 아닐 때만 일시정지 아이콘 표시
                if (_tab != 2 && !ctrl.value.isPlaying)
                  Center(
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.silver, width: 1.5),
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 32),
                    ),
                  ),
              ],
            ),
          ),
          // 크롭 탭: 비디오 위에 크롭 오버레이
          if (_tab == 2)
            LayoutBuilder(builder: (_, constraints) {
              return _CropOverlay(
                containerSize: constraints.biggest,
                imageSize: ctrl.value.size,
                cropRect: _cropRect,
                onCropChanged: (r) => setState(() {
                  _cropRect = r; _cropChanged = true; _cropRatioKey = '자유';
                }),
              );
            }),
        ],
      );
    }

    // 크롭 탭: 풀 이미지 + 오버레이
    if (_tab == 2) {
      return LayoutBuilder(builder: (_, constraints) {
        final size = constraints.biggest;
        return Stack(fit: StackFit.expand, children: [
          ColorFiltered(
            colorFilter: _buildFilter(),
            child: Image.file(File(_currentPath),
                fit: BoxFit.contain, gaplessPlayback: true),
          ),
          if (_imageSize != null)
            _CropOverlay(
              containerSize: size,
              imageSize: _imageSize!,
              cropRect: _cropRect,
              onCropChanged: (r) => setState(() {
                _cropRect = r; _cropChanged = true; _cropRatioKey = '자유';
              }),
            ),
        ]);
      });
    }

    // 크롭 적용 상태: CustomPainter로 크롭된 이미지 표시
    if (_cropChanged && _decodedImage != null) {
      return CustomPaint(
        painter: _CroppedImagePainter(
          image: _decodedImage!,
          srcRect: Rect.fromLTRB(
            _cropRect.left  * _decodedImage!.width,
            _cropRect.top   * _decodedImage!.height,
            _cropRect.right * _decodedImage!.width,
            _cropRect.bottom* _decodedImage!.height,
          ),
          colorFilter: _buildFilter(),
        ),
        child: Stack(children: [
          if (_vignette > 0)
            Positioned.fill(child: IgnorePointer(
                child: _VignetteOverlay(intensity: _vignette / 100))),
          if (_grain > 0)
            Positioned.fill(child: IgnorePointer(
                child: CustomPaint(painter: _GrainPainter(intensity: _grain / 100)))),
          if (_lightLeak > 0)
            Positioned.fill(child: IgnorePointer(
                child: _LightLeakOverlay(intensity: _lightLeak / 100))),
          if (_bloom > 0)
            Positioned.fill(child: IgnorePointer(
                child: _BloomOverlay(intensity: _bloom / 100))),
        ]),
      );
    }

    // 일반 표시
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: AppColors.surface),
        ColorFiltered(
          colorFilter: _buildFilter(),
          child: Image.file(File(_currentPath),
              fit: BoxFit.contain, width: double.infinity, height: double.infinity,
              gaplessPlayback: true),
        ),
        // 효과 오버레이는 실제 이미지 영역에만 (letterbox 제외)
        if ((_vignette > 0 || _grain > 0 || _lightLeak > 0 || _bloom > 0) && _imageSize != null)
          Center(
            child: AspectRatio(
              aspectRatio: _imageSize!.width / _imageSize!.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_vignette > 0)
                    IgnorePointer(child: _VignetteOverlay(intensity: _vignette / 100)),
                  if (_grain > 0)
                    IgnorePointer(child: CustomPaint(
                        painter: _GrainPainter(intensity: _grain / 100))),
                  if (_lightLeak > 0)
                    IgnorePointer(child: _LightLeakOverlay(intensity: _lightLeak / 100)),
                  if (_bloom > 0)
                    IgnorePointer(child: _BloomOverlay(intensity: _bloom / 100)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── 필터 탭 ───────────────────────────────────────────────────────────────

  Widget _buildFilterContent() {
    return Container(
      key: const ValueKey('filter'),
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 필터 스크롤 (100dp)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: BWFilters.all.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _FilterItem(
                    label: '없음', thumbPath: null,
                    selected: _selectedFilterId == null,
                    onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedFilterId = null); },
                  );
                }
                final f = BWFilters.all[i - 1];
                return _FilterItem(
                  label: f.name,
                  thumbPath: 'assets/thumbnails/${f.id}.jpg',
                  selected: _selectedFilterId == f.id,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedFilterId = f.id;
                      _filterIntensity = f.defaultIntensity;
                    });
                  },
                );
              },
            ),
          ),
          // 강도 슬라이더 (필터 선택 시)
          if (_selectedFilterId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  Expanded(child: _EditorSlider(
                    value: _filterIntensity, min: 0, max: 1,
                    divisions: 100,
                    onChanged: (v) => setState(() => _filterIntensity = v),
                  )),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 38,
                    child: Text('${(_filterIntensity * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: AppColors.textSecondary,
                            fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 36),
        ],
      ),
    );
  }

  // ── 효과 탭 ───────────────────────────────────────────────────────────────

  Widget _buildEffectsContent() {
    final effects = _effects;
    final sel     = effects[_selectedEffect];

    return Container(
      key: const ValueKey('effects'),
      color: Colors.black,
      child: Column(
        children: [
          // 효과 아이콘 행 (68dp)
          SizedBox(
            height: 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(effects.length, (i) {
                final e     = effects[i];
                final isSel = i == _selectedEffect;
                final val   = e.value.round();
                final valStr = val == 0 ? '+0'
                    : (val > 0 ? '+$val' : '$val');

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedEffect = i); },
                  child: SizedBox(
                    width: 52,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 아이콘 or 값 배지 (28dp)
                        SizedBox(
                          height: 28,
                          child: Center(
                            child: isSel
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.silver.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                          color: AppColors.silver, width: 0.5),
                                    ),
                                    child: Text(valStr,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                                  )
                                : Icon(e.icon,
                                    color: AppColors.textSecondary, size: 20),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 라벨 (11dp)
                        Text(e.label,
                            style: TextStyle(
                              color: isSel ? AppColors.textPrimary : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                            )),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          // 슬라이더
          Padding(
            padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
            child: _EditorSlider(
              key: ValueKey(_selectedEffect),
              value: sel.value, min: sel.min, max: sel.max,
              onChanged: sel.onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ── 자르기 탭 ─────────────────────────────────────────────────────────────

  Widget _buildCropContent() {
    const ratios = <String, double?>{
      '자유': null, '1:1': 1.0, '3:4': 3/4, '4:3': 4/3, '16:9': 16/9, '9:16': 9/16,
    };
    return Container(
      key: const ValueKey('crop'),
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 비율 버튼 행
          SizedBox(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ratios.entries.map((e) {
                final sel = _cropRatioKey == e.key;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _cropRatioKey = e.key);
                    if (e.value != null) _applyRatio(e.value);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.silver.withValues(alpha: 0.15) : null,
                      borderRadius: BorderRadius.circular(100),
                      border: sel ? Border.all(color: AppColors.silver, width: 0.5) : null,
                    ),
                    child: Text(e.key,
                        style: TextStyle(
                          color: sel ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ),
                );
              }).toList(),
            ),
          ),
          // 초기화 버튼
          if (_cropChanged)
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _cropRect = const Rect.fromLTWH(0, 0, 1, 1);
                  _cropChanged = false; _cropRatioKey = '자유';
                });
              },
              child: const Text('크롭 초기화',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            )
          else
            const SizedBox(height: 36),
        ],
      ),
    );
  }

  // ── 하단 탭 바 ────────────────────────────────────────────────────────────

  Widget _buildBottomTabBar(double botPad) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      padding: EdgeInsets.fromLTRB(0, 8, 0, botPad > 0 ? botPad : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BottomTab(icon: Icons.auto_fix_high_rounded, label: '필터',  selected: _tab == 0, hasChanges: _selectedFilterId != null, onTap: () { HapticFeedback.selectionClick(); setState(() => _tab = 0); }),
          _BottomTab(icon: Icons.tune_rounded,          label: '효과',  selected: _tab == 1, hasChanges: _exposure != 0 || _contrast != 0 || _grain != 0 || _vignette != 0 || _lightLeak != 0 || _bloom != 0, onTap: () { HapticFeedback.selectionClick(); setState(() => _tab = 1); }),
          _BottomTab(icon: Icons.crop_rounded,          label: '자르기', selected: _tab == 2, hasChanges: false, onTap: () { HapticFeedback.selectionClick(); setState(() => _tab = 2); }),
        ],
      ),
    );
  }
}

// ── 비교 오버레이 (Before/After split) ────────────────────────────────────────

class _CompareOverlay extends StatefulWidget {
  const _CompareOverlay({
    required this.imagePath,
    required this.colorFilter,
    required this.vignetteIntensity,
    required this.grainIntensity,
    this.videoController,
    this.afterLabel = '현재',
  });
  final String imagePath;
  final ColorFilter colorFilter;
  final double vignetteIntensity;
  final double grainIntensity;
  final VideoPlayerController? videoController;
  final String afterLabel;

  @override
  State<_CompareOverlay> createState() => _CompareOverlayState();
}

class _CompareOverlayState extends State<_CompareOverlay> {
  double _splitX = 0.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final splitPx = w * _splitX;

      return GestureDetector(
        onHorizontalDragUpdate: (d) {
          setState(() => _splitX = (_splitX + d.delta.dx / w).clamp(0.05, 0.95));
        },
        child: Stack(clipBehavior: Clip.none, children: [
          // Before: 원본 (전체, 동일 크기/정렬)
          Positioned.fill(
            child: widget.videoController != null
                ? FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: widget.videoController!.value.size.width,
                      height: widget.videoController!.value.size.height,
                      child: VideoPlayer(widget.videoController!),
                    ),
                  )
                : Image.file(File(widget.imagePath),
                    fit: BoxFit.contain, gaplessPlayback: true),
          ),
          // After: 필터 적용, CustomClipper로 오른쪽만 노출
          Positioned.fill(
            child: ClipRect(
              clipper: _SplitClipper(_splitX),
              child: ColorFiltered(
                colorFilter: widget.colorFilter,
                child: widget.videoController != null
                    ? FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: widget.videoController!.value.size.width,
                          height: widget.videoController!.value.size.height,
                          child: VideoPlayer(widget.videoController!),
                        ),
                      )
                    : Image.file(File(widget.imagePath),
                        fit: BoxFit.contain, gaplessPlayback: true),
              ),
            ),
          ),
          // 분할선
          Positioned(left: splitPx - 1, top: 0, width: 2, height: h,
            child: Container(color: Colors.white.withValues(alpha: 0.9))),
          // 핸들
          Positioned(
            left: splitPx - 14, top: h / 2 - 14,
            child: Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.compare_arrows_rounded,
                  color: Colors.black54, size: 16),
            ),
          ),
          // Before 레이블 (핸들 왼쪽)
          Positioned(
            left: splitPx - 14 - 8 - 56,
            top: h / 2 - 13,
            child: _SplitLabel(text: '원본')),
          // After 레이블 (핸들 오른쪽)
          Positioned(
            left: splitPx + 14 + 8,
            top: h / 2 - 13,
            child: _SplitLabel(text: widget.afterLabel)),
        ]),
      );
    });
  }
}

class _SplitLabel extends StatelessWidget {
  const _SplitLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(text,
        style: const TextStyle(color: Colors.white,
            fontSize: 12, fontWeight: FontWeight.w500)),
  );
}

// ── 상단 원형 버튼 ────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.active = false,
    this.loading = false,
    this.iconColor,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;
  final bool loading;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: active ? AppColors.silver.withValues(alpha: 0.15) : AppColors.surfaceElevated,
        shape: BoxShape.circle,
        border: Border.all(
            color: active ? AppColors.silver : AppColors.border, width: 0.5),
      ),
      child: loading
          ? const Padding(padding: EdgeInsets.all(9),
              child: CircularProgressIndicator(strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.silver)))
          : Icon(icon,
              color: iconColor ?? AppColors.textPrimary, size: 18),
    ),
  );
}

// ── 하단 탭 버튼 ──────────────────────────────────────────────────────────────

class _BottomTab extends StatelessWidget {
  const _BottomTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.hasChanges,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final bool hasChanges;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(color: color, fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
              ],
            ),
            // 변경 있을 때 인디케이터 dot
            if (hasChanges)
              Positioned(
                top: -2, right: -8,
                child: Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                      color: AppColors.silver, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 필터 아이템 ───────────────────────────────────────────────────────────────

class _FilterItem extends StatelessWidget {
  const _FilterItem({
    required this.label,
    required this.thumbPath,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String? thumbPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width:  selected ? 58 : 52,
            height: selected ? 78 : 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(selected ? 14 : 12),
              border: Border.all(
                color: selected ? AppColors.silver : AppColors.border,
                width: selected ? 2.0 : 0.5,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: AppColors.silver.withValues(alpha: 0.25),
                        blurRadius: 6)]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(selected ? 12 : 10),
              child: thumbPath != null
                  ? Image.asset(thumbPath!, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.surface,
                      child: Icon(Icons.block_rounded,
                          color: selected ? AppColors.silver : AppColors.textDisabled,
                          size: 22)),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 58,
            child: Text(label,
                maxLines: 2, textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                )),
          ),
        ],
      ),
    ),
  );
}

// ── 슬라이더 ─────────────────────────────────────────────────────────────────

class _EditorSlider extends StatelessWidget {
  const _EditorSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions = 200,
  });
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int divisions;

  @override
  Widget build(BuildContext context) => SliderTheme(
    data: SliderThemeData(
      trackHeight: 2,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      overlayShape: SliderComponentShape.noOverlay,
      activeTrackColor: AppColors.silver,
      inactiveTrackColor: AppColors.border,
      thumbColor: AppColors.white,
    ),
    child: Slider(
      value: value.clamp(min, max),
      min: min, max: max,
      divisions: divisions,
      onChanged: onChanged,
    ),
  );
}

// ── 효과 정의 데이터 클래스 ───────────────────────────────────────────────────

class _EffectDef {
  const _EffectDef({
    required this.label, required this.icon, required this.value,
    required this.min, required this.max, required this.onChanged,
  });
  final String label;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
}

// ── 비네팅 오버레이 ───────────────────────────────────────────────────────────

class _VignetteOverlay extends StatelessWidget {
  const _VignetteOverlay({required this.intensity});
  final double intensity;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.center, radius: 1.0,
        colors: [Colors.transparent,
            Colors.black.withValues(alpha: intensity * 0.85)],
        stops: const [0.35, 1.0],
      ),
    ),
  );
}

// ── 그레인 페인터 ─────────────────────────────────────────────────────────────

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.intensity});
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random();
    final count = (size.width * size.height * intensity * 0.10).toInt();
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < count; i++) {
      final bright = rng.nextBool();
      paint.color = (bright ? Colors.white : Colors.black)
          .withValues(alpha: 0.10 + rng.nextDouble() * intensity * 0.55);
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.35 + rng.nextDouble() * 0.65, paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.intensity != intensity;
}

// ── 빛번짐 오버레이 ───────────────────────────────────────────────────────────

class _LightLeakOverlay extends StatelessWidget {
  const _LightLeakOverlay({required this.intensity});
  final double intensity;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(-0.8, -0.8),
        radius: 1.5,
        colors: [
          Colors.orange.withValues(alpha: intensity * 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ),
    ),
  );
}

// ── 글로우 오버레이 ───────────────────────────────────────────────────────────

class _BloomOverlay extends StatelessWidget {
  const _BloomOverlay({required this.intensity});
  final double intensity;

  @override
  Widget build(BuildContext context) => BackdropFilter(
    filter: ui.ImageFilter.blur(
      sigmaX: intensity * 10.0,
      sigmaY: intensity * 10.0,
    ),
    blendMode: BlendMode.screen,
    child: Container(
      color: Colors.white.withValues(alpha: intensity * 0.18),
    ),
  );
}

// ── 크롭 오버레이 ─────────────────────────────────────────────────────────────

class _CropOverlay extends StatelessWidget {
  const _CropOverlay({
    required this.containerSize,
    required this.imageSize,
    required this.cropRect,
    required this.onCropChanged,
  });
  final Size containerSize;
  final Size imageSize;
  final Rect cropRect;
  final ValueChanged<Rect> onCropChanged;

  ({double offX, double offY, double rW, double rH}) _layout() {
    final ia = imageSize.width / imageSize.height;
    final ca = containerSize.width / containerSize.height;
    double rW, rH;
    if (ia > ca) { rW = containerSize.width; rH = rW / ia; }
    else         { rH = containerSize.height; rW = rH * ia; }
    return (offX: (containerSize.width - rW) / 2, offY: (containerSize.height - rH) / 2,
        rW: rW, rH: rH);
  }

  Rect _toContainer() {
    final l = _layout();
    return Rect.fromLTRB(
      l.offX + cropRect.left  * l.rW, l.offY + cropRect.top    * l.rH,
      l.offX + cropRect.right * l.rW, l.offY + cropRect.bottom * l.rH,
    );
  }

  Rect _fromContainerDelta(Rect current, Offset delta, String corner) {
    final l = _layout();
    double left = current.left, top = current.top,
        right = current.right, bottom = current.bottom;
    const minSize = 40.0;
    if (corner == 'tl') {
      left  = (left  + delta.dx).clamp(l.offX, right - minSize);
      top   = (top   + delta.dy).clamp(l.offY, bottom - minSize);
    } else if (corner == 'tr') {
      right = (right + delta.dx).clamp(left + minSize, l.offX + l.rW);
      top   = (top   + delta.dy).clamp(l.offY, bottom - minSize);
    } else if (corner == 'bl') {
      left   = (left   + delta.dx).clamp(l.offX, right - minSize);
      bottom = (bottom + delta.dy).clamp(top + minSize, l.offY + l.rH);
    } else {
      right  = (right  + delta.dx).clamp(left + minSize, l.offX + l.rW);
      bottom = (bottom + delta.dy).clamp(top + minSize, l.offY + l.rH);
    }
    return Rect.fromLTRB(
      ((left  - l.offX) / l.rW).clamp(0.0, 1.0),
      ((top   - l.offY) / l.rH).clamp(0.0, 1.0),
      ((right - l.offX) / l.rW).clamp(0.0, 1.0),
      ((bottom- l.offY) / l.rH).clamp(0.0, 1.0),
    );
  }

  /// 크롭 영역 전체 이동 (크기 유지)
  Rect _moveRect(Rect current, Offset delta) {
    final l = _layout();
    final cW = current.width;
    final cH = current.height;
    final newLeft   = (current.left   + delta.dx).clamp(l.offX, l.offX + l.rW - cW);
    final newTop    = (current.top    + delta.dy).clamp(l.offY, l.offY + l.rH - cH);
    return Rect.fromLTRB(
      ((newLeft       - l.offX) / l.rW).clamp(0.0, 1.0),
      ((newTop        - l.offY) / l.rH).clamp(0.0, 1.0),
      ((newLeft + cW  - l.offX) / l.rW).clamp(0.0, 1.0),
      ((newTop  + cH  - l.offY) / l.rH).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cRect = _toContainer();
    return Stack(fit: StackFit.expand, children: [
      // 어두운 마스크 (크롭 외부)
      CustomPaint(
        painter: _CropMaskPainter(cRect, containerSize),
        size: containerSize,
      ),
      // 크롭 영역 내부 드래그 → 이동
      Positioned(
        left: cRect.left, top: cRect.top,
        width: cRect.width, height: cRect.height,
        child: GestureDetector(
          onPanUpdate: (d) => onCropChanged(_moveRect(cRect, d.delta)),
          child: CustomPaint(painter: _CropGridPainter()),
        ),
      ),
      // 코너 핸들 (L자형, 드래그 우선순위 높음)
      for (final corner in ['tl', 'tr', 'bl', 'br'])
        _CropHandle(
          cropRect: cRect,
          corner: corner,
          onDelta: (d) => onCropChanged(_fromContainerDelta(cRect, d, corner)),
        ),
    ]);
  }
}

class _CropMaskPainter extends CustomPainter {
  const _CropMaskPainter(this.cropRect, this.size);
  final Rect cropRect;
  final Size size;

  @override
  void paint(Canvas canvas, Size sz) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final full = Rect.fromLTWH(0, 0, sz.width, sz.height);
    final path = Path()
      ..addRect(full)
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
    // 크롭 테두리
    canvas.drawRect(cropRect, Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(_CropMaskPainter old) => old.cropRect != cropRect;
}

class _CropGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    // 3×3 격자
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(Offset(size.width * i / 3, 0),
          Offset(size.width * i / 3, size.height), paint);
      canvas.drawLine(Offset(0, size.height * i / 3),
          Offset(size.width, size.height * i / 3), paint);
    }
  }
  @override
  bool shouldRepaint(_CropGridPainter _) => false;
}

class _CropHandle extends StatelessWidget {
  const _CropHandle({
    required this.cropRect, required this.corner, required this.onDelta,
  });
  final Rect cropRect;
  final String corner;
  final ValueChanged<Offset> onDelta;

  @override
  Widget build(BuildContext context) {
    const s = 24.0; // 핸들 터치 영역
    const len = 20.0; // L자 길이
    const t = 3.0;   // L자 두께
    final left = corner.contains('l') ? cropRect.left - s / 2 : cropRect.right - s / 2;
    final top  = corner.contains('t') ? cropRect.top  - s / 2 : cropRect.bottom - s / 2;
    return Positioned(
      left: left, top: top, width: s, height: s,
      child: GestureDetector(
        onPanUpdate: (d) => onDelta(d.delta),
        child: CustomPaint(
          painter: _LHandlePainter(corner, len, t),
          size: const Size(s, s),
        ),
      ),
    );
  }
}

class _LHandlePainter extends CustomPainter {
  const _LHandlePainter(this.corner, this.len, this.t);
  final String corner; final double len, t;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white..strokeWidth = t..style = PaintingStyle.fill;
    final cx = size.width / 2, cy = size.height / 2;
    final sx = corner.contains('l') ? -1.0 : 1.0;
    final sy = corner.contains('t') ? -1.0 : 1.0;
    // 가로
    canvas.drawRect(Rect.fromLTWH(cx, cy - t / 2, sx * len, t), p);
    // 세로
    canvas.drawRect(Rect.fromLTWH(cx - t / 2, cy, t, sy * len), p);
  }
  @override
  bool shouldRepaint(_LHandlePainter _) => false;
}

// ── 크롭 이미지 페인터 ────────────────────────────────────────────────────────

class _CroppedImagePainter extends CustomPainter {
  const _CroppedImagePainter({
    required this.image, required this.srcRect, required this.colorFilter,
  });
  final ui.Image image;
  final Rect srcRect;
  final ColorFilter colorFilter;

  @override
  void paint(Canvas canvas, Size size) {
    final srcAspect = srcRect.width / srcRect.height;
    final dstAspect = size.width / size.height;
    double dW, dH, dX, dY;
    if (srcAspect > dstAspect) {
      dW = size.width; dH = size.width / srcAspect;
      dX = 0;          dY = (size.height - dH) / 2;
    } else {
      dH = size.height; dW = size.height * srcAspect;
      dY = 0;           dX = (size.width - dW) / 2;
    }
    canvas.drawImageRect(image, srcRect,
        Rect.fromLTWH(dX, dY, dW, dH),
        Paint()..colorFilter = colorFilter);
  }

  @override
  bool shouldRepaint(_CroppedImagePainter old) =>
      old.image != image || old.srcRect != srcRect || old.colorFilter != colorFilter;
}

// ── 비교 오버레이용 클리퍼 ─────────────────────────────────────────────────────

class _SplitClipper extends CustomClipper<Rect> {
  const _SplitClipper(this.splitX);
  final double splitX;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(
    size.width * splitX, 0,
    size.width * (1 - splitX), size.height,
  );

  @override
  bool shouldReclip(_SplitClipper old) => old.splitX != splitX;
}

// ── 스크롤 오버스크롤 효과 제거 (PageView 전용) ────────────────────────────────
class _NoThumbScrollBehavior extends ScrollBehavior {
  const _NoThumbScrollBehavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const PageScrollPhysics();
  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}
