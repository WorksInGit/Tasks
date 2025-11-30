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
  // helper to format date/time simply
  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dtDay = DateTime(dt.year, dt.month, dt.day);

    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    if (dtDay == today) return 'Today, $timeStr';
    if (dtDay == tomorrow) return 'Tomorrow, $timeStr';
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d $timeStr';
  }

  Future<DateTime?> _showDueDatePicker(BuildContext ctx, DateTime? initial) {
    final DateTime now = DateTime.now();
    // minimum allowed is now (disallow past dates/times)
    final DateTime minDate = now;
    // default initial - keep at least minDate
    DateTime temp = initial ?? minDate.add(const Duration(hours: 1));
    if (temp.isBefore(minDate)) temp = minDate;

    return showCupertinoModalPopup<DateTime>(
      context: ctx,
      builder: (c) {
        return Container(
          height: 320,
          color: CupertinoColors.systemBackground.resolveFrom(c),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // toolbar
                SizedBox(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(c, null),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Done'),
                        onPressed: () => Navigator.pop(c, temp),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.dateAndTime,
                        minimumDate: minDate,
                        initialDateTime: temp,
                        use24hFormat: false,
                        onDateTimeChanged: (DateTime newDt) {
                          // keep temp always >= minDate
                          if (newDt.isBefore(minDate)) {
                            setState(() => temp = minDate);
                          } else {
                            setState(() => temp = newDt);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddTaskModal() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    DateTime? selectedDue;

    await showCupertinoModalPopup(
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
                    const SizedBox(height: 12),
                    // short description section
                    CupertinoTextField(
                      controller: descController,
                      placeholder: 'Short description (optional)',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    // due date / time selection row
                    GestureDetector(
                      onTap: () async {
                        final picked = await _showDueDatePicker(
                          ctx,
                          selectedDue,
                        );
                        if (picked != null) {
                          selectedDue = picked;
                          // rebuild the modal to show updated date
                          // by popping and reopening modal with updated values.
                          // Simpler approach: close current popup and re-open with preserved controllers.
                          Navigator.pop(ctx);
                          // reopen modal with preserved controllers and selectedDue
                          // call the same function again but provide selectedDue via closure
                          // (quick approach: call _showAddTaskModal again with prefilled values).
                          // To keep code concise here we just reopen with the current values:
                          _reopenAddModalWithValues(
                            titleController,
                            descController,
                            selectedDue,
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors
                              .secondarySystemGroupedBackground
                              .resolveFrom(ctx),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                selectedDue == null
                                    ? 'No due date'
                                    : _formatDateTime(selectedDue!),
                                style: TextStyle(
                                  color: selectedDue == null
                                      ? CupertinoColors.inactiveGray
                                      : CupertinoColors.label.resolveFrom(ctx),
                                ),
                              ),
                            ),
                            const Icon(CupertinoIcons.calendar, size: 20),
                          ],
                        ),
                      ),
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
                                description: descController.text.trim().isEmpty
                                    ? null
                                    : descController.text.trim(),
                                dueDate: selectedDue,
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

  // reopen helper to preserve field values and selectedDue after picking date
  void _reopenAddModalWithValues(
    TextEditingController titleCtrl,
    TextEditingController descCtrl,
    DateTime? due,
  ) {
    final titleText = titleCtrl.text;
    final descText = descCtrl.text;
    // close any existing popup before reopening to avoid stacking
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
                        controller: TextEditingController.fromValue(
                          titleCtrl.value,
                        ),
                        placeholder: 'Task title',
                        autofocus: true,
                      ),
                      const SizedBox(height: 12),
                      CupertinoTextField(
                        controller: TextEditingController.fromValue(
                          descCtrl.value,
                        ),
                        placeholder: 'Short description (optional)',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          final picked = await _showDueDatePicker(ctx, due);
                          if (picked != null) {
                            Navigator.pop(ctx);
                            _reopenAddModalWithValues(
                              TextEditingController(text: titleText),
                              TextEditingController(text: descText),
                              picked,
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors
                                .secondarySystemGroupedBackground
                                .resolveFrom(ctx),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  due == null
                                      ? 'No due date'
                                      : _formatDateTime(due),
                                  style: TextStyle(
                                    color: due == null
                                        ? CupertinoColors.inactiveGray
                                        : CupertinoColors.label.resolveFrom(
                                            ctx,
                                          ),
                                  ),
                                ),
                              ),
                              const Icon(CupertinoIcons.calendar, size: 20),
                            ],
                          ),
                        ),
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
                              final text = titleText.trim();
                              if (text.isNotEmpty) {
                                final task = Task(
                                  id: DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                                  title: text,
                                  description: descText.trim().isEmpty
                                      ? null
                                      : descText.trim(),
                                  dueDate: due,
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
    });
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

  // new: show iOS-style details popup for a task
  void _showTaskDetails(Task task) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return CupertinoPopupSurface(
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: CupertinoColors.systemBackground.resolveFrom(ctx),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // CupertinoButton(
                      //   padding: EdgeInsets.zero,
                      //   onPressed: () => Navigator.pop(ctx),
                      //   child: const Icon(CupertinoIcons.clear),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Text(
                    task.description ?? 'No description',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  // Due date/time
                  Row(
                    children: [
                      const Icon(CupertinoIcons.calendar, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.dueDate == null
                              ? 'No due date'
                              : _formatDateTime(task.dueDate!),
                          style: TextStyle(
                            color: task.dueDate == null
                                ? CupertinoColors.inactiveGray
                                : CupertinoColors.label.resolveFrom(ctx),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Close'),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
                    // wrap the tile so tapping it shows details
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showTaskDetails(task),
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
                    ),
                  );
                },
              ),
      ),
    );
  }
}
