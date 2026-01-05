import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:video_player/video_player.dart';
import '../../data/models/video.dart';
import '../../data/repositories/video_repository.dart';
import '../../core/utils/logger.dart';
import '../../core/constants/app_constants.dart';
import 'subtitle_service.dart';

/// 视频导入服务
class VideoImportService {
  final VideoRepository _videoRepository;
  final SubtitleService _subtitleService;

  VideoImportService(this._videoRepository, [SubtitleService? subtitleService])
      : _subtitleService = subtitleService ?? SubtitleService();

  /// 选择并导入视频
  Future<Video?> importVideo() async {
    try {
      // 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        AppLogger.info('用户取消了视频选择');
        return null;
      }

      final file = result.files.first;
      final filePath = file.path;

      if (filePath == null) {
        throw Exception('无法获取文件路径');
      }

      // 验证文件
      final videoFile = File(filePath);
      if (!await videoFile.exists()) {
        throw Exception('视频文件不存在');
      }

      // 检查文件大小
      final fileSize = await videoFile.length();
      final fileSizeMB = fileSize / (1024 * 1024);
      if (fileSizeMB > AppConstants.maxVideoSizeMB) {
        throw Exception('视频文件过大（最大${AppConstants.maxVideoSizeMB}MB）');
      }

      // 获取视频信息
      final videoInfo = await _getVideoInfo(filePath);

      // 复制文件到应用目录
      final appDir = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${appDir.path}/${AppConstants.videosPath}');
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      final fileName = path.basename(filePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = '${timestamp}_$fileName';
      final newPath = '${videosDir.path}/$newFileName';
      
      await videoFile.copy(newPath);
      AppLogger.info('视频已复制到: $newPath');

      // 尝试提取字幕
      String? subtitlePath;
      try {
        subtitlePath = await _subtitleService.extractSubtitle(newPath);
        if (subtitlePath != null) {
          AppLogger.info('找到字幕文件: $subtitlePath');
        }
      } catch (e) {
        AppLogger.warning('提取字幕失败', e);
      }

      // 创建视频模型
      final video = Video()
        ..title = path.basenameWithoutExtension(fileName)
        ..path = newPath
        ..durationInSeconds = videoInfo.duration.inSeconds
        ..sizeInBytes = fileSize
        ..format = path.extension(fileName).replaceFirst('.', '')
        ..subtitlePath = subtitlePath
        ..createdAt = DateTime.now()
        ..tags = []
        ..playbackPosition = 0
        ..playCount = 0
        ..isFavorite = false
        ..noteCount = 0
        ..isCompleted = false
        ..completionPercent = 0.0;

      // 保存到数据库
      final videoId = await _videoRepository.createVideo(video);
      video.id = videoId;

      AppLogger.info('视频导入成功: ${video.title}');
      return video;
    } catch (e, stackTrace) {
      AppLogger.error('视频导入失败', e, stackTrace);
      rethrow;
    }
  }

  /// 导入多个视频
  Future<List<Video>> importMultipleVideos() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final videos = <Video>[];
      for (final file in result.files) {
        if (file.path != null) {
          try {
            // TODO: 实现批量导入逻辑
            // 可以复用 importVideo 的逻辑
          } catch (e) {
            AppLogger.error('导入视频失败: ${file.name}', e);
          }
        }
      }

      return videos;
    } catch (e, stackTrace) {
      AppLogger.error('批量导入视频失败', e, stackTrace);
      rethrow;
    }
  }

  /// 获取视频信息
  Future<_VideoInfo> _getVideoInfo(String path) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(File(path));
      await controller.initialize();

      final duration = controller.value.duration;
      final size = controller.value.size;

      return _VideoInfo(
        duration: duration,
        width: size.width.toInt(),
        height: size.height.toInt(),
      );
    } catch (e) {
      AppLogger.error('获取视频信息失败', e);
      // 返回默认值
      return _VideoInfo(
        duration: Duration.zero,
        width: 0,
        height: 0,
      );
    } finally {
      await controller?.dispose();
    }
  }

  /// 生成视频缩略图
  Future<String?> generateThumbnail(String videoPath) async {
    try {
      // TODO: 使用 FFmpeg 或其他工具生成缩略图
      // 这里需要集成视频处理库
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('生成缩略图失败', e, stackTrace);
      return null;
    }
  }

  /// 删除视频文件
  Future<void> deleteVideoFile(String videoPath) async {
    try {
      final file = File(videoPath);
      if (await file.exists()) {
        await file.delete();
        AppLogger.info('视频文件已删除: $videoPath');
      }
    } catch (e, stackTrace) {
      AppLogger.error('删除视频文件失败', e, stackTrace);
      rethrow;
    }
  }
}

/// 视频信息
class _VideoInfo {
  final Duration duration;
  final int width;
  final int height;

  _VideoInfo({
    required this.duration,
    required this.width,
    required this.height,
  });
}

