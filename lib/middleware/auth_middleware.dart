import 'package:conduit_core/conduit_core.dart';
import '../model/user.dart';

class AuthMiddleware extends Controller {
  AuthMiddleware(this.context);
  
  final ManagedContext context;
  
  @override
  Future<Request?> handle(Request request) async {
    // Get token from header
    final authHeader = request.raw.headers.value('authorization');
    
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      // Pass through; downstream controllers will check for user
      return request;
    }
    
    final token = authHeader.substring(7); // Remove 'Bearer ' prefix
    
    // Find user by token
    final query = Query<User>(context)
      ..where((u) => u.token).equalTo(token);
    
    final user = await query.fetchOne();
    
    if (user == null) {
      return request;
    }
    
    // Add user to request for use in controllers
    request.attachments['user'] = user;
    
    return request;
  }
}
