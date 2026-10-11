import 'package:eduapge2/core/hidden_grades_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class HiddenGradesScreen extends StatefulWidget {
  const HiddenGradesScreen({super.key});

  @override
  State<HiddenGradesScreen> createState() => _HiddenGradesScreenState();
}

class _HiddenGradesScreenState extends State<HiddenGradesScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isUnlocked = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _unlock();
  }

  Future<void> _unlock() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics && !isSupported) {
        if (!mounted) return;
        setState(() {
          _isUnlocked = true;
          _checking = false;
        });
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Подтвердите доступ к скрытым оценкам',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (!mounted) return;
      setState(() {
        _isUnlocked = authenticated;
        _checking = false;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _isUnlocked = true;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Скрытые оценки'),
      ),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : !_isUnlocked
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Доступ не подтверждён. Попробуйте ещё раз.'),
                  ),
                )
              : ListenableBuilder(
                  listenable: hiddenGradesStore,
                  builder: (context, _) {
                    final ids = hiddenGradesStore.ids.toList()..sort();
                    if (ids.isEmpty) {
                      return const Center(
                        child: Text('Скрытых оценок нет.'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: ids.length,
                      itemBuilder: (context, index) {
                        final id = ids[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.visibility_off_outlined),
                            title: Text('Оценка $id'),
                            trailing: TextButton(
                              onPressed: () async {
                                await hiddenGradesStore.restore(id);
                              },
                              child: const Text('Вернуть'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
