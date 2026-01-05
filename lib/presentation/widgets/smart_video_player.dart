import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/video_note.dart';

/// 智能视频播放器组件
class SmartVideoPlayer extends StatefulWidget {
  final String videoPath;
  final int videoId;
  final List<VideoNote> notes;
  final Duration? initialPosition;
  final ValueChanged<Duration>? onPositionChanged;
  final ValueChanged<Duration>? onNoteTimestampTap;
  final VoidCallback? onAddNote;

  const SmartVideoPlayer({
    super.key,
    required this.videoPath,
    required this.videoId,
    this.notes = const [],
    this.initialPosition,
    this.onPositionChanged,
    this.onNoteTimestampTap,
    this.onAddNote,
  });

  @override
  State<SmartVideoPlayer> createState() => _SmartVideoPlayerState();
}

class _SmartVideoPlayerState extends State<SmartVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // 判断是在线视频还是本地视频
      final isOnline = widget.videoPath.startsWith('http://') || 
                      widget.videoPath.startsWith('https://');
      
      if (isOnline) {
        // 在线视频
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoPath),
        );
      } else {
        // 本地视频
        _videoPlayerController = VideoPlayerController.file(
          File(widget.videoPath),
        );
      }

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.grey[300]!,
          bufferedColor: Colors.grey[200]!,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  '播放失败',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      // 设置初始播放位置
      if (widget.initialPosition != null) {
        await _videoPlayerController.seekTo(widget.initialPosition!);
      }

      // 监听播放位置变化
      _videoPlayerController.addListener(_onVideoPositionChanged);

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _onVideoPositionChanged() {
    if (_videoPlayerController.value.isInitialized) {
      final position = _videoPlayerController.value.position;
      widget.onPositionChanged?.call(position);
    }
  }

  @override
  void dispose() {
    _videoPlayerController.removeListener(_onVideoPositionChanged);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorView();
    }

    if (!_isInitialized || _chewieController == null) {
      return _buildLoadingView();
    }

    return Column(
      children: [
        // 视频播放器
        AspectRatio(
          aspectRatio: _videoPlayerController.value.aspectRatio,
          child: Stack(
            children: [
              Chewie(controller: _chewieController!),
              
              // 添加笔记按钮（悬浮）
              if (widget.onAddNote != null)
                Positioned(
                  right: 16,
                  bottom: 60,
                  child: FloatingActionButton(
                    heroTag: 'video_player_add_note_fab',
                    mini: true,
                    onPressed: widget.onAddNote,
                    backgroundColor: AppColors.accent,
                    child: const Icon(Icons.add_comment, size: 20),
                  ),
                ),
            ],
          ),
        ),

        // 播放速度控制
        _buildSpeedControl(),

        // 笔记时间轴
        if (widget.notes.isNotEmpty)
          _buildNotesTimeline(),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      height: 250,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              '加载视频中...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.black,
      height: 250,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  '视频加载失败',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? '未知错误',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _isInitialized = false;
                    });
                    _initializePlayer();
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('播放速度:', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AppConstants.playbackSpeeds.map((speed) {
                  final isSelected = _playbackSpeed == speed;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${speed}x'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          _setPlaybackSpeed(speed);
                        }
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTimeline() {
    final duration = _videoPlayerController.value.duration;
    if (duration == Duration.zero) return const SizedBox.shrink();

    return Container(
      height: 60,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '笔记标记',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Stack(
              children: [
                // 时间轴背景
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // 笔记标记
                ...widget.notes.map((note) {
                  final position = note.timestampInSeconds / duration.inSeconds;
                  return Positioned(
                    left: position * (MediaQuery.of(context).size.width - 32),
                    child: GestureDetector(
                      onTap: () {
                        widget.onNoteTimestampTap?.call(note.timestamp);
                        _videoPlayerController.seekTo(note.timestamp);
                      },
                      child: Container(
                        width: 8,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _getNoteColor(note.type),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getNoteColor(NoteType type) {
    switch (type) {
      case NoteType.highlight:
        return AppColors.noteHighlight;
      case NoteType.comment:
        return AppColors.noteComment;
      case NoteType.question:
        return AppColors.noteQuestion;
    }
  }

  void _setPlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _videoPlayerController.setPlaybackSpeed(speed);
  }

  /// 跳转到指定时间
  Future<void> seekTo(Duration position) async {
    await _videoPlayerController.seekTo(position);
  }

  /// 播放
  Future<void> play() async {
    await _videoPlayerController.play();
  }

  /// 暂停
  Future<void> pause() async {
    await _videoPlayerController.pause();
  }

  /// 获取当前播放位置
  Duration get currentPosition => _videoPlayerController.value.position;

  /// 获取视频时长
  Duration get duration => _videoPlayerController.value.duration;

  /// 是否正在播放
  bool get isPlaying => _videoPlayerController.value.isPlaying;
}

