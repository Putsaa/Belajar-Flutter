import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../helpers/database_helper.dart';
import '../helpers/notification_helper.dart';
import 'add_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Todo> todos = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshTodos();
  }

  Future _refreshTodos() async {
    setState(() => isLoading = true);
    todos = await DatabaseHelper.instance.getTodos();
    setState(() => isLoading = false);
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFEF4444); // Red
      case 'Medium':
        return const Color(0xFFF59E0B); // Amber
      case 'Low':
        return const Color(0xFF10B981); // Green
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/logo.png',
                              width: 48,
                              height: 48,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "My Tasks",
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${todos.where((t) => t.isDone == 0).length} pending tasks",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)))
                    : todos.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 10, bottom: 100),
                            itemCount: todos.length,
                            itemBuilder: (context, index) {
                              return _buildTodoCard(todos[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        height: 64,
        width: 64,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEC4899).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddEditScreen()),
            );
            _refreshTodos();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, size: 32, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 20),
          Text(
            "All caught up!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Time to add a new grand task.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoCard(Todo todo) {
    final bool isDone = todo.isDone == 1;
    final Color priorityColor = _getPriorityColor(todo.priority);
    
    String deadlineText = '';
    if (todo.deadline != null) {
      final dt = DateTime.parse(todo.deadline!);
      deadlineText = DateFormat('dd MMM yyyy, HH:mm').format(dt);
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddEditScreen(todo: todo)),
        );
        _refreshTodos();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDone 
                ? const Color(0xFF10B981).withOpacity(0.3) 
                : priorityColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  todo.isDone = isDone ? 0 : 1;
                  await DatabaseHelper.instance.updateTodo(todo);
                  if (todo.isDone == 1 && todo.id != null) {
                     // Cancel notification if marked done
                     await NotificationHelper().cancelNotification(todo.id!);
                  }
                  _refreshTodos();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isDone
                        ? const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF047857)])
                        : null,
                    border: Border.all(
                      color: isDone ? Colors.transparent : priorityColor,
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDone ? Colors.white54 : Colors.white,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.white54,
                      ),
                    ),
                    if (todo.target.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        ' ${todo.target}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDone ? Colors.white38 : const Color(0xFFEC4899),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (deadlineText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: isDone ? Colors.white38 : Colors.white60),
                          const SizedBox(width: 4),
                          Text(
                            deadlineText,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDone ? Colors.white38 : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFF43F5E)),
                onPressed: () async {
                  await DatabaseHelper.instance.deleteTodo(todo.id!);
                  await NotificationHelper().cancelNotification(todo.id!);
                  _refreshTodos();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
