import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';

class TodoService {
  static const String _todosKey = 'todos';
  static TodoService? _instance;
  SharedPreferences? _prefs;

  TodoService._internal();

  static Future<TodoService> getInstance() async {
    _instance ??= TodoService._internal();
    _instance!._prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  Future<List<Todo>> getTodos() async {
    try {
      final String? todosJson = _prefs!.getString(_todosKey);
      if (todosJson == null) return [];

      final List<dynamic> todosList = jsonDecode(todosJson);
      return todosList.map((json) => Todo.fromJson(json)).toList();
    } catch (e) {
      print('Error loading todos: $e');
      return [];
    }
  }

  Future<bool> saveTodos(List<Todo> todos) async {
    try {
      final List<Map<String, dynamic>> todosJson =
          todos.map((todo) => todo.toJson()).toList();
      await _prefs!.setString(_todosKey, jsonEncode(todosJson));
      return true;
    } catch (e) {
      print('Error saving todos: $e');
      return false;
    }
  }

  Future<bool> addTodo(Todo todo) async {
    try {
      final List<Todo> todos = await getTodos();
      todos.add(todo);
      return await saveTodos(todos);
    } catch (e) {
      print('Error adding todo: $e');
      return false;
    }
  }

  Future<bool> updateTodo(Todo updatedTodo) async {
    try {
      final List<Todo> todos = await getTodos();
      final int index = todos.indexWhere((todo) => todo.id == updatedTodo.id);
      
      if (index != -1) {
        todos[index] = updatedTodo;
        return await saveTodos(todos);
      }
      
      return false;
    } catch (e) {
      print('Error updating todo: $e');
      return false;
    }
  }

  Future<bool> deleteTodo(String id) async {
    try {
      final List<Todo> todos = await getTodos();
      todos.removeWhere((todo) => todo.id == id);
      return await saveTodos(todos);
    } catch (e) {
      print('Error deleting todo: $e');
      return false;
    }
  }

  Future<bool> toggleTodoStatus(String id) async {
    try {
      final List<Todo> todos = await getTodos();
      final int index = todos.indexWhere((todo) => todo.id == id);
      
      if (index != -1) {
        final Todo currentTodo = todos[index];
        final TodoStatus newStatus = currentTodo.status == TodoStatus.completed
            ? TodoStatus.pending
            : TodoStatus.completed;
        
        final DateTime? completedAt = newStatus == TodoStatus.completed
            ? DateTime.now()
            : null;
            
        todos[index] = currentTodo.copyWith(
          status: newStatus,
          completedAt: completedAt,
        );
        
        return await saveTodos(todos);
      }
      
      return false;
    } catch (e) {
      print('Error toggling todo status: $e');
      return false;
    }
  }

  Future<List<Todo>> getTodosByCategory(String category) async {
    try {
      final List<Todo> todos = await getTodos();
      return todos.where((todo) => todo.category == category).toList();
    } catch (e) {
      print('Error getting todos by category: $e');
      return [];
    }
  }

  Future<List<Todo>> getTodosByStatus(TodoStatus status) async {
    try {
      final List<Todo> todos = await getTodos();
      return todos.where((todo) => todo.status == status).toList();
    } catch (e) {
      print('Error getting todos by status: $e');
      return [];
    }
  }

  Future<List<Todo>> searchTodos(String query) async {
    try {
      final List<Todo> todos = await getTodos();
      final String lowercaseQuery = query.toLowerCase();
      
      return todos.where((todo) {
        return todo.title.toLowerCase().contains(lowercaseQuery) ||
            (todo.description?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    } catch (e) {
      print('Error searching todos: $e');
      return [];
    }
  }

  Future<bool> clearAllTodos() async {
    try {
      await _prefs!.remove(_todosKey);
      return true;
    } catch (e) {
      print('Error clearing todos: $e');
      return false;
    }
  }
}