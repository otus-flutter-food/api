import 'package:conduit_common/conduit_common.dart';
import 'package:foodapi/controllers/freezer.dart';
import 'package:foodapi/controllers/user.dart';
import 'package:foodapi/foodapi.dart';
import 'package:conduit_open_api/v3.dart';

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
    logger.onRecord.listen(
        (rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));
    final dataModel = ManagedDataModel.fromCurrentMirrorSystem();
    final persistence = PostgreSQLPersistentStore(
        "postgres", "password", "127.0.0.1", 5432, "food");
    context = ManagedContext(dataModel, persistence);
  }

  @override
  Controller get entryPoint {
    final router = Router();

    router.route("/recipe[/:id]").link(() => RecipeController(context));
    router.route("/comment[/:id]").link(() => CommentController(context));
    router.route("/ingredient[/:id]").link(() => IngredientController(context));
    router
        .route("/measure_unit[/:id]")
        .link(() => MeasureUnitController(context));
    router.route("/freezer[/:id]").link(() => FreezerController(context));
    router.route("/favorite[/:id]").link(() => FavoriteController(context));
    router.route("/user").link(() => UserController(context));

    return router;
  }
}
