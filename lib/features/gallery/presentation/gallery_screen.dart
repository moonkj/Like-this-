import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';

/// 갤러리 화면 — Like It! 구조 기반, Like This 색상 적용
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<AssetEntity> _assets = [];
  bool _isLoading = true;
  bool _permissionDenied = false;

  // 다중 선택 모드
  bool _isMultiSelectMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    PhotoManager.addChangeCallback(_onPhotosChanged);
    PhotoManager.startChangeNotify();
  }

  @override
  void dispose() {
    PhotoManager.removeChangeCallback(_onPhotosChanged);
    PhotoManager.stopChangeNotify();
    super.dispose();
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
    final assets = await albums.first.getAssetListPaged(page: 0, size: 200);
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

    final assets = await albums.first.getAssetListPaged(page: 0, size: 200);
    if (mounted) setState(() { _assets = assets; _isLoading = false; });
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

    context.push('/editor', extra: file.path);
  }

  void _toggleMultiSelectMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      _selectedIds.clear();
    });
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isMultiSelectMode ? Icons.close_rounded : Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onPressed: _isMultiSelectMode ? _toggleMultiSelectMode : () => context.pop(),
          ),
          Expanded(
            child: _isMultiSelectMode
                ? Text(
                    '${_selectedIds.length}장 선택됨',
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

          // 다중선택 모드: 공유 + 삭제
          if (_isMultiSelectMode && _selectedIds.isNotEmpty) ...[
            _topCircleBtn(Icons.ios_share_rounded, onTap: _shareSelected),
            const SizedBox(width: 8),
            _topCircleBtn(Icons.delete_outline_rounded, color: Colors.red, onTap: _confirmAndDelete),
          ],
        ],
      ),
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
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: _assets.length,
      itemBuilder: (context, index) {
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
