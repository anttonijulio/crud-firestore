import 'package:crud_firestore/app/page/note_page.dart';
import 'package:flutter/material.dart';

// collection id
const collectionId = 'note-collection';

// nav key
final navKey = GlobalKey<NavigatorState>();

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: false),
      darkTheme: ThemeData.dark(useMaterial3: false),
      themeMode: ThemeMode.system,
      navigatorKey: navKey,
      home: const NotePage(),
    );
  }
}
