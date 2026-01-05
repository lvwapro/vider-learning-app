import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/pages/splash_page.dart';
import '../../presentation/pages/main_page.dart';
import '../../presentation/pages/video_list_page.dart';
import '../../presentation/pages/video_player_page.dart';
import '../../presentation/pages/notes_page.dart';
import '../../presentation/pages/mindmap_page.dart';
import '../../presentation/pages/mindmap_editor_page.dart';
import '../../presentation/pages/settings_page.dart';

/// 路由路径常量
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String home = '/home';
  static const String videoList = '/videos/all';
  static const String videoPlayer = '/video/:id';
  static const String notes = '/notes/all';
  static const String noteDetail = '/notes/:id';
  static const String mindmap = '/mindmap';
  static const String mindmapDetail = '/mindmap/:id';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

/// 应用路由配置
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // 启动页
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // 主页
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const MainPage(initialIndex: 0),
      ),

      // 视频库 Tab
      GoRoute(
        path: AppRoutes.videoList,
        name: 'videoListTab',
        builder: (context, state) => const MainPage(initialIndex: 1),
      ),

      // 笔记 Tab
      GoRoute(
        path: AppRoutes.notes,
        name: 'notesTab',
        builder: (context, state) => const MainPage(initialIndex: 2),
      ),

      // 我的 Tab
      GoRoute(
        path: AppRoutes.profile,
        name: 'profileTab',
        builder: (context, state) => const MainPage(initialIndex: 3),
      ),

      // 视频列表（完整页面）
      GoRoute(
        path: '/videos/all',
        name: 'videoList',
        builder: (context, state) => const VideoListPage(),
      ),

      // 视频播放器
      GoRoute(
        path: AppRoutes.videoPlayer,
        name: 'videoPlayer',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return VideoPlayerPage(videoId: id);
        },
      ),

      // 笔记列表（完整页面）
      GoRoute(
        path: '/notes/all',
        name: 'noteList',
        builder: (context, state) => const NotesPage(),
      ),

      // 思维导图列表（完整页面）
      GoRoute(
        path: AppRoutes.mindmap,
        name: 'mindmap',
        builder: (context, state) => const MindMapPage(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'mindmapEditor',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return MindMapEditorPage(mindMapId: id);
            },
          ),
        ],
      ),

      // 设置页
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],

    // 错误处理
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '页面未找到',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );
}

