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
        
        // Try different decoding approaches
        dynamic decodedBody;
        try {
          decodedBody = await request.body.decode<Map<String, dynamic>>();
        } catch (e1) {
          print("First decode attempt failed: $e1");
          try {
            decodedBody = await request.body.decode();
          } catch (e2) {
            print("Second decode attempt failed: $e2");
            // Try to read raw bytes
            final bytes = await request.body.original.toList();
            final rawString = String.fromCharCodes(bytes.expand((x) => x));
            print("Raw body string: $rawString");
            decodedBody = {"raw": rawString};
          }
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
