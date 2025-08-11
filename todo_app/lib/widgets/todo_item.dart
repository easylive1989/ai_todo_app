import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../models/category.dart';
import '../providers/todo_provider.dart';
import '../screens/add_todo_screen.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;

  const TodoItem({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    final category = Category.findById(todo.category);
    final isCompleted = todo.status == TodoStatus.completed;
    final isCancelled = todo.status == TodoStatus.cancelled;
    final isInProgress = todo.status == TodoStatus.inProgress;
    final isPending = todo.status == TodoStatus.pending;
    final isOverdue = todo.dueDate != null && 
        todo.dueDate!.isBefore(DateTime.now()) && 
        !isCompleted && !isCancelled;

    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // 左滑 - 顯示刪除確認對話框
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('刪除待辦事項'),
              content: Text('確定要刪除「${todo.title}」嗎？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('刪除'),
                ),
              ],
            ),
          ) ?? false;
        } else if (direction == DismissDirection.startToEnd) {
          // 右滑 - 切換到下一個狀態
          String nextStatusText = '';
          if (isPending) {
            context.read<TodoProvider>().updateTodoStatus(todo.id, TodoStatus.inProgress);
            nextStatusText = '已標記為進行中';
          } else if (isInProgress) {
            context.read<TodoProvider>().updateTodoStatus(todo.id, TodoStatus.completed);
            nextStatusText = '已標記為完成';
          } else if (isCompleted) {
            context.read<TodoProvider>().updateTodoStatus(todo.id, TodoStatus.pending);
            nextStatusText = '已標記為待處理';
          } else if (isCancelled) {
            context.read<TodoProvider>().updateTodoStatus(todo.id, TodoStatus.pending);
            nextStatusText = '已重新開啟';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(nextStatusText),
              duration: const Duration(seconds: 2),
              backgroundColor: _getStatusColor(todo.status),
            ),
          );
          return false; // 不要真的移除項目，只是改變狀態
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          // 刪除待辦事項
          context.read<TodoProvider>().deleteTodo(todo.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('待辦事項已刪除'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              _getNextStatusIcon(todo.status),
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              _getNextStatusText(todo.status),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '刪除',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.delete,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
      child: Card(
        child: ListTile(
          leading: _buildStatusIndicator(context, todo.status),
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: (isCompleted || isCancelled) ? TextDecoration.lineThrough : null,
              color: (isCompleted || isCancelled)
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                  : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (todo.description != null && todo.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    todo.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: (isCompleted || isCancelled)
                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  // 分類標籤
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: category.color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category.icon,
                          size: 12,
                          color: category.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 10,
                            color: category.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // 優先級標籤
                  _buildPriorityChip(context, todo.priority),
                  
                  const Spacer(),
                  
                  // 到期時間
                  if (todo.dueDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOverdue 
                            ? Colors.red.withOpacity(0.1)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isOverdue 
                              ? Colors.red.withOpacity(0.3)
                              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 10,
                            color: isOverdue ? Colors.red : Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatDueDate(todo.dueDate!),
                            style: TextStyle(
                              fontSize: 9,
                              color: isOverdue ? Colors.red : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddTodoScreen(todoToEdit: todo),
              ),
            );
          },
          onLongPress: () {
            _showOptionsBottomSheet(context, todo);
          },
        ),
      ),
    );
  }

  Widget _buildPriorityChip(BuildContext context, Priority priority) {
    Color color;
    String label;
    
    switch (priority) {
      case Priority.high:
        color = Colors.red;
        label = '高';
        break;
      case Priority.medium:
        color = Colors.orange;
        label = '中';
        break;
      case Priority.low:
        color = Colors.green;
        label = '低';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDateDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueDateDay == today) {
      return '今天 ${DateFormat('HH:mm').format(dueDate)}';
    } else if (dueDateDay == tomorrow) {
      return '明天 ${DateFormat('HH:mm').format(dueDate)}';
    } else {
      return DateFormat('MM/dd HH:mm').format(dueDate);
    }
  }

  void _showOptionsBottomSheet(BuildContext context, Todo todo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          if (todo.status != TodoStatus.cancelled)
            ListTile(
              leading: Icon(_getNextStatusIcon(todo.status)),
              title: Text(_getNextStatusText(todo.status)),
              onTap: () {
                Navigator.pop(context);
                _moveToNextStatus(context, todo);
              },
            ),
          if (todo.status != TodoStatus.cancelled)
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.orange),
              title: const Text('取消'),
              onTap: () {
                Navigator.pop(context);
                context.read<TodoProvider>().updateTodoStatus(todo.id, TodoStatus.cancelled);
              },
            ),
          if (todo.status == TodoStatus.cancelled)
            ListTile(
              leading: const Icon(Icons.restart_alt, color: Colors.blue),
              title: const Text('重新開啟'),
              onTap: () {
                Navigator.pop(context);
                context.read<TodoProvider>().updateTodoStatus(todo.id, TodoStatus.pending);
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('編輯'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddTodoScreen(todoToEdit: todo),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('刪除', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteDialog(context, todo);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除待辦事項'),
        content: Text('確定要刪除「${todo.title}」嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TodoProvider>().deleteTodo(todo.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('待辦事項已刪除'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, TodoStatus status) {
    IconData icon;
    Color color;
    
    switch (status) {
      case TodoStatus.pending:
        icon = Icons.radio_button_unchecked;
        color = Theme.of(context).colorScheme.outline;
        break;
      case TodoStatus.inProgress:
        icon = Icons.play_circle_outline;
        color = Colors.blue;
        break;
      case TodoStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case TodoStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.grey;
        break;
    }
    
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: () => _moveToNextStatus(context, todo),
    );
  }

  IconData _getNextStatusIcon(TodoStatus status) {
    switch (status) {
      case TodoStatus.pending:
        return Icons.play_circle_outline;
      case TodoStatus.inProgress:
        return Icons.check_circle;
      case TodoStatus.completed:
        return Icons.radio_button_unchecked;
      case TodoStatus.cancelled:
        return Icons.restart_alt;
    }
  }

  String _getNextStatusText(TodoStatus status) {
    switch (status) {
      case TodoStatus.pending:
        return '開始進行';
      case TodoStatus.inProgress:
        return '標記完成';
      case TodoStatus.completed:
        return '重新開啟';
      case TodoStatus.cancelled:
        return '重新開啟';
    }
  }

  Color _getStatusColor(TodoStatus status) {
    switch (status) {
      case TodoStatus.pending:
        return Colors.orange;
      case TodoStatus.inProgress:
        return Colors.blue;
      case TodoStatus.completed:
        return Colors.green;
      case TodoStatus.cancelled:
        return Colors.grey;
    }
  }

  void _moveToNextStatus(BuildContext context, Todo todo) {
    TodoStatus nextStatus;
    switch (todo.status) {
      case TodoStatus.pending:
        nextStatus = TodoStatus.inProgress;
        break;
      case TodoStatus.inProgress:
        nextStatus = TodoStatus.completed;
        break;
      case TodoStatus.completed:
        nextStatus = TodoStatus.pending;
        break;
      case TodoStatus.cancelled:
        nextStatus = TodoStatus.pending;
        break;
    }
    context.read<TodoProvider>().updateTodoStatus(todo.id, nextStatus);
  }
}