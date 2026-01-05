import 'dart:io';
import 'package:path/path.dart' as path;
import '../../core/utils/logger.dart';
import '../models/subtitle.dart';

/// 字幕提取服务
class SubtitleService {
  /// 从视频文件中提取字幕
  /// 
  /// 策略：
  /// 1. 检查是否有同名的 .srt 或 .vtt 字幕文件
  /// 2. 如果有 ffmpeg，尝试提取内嵌字幕
  /// 3. 返回字幕文件路径
  Future<String?> extractSubtitle(String videoPath) async {
    try {
      // 首先检查同目录下是否有同名字幕文件
      final externalSubtitle = await _findExternalSubtitle(videoPath);
      if (externalSubtitle != null) {
        AppLogger.info('找到外部字幕文件: $externalSubtitle');
        return externalSubtitle;
      }

      // TODO: 如果需要，可以集成 ffmpeg 提取内嵌字幕
      // final embeddedSubtitle = await _extractEmbeddedSubtitle(videoPath);
      // if (embeddedSubtitle != null) {
      //   return embeddedSubtitle;
      // }

      AppLogger.info('未找到视频字幕: $videoPath');
      return null;
    } catch (e) {
      AppLogger.error('提取字幕失败', e);
      return null;
    }
  }

  /// 查找外部字幕文件（同名的 .srt 或 .vtt）
  Future<String?> _findExternalSubtitle(String videoPath) async {
    final videoFile = File(videoPath);
    final videoDir = videoFile.parent;
    final videoBaseName = path.basenameWithoutExtension(videoPath);

    // 检查常见字幕格式
    final subtitleExtensions = ['srt', 'vtt', 'ass', 'ssa'];
    
    for (final ext in subtitleExtensions) {
      final subtitlePath = path.join(videoDir.path, '$videoBaseName.$ext');
      final subtitleFile = File(subtitlePath);
      
      if (await subtitleFile.exists()) {
        return subtitlePath;
      }
    }

    return null;
  }

  /// 读取字幕文件内容
  Future<String?> readSubtitleFile(String subtitlePath) async {
    try {
      final file = File(subtitlePath);
      if (!await file.exists()) {
        AppLogger.warning('字幕文件不存在: $subtitlePath');
        return null;
      }

      return await file.readAsString();
    } catch (e) {
      AppLogger.error('读取字幕文件失败', e);
      return null;
    }
  }

  /// 解析字幕文件
  Future<List<SubtitleEntry>> parseSubtitleFile(String subtitlePath) async {
    try {
      final content = await readSubtitleFile(subtitlePath);
      if (content == null) return [];

      return SubtitleParser.parse(content);
    } catch (e) {
      AppLogger.error('解析字幕失败', e);
      return [];
    }
  }

  /// 从字幕中生成时间戳笔记
  /// 
  /// 可以用于：
  /// 1. 自动为视频创建基础笔记
  /// 2. 提供搜索功能
  Future<List<Map<String, dynamic>>> generateNotesFromSubtitle(
    String subtitlePath,
    int videoId,
  ) async {
    try {
      final entries = await parseSubtitleFile(subtitlePath);
      final notes = <Map<String, dynamic>>[];

      // 每隔 N 秒生成一条笔记（避免笔记过多）
      const intervalSeconds = 30;
      Duration lastNoteTime = Duration.zero;

      for (final entry in entries) {
        if (entry.startTime - lastNoteTime >= const Duration(seconds: intervalSeconds)) {
          notes.add({
            'videoId': videoId,
            'timestamp': entry.startTime,
            'text': entry.text,
            'type': 'subtitle',
          });
          lastNoteTime = entry.startTime;
        }
      }

      AppLogger.info('从字幕生成了 ${notes.length} 条笔记');
      return notes;
    } catch (e) {
      AppLogger.error('从字幕生成笔记失败', e);
      return [];
    }
  }

  /// 在字幕中搜索关键词
  Future<List<SubtitleEntry>> searchInSubtitle(
    String subtitlePath,
    String keyword,
  ) async {
    try {
      final entries = await parseSubtitleFile(subtitlePath);
      return entries.where((entry) {
        return entry.text.toLowerCase().contains(keyword.toLowerCase());
      }).toList();
    } catch (e) {
      AppLogger.error('搜索字幕失败', e);
      return [];
    }
  }

  /// 获取字幕统计信息
  Future<Map<String, dynamic>> getSubtitleStats(String subtitlePath) async {
    try {
      final entries = await parseSubtitleFile(subtitlePath);
      
      if (entries.isEmpty) {
        return {
          'count': 0,
          'duration': Duration.zero,
          'totalWords': 0,
        };
      }

      final totalWords = entries.fold<int>(
        0,
        (sum, entry) => sum + entry.text.split(' ').length,
      );

      return {
        'count': entries.length,
        'duration': entries.last.endTime - entries.first.startTime,
        'totalWords': totalWords,
        'averageWordsPerEntry': totalWords / entries.length,
      };
    } catch (e) {
      AppLogger.error('获取字幕统计失败', e);
      return {'count': 0, 'duration': Duration.zero, 'totalWords': 0};
    }
  }
}

