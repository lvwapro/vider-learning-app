import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/constants/app_colors.dart';
import '../providers/video_providers.dart';
import '../providers/note_providers.dart';
import '../providers/video_import_provider.dart';

/// 主页
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  void _onNavigationChanged(int index) {
    if (_selectedIndex == index) return;
    
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.videoList);
        break;
      case 2:
        context.go(AppRoutes.notes);
        break;
      case 3:
        context.go(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final videosAsync = ref.watch(allVideosProvider);
    final notesAsync = ref.watch(allNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('学迹VidNotes'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 实现搜索功能
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 统计概览（简洁版）
            _buildStatsOverview(videosAsync, notesAsync),
            const SizedBox(height: 24),

            // 主要功能卡片（类似 Deja 的大卡片布局）
            Expanded(
              child: _buildMainFeatures(),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              heroTag: 'home_page_fab',
              onPressed: () => _importVideo(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('导入视频'),
              elevation: 4,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavigationChanged,
        elevation: 8,
        animationDuration: const Duration(milliseconds: 300),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library),
            label: '视频库',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_outlined),
            selectedIcon: Icon(Icons.note),
            label: '笔记',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(
    AsyncValue<List<dynamic>> videosAsync,
    AsyncValue<List<dynamic>> notesAsync,
  ) {
    final videoCount = videosAsync.valueOrNull?.length ?? 0;
    final noteCount = notesAsync.valueOrNull?.length ?? 0;

    return Row(
      children: [
        _buildStatItem('视频', videoCount),
        const SizedBox(width: 24),
        _buildStatItem('笔记', noteCount),
        const SizedBox(width: 24),
        _buildStatItem('导图', 0),
      ],
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildMainFeatures() {
    return ListView(
      children: [
        _buildFeatureCard(
          icon: Icons.video_library_outlined,
          title: '视频库',
          subtitle: '管理学习视频',
          color: AppColors.primary,
          onTap: () => context.go(AppRoutes.videoList),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          icon: Icons.note_outlined,
          title: '我的笔记',
          subtitle: '查看所有笔记',
          color: AppColors.secondary,
          onTap: () => context.go(AppRoutes.notes),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          icon: Icons.account_tree_outlined,
          title: '思维导图',
          subtitle: '知识可视化',
          color: AppColors.accent,
          onTap: () => context.go(AppRoutes.mindmap),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          icon: Icons.add_circle_outline,
          title: '导入视频',
          subtitle: '添加新内容',
          color: Colors.green,
          onTap: () => _importVideo(context, ref),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 导入视频
  Future<void> _importVideo(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(videoImportControllerProvider.notifier);
    
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('导入视频中...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final video = await controller.importVideo();
      
      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        
        if (video != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('视频导入成功: ${video.title}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

