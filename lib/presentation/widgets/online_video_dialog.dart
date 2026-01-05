import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/online_video_service.dart';
import '../../core/constants/app_colors.dart';

/// 添加在线视频对话框
Future<String?> showAddOnlineVideoDialog(BuildContext context) async {
  return await showDialog<String>(
    context: context,
    builder: (context) => const _AddOnlineVideoDialog(),
  );
}

class _AddOnlineVideoDialog extends StatefulWidget {
  const _AddOnlineVideoDialog();

  @override
  State<_AddOnlineVideoDialog> createState() => _AddOnlineVideoDialogState();
}

class _AddOnlineVideoDialogState extends State<_AddOnlineVideoDialog> {
  final TextEditingController _urlController = TextEditingController();
  final OnlineVideoService _service = OnlineVideoService();

  VideoPlatform? _detectedPlatform;
  String? _errorMessage;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _onUrlChanged(String url) {
    if (url.isEmpty) {
      setState(() {
        _detectedPlatform = null;
        _errorMessage = null;
      });
      return;
    }

    final platform = _service.detectPlatform(url);
    setState(() {
      _detectedPlatform = platform;
      _errorMessage = platform == VideoPlatform.unknown ? '不支持的视频源' : null;
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _urlController.text = data!.text!;
      _onUrlChanged(data.text!);
    }
  }

  void _addVideo() {
    final input = _urlController.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = '请输入视频链接');
      return;
    }

    if (_detectedPlatform == VideoPlatform.unknown) {
      setState(() => _errorMessage = '不支持的视频源');
      return;
    }

    // 返回原始输入（包含标题和URL）
    Navigator.of(context).pop(input);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加在线视频'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // URL输入框
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: '视频链接',
                hintText: '支持直接粘贴分享文本，如：【标题】链接',
                prefixIcon: const Icon(Icons.link),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste),
                  onPressed: _pasteFromClipboard,
                  tooltip: '从剪贴板粘贴',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _errorMessage,
              ),
              onChanged: _onUrlChanged,
              maxLines: 3,
              keyboardType: TextInputType.url,
            ),

            const SizedBox(height: 16),

            // 平台检测结果
            if (_detectedPlatform != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _detectedPlatform == VideoPlatform.unknown
                      ? Colors.red.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _service.getPlatformIcon(_detectedPlatform!),
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _service.getPlatformName(_detectedPlatform!),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _service.getSuggestion(_detectedPlatform!),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 使用提示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '使用提示',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '支持直接粘贴分享文本，例如：\n【TED科普】为什么有些关系能长久，有些不能？-哔哩哔哩】 https://b23.tv/xxxxx',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '应用会自动提取视频链接和标题',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 支持的平台说明
            _buildSupportInfo(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _detectedPlatform != null &&
                  _detectedPlatform != VideoPlatform.unknown
              ? _addVideo
              : null,
          child: const Text('添加'),
        ),
      ],
    );
  }

  Widget _buildSupportInfo() {
    return ExpansionTile(
      title: const Text(
        '支持的平台',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      tilePadding: EdgeInsets.zero,
      children: [
        _buildPlatformItem('📺 哔哩哔哩', '需要使用工具下载或提供直接链接'),
        _buildPlatformItem('▶️ YouTube', '需要使用工具下载'),
        _buildPlatformItem('🔗 直接链接', '支持 .mp4, .m3u8 等格式'),
      ],
    );
  }

  Widget _buildPlatformItem(String platform, String note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              platform,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            note,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// 在线视频详情页（显示解析结果）
class OnlineVideoInfoPage extends ConsumerWidget {
  final OnlineVideoInfo videoInfo;

  const OnlineVideoInfoPage({
    super.key,
    required this.videoInfo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = OnlineVideoService();
    final canPlay = service.supportDirectPlay(videoInfo.platform);

    return Scaffold(
      appBar: AppBar(
        title: const Text('视频信息'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 缩略图
          if (videoInfo.thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                videoInfo.thumbnailUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.video_library, size: 64),
                  );
                },
              ),
            ),

          const SizedBox(height: 20),

          // 标题
          Text(
            videoInfo.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),

          const SizedBox(height: 12),

          // 平台信息
          Row(
            children: [
              Text(
                service.getPlatformIcon(videoInfo.platform),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                service.getPlatformName(videoInfo.platform),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 描述
          if (videoInfo.description != null) ...[
            Text(
              videoInfo.description!,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 建议
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: canPlay
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              service.getSuggestion(videoInfo.platform),
              style: const TextStyle(height: 1.5),
            ),
          ),

          const SizedBox(height: 24),

          // 操作按钮
          if (canPlay) ...[
            FilledButton.icon(
              onPressed: () {
                // TODO: 在线播放
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('在线播放功能开发中...')),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('在线播放'),
            ),
            const SizedBox(height: 12),
          ],

          OutlinedButton.icon(
            onPressed: () {
              // TODO: 下载到本地
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('下载功能开发中...')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('下载到本地'),
          ),
        ],
      ),
    );
  }
}
