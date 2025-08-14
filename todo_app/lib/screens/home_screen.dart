import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/category.dart';
import '../widgets/todo_item.dart';
import 'add_todo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Todo App',
          style: TextStyle(color: Colors.orange),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // 搜尋列
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜尋待辦事項...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<TodoProvider>().clearSearch();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  onChanged: (value) {
                    context.read<TodoProvider>().setSearchQuery(value);
                  },
                ),
              ),
              // 標籤頁
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.list), text: '全部'),
                  Tab(icon: Icon(Icons.pending_actions), text: '未完成'),
                  Tab(icon: Icon(Icons.done_all), text: '已完成'),
                ],
              ),
            ],
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodoList(context, showAll: true),
          _buildTodoList(context, showCompleted: false),
          _buildTodoList(context, showCompleted: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddTodoScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          final categoryCounts = todoProvider.getCategoryCounts();
          
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Todo App',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '統計資訊',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatItem(
                          context,
                          '總計',
                          todoProvider.totalTodos.toString(),
                          Icons.list_alt,
                        ),
                        const SizedBox(width: 16),
                        _buildStatItem(
                          context,
                          '未完成',
                          todoProvider.pendingCount.toString(),
                          Icons.pending_actions,
                        ),
                        const SizedBox(width: 16),
                        _buildStatItem(
                          context,
                          '完成率',
                          '${(todoProvider.completionRate * 100).toInt()}%',
                          Icons.trending_up,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('全部分類'),
                trailing: Text('${todoProvider.pendingCount}'),
                selected: todoProvider.selectedCategoryId == 'all',
                onTap: () {
                  todoProvider.setSelectedCategory('all');
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ...Category.defaultCategories.map((category) {
                final count = categoryCounts[category.id] ?? 0;
                return ListTile(
                  leading: Icon(category.icon, color: category.color),
                  title: Text(category.name),
                  trailing: count > 0 ? Text('$count') : null,
                  selected: todoProvider.selectedCategoryId == category.id,
                  onTap: () {
                    todoProvider.setSelectedCategory(category.id);
                    Navigator.pop(context);
                  },
                );
              }),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: const Text('清除已完成'),
                onTap: () async {
                  if (todoProvider.completedCount > 0) {
                    final confirmed = await _showClearCompletedDialog(context);
                    if (confirmed == true) {
                      await todoProvider.clearCompletedTodos();
                    }
                  }
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 16,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTodoList(BuildContext context, {bool showAll = false, bool? showCompleted}) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        if (todoProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List todos;
        if (showAll) {
          todos = todoProvider.todos;
        } else if (showCompleted == true) {
          todos = todoProvider.completedTodos;
        } else {
          todos = todoProvider.pendingTodos;
        }

        if (todos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  showCompleted == true ? Icons.done_all : Icons.add_task,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  showCompleted == true
                      ? '還沒有已完成的待辦事項'
                      : todoProvider.searchQuery.isNotEmpty
                          ? '找不到符合條件的待辦事項'
                          : '還沒有待辦事項\n點擊 + 按鈕新增第一個',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: todos.length,
          itemBuilder: (context, index) {
            return TodoItem(todo: todos[index]);
          },
        );
      },
    );
  }

  Future<bool?> _showClearCompletedDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除已完成'),
        content: const Text('確定要清除所有已完成的待辦事項嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}