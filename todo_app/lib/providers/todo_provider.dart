import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../models/category.dart' as TodoCategory;
import '../services/todo_service.dart';

class TodoProvider with ChangeNotifier {
  List<Todo> _todos = [];
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  bool _isLoading = false;
  
  final TodoService _todoService;

  TodoProvider(this._todoService) {
    loadTodos();
  }

  List<Todo> get todos => _getFilteredTodos();
  List<Todo> get allTodos => List.unmodifiable(_todos);
  String get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  List<Todo> get pendingTodos => _todos.where((todo) => todo.status == TodoStatus.pending).toList();
  List<Todo> get inProgressTodos => _todos.where((todo) => todo.status == TodoStatus.inProgress).toList();
  List<Todo> get completedTodos => _todos.where((todo) => todo.status == TodoStatus.completed).toList();
  List<Todo> get cancelledTodos => _todos.where((todo) => todo.status == TodoStatus.cancelled).toList();

  int get totalTodos => _todos.length;
  int get pendingCount => pendingTodos.length;
  int get inProgressCount => inProgressTodos.length;
  int get completedCount => completedTodos.length;
  int get cancelledCount => cancelledTodos.length;
  int get activeCount => pendingCount + inProgressCount;
  double get completionRate => totalTodos == 0 ? 0.0 : completedCount / totalTodos;

  List<Todo> _getFilteredTodos() {
    List<Todo> filtered = List.from(_todos);

    // 按分類過濾
    if (_selectedCategoryId != 'all') {
      filtered = filtered.where((todo) => todo.category == _selectedCategoryId).toList();
    }

    // 按搜尋查詢過濾
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((todo) {
        return todo.title.toLowerCase().contains(query) ||
            (todo.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // 排序：按狀態優先級排序（進行中 > 待處理 > 已完成 > 已取消）
    filtered.sort((a, b) {
      if (a.status != b.status) {
        // 狀態優先級排序
        const statusOrder = {
          TodoStatus.inProgress: 0,
          TodoStatus.pending: 1,
          TodoStatus.completed: 2,
          TodoStatus.cancelled: 3,
        };
        return statusOrder[a.status]!.compareTo(statusOrder[b.status]!);
      }
      
      if (a.priority != b.priority) {
        return b.priority.index.compareTo(a.priority.index); // 高優先級在前
      }
      
      return b.createdAt.compareTo(a.createdAt); // 新建的在前
    });

    return filtered;
  }

  Future<void> loadTodos() async {
    _setLoading(true);
    try {
      _todos = await _todoService.getTodos();
      notifyListeners();
    } catch (e) {
      print('Error loading todos: $e');
    }
    _setLoading(false);
  }

  Future<bool> addTodo(Todo todo) async {
    _setLoading(true);
    try {
      final success = await _todoService.addTodo(todo);
      if (success) {
        _todos.add(todo);
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error adding todo: $e');
    }
    _setLoading(false);
    return false;
  }

  Future<bool> updateTodo(Todo updatedTodo) async {
    _setLoading(true);
    try {
      final success = await _todoService.updateTodo(updatedTodo);
      if (success) {
        final index = _todos.indexWhere((todo) => todo.id == updatedTodo.id);
        if (index != -1) {
          _todos[index] = updatedTodo;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      print('Error updating todo: $e');
    }
    _setLoading(false);
    return false;
  }

  Future<bool> deleteTodo(String id) async {
    _setLoading(true);
    try {
      final success = await _todoService.deleteTodo(id);
      if (success) {
        _todos.removeWhere((todo) => todo.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error deleting todo: $e');
    }
    _setLoading(false);
    return false;
  }

  Future<bool> toggleTodoStatus(String id) async {
    try {
      final success = await _todoService.toggleTodoStatus(id);
      if (success) {
        final index = _todos.indexWhere((todo) => todo.id == id);
        if (index != -1) {
          final currentTodo = _todos[index];
          final newStatus = currentTodo.status == TodoStatus.completed
              ? TodoStatus.pending
              : TodoStatus.completed;
          
          final DateTime? completedAt = newStatus == TodoStatus.completed
              ? DateTime.now()
              : null;
              
          _todos[index] = currentTodo.copyWith(
            status: newStatus,
            completedAt: completedAt,
          );
          
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      print('Error toggling todo status: $e');
    }
    return false;
  }

  Future<bool> updateTodoStatus(String id, TodoStatus newStatus) async {
    try {
      final index = _todos.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        final currentTodo = _todos[index];
        
        final DateTime? completedAt = newStatus == TodoStatus.completed
            ? DateTime.now()
            : (currentTodo.status == TodoStatus.completed && newStatus != TodoStatus.completed)
                ? null
                : currentTodo.completedAt;
                
        final updatedTodo = currentTodo.copyWith(
          status: newStatus,
          completedAt: completedAt,
        );
        
        final success = await _todoService.updateTodo(updatedTodo);
        if (success) {
          _todos[index] = updatedTodo;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      print('Error updating todo status: $e');
    }
    return false;
  }

  void setSelectedCategory(String categoryId) {
    if (_selectedCategoryId != categoryId) {
      _selectedCategoryId = categoryId;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  List<Todo> getTodosByCategory(String categoryId) {
    return _todos.where((todo) => todo.category == categoryId).toList();
  }

  Map<String, int> getCategoryCounts() {
    final Map<String, int> counts = {};
    
    // 初始化所有分類計數為 0
    for (final category in TodoCategory.Category.defaultCategories) {
      counts[category.id] = 0;
    }
    
    // 計算每個分類的活躍待辦事項數量（待處理和進行中）
    for (final todo in _todos) {
      if (todo.status == TodoStatus.pending || todo.status == TodoStatus.inProgress) {
        counts[todo.category] = (counts[todo.category] ?? 0) + 1;
      }
    }
    
    return counts;
  }

  List<Todo> getTodosForToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return _todos.where((todo) {
      if (todo.dueDate == null) return false;
      return todo.dueDate!.isAfter(today) && todo.dueDate!.isBefore(tomorrow);
    }).toList();
  }

  List<Todo> getOverdueTodos() {
    final now = DateTime.now();
    
    return _todos.where((todo) {
      if (todo.dueDate == null || 
          todo.status == TodoStatus.completed ||
          todo.status == TodoStatus.cancelled) return false;
      return todo.dueDate!.isBefore(now);
    }).toList();
  }

  Future<bool> clearCompletedTodos() async {
    _setLoading(true);
    try {
      final completedIds = _todos
          .where((todo) => todo.status == TodoStatus.completed)
          .map((todo) => todo.id)
          .toList();
      
      bool allDeleted = true;
      for (final id in completedIds) {
        final success = await _todoService.deleteTodo(id);
        if (!success) allDeleted = false;
      }
      
      if (allDeleted) {
        _todos.removeWhere((todo) => todo.status == TodoStatus.completed);
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error clearing completed todos: $e');
    }
    _setLoading(false);
    return false;
  }
}