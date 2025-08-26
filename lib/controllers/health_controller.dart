import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';

class HealthController extends ResourceController {
  HealthController(this.context);

  final ManagedContext context;

  @Operation.get()
  Future<Response> checkHealth() async {
    return _performHealthCheck();
  }

  @Operation('HEAD')
  Future<Response> checkHealthHead() async {
    final result = await _performHealthCheck();
    // Для HEAD запроса возвращаем только статус код без тела
    return Response(result.statusCode ?? 200, null, {});
  }

  Future<Response> _performHealthCheck() async {
    try {
      // Проверяем подключение к базе данных простым запросом
      final query = context.persistentStore.execute("SELECT 1 as health_check");
      await query;
      
      // Проверяем возможность записи - создаем временную запись в специальной таблице
      // или обновляем timestamp в существующей таблице
      final writeCheck = context.persistentStore.execute("""
        INSERT INTO _health_check (checked_at, status) 
        VALUES (NOW(), 'ok') 
        ON CONFLICT (id) 
        DO UPDATE SET checked_at = NOW(), status = 'ok'
        WHERE _health_check.id = 1
      """);
      await writeCheck;
      
      // Если все проверки пройдены успешно, возвращаем OK статус
      return Response.ok({
        'status': 'healthy',
        'database': 'connected',
        'database_writable': true,
        'timestamp': DateTime.now().toIso8601String(),
        'service': 'foodapi',
        'version': '0.3.0'
      });
    } catch (e) {
      // Если есть проблема с БД, возвращаем 500 Internal Server Error
      return Response.serverError(body: {
        'status': 'unhealthy',
        'database': 'error',
        'database_writable': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'service': 'foodapi',
        'version': '0.3.0'
      }); // По умолчанию serverError возвращает 500
    }
  }
}