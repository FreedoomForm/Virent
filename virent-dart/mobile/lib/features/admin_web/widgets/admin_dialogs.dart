import 'admin_table_page.dart' show adminPrimaryColor, adminPrimaryForeground;
// admin_dialogs.dart — Reusable dialog & action helpers for the admin web
// panel pages.
//
// Wired into every page in `lib/features/admin_web/pages/`. Each helper
// takes a [BuildContext] (and sometimes a [WidgetRef]) plus a small payload
// and handles the entire UX flow: opens an AlertDialog, collects input,
// invokes the supplied async callback, shows a SnackBar with the result and
// dismisses the loading overlay.
//
// Functions exposed:
//   - showAdminInfoDialog       → simple "OK" alert
//   - showAdminConfirmDialog    → "Удалить?" / "Отмена" confirmation
//   - showAdminViewDialog       → read-only dump of a Map<String,dynamic>
//   - showAdminFormDialog       → create/edit form (returns Map of values)
//   - showAdminDeleteDialog     → confirmation → call delete action
//   - showAdminSnack            → inline SnackBar feedback
//   - runAdminAction            → wraps an async action with loading + SnackBar
//
// Keeping these here lets each page widget stay declarative: page code only
// has to declare which fields an entity has and which provider to invalidate.

import 'package:flutter/material.dart';

/// One form field descriptor used by [showAdminFormDialog].
class AdminField {
  const AdminField({
    required this.key,
    required this.label,
    this.hint,
    this.obscure = false,
    this.multiline = false,
    this.initial = '',
  });
  final String key;
  final String label;
  final String? hint;
  final bool obscure;
  final bool multiline;
  final String initial;
}

/// Shows a simple informational alert with one "OK" button.
Future<void> showAdminInfoDialog(
  BuildContext context,
  String title,
  String message,
) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Inline SnackBar feedback helper — no dialog.
void showAdminSnack(BuildContext context, String message, {bool isError = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : null,
    ),
  );
}

/// Wraps an async action: shows a non-dismissible loading spinner, awaits
/// [action], then dismisses the spinner and shows a SnackBar with either
/// [successMessage] or the error text.
Future<void> runAdminAction(
  BuildContext context,
  Future<void> Function() action, {
  String successMessage = 'Готово',
}) async {
  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    await action();
    if (context.mounted) {
      Navigator.of(context).pop();
      showAdminSnack(context, successMessage);
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      showAdminSnack(context, 'Ошибка: $e', isError: true);
    }
  }
}

/// Shows a confirmation dialog. Calls [onConfirm] when user taps the confirm
/// button. Wraps the call with [runAdminAction] for loading + SnackBar
/// feedback.
Future<void> showAdminConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required Future<void> Function() onConfirm,
  String confirmLabel = 'Подтвердить',
  String cancelLabel = 'Отмена',
  String successMessage = 'Готово',
  Color confirmColor = Colors.red,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    if (!context.mounted) return;
    await runAdminAction(context, onConfirm, successMessage: successMessage);
  }
}

/// Convenience wrapper for delete confirmations.
Future<void> showAdminDeleteDialog(
  BuildContext context, {
  required String name,
  required Future<void> Function() onDelete,
}) async {
  await showAdminConfirmDialog(
    context,
    title: 'Удалить?',
    message: 'Удалить "$name"? Действие нельзя отменить.',
    confirmLabel: 'Удалить',
    successMessage: 'Удалено',
    onConfirm: onDelete,
  );
}

/// Shows a read-only dialog listing every key/value pair of [item].
Future<void> showAdminViewDialog(
  BuildContext context, {
  required String title,
  required Map<String, dynamic> item,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: item.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                    children: [
                      TextSpan(
                        text: '${e.key}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: '${e.value}'),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    ),
  );
}

/// Shows a bulk action confirmation dialog. Refuses to proceed when
/// [selectedCount] is zero (shows an error SnackBar instead).
Future<void> showAdminBulkActionDialog(
  BuildContext context, {
  required String title,
  required String message,
  required int selectedCount,
  required Future<void> Function() onConfirm,
  String confirmLabel = 'Подтвердить',
  String successMessage = 'Готово',
}) async {
  if (selectedCount == 0) {
    if (!context.mounted) return;
    showAdminSnack(context, 'Нет выбранных элементов', isError: true);
    return;
  }
  await showAdminConfirmDialog(
    context,
    title: title,
    message: '$message (Выбрано: $selectedCount)',
    onConfirm: onConfirm,
    confirmLabel: confirmLabel,
    successMessage: successMessage,
  );
}

/// Shows a filter form dialog with one [TextField] per [AdminField]. When
/// the user taps "Применить", [onApply] is called with the entered values.
Future<void> showAdminFilterDialog(
  BuildContext context, {
  required String title,
  required List<AdminField> fields,
  required Future<void> Function(Map<String, dynamic> values) onApply,
  String successMessage = 'Фильтры применены',
}) async {
  final controllers = {
    for (final f in fields) f.key: TextEditingController(text: f.initial),
  };
  Map<String, dynamic>? result;
  try {
    result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: fields
                    .map((f) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: TextField(
                            controller: controllers[f.key],
                            obscureText: f.obscure,
                            maxLines: f.multiline ? 3 : 1,
                            decoration: InputDecoration(
                              labelText: f.label,
                              hintText: f.hint,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                final values = {
                  for (final f in fields) f.key: null,
                };
                Navigator.of(ctx).pop(values);
              },
              child: const Text('Сбросить'),
            ),
            ElevatedButton(
              onPressed: () {
                final values = {
                  for (final f in fields) f.key: controllers[f.key]!.text,
                };
                Navigator.of(ctx).pop(values);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: adminPrimaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Применить'),
            ),
          ],
        );
      },
    );
  } finally {
    for (final c in controllers.values) {
      c.dispose();
    }
  }
  if (result == null) return;
  // When the user tapped "Сбросить", values are all null — still call onApply
  // so the page can clear its filter state.
  final values = Map<String, dynamic>.from(result);
  if (!context.mounted) return;
  await runAdminAction(
    context,
    () => onApply(values),
    successMessage: successMessage,
  );
}

/// Shows a form dialog with one [TextField] per [AdminField]. When the user
/// taps the submit button, [onSubmit] is called with a Map of field-key →
/// entered text. A loading spinner is shown while [onSubmit] is running and a
/// SnackBar with the result is displayed afterwards.
///
/// Pass [isEdit] to swap the submit label to "Сохранить" and the success
/// message to "Сохранено".
Future<void> showAdminFormDialog(
  BuildContext context, {
  required String title,
  required List<AdminField> fields,
  required Future<void> Function(Map<String, dynamic> values) onSubmit,
  bool isEdit = false,
  String? successMessage,
}) async {
  final controllers = {
    for (final f in fields) f.key: TextEditingController(text: f.initial),
  };
  Map<String, dynamic>? result;
  try {
    result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: fields
                    .map((f) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: TextField(
                            controller: controllers[f.key],
                            obscureText: f.obscure,
                            maxLines: f.multiline ? 3 : 1,
                            decoration: InputDecoration(
                              labelText: f.label,
                              hintText: f.hint,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final values = {
                  for (final f in fields) f.key: controllers[f.key]!.text,
                };
                Navigator.of(ctx).pop(values);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: adminPrimaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Сохранить' : 'Создать'),
            ),
          ],
        );
      },
    );
  } finally {
    for (final c in controllers.values) {
      c.dispose();
    }
  }
  if (result == null) return;
  final values = Map<String, dynamic>.from(result);
  if (!context.mounted) return;
  await runAdminAction(
    context,
    () => onSubmit(values),
    successMessage: successMessage ?? (isEdit ? 'Сохранено' : 'Создано'),
  );
}
