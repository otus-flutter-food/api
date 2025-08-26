
import 'package:conduit_common/conduit_common.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_open_api/v3.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';
import 'package:foodapi/controllers/user.dart';
import 'package:foodapi/foodapi.dart';

// Recipe controllers
import 'controllers/recipe_new.dart';

// Entity controllers
import 'controllers/measureunit_controller.dart';
import 'controllers/ingredient_new.dart';
import 'controllers/freezer_new.dart';
import 'controllers/favorite_new.dart';
import 'controllers/comment_new.dart';

// Recipe relationship controllers  
import 'controller/recipe_step_controller.dart';
import 'controller/recipe_step_link_controller.dart';
import 'controller/recipe_ingredient_controller.dart';

// User & auth controllers
import 'controllers/user_profile_controller.dart';
import 'middleware/auth_middleware.dart';

// Health check controller
import 'controllers/health_controller.dart';


class FoodapiChannel extends ApplicationChannel {
  late ManagedContext context;

  @override
  Future<APIDocument> documentAPI(Map<String, dynamic> projectSpec) async {
    final doc = await super.documentAPI(projectSpec);
    doc.info.title = "Food Recipe API";
    doc.info.description = "REST API для приложения рецептов";
    doc.info.version = "0.3.0";
    doc.servers = [APIServerDescription(Uri.parse("https://foodapi.dzolotov.pro"))];
    return doc;
  }

  @override
  void documentComponents(APIDocumentContext registry) {
    super.documentComponents(registry);
    
    // Регистрируем схему для MeasureUnit
    registry.schema.register('MeasureUnit', APISchemaObject.object({
      'id': APISchemaObject.integer(),
      'one': APISchemaObject.string(),
      'few': APISchemaObject.string(),
      'many': APISchemaObject.string(),
    }));
    
    // Регистрируем схему для Ingredient
    registry.schema.register('Ingredient', APISchemaObject.object({
      'id': APISchemaObject.integer(),
      'name': APISchemaObject.string(),
      'caloriesForUnit': APISchemaObject.number(),
      'measureunit': APISchemaObject.object({
        'id': APISchemaObject.integer(),
        'one': APISchemaObject.string(),
        'few': APISchemaObject.string(),
        'many': APISchemaObject.string(),
      })
    }));
    
    // Регистрируем схему для Favorite
    registry.schema.register('Favorite', APISchemaObject.object({
      'id': APISchemaObject.integer(),
      'user': APISchemaObject.object({
        'id': APISchemaObject.integer(),
        'login': APISchemaObject.string(),
      }),
      'recipe': APISchemaObject.object({
        'id': APISchemaObject.integer(),
        'name': APISchemaObject.string(),
        'duration': APISchemaObject.integer(),
        'photo': APISchemaObject.string(),
      })
    }));
    
    // Регистрируем схему для Freezer
    registry.schema.register('Freezer', APISchemaObject.object({
      'id': APISchemaObject.integer(),
      'count': APISchemaObject.number(),
      'user': APISchemaObject.object({
        'id': APISchemaObject.integer(),
        'login': APISchemaObject.string(),
      }),
      'ingredient': APISchemaObject.object({
        'id': APISchemaObject.integer(),
        'name': APISchemaObject.string(),
      })
    }));
    
    // Регистрируем схему для Recipe
    registry.schema.register('Recipe', APISchemaObject.object({
      'id': APISchemaObject.integer(),
      'name': APISchemaObject.string(),
      'duration': APISchemaObject.integer(),
      'photo': APISchemaObject.string(),
    }));
    
    // Регистрируем схему для RecipeStep
    registry.schema.register('RecipeStep', APISchemaObject.object({
      'id': APISchemaObject.integer(),
      'name': APISchemaObject.string(),
      'duration': APISchemaObject.integer(),
    }));
    
    // Регистрируем схему для RecipeStepLink
    registry.schema.register('RecipeStepLink', APISchemaObject.object({
      'id': APISchemaObject.integer(),
      'number': APISchemaObject.integer(),
      'recipe': APISchemaObject.object({
        'id': APISchemaObject.integer(),
        'name': APISchemaObject.string(),
      }),
      'step': APISchemaObject.object({
        'id': APISchemaObject.integer(),
        'name': APISchemaObject.string(),
      }),
    }));
    
    // Регистрируем схему для RecipeIngredient
    registry.schema.register('RecipeIngredient', APISchemaObject.object({
      'id': APISchemaObject.integer(),
      'count': APISchemaObject.number(),
      'recipe': APISchemaObject.object({
        'id': APISchemaObject.integer(),
        'name': APISchemaObject.string(),
      }),
      'ingredient': APISchemaObject.object({
        'id': APISchemaObject.integer(),
        'name': APISchemaObject.string(),
      }),
    }));
    
    // Регистрируем схему для Comment
    registry.schema.register('Comment', APISchemaObject.object({
      'id': APISchemaObject.integer(),
      'text': APISchemaObject.string(),
      'photo': APISchemaObject.string(),
      'dateTime': APISchemaObject.string()..format = 'date-time',
      'user': APISchemaObject.object({
        'id': APISchemaObject.integer(),
        'login': APISchemaObject.string(),
      }),
      'recipe': APISchemaObject.object({
        'id': APISchemaObject.integer(),
        'name': APISchemaObject.string(),
      }),
    }));
  }

  @override
  Future prepare() async {
    options?.address = "0.0.0.0";
    logger.onRecord.listen(
        (rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));
    final dataModel = ManagedDataModel.fromCurrentMirrorSystem();
    
    final dbHost = Platform.environment['DATABASE_HOST'] ?? 'localhost';
    final dbPort = int.parse(Platform.environment['DATABASE_PORT'] ?? '5433');
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
    
    // Health check endpoint (no auth required, no logging)
    router.route("/healthz").link(() => HealthController(context));
    
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

    // Recipe endpoints
    router.route("/recipe[/:id]").link(() => RecipeController(context));
    router.route("/recipe/search").link(() => RecipeSearchController(context));
    
    // Recipe steps
    router.route("/steps[/:id]").link(() => RecipeStepController(context));
    
    // Recipe step links
    router.route("/recipe-step-links[/:id]").link(() => RecipeStepLinkController(context));
    router.route("/recipe-step-links/recipe/:recipeId").link(() => RecipeStepLinkController(context));
    router.route("/recipe-step-links/batch").link(() => RecipeStepLinkController(context));
    router.route("/recipe-step-links/reorder").link(() => RecipeStepLinkController(context));
    
    // Recipe ingredients
    router.route("/recipe-ingredients[/:id]").link(() => RecipeIngredientController(context));
    router.route("/recipe-ingredients/batch").link(() => RecipeIngredientController(context));
    router.route("/recipe-ingredients/recipe/:recipeId").link(() => RecipeIngredientController(context));
    
    // Entity endpoints
    router.route("/measure_unit[/:id]").link(() => MeasureUnitController(context));
    router.route("/ingredient[/:id]").link(() => IngredientController(context));
    router.route("/favorite[/:id]").link(() => FavoriteController(context));
    router.route("/freezer[/:id]").link(() => FreezerController(context));
    router.route("/comment[/:id]").link(() => CommentController(context));
    
    // Authentication endpoints (no auth required)
    router.route("/user").link(() => UserController(context));
    router.route("/user/:id").link(() => UserInfoController(context));
    
    // User-specific endpoints (authentication required)
    router.route("/user/profile[/:path]")
      .link(() => AuthMiddleware(context))!
      .link(() => UserProfileController(context));
    
    router.route("/user/favorites[/:recipeId]")
      .link(() => AuthMiddleware(context))!
      .link(() => UserFavoritesController(context));
    
    router.route("/user/comments[/:id]")
      .link(() => AuthMiddleware(context))!
      .link(() => UserCommentsController(context));
    
    // Все тестовые endpoints удалены

    return router;
  }
}
