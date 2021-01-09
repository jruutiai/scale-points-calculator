import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'AppLocalizations.dart';
import 'item.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales:
          AppLocalizationsDelegate.supportedLocales.map((e) => Locale(e)),
      onGenerateTitle: (context) =>
          AppLocalizations.of(context).translate('appName'),
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
  var points;
  var loading = true;
  Locale locale;

  loadJson() async {
    String data = await rootBundle.loadString('assets/points.json');
    points = Item.fromJson(json.decode(data));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadJson();
      setState(() {
        loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('appName')),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    if (loading) {
      return Text(AppLocalizations.of(context).translate('loading'));
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                  "${AppLocalizations.of(context).translate('totalPoints')}: ${getPoints()}",
                  style: _headerFont)),
          Expanded(
              child: ListView.builder(
                          padding: EdgeInsets.all(16.0),
                          itemBuilder: (context, i) {
                            if (i >= points.items.length) {
                              return null;
                            }
                            return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  Divider(),
                                  Center(
                                      child: Container(
                                      constraints: BoxConstraints(minWidth: 200, maxWidth: 800),
                                  child: _buildRow(points.items[i])))
                                ]);
                          }))
        ],
      );
    }
  }

  int getPoints() {
    var points = 0;
    _saved.forEach((element) {
      points += element.points;
    });
    return points;
  }

  Widget _buildRow(Item item, [Item parent]) {
    final alreadySaved = _saved.where((element) => element == item).length;
    if (item.points != null) {
      return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: ListTile(
              title: Text(
                "${AppLocalizations.of(context).translate(item.title)} (${item.points})",
                style: _biggerFont,
              ),
              subtitle: item.subtitle != null
                  ? Text(AppLocalizations.of(context).translate(item.subtitle))
                  : null,
              trailing: item.allowMultiple != null && item.allowMultiple
                  ? Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.remove,
                            color: alreadySaved > 0
                                ? ThemeData.light().accentColor
                                : ThemeData.light().disabledColor),
                        onPressed: () {
                          setState(() {
                            _saved.remove(item);
                          });
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
                        onPressed: () {
                          if (item.maxSelections == null ||
                              alreadySaved < item.maxSelections) {
                            setState(() {
                              _saved.add(item);
                            });
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
              onTap: () {
                setState(() {
                  if (item.allowMultiple != null && item.allowMultiple) {
                    return;
                  }
                  if (alreadySaved > 0) {
                    _saved.remove(item);
                  } else {
                    if (parent.exclusive != null && parent.exclusive) {
                      parent.items.forEach((element) {
                        _saved.remove(element);
                      });
                    }
                    _saved.add(item);
                  }
                });
              }));
    } else {
      var children = <Widget>[
        ListTile(
            title: Text(
              AppLocalizations.of(context).translate(item.title),
              style: _headerFont,
            ),
            subtitle: item.subtitle != null
                ? Text(AppLocalizations.of(context).translate(item.subtitle))
                : null)
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
