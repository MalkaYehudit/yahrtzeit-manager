
import 'package:cambium_project/views/manage_yahrtzeits.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home_page.dart';
import '../localizations/app_localizations.dart';
import '../models/yahrtzeit.dart';
import '../services/keyboard_layouts.dart';
import '../services/yahrtzeits_manager.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'dart:convert';
import 'manage_yahrtzeits.dart';

class AddYahrtzeitPage extends StatefulWidget {
  final Yahrtzeit? yahrtzeit;
  final bool isEditing;
  final int yearsToSync;
  final bool syncSettings;
  final bool notifications;
  final String language;
  final String jewishLanguage;
  final String calendar;
  final int years;
  final int days;
  int months;
  final VoidCallback toggleSyncSettings;
  final VoidCallback toggleNotifications;
  final Function(String) changeLanguage;
  final Function(String) changeJewishLanguage;
  final Function(String) changeCalendar;
  final Function(int) changeYears;
  final Function(int) changeDays;
  final Function(int) changeMonths;

  AddYahrtzeitPage({
    this.yahrtzeit,
    this.isEditing = false,
    required this.yearsToSync,
    required this.syncSettings,
    required this.notifications,
    required this.language,
    required this.jewishLanguage,
    required this.calendar,
    required this.years,
    required this.days,
    required this.months,
    required this.toggleSyncSettings,
    required this.toggleNotifications,
    required this.changeLanguage,
    required this.changeJewishLanguage,
    required this.changeCalendar,
    required this.changeYears,
    required this.changeDays,
    required this.changeMonths,
  });

  @override
  _AddYahrtzeitPageState createState() => _AddYahrtzeitPageState();
}

class _AddYahrtzeitPageState extends State<AddYahrtzeitPage> {
  final _formKey = GlobalKey<FormState>();
  final _englishNameController = TextEditingController();
  final _hebrewNameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showCustomKeyboard = false;
  KeyboardLayoutType _currentLanguage = KeyboardLayoutType.Hebrew;

  final _groupController = TextEditingController();
  int? _selectedDay;
  int? _selectedMonth;
  final YahrtzeitsManager manager = YahrtzeitsManager();
  List<String> groups = [];

  Map<int, String> getMonths(BuildContext context) {
  return {
    1: AppLocalizations.of(context)!.translate('Tishrei'),
    2: AppLocalizations.of(context)!.translate('Cheshvan'),
    3: AppLocalizations.of(context)!.translate('Kislev'),
    4: AppLocalizations.of(context)!.translate('Teves'),
    5: AppLocalizations.of(context)!.translate('Shevat'),
    6: AppLocalizations.of(context)!.translate('Adar'),
    7: AppLocalizations.of(context)!.translate('Adar I'),
    8: AppLocalizations.of(context)!.translate('Adar II'),
    9: AppLocalizations.of(context)!.translate('Nissan'),
    10: AppLocalizations.of(context)!.translate('Iyar'),
    11: AppLocalizations.of(context)!.translate('Sivan'),
    12: AppLocalizations.of(context)!.translate('Tammuz'),
    13: AppLocalizations.of(context)!.translate('Av'),
    14: AppLocalizations.of(context)!.translate('Elul'),
  };
}

static const List<String> hebrewDays = [

    'א',
    'ב',
    'ג',
    'ד',
    'ה',
    'ו',
    'ז',
    'ח',
    'ט',
    'י',
    'יא',
    'יב',
    'יג',
    'יד',
    'טו',
    'טז',
    'יז',
    'יח',
    'יט' 'כ',
    'כא',
    'כב',
    'כג',
    'כד',
    'כה',
    'כו',
    'כז',
    'כח',
    'כט',
    'ל'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.yahrtzeit != null) {
      _englishNameController.text = widget.yahrtzeit!.englishName ?? '';
      _hebrewNameController.text = widget.yahrtzeit!.hebrewName;
      _selectedDay = widget.yahrtzeit!.day;
      _selectedMonth = widget.yahrtzeit!.month;
      _groupController.text = widget.yahrtzeit!.group ?? '';
    }
    fetchGroups();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // הסתרת מקלדת ברירת המחדל
        SystemChannels.textInput.invokeMethod('TextInput.hide');
        setState(() {
          _showCustomKeyboard = true;
        });
      } else {
        setState(() {
          _showCustomKeyboard = false;
        });
      }
    });
  }

  Future<void> fetchGroups() async {
    try {
      final fetchedGroups = await manager.getAllGroups();
      setState(() {
        groups = fetchedGroups;
      });
    } catch (e) {
      print('Error fetching groups: $e');
    }
  }

  Future<void> writeData(List<Map<String, dynamic>> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('yahrtzeit_data', json.encode(data));
  }

  Future<List<Map<String, dynamic>>> readData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('yahrtzeit_data');
    if (jsonString != null) {
      return List<Map<String, dynamic>>.from(json.decode(jsonString));
    } else {
      return [];
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final localizations = AppLocalizations.of(context)!;

      try {
        List<Map<String, dynamic>> jsonData = await readData();
        Yahrtzeit newYahrtzeit;
        if (widget.language == 'en') {
          newYahrtzeit = Yahrtzeit(
            englishName: _englishNameController.text,
            hebrewName: _hebrewNameController.text.isNotEmpty
                ? _hebrewNameController.text
                : '',
            day: _selectedDay,
            month: _selectedMonth,
            group: _groupController.text,
          );
        } else {
          newYahrtzeit = Yahrtzeit(
            hebrewName: _hebrewNameController.text,
            englishName: _englishNameController.text.isNotEmpty
                ? _englishNameController.text
                : '',
            day: _selectedDay,
            month: _selectedMonth,
            group: _groupController.text,
          );
        }

        jsonData.add(newYahrtzeit.toJson());

        if (widget.syncSettings) {
          await manager.addYahrtzeit(
              newYahrtzeit, widget.yearsToSync, widget.syncSettings);
        }

        await writeData(jsonData);
        print('JSON file content: ${json.encode(jsonData)}');
        final savedData = await readData();
        print('Saved Data: $savedData');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.translate('Data saved!'))),
        );
        Navigator.pop(context, true);
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(localizations.translate('error')),
            content: Text('${localizations.translate('error')}: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(localizations.translate('ok')),
              ),
            ],
          ),
        );
      }
    }
  }


  Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () {
      FocusScope.of(context).requestFocus(new FocusNode());
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? AppLocalizations.of(context)!.translate('Edit Yahrtzeit') : AppLocalizations.of(context)!.translate('Add Yahrtzeit'),
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey[600],
        elevation: 0,
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _englishNameController,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!
                        .translate('English Name')),
                validator: (value) {
                  if (widget.language == 'en' &&
                      (value == null || value.isEmpty)) {
                    return AppLocalizations.of(context)!.translate('Please enter English name');
                  }
                  return null;
                },
              ),
              TextFormField(
                onTap: () {
                  FocusScope.of(context).requestFocus(_focusNode);
                },
                controller: _hebrewNameController,
                focusNode: _focusNode,
                readOnly: true,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!
                        .translate('Hebrew Name')),
                validator: (value) {
                  if (widget.language == 'he' &&
                      (value == null || value.isEmpty)) {
                    return AppLocalizations.of(context)!.translate('Please enter Hebrew name');
                  }
                  return null;
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: widget.language == 'he'
                        ? DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!
                                    .translate('day')),
                            value: _selectedDay,
                            items: hebrewDays.asMap().entries.map((entry) {
                              return DropdownMenuItem<int>(
                                value: entry.key + 1,
                                child: Text(entry.value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDay = value;
                              });
                            },
                          )
                        : DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!
                                    .translate('day')),
                            value: _selectedDay,
                            items: List.generate(31, (index) => index + 1)
                                .map((day) {
                              return DropdownMenuItem<int>(
                                value: day,
                                child: Text(
                                    day.toString()), // תצוגה של מספר באנגלית
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDay = value;
                              });
                            },
                          ),
                  ),
                  SizedBox(width: 16), // Add spacing between the fields
                  // Expanded(
                  //   child: DropdownButtonFormField<int>(
                  //     decoration: InputDecoration(
                  //         labelText: AppLocalizations.of(context)!
                  //             .translate('month')),
                  //     value: _selectedMonth,
                  //     items: hebrewMonths.entries.map((entry) {
                  //       return DropdownMenuItem<int>(
                  //         value: entry.key,
                  //         child: Text(entry.value),
                  //       );
                  //     }).toList(),
                  //     onChanged: (value) {
                  //       setState(() {
                  //         _selectedMonth = value;
                  //       });
                  //     },
                  //     validator: (value) {
                  //       return null;
                  //     },
                  //   ),
                  // ),

                  Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!
                                .translate('month')),
                        value: _selectedMonth,
                        items: getMonths(context).entries.map((entry) {
                          return DropdownMenuItem<int>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMonth = value;
                          });
                        },
                        validator: (value) {
                          return null;
                        },
                      ),
                    ),
                ],
              ),
              TextFormField(
                controller: _groupController,
                decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)!.translate('Group')),
              ),
              SizedBox(height: 30), // Add spacing between the fields
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(
                    widget.isEditing ? AppLocalizations.of(context)!.translate('Update Yahrtzeit') : AppLocalizations.of(context)!.translate('Add Yahrtzeit'),
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
              ),
              // Spacer to push the keyboard to the bottom of the screen
              Spacer(),
              if (_showCustomKeyboard)
                KeyboardLayout(
                  layoutType: _currentLanguage,
                  onKeyPressed: (key) {
                    setState(() {
                      if (key == 'DEL') {
                        if (_hebrewNameController.text.isNotEmpty) {
                          _hebrewNameController.text =
                              _hebrewNameController.text.substring(
                                  0, _hebrewNameController.text.length - 1);
                        }
                      } else if (key == 'Lang') {
                        _currentLanguage =
                            _currentLanguage == KeyboardLayoutType.English
                                ? KeyboardLayoutType.Hebrew
                                : KeyboardLayoutType.English;
                      } else {
                        _hebrewNameController.text += key;
                      }
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
  // static const Map<int, String> englishMonths = {
  //   JewishDate.NISSAN: 'Nissan',
  //   JewishDate.IYAR: 'Iyar',
  //   JewishDate.SIVAN: 'Sivan',
  //   JewishDate.TAMMUZ: 'Tammuz',
  //   JewishDate.AV: 'Av',
  //   JewishDate.ELUL: 'Elul',
  //   JewishDate.TISHREI: 'Tishrei',
  //   JewishDate.CHESHVAN: 'Cheshvan',
  //   JewishDate.KISLEV: 'Kislev',
  //   JewishDate.TEVES: 'Teves',
  //   JewishDate.SHEVAT: 'Shevat',
  //   JewishDate.ADAR: 'Adar',
  //   JewishDate.ADAR_II: 'Adar II',
  // };

  // static const Map<int, String> hebrewMonths = {
  //   JewishDate.NISSAN: 'ניסן',
  //   JewishDate.IYAR: 'אייר',
  //   JewishDate.SIVAN: 'סיוון',
  //   JewishDate.TAMMUZ: 'תמוז',
  //   JewishDate.AV: 'אב',
  //   JewishDate.ELUL: 'אלול',
  //   JewishDate.TISHREI: 'תשרי',
  //   JewishDate.CHESHVAN: 'חשוון',
  //   JewishDate.KISLEV: 'כסלו',
  //   JewishDate.TEVES: 'טבת',
  //   JewishDate.SHEVAT: 'שבט',
  //   JewishDate.ADAR: 'אדר',
  //   JewishDate.ADAR_II: 'אדר ב׳',
  // };
// static const Map<int, String> englishMonths = {
//   1: 'Nissan',
//   2: 'Iyar',
//   3: 'Sivan',
//   4: 'Tammuz',
//   5: 'Av',
//   6: 'Elul',
//   7: 'Tishrei',
//   8: 'Cheshvan',
//   9: 'Kislev',
//   10: 'Teves',
//   11: 'Shevat',
//   12: 'Adar',
//   13: 'Adar I',  // הוסף שורה זו
//   14: 'Adar II',
// };
// Map<int, String> getMonths(BuildContext context) {
//   return {
//     1: AppLocalizations.of(context)!.translate('Tishrei'),
//     2: AppLocalizations.of(context)!.translate('Cheshvan'),
//     3: AppLocalizations.of(context)!.translate('Kislev'),
//     4: AppLocalizations.of(context)!.translate('Teves'),
//     5: AppLocalizations.of(context)!.translate('Shevat'),
//     6: AppLocalizations.of(context)!.translate('Adar'),
//     7: AppLocalizations.of(context)!.translate('Adar I'),
//     8: AppLocalizations.of(context)!.translate('Adar II'),
//     9: AppLocalizations.of(context)!.translate('Nissan'),
//     10: AppLocalizations.of(context)!.translate('Iyar'),
//     11: AppLocalizations.of(context)!.translate('Sivan'),
//     12: AppLocalizations.of(context)!.translate('Tammuz'),
//     13: AppLocalizations.of(context)!.translate('Av'),
//     14: AppLocalizations.of(context)!.translate('Elul'),
//   };
// }

  // static const List<String> hebrewDays = [
  //   'א',
  //   'ב',
  //   'ג',
  //   'ד',
  //   'ה',
  //   'ו',
  //   'ז',
  //   'ח',
  //   'ט',
  //   'י',
  //   'יא',
  //   'יב',
  //   'יג',
  //   'יד',
  //   'טו',
  //   'טז',
  //   'יז',
  //   'יח',
  //   'יט' 'כ',
  //   'כא',
  //   'כב',
  //   'כג',
  //   'כד',
  //   'כה',
  //   'כו',
  //   'כז',
  //   'כח',
  //   'כט',
  //   'ל'
  // ];

  // @override
  // void initState() {
  //   super.initState();
  //   if (widget.isEditing && widget.yahrtzeit != null) {
  //     _englishNameController.text = widget.yahrtzeit!.englishName ?? '';
  //     _hebrewNameController.text = widget.yahrtzeit!.hebrewName;
  //     _selectedDay = widget.yahrtzeit!.day;
  //     _selectedMonth = widget.yahrtzeit!.month;
  //     _groupController.text = widget.yahrtzeit!.group ?? '';
  //   }
  //   fetchGroups();
  //   _focusNode.addListener(() {
  //     if (_focusNode.hasFocus) {
  //       // הסתרת מקלדת ברירת המחדל
  //       SystemChannels.textInput.invokeMethod('TextInput.hide');
  //       setState(() {
  //         _showCustomKeyboard = true;
  //       });
  //     } else {
  //       setState(() {
  //         _showCustomKeyboard = false;
  //       });
  //     }
  //   });
  // }

  // Future<void> fetchGroups() async {
  //   try {
  //     final fetchedGroups = await manager.getAllGroups();
  //     setState(() {
  //       groups = fetchedGroups;
  //     });
  //   } catch (e) {
  //     print('Error fetching groups: $e');
  //   }
  // }

  // Future<void> writeData(List<Map<String, dynamic>> data) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('yahrtzeit_data', json.encode(data));
  // }

  // Future<List<Map<String, dynamic>>> readData() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? jsonString = prefs.getString('yahrtzeit_data');
  //   if (jsonString != null) {
  //     return List<Map<String, dynamic>>.from(json.decode(jsonString));
  //   } else {
  //     return [];
  //   }
  // }

  // void _submitForm() async {
  //   if (_formKey.currentState!.validate()) {
  //     _formKey.currentState!.save();
  //     final localizations = AppLocalizations.of(context)!;

  //     try {
  //       List<Map<String, dynamic>> jsonData = await readData();
  //       Yahrtzeit newYahrtzeit;
  //       if (widget.language == 'en') {
  //         newYahrtzeit = Yahrtzeit(
  //           englishName: _englishNameController.text,
  //           hebrewName: _hebrewNameController.text.isNotEmpty
  //               ? _hebrewNameController.text
  //               : '',
  //           day: _selectedDay,
  //           month: _selectedMonth,
  //           group: _groupController.text,
  //         );
  //       } else {
  //         newYahrtzeit = Yahrtzeit(
  //           hebrewName: _hebrewNameController.text,
  //           englishName: _englishNameController.text.isNotEmpty
  //               ? _englishNameController.text
  //               : '',
  //           day: _selectedDay,
  //           month: _selectedMonth,
  //           group: _groupController.text,
  //         );
  //       }

  //       jsonData.add(newYahrtzeit.toJson());

  //       if (widget.syncSettings) {
  //         await manager.addYahrtzeit(
  //             newYahrtzeit, widget.yearsToSync, widget.syncSettings);
  //       }

  //       await writeData(jsonData);
  //       print('JSON file content: ${json.encode(jsonData)}');
  //       final savedData = await readData();
  //       print('Saved Data: $savedData');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text(AppLocalizations.of(context)!.translate('Data saved!'))),
  //       );
  //       Navigator.pop(context, true);
  //     } catch (e) {
  //       showDialog(
  //         context: context,
  //         builder: (context) => AlertDialog(
  //           title: Text(localizations.translate('error')),
  //           content: Text('${localizations.translate('error')}: $e'),
  //           actions: [
  //             TextButton(
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //               child: Text(localizations.translate('ok')),
  //             ),
  //           ],
  //         ),
  //       );
  //     }
  //   }
  // }

  // String _getMonthName(int month) {
  //   return Localizations.localeOf(context).languageCode == 'en'
  //       ? hebrewMonths[month] ?? ''
  //       : englishMonths[month] ?? '';
  // }



// @override
// Widget build(BuildContext context) {
//   return GestureDetector(
//     onTap: () {
//       FocusScope.of(context).requestFocus(new FocusNode());
//     },
//     child: Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.isEditing ? 'Edit Yahrtzeit' : 'Add Yahrtzeit',
//           style: TextStyle(color: Colors.white),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.grey[600],
//         elevation: 0,
//         actionsIconTheme: IconThemeData(color: Colors.white),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: <Widget>[
//               TextFormField(
//                 controller: _englishNameController,
//                 decoration: InputDecoration(
//                     labelText: AppLocalizations.of(context)!
//                         .translate('English Name')),
//                 validator: (value) {
//                   if (widget.language == 'en' &&
//                       (value == null || value.isEmpty)) {
//                     return 'Please enter English name';
//                   }
//                   return null;
//                 },
//               ),
//               TextFormField(
//                 onTap: () {
//                   FocusScope.of(context).requestFocus(_focusNode);
//                 },
//                 controller: _hebrewNameController,
//                 focusNode: _focusNode,
//                 readOnly: true,
//                 decoration: InputDecoration(
//                     labelText: AppLocalizations.of(context)!
//                         .translate('Hebrew Name')),
//                 validator: (value) {
//                   if (widget.language == 'he' &&
//                       (value == null || value.isEmpty)) {
//                     return 'Please enter Hebrew name';
//                   }
//                   return null;
//                 },
//               ),
//               Row(
//                 children: [
//                   Expanded(
//                     child: widget.language == 'he'
//                         ? DropdownButtonFormField<int>(
//                             decoration: InputDecoration(
//                                 labelText: AppLocalizations.of(context)!
//                                     .translate('day')),
//                             value: _selectedDay,
//                             items: hebrewDays.asMap().entries.map((entry) {
//                               return DropdownMenuItem<int>(
//                                 value: entry.key + 1,
//                                 child: Text(entry.value),
//                               );
//                             }).toList(),
//                             onChanged: (value) {
//                               setState(() {
//                                 _selectedDay = value;
//                               });
//                             },
//                           )
//                         : DropdownButtonFormField<int>(
//                             decoration: InputDecoration(
//                                 labelText: AppLocalizations.of(context)!
//                                     .translate('day')),
//                             value: _selectedDay,
//                             items: List.generate(31, (index) => index + 1)
//                                 .map((day) {
//                               return DropdownMenuItem<int>(
//                                 value: day,
//                                 child: Text(
//                                     day.toString()), // תצוגה של מספר באנגלית
//                               );
//                             }).toList(),
//                             onChanged: (value) {
//                               setState(() {
//                                 _selectedDay = value;
//                               });
//                             },
//                           ),
//                   ),
//                   SizedBox(width: 16), // Add spacing between the fields
//                   Expanded(
//                     child: DropdownButtonFormField<int>(
//                       decoration: InputDecoration(
//                           labelText: AppLocalizations.of(context)!
//                               .translate('month')),
//                       value: _selectedMonth,
//                       items: hebrewMonths.entries.map((entry) {
//                         return DropdownMenuItem<int>(
//                           value: entry.key,
//                           child: Text(entry.value),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedMonth = value;
//                         });
//                       },
//                       validator: (value) {
//                         return null;
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               TextFormField(
//                 controller: _groupController,
//                 decoration: InputDecoration(
//                     labelText:
//                         AppLocalizations.of(context)!.translate('Group')),
//               ),
//               SizedBox(height: 30), // Add spacing between the fields
//               ElevatedButton(
//                 onPressed: _submitForm,
//                 child: Text(
//                     widget.isEditing ? 'Update Yahrtzeit' : 'Add Yahrtzeit',
//                     style: TextStyle(
//                         color: Colors.black,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 20)),
//               ),
//               // Spacer to push the keyboard to the bottom of the screen
//               Spacer(),
//               if (_showCustomKeyboard)
//                 KeyboardLayout(
//                   layoutType: _currentLanguage,
//                   onKeyPressed: (key) {
//                     setState(() {
//                       if (key == 'DEL') {
//                         if (_hebrewNameController.text.isNotEmpty) {
//                           _hebrewNameController.text =
//                               _hebrewNameController.text.substring(
//                                   0, _hebrewNameController.text.length - 1);
//                         }
//                       } else if (key == 'Lang') {
//                         _currentLanguage =
//                             _currentLanguage == KeyboardLayoutType.English
//                                 ? KeyboardLayoutType.Hebrew
//                                 : KeyboardLayoutType.English;
//                       } else {
//                         _hebrewNameController.text += key;
//                       }
//                     });
//                   },
//                 ),
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
// }
// }
