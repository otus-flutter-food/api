import 'package:json_annotation/json_annotation.dart';

part 'levels_dto.g.dart';

@JsonSerializable()
class Item {
  Item({required this.code});
  int? code;

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  Map<String, dynamic> toJson() => _$ItemToJson(this);
}

@JsonSerializable()
class Size {
  Size(this.h, this.w);
  final int h;
  final int w;

  factory Size.fromJson(Map<String, dynamic> json) => _$SizeFromJson(json);

  Map<String, dynamic> toJson() => _$SizeToJson(this);
}

@JsonSerializable()
class LevelDto {
  LevelDto({required this.field, required this.levelId});

  int levelId;
  late List<List<Item?>> field;
  late Size size;

  factory LevelDto.fromJson(Map<String, dynamic> json) =>
      _$LevelDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LevelDtoToJson(this);

  static Future<Map<int, LevelDto>> openLevels(String levelsFile) async {
    Map<int, LevelDto> levels = <int, LevelDto>{};
    try {
      int rowNum = 0;
      int elementId = 0;

      List<String> rows = levelsFile.split('\n');

      int levelId = 0;
      while (levelId != 60) {
        levelId = int.parse(rows[rowNum]);
        rowNum++;
        int h = int.parse(rows[rowNum].split(' ')[1]);
        int w = int.parse(rows[rowNum].split(' ')[0]);
        rowNum++;

        List<List<Item?>> field = [];
        for (var i = 0; i < h; i++) {
          List<Item?> fieldRow = [];
          for (int element in rows[rowNum].split(' ').map(int.parse)) {
            elementId++;
            fieldRow.add(Item(code: element));
          }
          field.add(fieldRow);
          rowNum++;
        }
        levels[levelId] = LevelDto(
          field: field,
          levelId: levelId,
        )..size = Size(h, w);
      }
    } catch (e) {}
    return Future.value(levels);
  }
}
