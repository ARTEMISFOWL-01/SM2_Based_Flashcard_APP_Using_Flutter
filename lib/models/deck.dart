import 'package:hive/hive.dart';

part 'deck.g.dart';

@HiveType(typeId: 0)
class Deck extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  Deck({required this.id, required this.name});
}
