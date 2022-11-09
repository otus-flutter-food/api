import 'dart:async';
import 'dart:io';

import 'package:foodapi/utils/app_env.dart';
import 'package:foodapi/utils/app_response.dart';
import 'package:conduit/conduit.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

class TokenController extends Controller {
  @override
  FutureOr<RequestOrResponse?> handle(Request request) {
    try {
      final header = request.raw.headers.value(HttpHeaders.authorizationHeader);
      final token = AuthorizationBearerParser().parse(header);
      final jwtClaim = verifyJwtHS256Signature(token ?? "", AppEnv.secretKey);
      jwtClaim.validate();
      return request;
    } catch (error) {
      return AppResponse.unauthorized(error);
    }
  }
}
