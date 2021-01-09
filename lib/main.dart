import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:language_pickers/language_picker_dialog.dart';
import 'package:language_pickers/languages.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'item.dart';

void main() {
  runApp(
    EasyLocalization(
        useOnlyLangCode: true,
        supportedLocales: [Locale('en'), Locale('fi')],
        path: 'assets/i18n',
        fallbackLocale: Locale('en'),
        child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      onGenerateTitle: (context) => tr('appName'),
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      home: ScalePointsCalculator(),
    );
  }
}

class ScalePointsCalculator extends StatefulWidget {
  @override
  _ScalePointsCalculatorState createState() => _ScalePointsCalculatorState();
}

class _ScalePointsCalculatorState extends State<ScalePointsCalculator> {
  final _saved = <Item>[];
  final _headerFont = TextStyle(fontSize: 22.0);
  final _biggerFont = TextStyle(fontSize: 18.0);
  final _listFont = TextStyle(fontSize: 16.0);
  Item _points;
  final _savedKey = "SAVED_ITEMS";

  loadJson() async {
    String data = await rootBundle.loadString('assets/points.json');
    final points = Item.fromJson(json.decode(data));
    final saved = <Item>[];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedKeys = prefs.getStringList(_savedKey);

    if(savedKeys != null) {
      savedKeys.forEach((element) {
        saved.add(findItem(element, points));
      });
    }

    setState(() {
      _points = points;
      _saved.addAll(saved);
    });
  }

  Item findItem(String key, Item item) {
    final keys = key.split(".");
    final found = item.items.where((element) => element.title == keys[0]).first;
    if (keys.length == 1) {
      return found;
    } else {
      return findItem(keys.sublist(1).join("."), found);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadJson();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('appName')),
        actions: [
          IconButton(
              icon: Icon(Icons.list), onPressed: _openLanguagePickerDialog),
        ],
      ),
      body: _buildUI(),
    );
  }

  Widget _buildDialogItem(Language language) => Text(language.name);

  void _openLanguagePickerDialog() => showDialog(
        context: context,
        builder: (context) => Theme(
            data: Theme.of(context).copyWith(primaryColor: Colors.pink),
            child: LanguagePickerDialog(
                languagesList: defaultLanguagesList
                    .where((element) => context.supportedLocales
                        .map((e) => e.languageCode)
                        .contains(element['isoCode']))
                    .toList()
                    .cast<Map<String, String>>(),
                titlePadding: EdgeInsets.all(8.0),
                isSearchable: false,
                title: Text(tr('selectLanguage')),
                onValuePicked: (Language language) => setState(() {
                      context.locale = Locale(language.isoCode);
                    }),
                itemBuilder: _buildDialogItem)),
      );

  Widget _buildUI() {
    if (_points == null) {
      return Text(tr('loading'));
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text("${tr('totalPoints')}: ${getPoints()}",
                  style: _headerFont)),
          Expanded(
              child: ListView.builder(
                  padding: EdgeInsets.all(16.0),
                  itemBuilder: (context, i) {
                    if (i >= _points.items.length) {
                      return null;
                    }
                    return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Divider(),
                          Center(
                              child: Container(
                                  constraints: BoxConstraints(
                                      minWidth: 200, maxWidth: 800),
                                  child: _buildRow(_points.items[i])))
                        ]);
                  })),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: FlatButton(
                  color: ThemeData.light().buttonColor,
                  padding: EdgeInsets.all(16.0),
                  onPressed: getPoints() < 0
                      ? () {
                          _showSummaryView();
                        }
                      : null,
                  child: Text(
                    tr('summary'),
                    style: _biggerFont,
                  ),
                )),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: FlatButton(
                  color: ThemeData.light().buttonColor,
                  padding: EdgeInsets.all(16.0),
                  onPressed: () async {
                    await _clearSaved();
                  },
                  child: Text(
                    tr('clear'),
                    style: _biggerFont,
                  ),
                ))
          ])
        ],
      );
    }
  }

  Item _getParentFromBranch(Item item, Item branch) {
    if (branch.items.contains(item)) {
      return branch;
    } else {
      for (Item element in branch.items) {
        final ret = _getParentFromBranch(item, element);
        if (ret != null) {
          return ret;
        }
      }
    }
    return null;
  }

  String _getFullPath(Item item) {
    final parent = _getParentFromBranch(item, _points);
    if (parent == _points) {
      return item.title;
    } else {
      return "${_getFullPath(parent)}.${item.title}";
    }
  }

  bool _hasSelectedChildren(Item item) {
    var ret = false;
    if (item.items != null) {
      item.items.forEach((element) {
        if (_saved.contains(element)) {
          ret = true;
        }

        if (element.items != null) {
          if (_hasSelectedChildren(element)) {
            ret = true;
          }
        }
      });
    }

    return ret;
  }

  List<Widget> getTilesForSelectedSubItems(Item item, int level) {
    List<Widget> list = <Widget>[];
    if (_saved.contains(item)) {
      final count = _saved.where((element) => element == item).length;
      list.add(Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0 * level, vertical: 4),
          child: Text(
            "${tr(item.title)} (${item.points * count})",
            style: _listFont,
          )));
    } else if (_hasSelectedChildren(item)) {
      list.add(Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0 * level, vertical: 4),
          child: Text(tr(item.title), style: _listFont)));
      item.items.forEach((element) {
        list.addAll(getTilesForSelectedSubItems(element, level + 1));
      });
    }

    return list;
  }

  void _showSummaryView() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          List<Widget> tiles = <Widget>[];

          _points.items.forEach((element) {
            tiles.addAll(getTilesForSelectedSubItems(element, 0));
          });

          return Scaffold(
            appBar: AppBar(
              title: Text("${tr('totalPoints')}: ${getPoints()}"),
            ),
            body: ListView(
              padding: EdgeInsets.all(16),
              children: tiles,
            ),
          );
        },
      ),
    );
  }

  int getPoints() {
    var points = 0;
    _saved.forEach((element) {
      points += element.points;
    });
    return points;
  }

  Future<bool> _clearSaved() async {
    setState(() {
      _saved.clear();
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.remove(_savedKey);
  }

  Future<bool> _add(Item item) async {
    setState(() {
      _saved.add(item);
    });
    final savedPaths = _saved.map((e) => _getFullPath(e)).toList();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_savedKey, savedPaths);
  }

  Future<bool> _remove(Item item) async {
    setState(() {
      _saved.remove(item);
    });
    final savedPaths = _saved.map((e) => _getFullPath(e)).toList();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedKey);
    return prefs.setStringList(_savedKey, savedPaths);
  }

  Widget _buildRow(Item item, [Item parent]) {
    final alreadySaved = _saved.where((element) => element == item).length;
    if (item.points != null) {
      return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: ListTile(
              title: Text(
                "${tr(item.title)} (${item.points})",
                style: _biggerFont,
              ),
              subtitle: item.subtitle != null ? Text(tr(item.subtitle)) : null,
              trailing: item.allowMultiple != null && item.allowMultiple
                  ? Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.remove,
                            color: alreadySaved > 0
                                ? ThemeData.light().accentColor
                                : ThemeData.light().disabledColor),
                        onPressed: () async {
                          await _remove(item);
                        },
                      ),
                      Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          child: Text("$alreadySaved")),
                      IconButton(
                        icon: Icon(Icons.add,
                            color: item.maxSelections == null ||
                                    alreadySaved < item.maxSelections
                                ? ThemeData.light().accentColor
                                : ThemeData.light().disabledColor),
                        onPressed: () async {
                          if (item.maxSelections == null ||
                              alreadySaved < item.maxSelections) {
                            await _add(item);
                          }
                        },
                      )
                    ])
                  : Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        alreadySaved > 0
                            ? Icons.add_circle
                            : Icons.add_circle_outline,
                        color: alreadySaved > 0
                            ? ThemeData.light().primaryColor
                            : ThemeData.light().accentColor,
                      )),
              onTap: () async {
                if (item.allowMultiple != null && item.allowMultiple) {
                  return;
                }
                if (alreadySaved > 0) {
                  await _remove(item);
                } else {
                  if (parent.exclusive != null && parent.exclusive) {
                    parent.items.forEach((element) async {
                      await _remove(element);
                    });
                  }
                  await _add(item);
                }
              }));
    } else {
      var children = <Widget>[
        ListTile(
            title: Text(
              tr(item.title),
              style: _headerFont,
            ),
            subtitle: item.subtitle != null ? Text(tr(item.subtitle)) : null)
      ];
      item.items.forEach((element) {
        children.add(_buildRow(element, item));
      });
      return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Column(children: children));
    }
  }
}
