import 'package:hive/hive.dart';
import 'dart:math';

part 'subscription.g.dart';

@HiveType(typeId: 0)
class Subscription extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late double amount;

  @HiveField(2)
  late DateTime nextBillDate;

  @HiveField(3)
  late String period;

  @HiveField(4)
  late String category;

  @HiveField(5) // New: The anchor for our notification
  late int notificationId;

  Subscription({
    required this.name,
    required this.amount,
    required this.nextBillDate,
    required this.period,
    required this.category,
    int? notificationId, // Optional in constructor
  }) {
    // If no ID is provided (new sub), generate a random 32-bit integer
    this.notificationId = notificationId ?? Random().nextInt(2147483647);
  }
}