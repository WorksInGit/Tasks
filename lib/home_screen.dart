import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'task_controller.dart';
import 'task.dart';
import 'package:flutter/services.dart'; // added for haptics

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showAddTaskModal() {
    final TextEditingController titleController = TextEditingController();
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: CupertinoPopupSurface(
            child: SafeArea(
              top: false,
              child: Container(
                color: CupertinoColors.systemBackground.resolveFrom(ctx),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Add Task',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CupertinoTextField(
                      controller: titleController,
                      placeholder: 'Task title',
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton.filled(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Text('Add'),
                          onPressed: () {
                            final text = titleController.text.trim();
                            if (text.isNotEmpty) {
                              final task = Task(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                title: text,
                              );
                              context.read<TasksController>().addTask(task);
                            }
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext ctx, Task task) {
    return showCupertinoModalPopup<bool>(
      context: ctx,
      builder: (c) {
        return CupertinoActionSheet(
          title: Text('Delete "${task.title}"?'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(c, true),
              isDestructiveAction: true,
              child: const Text('Delete'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
        );
      },
    ).then((value) => value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksController>().tasks;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Tasks'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showAddTaskModal,
          child: const Icon(CupertinoIcons.add, size: 25),
        ),
      ),
      child: SafeArea(
        child: tasks.isEmpty
            ? const Center(
                child: Text(
                  'No tasks',
                  style: TextStyle(color: CupertinoColors.inactiveGray),
                ),
              )
            : ListView.separated(
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Dismissible(
                    key: ValueKey(task.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) =>
                        _confirmDelete(context, task),
                    onDismissed: (_) =>
                        context.read<TasksController>().removeTask(task.id),
                    background: Container(
                      color: CupertinoColors.systemRed.resolveFrom(context),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 16),
                      child: Row(
                        children: const [
                          Icon(
                            CupertinoIcons.delete_solid,
                            color: CupertinoColors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: CupertinoColors.white),
                          ),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      color: CupertinoColors.systemRed.resolveFrom(context),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Icon(
                            CupertinoIcons.delete_solid,
                            color: CupertinoColors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: CupertinoColors.white),
                          ),
                        ],
                      ),
                    ),
                    child: CupertinoListTile(
                      leading: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.read<TasksController>().toggleDone(task.id);
                        },
                        child: Icon(
                          task.isDone
                              ? CupertinoIcons.check_mark_circled_solid
                              : CupertinoIcons.circle,
                          color: task.isDone
                              ? CupertinoColors.systemBlue
                              : CupertinoColors.inactiveGray,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: task.isDone
                              ? CupertinoColors.inactiveGray
                              : CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
