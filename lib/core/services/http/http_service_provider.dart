
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frame/core/services/http/dio_http_service.dart';
import 'package:frame/core/storage/storage_service_provider.dart';

final httpServiceProvider = Provider<HttpService>((ref) {
  final storageService = ref.watch(storageServiceProvider);

  return DioHttpService(storageService);
});

abstract class HttpService {
  /// Http base url
  String get baseUrl;

  /// Http headers
  Map<String, String> get headers;

  /// Http get request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool forceRefresh = false,
  });

  /// Http post request
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  });

  /// Http put request
  Future<dynamic> put();

  /// Http delete request
  Future<dynamic> delete();
}
