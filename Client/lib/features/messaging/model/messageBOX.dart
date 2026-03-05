import 'package:hive/hive.dart';

part 'messageBOX.g.dart';


@HiveType(typeId: 2) // Use a unique typeId
class Message extends HiveObject {
  @HiveField(0)
  final String fromUUID;

  @HiveField(1)
  final String bits;

  @HiveField(2)
  final DateTime timestamp;

  Message({
    required this.fromUUID,
    required this.bits,
    required this.timestamp,
  });
}