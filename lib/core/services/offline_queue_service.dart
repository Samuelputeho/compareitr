import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

enum QueueOperationType {
  addToCart,
  removeFromCart,
  updateQuantity,
  createOrder,
  updateProfile,
}

class QueueOperation {
  final String id;
  final QueueOperationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;
  final String? error;

  QueueOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'retryCount': retryCount,
      'error': error,
    };
  }

  factory QueueOperation.fromJson(Map<String, dynamic> json) {
    return QueueOperation(
      id: json['id'],
      type: QueueOperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QueueOperationType.addToCart,
      ),
      data: json['data'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
      error: json['error'],
    );
  }

  QueueOperation copyWith({
    String? id,
    QueueOperationType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
    String? error,
  }) {
    return QueueOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      error: error ?? this.error,
    );
  }
}

class OfflineQueueService {
  static const String _queueBoxName = 'offline_queue';
  static const String _queueKey = 'pending_operations';
  
  static Box? _box;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(minutes: 5);

  // Initialize the queue service
  static Future<void> init() async {
    _box = await Hive.openBox(_queueBoxName);
  }

  // Add operation to queue
  static Future<void> addToQueue(
    QueueOperationType type,
    Map<String, dynamic> data, {
    String? customId,
  }) async {
    if (_box == null) {
      await init();
    }

    final operation = QueueOperation(
      id: customId ?? '${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      data: data,
      timestamp: DateTime.now(),
    );

    final queue = _getQueue();
    queue.add(operation);
    await _saveQueue(queue);

    if (kDebugMode) {
      print('📝 Added operation to queue: ${operation.type.name}');
    }
  }

  // Get all pending operations
  static List<QueueOperation> getPendingOperations() {
    return _getQueue();
  }

  // Get operations by type
  static List<QueueOperation> getOperationsByType(QueueOperationType type) {
    return _getQueue().where((op) => op.type == type).toList();
  }

  // Remove operation from queue
  static Future<void> removeFromQueue(String operationId) async {
    final queue = _getQueue();
    queue.removeWhere((op) => op.id == operationId);
    await _saveQueue(queue);

    if (kDebugMode) {
      print('✅ Removed operation from queue: $operationId');
    }
  }

  // Update operation (for retry with error)
  static Future<void> updateOperation(
    String operationId,
    String? error,
  ) async {
    final queue = _getQueue();
    final index = queue.indexWhere((op) => op.id == operationId);
    
    if (index != -1) {
      final operation = queue[index];
      queue[index] = operation.copyWith(
        retryCount: operation.retryCount + 1,
        error: error,
      );
      await _saveQueue(queue);

      if (kDebugMode) {
        print('🔄 Updated operation retry count: $operationId (${operation.retryCount + 1})');
      }
    }
  }

  // Clear all operations
  static Future<void> clearQueue() async {
    if (_box != null) {
      await _box!.delete(_queueKey);
    }

    if (kDebugMode) {
      print('🗑️ Cleared offline queue');
    }
  }

  // Clear operations by type
  static Future<void> clearOperationsByType(QueueOperationType type) async {
    final queue = _getQueue();
    queue.removeWhere((op) => op.type == type);
    await _saveQueue(queue);

    if (kDebugMode) {
      print('🗑️ Cleared operations of type: ${type.name}');
    }
  }

  // Get queue statistics
  static Map<String, dynamic> getQueueStats() {
    final queue = _getQueue();
    final stats = <String, int>{};
    
    for (final operation in queue) {
      final key = operation.type.name;
      stats[key] = (stats[key] ?? 0) + 1;
    }

    return {
      'total_operations': queue.length,
      'by_type': stats,
      'oldest_operation': queue.isNotEmpty 
          ? queue.map((op) => op.timestamp).reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String()
          : null,
      'failed_operations': queue.where((op) => op.error != null).length,
    };
  }

  // Check if operation should be retried
  static bool shouldRetry(QueueOperation operation) {
    if (operation.retryCount >= _maxRetries) return false;
    
    final timeSinceLastAttempt = DateTime.now().difference(operation.timestamp);
    return timeSinceLastAttempt >= _retryDelay;
  }

  // Get operations ready for retry
  static List<QueueOperation> getOperationsReadyForRetry() {
    return _getQueue().where(shouldRetry).toList();
  }

  // Helper methods
  static List<QueueOperation> _getQueue() {
    if (_box == null) return [];
    
    final queueJson = _box!.get(_queueKey);
    if (queueJson == null) return [];
    
    try {
      final List<dynamic> queueList = queueJson;
      return queueList.map((json) => QueueOperation.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing queue: $e');
      }
      return [];
    }
  }

  static Future<void> _saveQueue(List<QueueOperation> queue) async {
    if (_box == null) return;
    
    final queueJson = queue.map((op) => op.toJson()).toList();
    await _box!.put(_queueKey, queueJson);
  }

  // Convenience methods for common operations
  static Future<void> queueAddToCart({
    required String cartId,
    required String productId,
    required int quantity,
    required double price,
  }) async {
    await addToQueue(
      QueueOperationType.addToCart,
      {
        'cartId': cartId,
        'productId': productId,
        'quantity': quantity,
        'price': price,
      },
    );
  }

  static Future<void> queueRemoveFromCart({
    required String cartId,
    required String productId,
  }) async {
    await addToQueue(
      QueueOperationType.removeFromCart,
      {
        'cartId': cartId,
        'productId': productId,
      },
    );
  }

  static Future<void> queueUpdateQuantity({
    required String cartId,
    required String productId,
    required int newQuantity,
  }) async {
    await addToQueue(
      QueueOperationType.updateQuantity,
      {
        'cartId': cartId,
        'productId': productId,
        'newQuantity': newQuantity,
      },
    );
  }

  static Future<void> queueCreateOrder({
    required Map<String, dynamic> orderData,
  }) async {
    await addToQueue(
      QueueOperationType.createOrder,
      orderData,
    );
  }
}
