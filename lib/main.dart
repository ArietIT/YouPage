import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:eduapge2/api.dart';
import 'package:eduapge2/homework.dart';
import 'package:eduapge2/icanteen.dart';
import 'package:eduapge2/load.dart';
import 'package:eduapge2/messages.dart';
import 'package:eduapge2/qrlogin.dart';
import 'package:eduapge2/timetable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import 'package:eduapge2/l10n/app_localizations.dart';
import 'home.dart';
import 'package:toastification/toastification.dart';
import 'package:eduapge2/components/glass.dart';
import 'package:eduapge2/core/privacy_settings.dart';
import 'package:eduapge2/core/runtime_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await privacySettings.load();
  runApp(const MyApp());
}

abstract class BaseState<T extends StatefulWidget> extends State<T> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ColorScheme _generateColorScheme(Color? primaryColor,
      [Brightness? brightness]) {
    final Color seedColor = primaryColor ?? Colors.blue;

    final ColorScheme newScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness ?? Brightness.light,
    );

    return newScheme.harmonized();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return ToastificationWrapper(
        child: MaterialApp(
          title: 'YouPage',
          navigatorKey: navigatorKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: [
            Locale('en'),
            ...AppLocalizations.supportedLocales,
          ],
          builder: (context, child) => DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? const [Color(0xff08111f), Color(0xff1c1231), Color(0xff071b20)]
                    : const [Color(0xffdff5ff), Color(0xffefe3ff), Color(0xffffebdc)],
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
          theme: ThemeData(
            colorScheme: _generateColorScheme(
              lightColorScheme?.primary,
              Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
            cardTheme: CardThemeData(
              color: Colors.white.withOpacity(.68),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: _generateColorScheme(
              darkColorScheme?.primary,
              Brightness.dark,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
            cardTheme: CardThemeData(
              color: Colors.white.withOpacity(.08),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
          ),
          themeMode: ThemeMode.system,
          home: const PageBase(),
        ),
      );
    });
  }
}

class PageBase extends StatefulWidget {
  const PageBase({super.key});

  @override
  BaseState<PageBase> createState() => PageBaseState();
}

class PageBaseState extends BaseState<PageBase> {
  int _selectedIndex = 0;
  String baseUrl = RuntimeConfig.defaultBackendUrl;

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  bool loaded = false;

  bool error = false; //for error status
  bool loading = false; //for data featching status
  String errmsg = ""; //to assing any error message from API/runtime
  List<TimelineItem> apidataMsg = [];
  bool refresh = true;
  bool iCanteenEnabled = false;

  SessionManager sessionManager = SessionManager();

  @override
  void initState() {
    setOptimalDisplayMode();
    super.initState();
    initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (uri.path.startsWith('/l/')) {
        final code = uri.pathSegments[1];
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (context) => QRLoginPage(
            code: code,
          ),
        ));
      }
    });
  }

  Future<void> setOptimalDisplayMode() async {
    final List<DisplayMode> supported = await FlutterDisplayMode.supported;
    final DisplayMode active = await FlutterDisplayMode.active;

    final List<DisplayMode> sameResolution = supported
        .where((DisplayMode m) =>
            m.width == active.width && m.height == active.height)
        .toList()
      ..sort((DisplayMode a, DisplayMode b) =>
          b.refreshRate.compareTo(a.refreshRate));

    final DisplayMode mostOptimalMode =
        sameResolution.isNotEmpty ? sameResolution.first : active;

    await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> getMsgs() async {
    apidataMsg = EP2Data.getInstance().timeline.items.values.toList();
    dynamic ic = await sessionManager.get('iCanteenEnabled');
    if (ic.runtimeType == bool && ic == true) {
      iCanteenEnabled = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return !loaded
        ? Scaffold(
            appBar: AppBar(
              toolbarHeight: 0,
            ),
            body: LoadingScreen(
              sessionManager: sessionManager,
              loadedCallback: () {
                getMsgs();
                setState(() {
                  loaded = true;
                });
              },
            ),
          )
        : Scaffold(
            appBar: AppBar(
              toolbarHeight: 0,
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: <Widget>[
                HomePage(
                  sessionManager: sessionManager,
                  reLogin: () {
                    setState(() {
                      loaded = false;
                    });
                  },
                  onDestinationSelected: _onDestinationSelected,
                ),
                TimeTablePage(
                  sessionManager: sessionManager,
                ),
                if (iCanteenEnabled)
                  ICanteenPage(
                    sessionManager: sessionManager,
                  ),
                MessagesPage(
                  sessionManager: sessionManager,
                ),
                HomeworkPage(
                  sessionManager: sessionManager,
                )
              ],
            ),
            bottomNavigationBar: GlassNavigationBar(
              destinations: <NavigationDestination>[
                NavigationDestination(
                  icon: const Icon(Icons.home),
                  label: AppLocalizations.of(context)!.mainHome,
                  selectedIcon: const Icon(Icons.home_outlined),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_month),
                  label: AppLocalizations.of(context)!.mainTimetable,
                  selectedIcon: const Icon(Icons.calendar_month_outlined),
                ),
                if (iCanteenEnabled)
                  NavigationDestination(
                    icon: const Icon(Icons.lunch_dining_rounded),
                    label: AppLocalizations.of(context)!.mainICanteen,
                    selectedIcon: const Icon(Icons.lunch_dining_outlined),
                  ),
                /*
                NavigationDestination(
                  icon: Badge(
                    label: Text(apidataMsg
                        .where((msg) => msg["isSeen"] == false)
                        .toList()
                        .length
                        .toString()),
                    child: const Icon(Icons.mail),
                  ),
                  label: AppLocalizations.of(context)!.mainMessages,
                  selectedIcon: Badge(
                    label: Text(apidataMsg
                        .where((msg) => msg["isSeen"] == false)
                        .toList()
                        .length
                        .toString()),
                    child: const Icon(Icons.mail_outline),
                  ),
                ),
                */
                NavigationDestination(
                  icon: const Icon(Icons.mail),
                  label: AppLocalizations.of(context)!.mainMessages,
                  selectedIcon: const Icon(Icons.mail_outline),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.home_work),
                  label: AppLocalizations.of(context)!.mainHomework,
                  selectedIcon: const Icon(Icons.home_work_outlined),
                ),
              ],
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
            ),
          );
  }
}
