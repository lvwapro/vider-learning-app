/// 字幕条目
class SubtitleEntry {
  final int index;
  final Duration startTime;
  final Duration endTime;
  final String text;

  SubtitleEntry({
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.text,
  });

  /// 检查给定时间是否在此字幕的时间范围内
  bool isActiveAt(Duration time) {
    return time >= startTime && time <= endTime;
  }

  /// 从 SRT 格式解析字幕条目
  static SubtitleEntry? fromSrtBlock(String block) {
    final lines = block.trim().split('\n');
    if (lines.length < 3) return null;

    try {
      // 解析索引
      final index = int.parse(lines[0].trim());

      // 解析时间范围 (格式: 00:00:00,000 --> 00:00:00,000)
      final timeLine = lines[1].trim();
      final times = timeLine.split('-->');
      if (times.length != 2) return null;

      final startTime = _parseSrtTime(times[0].trim());
      final endTime = _parseSrtTime(times[1].trim());

      // 解析文本（可能多行）
      final text = lines.sublist(2).join('\n').trim();

      return SubtitleEntry(
        index: index,
        startTime: startTime,
        endTime: endTime,
        text: text,
      );
    } catch (e) {
      return null;
    }
  }

  /// 解析 SRT 时间格式: 00:00:00,000
  static Duration _parseSrtTime(String timeStr) {
    final parts = timeStr.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final secondsParts = parts[2].split(',');
    final seconds = int.parse(secondsParts[0]);
    final milliseconds = int.parse(secondsParts[1]);

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }

  /// 从 WebVTT 格式解析字幕条目
  static SubtitleEntry? fromVttBlock(String block, int index) {
    final lines = block.trim().split('\n');
    if (lines.length < 2) return null;

    try {
      // WebVTT 格式: 00:00:00.000 --> 00:00:00.000
      final timeLine = lines[0].trim();
      final times = timeLine.split('-->');
      if (times.length != 2) return null;

      final startTime = _parseVttTime(times[0].trim());
      final endTime = _parseVttTime(times[1].trim());

      // 解析文本
      final text = lines.sublist(1).join('\n').trim();

      return SubtitleEntry(
        index: index,
        startTime: startTime,
        endTime: endTime,
        text: text,
      );
    } catch (e) {
      return null;
    }
  }

  /// 解析 WebVTT 时间格式: 00:00:00.000
  static Duration _parseVttTime(String timeStr) {
    final parts = timeStr.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final secondsParts = parts[2].split('.');
    final seconds = int.parse(secondsParts[0]);
    final milliseconds = int.parse(secondsParts[1]);

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }

  @override
  String toString() {
    return 'SubtitleEntry(index: $index, time: ${startTime.inSeconds}s-${endTime.inSeconds}s, text: $text)';
  }
}

/// 字幕解析器
class SubtitleParser {
  /// 从 SRT 文件内容解析字幕
  static List<SubtitleEntry> parseSrt(String content) {
    final entries = <SubtitleEntry>[];
    final blocks = content.split('\n\n');

    for (final block in blocks) {
      if (block.trim().isEmpty) continue;
      
      final entry = SubtitleEntry.fromSrtBlock(block);
      if (entry != null) {
        entries.add(entry);
      }
    }

    return entries;
  }

  /// 从 WebVTT 文件内容解析字幕
  static List<SubtitleEntry> parseVtt(String content) {
    final entries = <SubtitleEntry>[];
    
    // 移除 WEBVTT 头部
    String cleaned = content;
    if (cleaned.startsWith('WEBVTT')) {
      final lines = cleaned.split('\n');
      cleaned = lines.skip(1).join('\n');
    }

    final blocks = cleaned.split('\n\n');
    int index = 1;

    for (final block in blocks) {
      if (block.trim().isEmpty) continue;
      
      final entry = SubtitleEntry.fromVttBlock(block, index++);
      if (entry != null) {
        entries.add(entry);
      }
    }

    return entries;
  }

  /// 自动检测格式并解析
  static List<SubtitleEntry> parse(String content) {
    if (content.trim().startsWith('WEBVTT')) {
      return parseVtt(content);
    } else {
      return parseSrt(content);
    }
  }

  /// 获取指定时间点的字幕文本
  static String? getTextAt(List<SubtitleEntry> entries, Duration time) {
    for (final entry in entries) {
      if (entry.isActiveAt(time)) {
        return entry.text;
      }
    }
    return null;
  }
}

