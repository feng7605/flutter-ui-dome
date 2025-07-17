import '../../core/error/exceptions.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  /// 远程登录请求
  ///
  /// 如果成功返回[UserModel]，否则抛出[ServerException]
  Future<UserModel> login(String email, String password);

  /// 远程注册请求
  Future<UserModel> register(String name, String email, String password);

  /// 重置密码请求
  Future<void> resetPassword(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await apiClient.postRaw(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );
      
      return UserModel.fromJson(response['user']);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    try {
      final response = await apiClient.postRaw(
        '/auth/register',
        body: {
          'name': name,
          'email': email,
          'password': password,
        },
      );
      
      return UserModel.fromJson(response['user']);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await apiClient.postRaw(
        '/auth/reset-password',
        body: {
          'email': email,
        },
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
