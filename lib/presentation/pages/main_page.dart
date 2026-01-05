import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/video.dart';
import '../../domain/services/online_video_service.dart';
import '../providers/theme_provider.dart';
import '../providers/video_providers.dart';
import '../providers/note_providers.dart';
import '../providers/video_import_provider.dart';
import '../widgets/online_video_dialog.dart';

/// 主容器页面 - 包含底部导航栏的所有页面
class MainPage extends ConsumerStatefulWidget {
  final int initialIndex;
  
  const MainPage({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onNavigationChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _HomePage(),
          _VideoLibraryPage(),
          _NotesPage(),
          _ProfilePage(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              heroTag: 'main_page_fab',
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

  /// 导入视频
  Future<void> _importVideo(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(videoImportControllerProvider.notifier);
    
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
          // 显示成功提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('视频导入成功: ${video.title}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // 跳转到视频播放页面
          context.push('/video/${video.id}');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// 首页内容
class _HomePage extends ConsumerWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            _buildStatsOverview(context, videosAsync, notesAsync),
            const SizedBox(height: 24),

            // 主要功能卡片
            Expanded(
              child: _buildMainFeatures(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(
    BuildContext context,
    AsyncValue<List<dynamic>> videosAsync,
    AsyncValue<List<dynamic>> notesAsync,
  ) {
    final videoCount = videosAsync.valueOrNull?.length ?? 0;
    final noteCount = notesAsync.valueOrNull?.length ?? 0;

    return Row(
      children: [
        _buildStatItem(context, '视频', videoCount),
        const SizedBox(width: 24),
        _buildStatItem(context, '笔记', noteCount),
        const SizedBox(width: 24),
        _buildStatItem(context, '导图', 0),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, int count) {
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

  Widget _buildMainFeatures(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        _buildFeatureCard(
          context: context,
          icon: Icons.video_library_outlined,
          title: '视频库',
          subtitle: '管理学习视频',
          color: AppColors.primary,
          onTap: () => context.push(AppRoutes.videoList),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          context: context,
          icon: Icons.note_outlined,
          title: '我的笔记',
          subtitle: '查看所有笔记',
          color: AppColors.secondary,
          onTap: () => context.push(AppRoutes.notes),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          context: context,
          icon: Icons.account_tree_outlined,
          title: '思维导图',
          subtitle: '知识可视化',
          color: AppColors.accent,
          onTap: () => context.push(AppRoutes.mindmap),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          context: context,
          icon: Icons.cloud_outlined,
          title: '添加在线视频',
          subtitle: '哔哩哔哩、YouTube等',
          color: Colors.purple,
          onTap: () => _showAddOnlineVideo(context, ref),
        ),
      ],
    );
  }

  Future<void> _showAddOnlineVideo(BuildContext context, WidgetRef ref) async {
    final input = await showAddOnlineVideoDialog(context);
    if (input == null || !context.mounted) return;

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
                Text('正在添加视频...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // 解析视频信息
      final videoService = OnlineVideoService();
      final extractedTitle = videoService.extractTitle(input);
      final videoInfo = await videoService.parseVideo(input);
      
      if (videoInfo == null) {
        throw Exception('无法解析视频信息');
      }

      // 使用提取的标题或默认标题
      final title = extractedTitle ?? videoInfo.title;

      // 创建视频记录
      final videoRepository = ref.read(videoRepositoryProvider);
      final video = Video()
        ..title = title
        ..path = videoInfo.videoUrl  // 使用视频URL作为路径
        ..durationInSeconds = videoInfo.duration ?? 0
        ..sizeInBytes = 0  // 在线视频大小未知
        ..format = 'online'
        ..subtitlePath = videoInfo.subtitleUrl
        ..sourceUrl = videoInfo.originalUrl
        ..createdAt = DateTime.now()
        ..tags = ['在线视频', videoService.getPlatformName(videoInfo.platform)]
        ..playbackPosition = 0
        ..playCount = 0
        ..isFavorite = false
        ..noteCount = 0
        ..isCompleted = false
        ..completionPercent = 0.0;

      // 保存到数据库
      final videoId = await videoRepository.createVideo(video);
      video.id = videoId;

      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('视频添加成功: ${video.title}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // 跳转到视频播放页面
        context.push('/video/${video.id}');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildFeatureCard({
    required BuildContext context,
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
}

/// 视频库页面内容
class _VideoLibraryPage extends ConsumerWidget {
  const _VideoLibraryPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(allVideosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('视频库'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 实现搜索
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: 实现筛选
            },
          ),
        ],
      ),
      body: videosAsync.when(
        data: (videos) {
          if (videos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '还没有视频',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右下角按钮导入视频',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () {
                    context.push('/video/${video.id}');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // 缩略图
                        Container(
                          width: 120,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.2),
                                AppColors.primary.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.play_circle_filled,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // 视频信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    video.formattedDuration,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.storage,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    video.formattedSize,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // 操作按钮
                        IconButton(
                          icon: Icon(
                            video.isFavorite ? Icons.star : Icons.star_outline,
                            color: video.isFavorite ? Colors.amber : Colors.grey,
                          ),
                          onPressed: () async {
                            final repository = ref.read(videoRepositoryProvider);
                            await repository.toggleFavorite(video.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _importVideo(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('导入视频'),
        elevation: 4,
      ),
    );
  }

  Future<void> _importVideo(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(videoImportControllerProvider.notifier);
    
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
        Navigator.of(context).pop();
        
        if (video != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('视频导入成功: ${video.title}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          context.push('/video/${video.id}');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// 笔记页面内容
class _NotesPage extends ConsumerWidget {
  const _NotesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(allNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的笔记'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 实现搜索
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: 实现筛选
            },
          ),
        ],
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '还没有笔记',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '在视频播放时添加笔记',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.note,
                      color: AppColors.secondary,
                    ),
                  ),
                  title: Text(
                    note.userNote ?? note.originalText ?? '空笔记',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${note.formattedTimestamp} • ${note.typeDisplayName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                  onTap: () {
                    // 跳转到对应的视频播放页面
                    context.push('/video/${note.videoId}');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
            ],
          ),
        ),
      ),
    );
  }
}

/// 我的页面内容（简化版，导入 ProfilePage 的内容）
class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    // 直接使用 ProfilePage 的内容
    return const _ProfilePageContent();
  }
}

// 将 ProfilePage 的内容复制过来
class _ProfilePageContent extends ConsumerWidget {
  const _ProfilePageContent();

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
          _buildUserCard(context),
          const SizedBox(height: 16),
          _buildStatsSection(context, videosAsync, notesAsync),
          const SizedBox(height: 24),
          _buildSectionHeader(context, '外观'),
          _buildSettingTile(
            context: context,
            icon: Icons.palette_outlined,
            title: '主题模式',
            subtitle: _getThemeModeText(themeMode),
            onTap: () => _showThemeModeDialog(context, ref),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, '内容'),
          _buildSettingTile(
            context: context,
            icon: Icons.storage_outlined,
            title: '存储管理',
            subtitle: '管理本地缓存和数据',
            onTap: () {},
          ),
          _buildSettingTile(
            context: context,
            icon: Icons.download_outlined,
            title: '导出数据',
            subtitle: '备份笔记和思维导图',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, '关于'),
          _buildSettingTile(
            context: context,
            icon: Icons.info_outline,
            title: '关于应用',
            subtitle: '版本 1.0.0',
            onTap: () => context.push(AppRoutes.settings),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '学习者',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '持续学习，不断进步',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
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
}

// 导出为 HomePage 以保持兼容性
typedef HomePage = MainPage;

