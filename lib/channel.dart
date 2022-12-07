import 'package:conduit_common/conduit_common.dart';
import 'package:foodapi/controllers/freezer.dart';
import 'package:foodapi/controllers/token_controller.dart';
import 'package:foodapi/controllers/user_controller.dart';
import 'package:foodapi/controllers/auth_controller.dart';
// import 'package:foodapi/controllers/user.dart';
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
    CORSPolicy.defaultPolicy.allowedOrigins = [
      "172.20.20.4:8888", "0.0.0.0"
      // "https://dart.nvavia.ru",
      // "localhost:8888",
    ];
    options?.address = "0.0.0.0";
    logger.onRecord.listen((rec) => print(
        "Rec: ${rec.toString()} ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));
    final dataModel = ManagedDataModel.fromCurrentMirrorSystem();
    final persistence = PostgreSQLPersistentStore(
        "admin", "root", "127.0.0.1", 5432, "postgres");
    context = ManagedContext(dataModel, persistence);
  }

  @override
  Controller get entryPoint {
    final router = Router()
      ..route("token/[:refresh]").link(
        () => AppAuthController(context),
      )
      ..route("/user")
          .link(() => TokenController())!
          .link(() => UserController(context))
      ..route("/recipe[/:id]").link(() => RecipeController(context))
      ..route("/comment[/:id]").link(() => CommentController(context))
      ..route("/ingredient[/:id]").link(() => IngredientController(context))
      ..route("/measure_unit[/:id]").link(() => MeasureUnitController(context))
      ..route("/freezer[/:id]").link(() => FreezerController(context))
      ..route("/favorite[/:id]").link(() => FavoriteController(context))
      ..route("/favorites[/:id]").link(() => FavoritesController(context));
    //router.route("/user").link(() => UserController(context));
    //router.route("/user/:id").link(() => UserInfoController(context));

    return router;
  }
}
