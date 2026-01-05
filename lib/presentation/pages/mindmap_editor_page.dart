import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/mind_map.dart';
import '../widgets/mindmap_canvas.dart';
import '../providers/mindmap_providers.dart';
import '../../core/utils/logger.dart';

/// 思维导图编辑器页面
class MindMapEditorPage extends ConsumerStatefulWidget {
  final int? mindMapId;
  final List<MindMapNode>? initialNodes;
  final String? title;

  const MindMapEditorPage({
    super.key,
    this.mindMapId,
    this.initialNodes,
    this.title,
  });

  @override
  ConsumerState<MindMapEditorPage> createState() => _MindMapEditorPageState();
}

class _MindMapEditorPageState extends ConsumerState<MindMapEditorPage> {
  List<MindMapNode> _nodes = [];
  String? _selectedNodeId;
  late TextEditingController _titleController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title ?? '新思维导图');
    
    if (widget.initialNodes != null) {
      _nodes = widget.initialNodes!;
    } else if (widget.mindMapId != null) {
      _loadMindMap();
    }
  }

  Future<void> _loadMindMap() async {
    try {
      final repository = ref.read(mindMapRepositoryProvider);
      final mindMap = await repository.getMindMapById(widget.mindMapId!);
      
      if (mindMap != null) {
        setState(() {
          _titleController.text = mindMap.title;
          final List<dynamic> nodesJson = jsonDecode(mindMap.nodesJson);
          _nodes = nodesJson.map((json) => MindMapNode.fromJson(json)).toList();
        });
      }
    } catch (e) {
      AppLogger.error('加载思维导图失败', e);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          style: Theme.of(context).textTheme.titleLarge,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: '思维导图标题',
          ),
        ),
        actions: [
          if (_selectedNodeId != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editSelectedNode,
              tooltip: '编辑节点',
            ),
          if (_selectedNodeId != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedNode,
              tooltip: '删除节点',
            ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addNode,
            tooltip: '添加节点',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveMindMap,
            tooltip: '保存',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_image',
                child: Row(
                  children: [
                    Icon(Icons.image, size: 18),
                    SizedBox(width: 8),
                    Text('导出为图片'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 18),
                    SizedBox(width: 8),
                    Text('导出为PDF'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'export_image':
                  _exportAsImage();
                  break;
                case 'export_pdf':
                  _exportAsPDF();
                  break;
              }
            },
          ),
        ],
      ),
      body: _nodes.isEmpty
          ? _buildEmptyState()
          : MindMapCanvas(
              nodes: _nodes,
              selectedNodeId: _selectedNodeId,
              onNodeTap: (nodeId) {
                setState(() {
                  _selectedNodeId = nodeId;
                });
              },
              onNodeLongPress: (nodeId) {
                setState(() {
                  _selectedNodeId = nodeId;
                });
                _showNodeMenu(nodeId);
              },
            ),
      floatingActionButton: _nodes.isEmpty
          ? FloatingActionButton.extended(
              heroTag: 'mindmap_editor_fab',
              onPressed: _createRootNode,
              icon: const Icon(Icons.add),
              label: const Text('创建中心节点'),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
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
            '空白画布',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮创建中心节点',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  void _createRootNode() {
    showDialog(
      context: context,
      builder: (context) => _NodeEditorDialog(
        title: '创建中心节点',
        onSave: (title, content) {
          setState(() {
            _nodes.add(MindMapNode(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: title,
              content: content,
              colorHex: 'FF4361EE',
              positionX: 400,
              positionY: 300,
              width: 160,
              height: 80,
              nodeType: 'topic',
            ));
          });
        },
      ),
    );
  }

  void _addNode() {
    if (_selectedNodeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一个父节点')),
      );
      return;
    }

    final parentNode = _nodes.firstWhere((n) => n.id == _selectedNodeId);

    showDialog(
      context: context,
      builder: (context) => _NodeEditorDialog(
        title: '添加子节点',
        onSave: (title, content) {
          setState(() {
            final newNode = MindMapNode(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: title,
              content: content,
              colorHex: parentNode.colorHex,
              positionX: parentNode.positionX + 150,
              positionY: parentNode.positionY + 100,
              width: 120,
              height: 60,
              parentId: parentNode.id,
              nodeType: 'subtopic',
            );
            
            _nodes.add(newNode);
            parentNode.childrenIds.add(newNode.id);
          });
        },
      ),
    );
  }

  void _editSelectedNode() {
    if (_selectedNodeId == null) return;

    final node = _nodes.firstWhere((n) => n.id == _selectedNodeId);

    showDialog(
      context: context,
      builder: (context) => _NodeEditorDialog(
        title: '编辑节点',
        initialTitle: node.title,
        initialContent: node.content,
        onSave: (title, content) {
          setState(() {
            final index = _nodes.indexWhere((n) => n.id == _selectedNodeId);
            _nodes[index] = node.copyWith(title: title, content: content);
          });
        },
      ),
    );
  }

  void _deleteSelectedNode() {
    if (_selectedNodeId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除节点'),
        content: const Text('确定要删除这个节点及其所有子节点吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _deleteNodeRecursive(_selectedNodeId!);
              setState(() {
                _selectedNodeId = null;
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _deleteNodeRecursive(String nodeId) {
    final node = _nodes.firstWhere((n) => n.id == nodeId);
    
    // 递归删除子节点
    for (final childId in node.childrenIds) {
      _deleteNodeRecursive(childId);
    }
    
    // 从父节点中移除
    if (node.parentId != null) {
      final parent = _nodes.firstWhere((n) => n.id == node.parentId);
      parent.childrenIds.remove(nodeId);
    }
    
    // 删除节点本身
    _nodes.removeWhere((n) => n.id == nodeId);
  }

  void _showNodeMenu(String nodeId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑节点'),
              onTap: () {
                Navigator.pop(context);
                _editSelectedNode();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('添加子节点'),
              onTap: () {
                Navigator.pop(context);
                _addNode();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除节点', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteSelectedNode();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMindMap() async {
    if (_nodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('思维导图不能为空')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(mindMapRepositoryProvider);
      final rootNode = _nodes.firstWhere(
        (n) => n.parentId == null,
        orElse: () => _nodes.first,
      );

      if (widget.mindMapId != null) {
        // 更新现有思维导图
        final mindMap = await repository.getMindMapById(widget.mindMapId!);
        if (mindMap != null) {
          mindMap.title = _titleController.text;
          mindMap.nodesJson = jsonEncode(_nodes.map((n) => n.toJson()).toList());
          mindMap.rootNodeId = rootNode.id;
          await repository.updateMindMap(mindMap);
        }
      } else {
        // 创建新思维导图
        final mindMap = MindMap()
          ..title = _titleController.text
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now()
          ..layoutType = MindMapLayoutType.radial
          ..rootNodeId = rootNode.id
          ..nodesJson = jsonEncode(_nodes.map((n) => n.toJson()).toList())
          ..tags = []
          ..description = '';

        await repository.createMindMap(mindMap);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('思维导图已保存'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _exportAsImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导出图片功能开发中...')),
    );
  }

  void _exportAsPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导出PDF功能开发中...')),
    );
  }
}

/// 节点编辑对话框
class _NodeEditorDialog extends StatefulWidget {
  final String title;
  final String? initialTitle;
  final String? initialContent;
  final Function(String title, String? content) onSave;

  const _NodeEditorDialog({
    required this.title,
    this.initialTitle,
    this.initialContent,
    required this.onSave,
  });

  @override
  State<_NodeEditorDialog> createState() => _NodeEditorDialogState();
}

class _NodeEditorDialogState extends State<_NodeEditorDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '节点标题',
              hintText: '输入节点标题',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: '节点内容（可选）',
              hintText: '输入详细内容',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (_titleController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请输入节点标题')),
              );
              return;
            }
            widget.onSave(
              _titleController.text,
              _contentController.text.isEmpty ? null : _contentController.text,
            );
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

