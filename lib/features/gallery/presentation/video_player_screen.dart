import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.videoPath,
    required this.assetId,
  });

  final String videoPath;
  final String assetId;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _ctrl;
  bool _initialized = false;
  bool _showControls = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _ctrl.play();
          _ctrl.setLooping(true);
        }
      });
    _ctrl.addListener(_onPlayerUpdate);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onPlayerUpdate);
    _ctrl.dispose();
    super.dispose();
  }

  void _onPlayerUpdate() {
    if (mounted) setState(() {});
  }

  void _togglePlay() {
    HapticFeedback.selectionClick();
    if (_ctrl.value.isPlaying) {
      _ctrl.pause();
    } else {
      _ctrl.play();
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  Future<void> _share() async {
    await Share.shareXFiles([XFile(widget.videoPath)]);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('동영상을 삭제하시겠습니까?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: const Text('삭제된 동영상은 복구할 수 없습니다.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
    if (ok != true || !mounted) return;
    setState(() => _isDeleting = true);
    final deleted = await PhotoManager.editor.deleteWithIds([widget.assetId]);
    if (!mounted) return;
    if (deleted.isNotEmpty) {
      context.pop();
    } else {
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('삭제에 실패했습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 비디오
              if (_initialized)
                Center(
                  child: AspectRatio(
                    aspectRatio: _ctrl.value.aspectRatio,
                    child: VideoPlayer(_ctrl),
                  ),
                )
              else
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.silver),
                    strokeWidth: 1.5,
                  ),
                ),

              // 컨트롤 오버레이
              if (_showControls) ...[
                // 상단 바
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(4, topPad + 6, 12, 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_rounded,
                              color: AppColors.textPrimary, size: 20),
                          onPressed: () => context.pop(),
                        ),
                        const Spacer(),
                        _CircleBtn(
                          icon: Icons.ios_share_rounded,
                          onTap: _share,
                        ),
                        const SizedBox(width: 8),
                        _CircleBtn(
                          icon: Icons.delete_outline_rounded,
                          iconColor: Colors.red,
                          onTap: _isDeleting ? null : _confirmDelete,
                        ),
                      ],
                    ),
                  ),
                ),

                // 중앙 재생/일시정지 버튼
                Center(
                  child: GestureDetector(
                    onTap: _togglePlay,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.silver, width: 1.5),
                      ),
                      child: Icon(
                        _ctrl.value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),

                // 하단 진행 바
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, botPad + 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 시간 표시
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _initialized
                                  ? _formatDuration(_ctrl.value.position)
                                  : '00:00',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              _initialized
                                  ? _formatDuration(_ctrl.value.duration)
                                  : '00:00',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // 슬라이더
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.silver,
                            inactiveTrackColor: AppColors.border,
                            thumbColor: Colors.white,
                            overlayColor: Colors.white.withValues(alpha: 0.15),
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14),
                          ),
                          child: Slider(
                            value: _initialized
                                ? _ctrl.value.position.inMilliseconds
                                    .toDouble()
                                    .clamp(
                                        0,
                                        _ctrl.value.duration.inMilliseconds
                                            .toDouble())
                                : 0,
                            min: 0,
                            max: _initialized
                                ? _ctrl.value.duration.inMilliseconds
                                    .toDouble()
                                : 1,
                            onChanged: _initialized
                                ? (v) => _ctrl.seekTo(
                                    Duration(milliseconds: v.round()))
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── 상단 바 원형 버튼 ─────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Icon(icon,
            color: onTap == null
                ? AppColors.textDisabled
                : (iconColor ?? AppColors.textPrimary),
            size: 18),
      ),
    );
  }
}
