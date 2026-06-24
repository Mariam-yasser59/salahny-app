import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class RealtimeService {
  RealtimeService._();

  static final RealtimeService instance = RealtimeService._();

  io.Socket? _socket;
  final _events = StreamController<RealtimeEvent>.broadcast();

  Stream<RealtimeEvent> get events => _events.stream;

  Future<void> connect() async {
    if (_socket?.connected == true) return;
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) return;
    final origin = ApiConstants.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    _socket = io.io(
      origin,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );
    final connected = Completer<void>();
    _socket!
      ..on('booking_message', (data) => _emit('booking_message', data))
      ..on('tracking_update', (data) => _emit('tracking_update', data))
      ..on('direct_message', (data) => _emit('direct_message', data))
      ..on(
        'notification_created',
        (data) => _emit('notification_created', data),
      )
      ..on(
        'workshop_admin_message',
        (data) => _emit('workshop_admin_message', data),
      )
      ..onConnect((_) {
        if (!connected.isCompleted) connected.complete();
      })
      ..connect();
    if (_socket?.connected != true) {
      await connected.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {},
      );
    }
  }

  Future<void> joinBooking(String bookingId) async {
    await connect();
    _socket?.emit('join_booking', {'bookingId': bookingId});
  }

  Future<void> joinWorkshopAdmin({String? workshopId}) async {
    await connect();
    _socket?.emit('join_workshop_admin', {
      if (workshopId != null) 'workshopId': workshopId,
    });
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void _emit(String type, dynamic data) {
    if (data is Map) {
      _events.add(
        RealtimeEvent(type: type, data: Map<String, dynamic>.from(data)),
      );
    }
  }
}

class RealtimeEvent {
  const RealtimeEvent({required this.type, required this.data});

  final String type;
  final Map<String, dynamic> data;
}
