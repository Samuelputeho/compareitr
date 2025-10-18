import 'package:flutter/material.dart';
import 'package:compareitr/core/common/cache/cache.dart';
import 'package:compareitr/core/services/offline_queue_service.dart';

class OfflineIndicator extends StatelessWidget {
  final Widget child;
  final bool showWhenOnline;
  final double height;

  const OfflineIndicator({
    super.key,
    required this.child,
    this.showWhenOnline = false,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    final pendingOperations = OfflineQueueService.getPendingOperations();
    final hasPendingOperations = pendingOperations.isNotEmpty;
    
    return Column(
      children: [
        if (CacheManager.isOffline || showWhenOnline || hasPendingOperations) ...[
          Container(
            width: double.infinity,
            height: height,
            color: _getStatusColor(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStatusIcon(),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getStatusText(hasPendingOperations),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (hasPendingOperations) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${pendingOperations.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        Expanded(child: child),
      ],
    );
  }

  Color _getStatusColor() {
    if (CacheManager.isOffline) {
      return Colors.orange.shade700;
    } else if (OfflineQueueService.getPendingOperations().isNotEmpty) {
      return Colors.blue.shade700;
    } else {
      return Colors.green.shade700;
    }
  }

  IconData _getStatusIcon() {
    if (CacheManager.isOffline) {
      return Icons.wifi_off;
    } else if (OfflineQueueService.getPendingOperations().isNotEmpty) {
      return Icons.sync;
    } else {
      return Icons.wifi;
    }
  }

  String _getStatusText(bool hasPendingOperations) {
    if (CacheManager.isOffline) {
      return 'You\'re offline - Using cached data';
    } else if (hasPendingOperations) {
      return 'Syncing pending changes';
    } else {
      return CacheManager.connectionStatusText;
    }
  }
}

class OfflineBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const OfflineBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (!CacheManager.isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You\'re offline - Using cached data',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(
              Icons.refresh,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
