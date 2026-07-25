import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/api_config.dart';
import '../helpers/storage_helper.dart';

/// Lightweight Socket.IO client for live queue (and future realtime).
class AppSocketService {
  AppSocketService(this._storage);

  final StorageHelper _storage;
  io.Socket? _socket;
  final _queueControllers = <String, StreamController<Map<String, dynamic>>>{};

  bool get isConnected => _socket?.connected == true;

  Future<void> connect() async {
    if (_socket?.connected == true) return;
    final token = await _storage.getAccessToken();
    _socket?.dispose();
    _socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionAttempts(50)
          .setAuth(token != null && token.isNotEmpty ? {'token': token} : {})
          .build(),
    );
    _socket!
      ..onConnect((_) {
        if (kDebugMode) debugPrint('[socket] connected');
        if (token != null && token.isNotEmpty) {
          _socket!.emit('authenticate', {'token': token});
        }
      })
      ..on('queue_updated', (data) {
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          final id = '${map['appointmentId'] ?? map['appointment_id'] ?? ''}';
          _queueControllers[id]?.add(map);
        }
      })
      ..onDisconnect((_) {
        if (kDebugMode) debugPrint('[socket] disconnected');
      });
  }

  Future<void> joinAppointmentQueue(String appointmentId) async {
    await connect();
    final token = await _storage.getAccessToken();
    _socket?.emit('join_appointment_queue_room', {
      'appointment_id': appointmentId,
      if (token != null) 'token': token,
    });
  }

  Future<void> leaveAppointmentQueue(String appointmentId) async {
    _socket?.emit('leave_appointment_queue_room', {
      'appointment_id': appointmentId,
    });
  }

  Stream<Map<String, dynamic>> queueUpdates(String appointmentId) {
    final existing = _queueControllers[appointmentId];
    if (existing != null) return existing.stream;
    final c = StreamController<Map<String, dynamic>>.broadcast(
      onListen: () {
        joinAppointmentQueue(appointmentId);
      },
      onCancel: () {
        leaveAppointmentQueue(appointmentId);
        _queueControllers.remove(appointmentId)?.close();
      },
    );
    _queueControllers[appointmentId] = c;
    return c.stream;
  }

  void dispose() {
    for (final c in _queueControllers.values) {
      c.close();
    }
    _queueControllers.clear();
    _socket?.dispose();
    _socket = null;
  }
}
