import 'package:flutter/material.dart';
import '../../domain/models/subtitle.dart';

/// 字幕显示组件
class SubtitleOverlay extends StatelessWidget {
  final List<SubtitleEntry> subtitles;
  final Duration currentPosition;
  final TextStyle? style;
  final EdgeInsets padding;
  final Color backgroundColor;
  final double backgroundOpacity;

  const SubtitleOverlay({
    super.key,
    required this.subtitles,
    required this.currentPosition,
    this.style,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = Colors.black,
    this.backgroundOpacity = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    final currentText = SubtitleParser.getTextAt(subtitles, currentPosition);

    if (currentText == null || currentText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: Padding(
        padding: padding,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(backgroundOpacity),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              currentText,
              textAlign: TextAlign.center,
              style: style ??
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black,
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 字幕列表组件（用于显示完整字幕）
class SubtitleListWidget extends StatelessWidget {
  final List<SubtitleEntry> subtitles;
  final Duration? currentPosition;
  final ValueChanged<Duration>? onSeek;

  const SubtitleListWidget({
    super.key,
    required this.subtitles,
    this.currentPosition,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    if (subtitles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.subtitles_off_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无字幕',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: subtitles.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final subtitle = subtitles[index];
        final isActive = currentPosition != null &&
            subtitle.isActiveAt(currentPosition!);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isActive ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${subtitle.index}',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            title: Text(
              subtitle.text,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              _formatTime(subtitle.startTime),
              style: TextStyle(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
              ),
            ),
            trailing: onSeek != null
                ? IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => onSeek!(subtitle.startTime),
                  )
                : null,
            onTap: onSeek != null ? () => onSeek!(subtitle.startTime) : null,
          ),
        );
      },
    );
  }

  String _formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

/// 字幕搜索组件
class SubtitleSearchWidget extends StatefulWidget {
  final List<SubtitleEntry> subtitles;
  final ValueChanged<Duration>? onSeek;

  const SubtitleSearchWidget({
    super.key,
    required this.subtitles,
    this.onSeek,
  });

  @override
  State<SubtitleSearchWidget> createState() => _SubtitleSearchWidgetState();
}

class _SubtitleSearchWidgetState extends State<SubtitleSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<SubtitleEntry> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _searchResults = widget.subtitles.where((entry) {
        return entry.text.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索字幕内容...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _performSearch,
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty && _searchController.text.isEmpty
              ? Center(
                  child: Text(
                    '在字幕中搜索关键词',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '未找到匹配的字幕',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : SubtitleListWidget(
                      subtitles: _searchResults,
                      onSeek: widget.onSeek,
                    ),
        ),
      ],
    );
  }
}

