import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = await AppStore.load(prefs);
  runApp(ChangeNotifierProvider<AppStore>.value(value: store, child: const VeritasTennisApp()));
}
