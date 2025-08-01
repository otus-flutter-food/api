import 'dart:convert';
import 'dart:io';

import 'package:conduit_common/conduit_common.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_open_api/v3.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';
import 'package:foodapi/controllers/freezer.dart';
import 'package:foodapi/controllers/user.dart';
import 'package:foodapi/foodapi.dart';

import 'controllers/comment.dart';
import 'controllers/favorite.dart';
import 'controllers/ingredient.dart';
import 'controllers/recipe.dart';

class FoodapiChannel extends ApplicationChannel {
  late ManagedContext context;

  @override
  void documentComponents(APIDocumentContext registry) {
    super.documentComponents(registry);
    registry.schema.register(
      "Status",
      APISchemaObject.object(
        {
          "status": APISchemaObject.string(),
        },
      ),
    );
    registry.schema.register(
      "Error",
      APISchemaObject.object(
        {
          "error": APISchemaObject.string(),
        },
      ),
    );
    registry.schema.register(
      "Token",
      APISchemaObject.object(
        {
          "token": APISchemaObject.string(),
        },
      ),
    );
  }

  @override
  Future prepare() async {
    options?.address = "0.0.0.0";
    logger.onRecord.listen(
        (rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));
    final dataModel = ManagedDataModel.fromCurrentMirrorSystem();
    
    final dbHost = Platform.environment['DATABASE_HOST'] ?? 'localhost';
    final dbPort = int.parse(Platform.environment['DATABASE_PORT'] ?? '5432');
    final dbUser = Platform.environment['DATABASE_USER'] ?? 'food';
    final dbPassword = Platform.environment['DATABASE_PASSWORD'] ?? 'yaigoo2E';
    final dbName = Platform.environment['DATABASE_NAME'] ?? 'food';
    
    final persistence = PostgreSQLPersistentStore(
      dbUser,
      dbPassword,
      dbHost,
      dbPort,
      dbName,
      useSSL: false,
    );
    context = ManagedContext(dataModel, persistence);
  }

  @override
  Controller get entryPoint {
    final router = Router();
    
    // Logging middleware
    router.route("/[:path(.*)]")
      .linkFunction((request) async {
        print("\n[${DateTime.now().toIso8601String()}] ${request.method} ${request.path.string}");
        print("Headers: ${request.raw.headers}");
        if (request.method == "POST" || request.method == "PUT") {
          // print("Has body: ${request.hasBody}"); // Not available in Conduit 4.4.0
          print("Content-Length: ${request.raw.headers.value('content-length')}");
        }
        return request;
      });

    router.route("/recipe[/:id]").link(() => RecipeController(context));
    router
        .route("/recipe_step[/:id]")
        .link(() => RecipeStepController(context));
    router
        .route("/recipe_step_link[/:id]")
        .link(() => RecipeStepLinksController(context));
    router.route("/comment[/:id]").link(() => CommentController(context));
    router.route("/ingredient[/:id]").link(() => IngredientController(context));
    router
        .route("/recipe_ingredient[/:id]")
        .link(() => RecipeIngredientController(context));
    router
        .route("/measure_unit[/:id]")
        .link(() => MeasureUnitController(context));
    router.route("/freezer[/:id]").link(() => FreezerController(context));
    router.route("/favorite[/:id]").link(() => FavoriteController(context));
    router.route("/user").link(() => UserController(context));
    router.route("/user/:id").link(() => UserInfoController(context));
    
    // Test endpoint
    router.route("/test").linkFunction((request) async {
      return Response.ok({
        "status": "ok",
        "database_host": Platform.environment['DATABASE_HOST'] ?? 'localhost',
        "timestamp": DateTime.now().toIso8601String(),
        "dart_version": Platform.version
      });
    });
    
    // Debug endpoint to see what exactly arrives
    router.route("/debug-post").linkFunction((request) async {
      print("\n=== DEBUG POST REQUEST ===");
      print("Method: ${request.method}");
      print("Path: ${request.path}");
      print("Content-Length header: ${request.raw.headers.value('content-length')}");
      print("Content-Type header: ${request.raw.headers.value('content-type')}");
      print("Transfer-Encoding: ${request.raw.headers.value('transfer-encoding')}");
      print("Connection: ${request.raw.headers.value('connection')}");
      print("All headers: ${request.raw.headers}");
      // print("Has body: ${request.hasBody}"); // Not available in Conduit 4.4.0
      
      try {
        // Try to read raw bytes
        final bytes = await request.raw.fold<List<int>>([], (previous, element) => previous..addAll(element));
        print("Bytes received: ${bytes.length}");
        print("Bytes as list: $bytes");
        
        final rawString = String.fromCharCodes(bytes);
        print("Raw string: '$rawString'");
        print("Raw string length: ${rawString.length}");
        
        return Response.ok({
          "bytes_length": bytes.length,
          "raw_string": rawString,
          "headers": request.raw.headers.toString(),
          "content_length": request.raw.headers.value('content-length'),
          "content_type": request.raw.headers.value('content-type')
        });
      } catch (e) {
        print("Error reading body: $e");
        return Response.ok({
          "error": e.toString(),
          "headers": request.raw.headers.toString()
        });
      }
    });

    // Test POST endpoint with raw body handling
    router.route("/test-post-raw").linkFunction((request) async {
      if (request.method != "POST") {
        return Response(405, null, {})..headers["Allow"] = ["POST"];
      }
      
      try {
        // Read raw body
        final bytes = await request.raw.fold<List<int>>([], (previous, element) => previous..addAll(element));
        final rawString = String.fromCharCodes(bytes);
        print("Raw body received: $rawString");
        
        // Parse JSON manually
        final parsed = json.decode(rawString);
        return Response.ok({"received": parsed, "status": "ok", "method": "raw"});
      } catch (e) {
        print("Error in raw processing: $e");
        return Response.badRequest(body: {"error": "Raw processing failed: ${e.toString()}"});
      }
    });

    // Test POST endpoint
    router.route("/test-post").linkFunction((request) async {
      if (request.method != "POST") {
        return Response(405, null, {})..headers["Allow"] = ["POST"];
      }
      try {
        print("=== TEST POST DEBUG ===");
        print("Request method: ${request.method}");
        print("Request path: ${request.path}");
        print("Request raw: ${request.raw}");
        print("Dart version: ${Platform.version}");
        
        // In Conduit, decode() throws Response on error
        dynamic decodedBody;
        try {
          decodedBody = await request.body.decode<Map<String, dynamic>>();
        } on Response catch (errorResponse) {
          print("Decode threw Response: ${errorResponse.statusCode} - ${errorResponse.body}");
          return errorResponse;
        } catch (e) {
          print("Unexpected error: $e (${e.runtimeType})");
          return Response.serverError(body: {"error": "Unexpected error during decode"});
        }
        
        print("TEST POST received: $decodedBody");
        return Response.ok({"received": decodedBody, "status": "ok"});
      } catch (e, stackTrace) {
        print("Error decoding body: $e");
        print("Error type: ${e.runtimeType}");
        print("Stack trace: $stackTrace");
        return Response.badRequest(body: {"error": "Failed to decode body: ${e.toString()}"});
      }
    });

    return router;
  }
}
