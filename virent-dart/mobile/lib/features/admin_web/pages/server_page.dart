// server_page.dart — Virent admin server / Docker control (web panel).
//
// Ported from the old admin_server_screen.dart. Shows Docker container
// status (virent-api, virent-db, virent-redis, virent-worker) with
// start / stop / restart / rebuild / backup / restore buttons.
//
// Wired to [serverStatusProvider] (GET /admin/docker/status) and
// [serverLogsProvider] (GET /admin/logs).

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/configs/services/api_client.dart';
import '../../../core/configs/theme/app_colors.dart';
import '../../auth/presentation/providers/auth_providers.dart' show apiClientProvider;
import '../admin_web_providers.dart';

class ServerPage extends ConsumerWidget {
  const ServerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(serverStatusProvider);
    final logsAsync = ref.watch(serverLogsProvider);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Сервер — Docker',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF1B2A4E),
                      fontFamily: 'Inter')),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(serverStatusProvider);
                  ref.invalidate(serverLogsProvider);
                },
                icon: const Icon(LucideIcons.refresh_cw, size: 16),
                label: const Text('Обновить'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Container status cards
          Expanded(
            flex: 2,
            child: statusAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorBanner(
                  message: 'Не удалось загрузить статус: $e',
                  onRetry: () => ref.invalidate(serverStatusProvider)),
              data: (status) {
                final containers = (status['containers'] as List? ?? [])
                    .cast<Map<String, dynamic>>();
                if (containers.isEmpty) {
                  return const Center(child: Text('Контейнеры не найдены'));
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 340,
                    childAspectRatio: 1.6,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: containers.length,
                  itemBuilder: (ctx, i) => _ContainerCard(
                    container: containers[i],
                    onAction: (action) => _dockerAction(context, ref, containers[i]['name'], action),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Server logs
          Expanded(
            flex: 1,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.border),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Логи сервера',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter')),
                    const SizedBox(height: 8),
                    Expanded(
                      child: logsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Ошибка: $e')),
                        data: (logs) {
                          if (logs.isEmpty) {
                            return Center(
                              child: Text('Нет логов',
                                  style: TextStyle(color: AppColors.textSecondary)),
                            );
                          }
                          return Container(
                            color: const Color(0xFF1B2A4E),
                            padding: const EdgeInsets.all(12),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: logs.take(100).map((log) {
                                  final text = log['line'] ?? log['message'] ?? log.toString();
                                  return Text('$text',
                                      style: const TextStyle(
                                          color: Color(0xFF7C69EF),
                                          fontFamily: 'monospace',
                                          fontSize: 12));
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _dockerAction(
      BuildContext context, WidgetRef ref, String? name, String action) async {
    if (name == null) return;
    try {
      await ref.read(apiClientProvider).post('/admin/docker/$action', {'name': name});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Команда "$action" выполнена для $name')),
        );
        ref.invalidate(serverStatusProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}

class _ContainerCard extends StatelessWidget {
  const _ContainerCard({required this.container, required this.onAction});
  final Map<String, dynamic> container;
  final void Function(String action) onAction;

  @override
  Widget build(BuildContext context) {
    final name = container['name'] ?? '-';
    final status = container['status'] ?? 'unknown';
    final isRunning = status == 'running';
    final cpu = container['cpu'] ?? 0;
    final mem = container['mem'] ?? 0;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.container,
                    size: 20,
                    color: isRunning ? AppColors.success : AppColors.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRunning ? AppColors.success : AppColors.danger,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('CPU: $cpu%', style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
            Text('Память: ${mem}MB', style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
            const Spacer(),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (!isRunning)
                  _actionBtn('Старт', LucideIcons.play, () => onAction('start')),
                if (isRunning)
                  _actionBtn('Стоп', LucideIcons.square, () => onAction('stop')),
                _actionBtn('Рестарт', LucideIcons.refresh_cw, () => onAction('restart')),
                _actionBtn('Бэкап', LucideIcons.download, () => onAction('backup')),
                _actionBtn('Восстановить', LucideIcons.upload, () => onAction('restore')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFEBEE),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(LucideIcons.circle_alert, color: AppColors.danger),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
