import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/mindmap_providers.dart';
import '../providers/note_providers.dart';
import '../../domain/services/mindmap_generator_service.dart';
import '../../core/constants/app_colors.dart';
import 'mindmap_editor_page.dart';

/// 思维导图页面
class MindMapPage extends ConsumerWidget {
  const MindMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mindMapsAsync = ref.watch(allMindMapsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('思维导图'),
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
      body: mindMapsAsync.when(
        data: (mindMaps) {
          if (mindMaps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '还没有思维导图',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '从笔记生成或手动创建思维导图',
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
            itemCount: mindMaps.length,
            itemBuilder: (context, index) {
              final mindMap = mindMaps[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MindMapEditorPage(
                          mindMapId: mindMap.id,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.account_tree,
                                color: AppColors.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mindMap.title,
                                    style: Theme.of(context).textTheme.titleMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (mindMap.description != null &&
                                      mindMap.description!.isNotEmpty)
                                    Text(
                                      mindMap.description!,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                mindMap.isFavorite ? Icons.star : Icons.star_outline,
                                color: mindMap.isFavorite ? Colors.amber : null,
                              ),
                              onPressed: () async {
                                final repository = ref.read(mindMapRepositoryProvider);
                                await repository.toggleFavorite(mindMap.id);
                              },
                            ),
                          ],
                        ),
                        if (mindMap.tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: mindMap.tags.take(3).map((tag) {
                              return Chip(
                                label: Text(
                                  tag,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                        ],
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
        heroTag: 'mindmap_page_fab',
        onPressed: () => _showCreateOptions(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新建导图'),
      ),
    );
  }

  void _showCreateOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.note),
              title: const Text('从笔记生成'),
              subtitle: const Text('根据现有笔记自动生成思维导图'),
              onTap: () {
                Navigator.pop(context);
                _generateFromNotes(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('手动创建'),
              subtitle: const Text('创建空白思维导图并手动添加节点'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MindMapEditorPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateFromNotes(BuildContext context, WidgetRef ref) async {
    try {
      // 获取所有笔记
      final notesAsync = await ref.read(allNotesProvider.future);
      
      if (notesAsync.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('还没有笔记，无法生成思维导图')),
          );
        }
        return;
      }

      if (!context.mounted) return;

      // 显示生成对话框
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
                  Text('正在生成思维导图...'),
                ],
              ),
            ),
          ),
        ),
      );

      // 生成思维导图
      final generator = MindMapGeneratorService();
      final mindMap = await generator.generateFromNotes(
        notes: notesAsync,
        title: '笔记思维导图',
      );

      // 保存到数据库
      final repository = ref.read(mindMapRepositoryProvider);
      final mindMapId = await repository.createMindMap(mindMap);

      if (context.mounted) {
        Navigator.pop(context); // 关闭加载对话框
        
        // 跳转到编辑器
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MindMapEditorPage(mindMapId: mindMapId),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('思维导图生成成功！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('生成失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

