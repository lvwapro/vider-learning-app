import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/video_providers.dart';
import '../providers/note_providers.dart';
import '../../core/constants/app_constants.dart';

/// 我的页面
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final videosAsync = ref.watch(allVideosProvider);
    final notesAsync = ref.watch(allNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: false,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // 用户信息卡片
          _buildUserCard(context),
          const SizedBox(height: 16),

          // 学习统计
          _buildStatsSection(context, videosAsync, notesAsync),
          const SizedBox(height: 24),

          // 外观设置
          _buildSectionHeader(context, '外观'),
          _buildSettingTile(
            context: context,
            icon: Icons.palette_outlined,
            title: '主题模式',
            subtitle: _getThemeModeText(themeMode),
            onTap: () => _showThemeModeDialog(context, ref),
          ),

          const SizedBox(height: 24),

          // 内容管理
          _buildSectionHeader(context, '内容'),
          _buildSettingTile(
            context: context,
            icon: Icons.storage_outlined,
            title: '存储管理',
            subtitle: '管理本地缓存和数据',
            onTap: () {
              // TODO: 存储管理
            },
          ),
          _buildSettingTile(
            context: context,
            icon: Icons.download_outlined,
            title: '导出数据',
            subtitle: '备份笔记和思维导图',
            onTap: () {
              // TODO: 导出数据
            },
          ),

          const SizedBox(height: 24),

          // 关于
          _buildSectionHeader(context, '关于'),
          _buildSettingTile(
            context: context,
            icon: Icons.info_outline,
            title: '关于应用',
            subtitle: '版本 ${AppConstants.appVersion}',
            onTap: () => _showAboutDialog(context),
          ),
          _buildSettingTile(
            context: context,
            icon: Icons.privacy_tip_outlined,
            title: '隐私政策',
            subtitle: '了解我们如何保护您的隐私',
            onTap: () {
              // TODO: 隐私政策
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '学习者',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '持续学习，不断进步',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    AsyncValue<List<dynamic>> videosAsync,
    AsyncValue<List<dynamic>> notesAsync,
  ) {
    final videoCount = videosAsync.valueOrNull?.length ?? 0;
    final noteCount = notesAsync.valueOrNull?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context: context,
              label: '视频',
              value: videoCount,
              icon: Icons.video_library,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context: context,
              label: '笔记',
              value: noteCount,
              icon: Icons.note,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context: context,
              label: '导图',
              value: 0,
              icon: Icons.account_tree,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required int value,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeModeOption(
              context,
              ref,
              ThemeMode.light,
              '浅色',
              Icons.light_mode,
            ),
            _buildThemeModeOption(
              context,
              ref,
              ThemeMode.dark,
              '深色',
              Icons.dark_mode,
            ),
            _buildThemeModeOption(
              context,
              ref,
              ThemeMode.system,
              '跟随系统',
              Icons.settings_suggest,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeOption(
    BuildContext context,
    WidgetRef ref,
    ThemeMode mode,
    String label,
    IconData icon,
  ) {
    final currentMode = ref.watch(themeModeProvider);
    final isSelected = currentMode == mode;

    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () {
        final notifier = ref.read(themeModeProvider.notifier);
        switch (mode) {
          case ThemeMode.light:
            notifier.setLightMode();
            break;
          case ThemeMode.dark:
            notifier.setDarkMode();
            break;
          case ThemeMode.system:
            notifier.setSystemMode();
            break;
        }
        Navigator.of(context).pop();
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.school,
          size: 36,
          color: Colors.white,
        ),
      ),
      children: [
        const SizedBox(height: 16),
        const Text(
          '一款帮助你从视频中提取知识，创建笔记和思维导图的学习工具。',
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

