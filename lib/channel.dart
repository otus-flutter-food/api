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
    final persistence = PostgreSQLPersistentStore(
      "food",
      "yaigoo2E",
      "rc1b-6jiplnjx8d1kdn0a.mdb.yandexcloud.net",
      6432,
      "food",
      useSSL: true,
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

    return router;
  }
}
