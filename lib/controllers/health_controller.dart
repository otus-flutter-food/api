import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';

class HealthController extends ResourceController {
  HealthController(this.context);

  final ManagedContext context;

  @Operation.get()
  Future<Response> checkHealth() async {
    try {
      // Проверяем подключение к базе данных простым запросом
      final query = context.persistentStore.execute("SELECT 1");
      await query;
      
      // Если запрос выполнен успешно, возвращаем OK статус
      return Response.ok({
        'status': 'healthy',
        'database': 'connected',
        'timestamp': DateTime.now().toIso8601String(),
        'service': 'foodapi',
        'version': '0.3.0'
      });
    } catch (e) {
      // Если есть проблема с БД, возвращаем 503 Service Unavailable
      return Response.serverError(body: {
        'status': 'unhealthy',
        'database': 'disconnected',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'service': 'foodapi'
      })..statusCode = 503;
    }
  }
}