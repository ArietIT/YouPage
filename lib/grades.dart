import 'package:eduapge2/api.dart';
import 'package:eduapge2/components/hideable_grade.dart';
import 'package:eduapge2/core/hidden_grades_store.dart';
import 'package:eduapge2/main.dart';
import 'package:flutter/material.dart';
import 'package:eduapge2/l10n/app_localizations.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import 'package:eduapge2/components/glass.dart';
import 'package:eduapge2/core/privacy_settings.dart';

class GradesPage extends StatefulWidget {
  final SessionManager sessionManager;

  const GradesPage({super.key, required this.sessionManager});

  @override
  BaseState<GradesPage> createState() => GradesPageState();
}

class GradesPageState extends BaseState<GradesPage> {
  bool loading = true;

  final EP2Data data = EP2Data.getInstance();

  List<Widget> messages = [];

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    setState(() {
      loading = true; //make loading true to show progressindicator
    });

    messages = await getMessages(EP2Data.getInstance().grades);

    loading = false;
    setState(() {}); //refresh UI
  }

  Future<void> _hideGrade(String id) async {
    await hiddenGradesStore.hide(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
            'Оценка скрыта. Нажмите «Вернуть», чтобы восстановить её.'),
        action: SnackBarAction(
          label: 'Вернуть',
          onPressed: () => _restoreGrade(id),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _restoreGrade(String id) async {
    await hiddenGradesStore.restore(id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
        title: Text(AppLocalizations.of(context)!.gradesTitle),
        actions: [
          ListenableBuilder(
            listenable: privacySettings,
            builder: (context, _) => IconButton(
              tooltip:
                  privacySettings.enabled ? 'Показать оценки' : 'Скрыть оценки',
              onPressed: () =>
                  privacySettings.setEnabled(!privacySettings.enabled),
              icon: Icon(privacySettings.enabled
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
            ),
          ),
          PopupMenuButton<GradeMaskStyle>(
            tooltip: 'Способ скрытия оценок',
            onSelected: privacySettings.setStyle,
            itemBuilder: (context) => const [
              PopupMenuItem(
                  value: GradeMaskStyle.blur, child: Text('Размытие')),
              PopupMenuItem(value: GradeMaskStyle.dots, child: Text('Точки')),
            ],
          ),
        ],
      ),
      body: !loading
          ? GlassCard(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Stack(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: RefreshIndicator(
                        onRefresh: _pullRefresh,
                        child: ListView(
                          children: messages,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Text(AppLocalizations.of(context)!.loading),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  Future<void> _pullRefresh() async {
    setState(() {
      loading = true; //make loading true to show progressindicator
    });

    messages = await getMessages(EP2Data.getInstance().grades);

    loading = false;
    setState(() {}); //refresh UI
  }

  Future<List<Widget>> getMessages(Grades results) async {
    List<Widget> rows = <Widget>[];
    Map<String, List<Event>> grades = {};
    for (Event msg in results.events.values) {
      if (msg.data == "") continue;
      if (!grades.containsKey(msg.subjectID)) grades[msg.subjectID] = [];
      grades[msg.subjectID]?.add(msg);
    }
    for (String key in grades.keys) {
      List<Event>? g = grades[key];
      if (g == null) continue;
      if ((await data.dbi.getSubject(key)).name == "") continue;

      double avg = 0;
      try {
        List<double> allGrades = g
            .map((grade) =>
                double.parse(grade.data) * double.parse(grade.weight) / 20)
            .toList();
        List<double> allWeights =
            g.map((grade) => double.parse(grade.weight) / 20).toList();
        avg = allGrades.reduce((a, b) => a + b) /
            allWeights.reduce((a, b) => a + b);
      } catch (e) {
        continue;
      }

      rows.add(GlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      (await data.dbi.getSubject(key)).name,
                      style: TextStyle(
                        fontSize: 16,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: g
                      .map(
                        (grade) => HideableGrade(
                          id: grade.id,
                          value: grade.data,
                          onHide: _hideGrade,
                          onRestore: _restoreGrade,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            Column(
              children: [
                HideableGrade(
                  id: 'avg_$key',
                  value: avg.toStringAsFixed(2),
                  onHide: _hideGrade,
                  onRestore: _restoreGrade,
                ),
              ],
            ),
          ],
        ),
      ));
    }
    return rows;
  }
}
