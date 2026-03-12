import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/filter_model.dart';

/// 갤러리 화면 — Like It! 구조 기반, Like This 색상 적용
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<AssetEntity> _assets = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _permissionDenied = false;

  static const int _pageSize = 60;
  int _currentPage = 0;
  AssetPathEntity? _album;

  // 다중 선택 모드
  bool _isMultiSelectMode = false;
  final Set<String> _selectedIds = {};

  // 일괄 필터 처리
  bool _isProcessing = false;
  int _processedCount = 0;
  int _totalCount = 0;

  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()..addListener(_onScroll);
    _loadPhotos();
    PhotoManager.addChangeCallback(_onPhotosChanged);
    PhotoManager.startChangeNotify();
  }

  @override
  void dispose() {
    _scroll.dispose();
    PhotoManager.removeChangeCallback(_onPhotosChanged);
    PhotoManager.stopChangeNotify();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 400) {
      _loadMorePhotos();
    }
  }

  void _onPhotosChanged(MethodCall call) {
    if (mounted && !_isLoading) _quietReload();
  }

  Future<void> _quietReload() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
    );
    if (albums.isEmpty || !mounted) return;
    _album = albums.first;
    _currentPage = 0;
    _hasMore = true;
    final assets = await _album!.getAssetListPaged(
        page: 0, size: _pageSize);
    if (mounted) setState(() => _assets = assets);
  }

  Future<void> _loadPhotos() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      if (mounted) setState(() { _permissionDenied = true; _isLoading = false; });
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
    );
    if (albums.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _album = albums.first;
    final assets = await _album!.getAssetListPaged(
        page: 0, size: _pageSize);
    _currentPage = 0;
    _hasMore = assets.length >= _pageSize;
    if (mounted) setState(() { _assets = assets; _isLoading = false; });
  }

  Future<void> _loadMorePhotos() async {
    if (_isLoadingMore || !_hasMore || _album == null) return;
    setState(() => _isLoadingMore = true);
    final nextPage = _currentPage + 1;
    final more = await _album!.getAssetListPaged(
        page: nextPage, size: _pageSize);
    if (!mounted) return;
    setState(() {
      _assets = [..._assets, ...more];
      _currentPage = nextPage;
      _hasMore = more.length >= _pageSize;
      _isLoadingMore = false;
    });
  }

  Future<void> _selectAsset(AssetEntity asset) async {
    if (_isMultiSelectMode) {
      HapticFeedback.selectionClick();
      setState(() {
        if (_selectedIds.contains(asset.id)) {
          _selectedIds.remove(asset.id);
        } else {
          _selectedIds.add(asset.id);
        }
      });
      return;
    }

    final file = await asset.file;
    if (file == null || !mounted) return;

    // 이미지·비디오 모두 에디터로 전달 (에디터에서 타입별 처리)
    final index = _assets.indexWhere((a) => a.id == asset.id);
    context.push('/editor', extra: {
      'path': file.path,
      'assetId': asset.id,
      'assetList': _assets,
      'index': index,
    });
  }

  void _toggleMultiSelectMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      _selectedIds.clear();
    });
  }

  // ── 필터 파이프라인 (에디터와 동일) ──────────────────────────────────────

  ColorFilter _buildColorFilter(FilterModel filter, double intensity) {
    final tone = _filterTone(filter.id);
    final fc   = tone[0] * intensity + (1.0 - intensity);
    final fb   = tone[1] * intensity;
    final bwR  = 0.299 * intensity;
    final bwG  = 0.587 * intensity;
    final bwB  = 0.114 * intensity;
    final keep = 1.0 - intensity;
    return ColorFilter.matrix([
      (bwR + keep) * fc, bwG * fc,          bwB * fc,          0, fb,
      bwR * fc,          (bwG + keep) * fc, bwB * fc,          0, fb,
      bwR * fc,          bwG * fc,          (bwB + keep) * fc, 0, fb,
      0, 0, 0, 1, 0,
    ]);
  }

  List<double> _filterTone(String id) {
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

  // ── 일괄 필터 적용 ────────────────────────────────────────────────────────

  Future<void> _showFilterPanel() async {
    if (_selectedIds.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _FilterPickerSheet(
        onApply: (filter, intensity) {
          Navigator.of(ctx).pop();
          _applyFilterToSelected(filter, intensity);
        },
      ),
    );
  }

  Future<void> _applyFilterToSelected(FilterModel filter, double intensity) async {
    final selected = _assets.where((a) => _selectedIds.contains(a.id)).toList();
    final videos = selected.where((a) => a.type == AssetType.video).toList();
    final images = selected.where((a) => a.type == AssetType.image).toList();

    if (images.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('이미지가 없습니다. 동영상은 처리할 수 없습니다.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() {
      _isProcessing = true;
      _processedCount = 0;
      _totalCount = images.length;
    });

    final colorFilter = _buildColorFilter(filter, intensity);
    final vignetteStrength = filter.defaultVignette / 100 * 0.85;
    final dir = await getTemporaryDirectory();

    for (final asset in images) {
      final file = await asset.file;
      if (file == null) continue;

      try {
        final bytes = await file.readAsBytes();
        final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        final descriptor = await ui.ImageDescriptor.encoded(buffer);
        final codec = await descriptor.instantiateCodec();
        final frame = await codec.getNextFrame();
        final img = frame.image;
        final w = img.width.toDouble();
        final h = img.height.toDouble();

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));
        canvas.drawImage(img, Offset.zero, Paint()..colorFilter = colorFilter);

        if (filter.defaultVignette > 0) {
          final vPaint = Paint()
            ..shader = RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [Colors.transparent, Colors.black.withValues(alpha: vignetteStrength)],
              stops: const [0.35, 1.0],
            ).createShader(Rect.fromLTWH(0, 0, w, h));
          canvas.drawRect(Rect.fromLTWH(0, 0, w, h), vPaint);
        }

        final picture = recorder.endRecording();
        final rendered = await picture.toImage(img.width, img.height);
        final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
        img.dispose();

        final name = 'likethis_batch_${DateTime.now().millisecondsSinceEpoch}_$_processedCount.png';
        final outFile = File('${dir.path}/$name');
        await outFile.writeAsBytes(byteData!.buffer.asUint8List());
        await PhotoManager.editor.saveImageWithPath(outFile.path, title: name);
        if (mounted) setState(() => _processedCount++);
      } catch (_) {
        // 개별 실패는 스킵 (진행 카운트 포함)
        if (mounted) setState(() => _processedCount++);
      }
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isMultiSelectMode = false;
      _selectedIds.clear();
    });

    String msg = '${images.length}장 필터 적용 완료';
    if (videos.isNotEmpty) msg += ' (동영상 ${videos.length}개 건너뜀)';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.surfaceElevated,
      behavior: SnackBarBehavior.floating,
    ));

    _quietReload();
  }

  Future<void> _shareSelected() async {
    if (_selectedIds.isEmpty) return;
    final selected = _assets.where((a) => _selectedIds.contains(a.id)).toList();
    final files = <XFile>[];
    for (final asset in selected) {
      final file = await asset.file;
      if (file != null) files.add(XFile(file.path));
    }
    if (files.isEmpty) return;
    await Share.shareXFiles(files);
  }

  Future<void> _confirmAndDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(
          '$count장을 삭제하시겠습니까?',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        content: const Text(
          '삭제된 사진은 복구할 수 없습니다.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ids = _selectedIds.toList();
    await PhotoManager.editor.deleteWithIds(ids);
    if (!mounted) return;

    final idsToRemove = ids.toSet();
    setState(() {
      _assets.removeWhere((a) => idsToRemove.contains(a.id));
      _isMultiSelectMode = false;
      _selectedIds.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${ids.length}장 삭제됨'),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(child: _buildBody()),
              _buildBottomTabBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── 상단 바 ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _isMultiSelectMode ? Icons.close_rounded : Icons.arrow_back_ios_rounded,
                  color: _isProcessing ? AppColors.textDisabled : AppColors.textPrimary,
                  size: 20,
                ),
                onPressed: _isProcessing
                    ? null
                    : _isMultiSelectMode ? _toggleMultiSelectMode : () => context.pop(),
              ),
              Expanded(
                child: _isMultiSelectMode
                    ? Text(
                        _isProcessing
                            ? '$_processedCount / $_totalCount 처리 중...'
                            : '${_selectedIds.length}장 선택됨',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : const Text(
                        'LIKE THIS',
                        style: TextStyle(
                          color: AppColors.silver,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3.5,
                        ),
                      ),
              ),

              // 일반 모드: 선택 버튼
              if (!_isMultiSelectMode)
                TextButton(
                  onPressed: _toggleMultiSelectMode,
                  child: const Text(
                    '선택',
                    style: TextStyle(color: AppColors.silver, fontSize: 15),
                  ),
                ),

              // 다중선택 모드 + 항목 선택됨: 공유 → 필터 → 삭제
              if (_isMultiSelectMode && _selectedIds.isNotEmpty && !_isProcessing) ...[
                _topCircleBtn(Icons.ios_share_rounded, onTap: _shareSelected),
                const SizedBox(width: 8),
                _topCircleBtn(Icons.auto_fix_high_rounded, onTap: _showFilterPanel),
                const SizedBox(width: 8),
                _topCircleBtn(Icons.delete_outline_rounded, color: Colors.red, onTap: _confirmAndDelete),
              ],
            ],
          ),
        ),

        // 처리 중 진행 바
        if (_isProcessing)
          LinearProgressIndicator(
            value: _totalCount > 0 ? _processedCount / _totalCount : null,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation(AppColors.silver),
            minHeight: 2,
          ),
      ],
    );
  }

  Widget _topCircleBtn(IconData icon, {Color? color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Icon(icon, color: color ?? AppColors.textPrimary, size: 18),
      ),
    );
  }

  // ── 하단 탭 바 ────────────────────────────────────────────────────────────

  Widget _buildBottomTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _bottomTab(Icons.photo_library_rounded, '앨범', selected: true),
          GestureDetector(
            onTap: () => context.pop(),
            child: _bottomTab(Icons.camera_alt_rounded, '카메라', selected: false),
          ),
        ],
      ),
    );
  }

  Widget _bottomTab(IconData icon, String label, {required bool selected}) {
    final color = selected ? AppColors.textPrimary : AppColors.textSecondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ── 바디 ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.silver),
          strokeWidth: 1.5,
        ),
      );
    }

    if (_permissionDenied) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_outlined, color: AppColors.textDisabled, size: 48),
            const SizedBox(height: 16),
            const Text('사진 접근 권한이 필요합니다',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => PhotoManager.openSetting(),
              child: const Text('설정에서 허용',
                  style: TextStyle(color: AppColors.silver)),
            ),
          ],
        ),
      );
    }

    if (_assets.isEmpty) {
      return const Center(
        child: Text('사진이 없습니다',
            style: TextStyle(color: AppColors.textDisabled)),
      );
    }

    return _buildGrid();
  }

  // ── 3컬럼 그리드 ──────────────────────────────────────────────────────────

  Widget _buildGrid() {
    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final asset = _assets[index];
              final isSelected = _selectedIds.contains(asset.id);
              return _AssetThumbnail(
                key: ValueKey(asset.id),
                asset: asset,
                isSelected: isSelected,
                isMultiSelectMode: _isMultiSelectMode,
                onTap: () => _selectAsset(asset),
                onLongPress: () async {
                  final file = await asset.file;
                  if (file == null || !mounted) return;
                  await Share.shareXFiles([XFile(file.path)]);
                },
              );
            },
            childCount: _assets.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
        ),

        // 페이지네이션 로딩 인디케이터
        if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(AppColors.silver),
                  ),
                ),
              ),
            ),
          ),

        // 바닥 여백
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
      ],
    );
  }
}

// ── 썸네일 위젯 ───────────────────────────────────────────────────────────────

class _AssetThumbnail extends StatefulWidget {
  const _AssetThumbnail({
    super.key,
    required this.asset,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onTap,
    this.onLongPress,
  });

  final AssetEntity asset;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<_AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<_AssetThumbnail> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(_AssetThumbnail old) {
    super.didUpdateWidget(old);
    if (old.asset.id != widget.asset.id) {
      setState(() => _bytes = null);
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    final bytes = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(180, 180),
      quality: 70,
    );
    if (mounted) setState(() => _bytes = bytes);
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 썸네일
            _bytes != null
                ? Image.memory(_bytes!, fit: BoxFit.cover)
                : const ColoredBox(color: AppColors.surface),

            // 동영상 재생시간 뱃지
            if (widget.asset.type == AssetType.video)
              Positioned(
                bottom: 5, left: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(widget.asset.duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            // 다중 선택 체크박스
            if (widget.isMultiSelectMode)
              Positioned(
                top: 6, right: 6,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isSelected
                        ? AppColors.silver
                        : Colors.transparent,
                    border: Border.all(
                      color: widget.isSelected ? AppColors.silver : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: widget.isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.black, size: 14)
                      : null,
                ),
              ),

            // 선택 시 어두운 오버레이
            if (widget.isMultiSelectMode && widget.isSelected)
              const ColoredBox(color: Color(0x44000000)),
          ],
        ),
      ),
    );
  }
}

// ── 필터 선택 바텀시트 ────────────────────────────────────────────────────────

class _FilterPickerSheet extends StatefulWidget {
  const _FilterPickerSheet({required this.onApply});
  final void Function(FilterModel filter, double intensity) onApply;

  @override
  State<_FilterPickerSheet> createState() => _FilterPickerSheetState();
}

class _FilterPickerSheetState extends State<_FilterPickerSheet> {
  FilterModel? _selected;
  double _intensity = 1.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 필터 가로 스크롤 (카메라 뷰와 동일한 직사각형 썸네일)
          SizedBox(
            height: 112,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: BWFilters.all.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final filter = BWFilters.all[i];
                final isSelected = _selected?.id == filter.id;
                final w = isSelected ? 58.0 : 52.0;
                final h = isSelected ? 78.0 : 70.0;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selected = filter);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: w,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          width: w, height: h,
                          decoration: BoxDecoration(
                            color: filter.fallbackColor,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(color: AppColors.silver, width: 2)
                                : Border.all(color: AppColors.border, width: 0.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.asset(
                              'assets/thumbnails/${filter.id}.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => Center(
                                child: Text(
                                  filter.name[0],
                                  style: const TextStyle(
                                    color: AppColors.silverLight,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          filter.name,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // 필터 강도 슬라이더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '필터 강도',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(_intensity * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.silver,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.silver,
                    inactiveTrackColor: AppColors.border,
                    thumbColor: AppColors.silver,
                    overlayColor: AppColors.silver.withValues(alpha: 0.15),
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: _intensity,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (v) => setState(() => _intensity = v),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 적용 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selected == null
                    ? null
                    : () => widget.onApply(_selected!, _intensity),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.silver,
                  disabledBackgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '적용',
                  style: TextStyle(
                    color: _selected == null
                        ? AppColors.textDisabled
                        : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
