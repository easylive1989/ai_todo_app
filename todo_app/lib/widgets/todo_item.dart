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
    final isOverdue = todo.dueDate != null && 
        todo.dueDate!.isBefore(DateTime.now()) && 
        !isCompleted;

    return Card(
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: (value) {
            context.read<TodoProvider>().toggleTodoStatus(todo.id);
          },
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted 
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
                    color: isCompleted 
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
          ListTile(
            leading: Icon(
              todo.status == TodoStatus.completed ? Icons.undo : Icons.done,
            ),
            title: Text(
              todo.status == TodoStatus.completed ? '標記為未完成' : '標記為已完成',
            ),
            onTap: () {
              Navigator.pop(context);
              context.read<TodoProvider>().toggleTodoStatus(todo.id);
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
}