import 'package:supabase_flutter/supabase_flutter.dart';

/// Token dei telefoni per le push (tabella `device_tokens`, via RPC).
abstract interface class DeviceTokenRepository {
  /// Associa [token] al profilo corrente (se era di un altro profilo sullo
  /// stesso telefono, passa a questo).
  Future<void> register({required String token, required String platform});

  /// Toglie [token]: non arriveranno più push a questo telefono.
  Future<void> unregister(String token);
}

class SupabaseDeviceTokenRepository implements DeviceTokenRepository {
  SupabaseDeviceTokenRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> register({required String token, required String platform}) =>
      _client.rpc<void>(
        'register_device_token',
        params: {'p_token': token, 'p_platform': platform},
      );

  @override
  Future<void> unregister(String token) =>
      _client.rpc<void>('unregister_device_token', params: {'p_token': token});
}
