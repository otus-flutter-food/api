import 'package:conduit_core/conduit_core.dart';
import '../utils/naming_converter.dart';

/// Controller-helper для обработки camelCase ↔ snake_case конвертации
class NamingController extends ResourceController {
  
  /// Декодирует request body с поддержкой camelCase конвертации
  Future<Map<String, dynamic>> decodeBodyWithNamingConversion() async {
    try {
      final originalBody = await request!.body.decode<Map<String, dynamic>>();
      
      // Конвертируем camelCase поля в snake_case
      return NamingConverter.convertMapKeysToSnake(originalBody);
    } catch (e) {
      print("Warning: Could not convert request body: $e");
      // Если конвертация не удалась, возвращаем как есть
      return await request!.body.decode<Map<String, dynamic>>();
    }
  }
  
  /// Создает Response с конвертацией snake_case в camelCase
  Response createResponseWithNamingConversion(int statusCode, dynamic body, {Map<String, Object>? headers}) {
    try {
      final convertedBody = NamingConverter.convertResponseToCamelCase(body);
      return Response(statusCode, headers, convertedBody);
    } catch (e) {
      print("Warning: Could not convert response body: $e");
      // Если конвертация не удалась, возвращаем как есть
      return Response(statusCode, headers, body);
    }
  }
}