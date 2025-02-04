import 'package:kosher_dart/kosher_dart.dart';
import 'package:uuid/uuid.dart';

class Yahrtzeit {
  final String id;
  final String? englishName;
  final String hebrewName;
  final int? day;
  final int? month;
  final String? group;
  bool selected = false;

  Yahrtzeit({
    this.englishName,
    required this.hebrewName,
    required this.day,
    required this.month,
    this.group,
    String? id,
  }) : id = id ?? Uuid().v4();

  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'englishName': englishName,
      'hebrewName': hebrewName,
      'day': day,
      'month': month,
      'group': group,
      'selected': selected,
    };
  }

  factory Yahrtzeit.fromJson(Map<String, dynamic> json) {
    return Yahrtzeit(
      id: json['id'], // דאג ש־id יקרא גם מה־JSON
      englishName: json['englishName'],
      hebrewName: json['hebrewName'],
      day: json['day'],
      month: json['month'],
      group: json['group'],
    )..selected = json['selected'] ?? false;
  }
  DateTime? getGregorianDate() {
  if (month == null || day == null) {
    // אם month או day אינם מאותחלים, החזר null או טיפול חלופי
    return null;
  }

  int year = JewishDate().getJewishYear();
  JewishDate jewishDate = JewishDate.initDate(
      jewishYear: year, jewishMonth: month!, jewishDayOfMonth: day!);
  DateTime gregorianDate = DateTime(
    jewishDate.getGregorianYear(),
    jewishDate.getGregorianMonth(),
    jewishDate.getGregorianDayOfMonth(),
  );

  DateTime currentDate = DateTime.now();
  if (gregorianDate.isBefore(currentDate)) {
    year += 1;
    jewishDate = JewishDate.initDate(
        jewishYear: year, jewishMonth: month!, jewishDayOfMonth: day!);
    gregorianDate = DateTime(
      jewishDate.getGregorianYear(),
      jewishDate.getGregorianMonth(),
      jewishDate.getGregorianDayOfMonth(),
    );
  }

  return gregorianDate;
}

}