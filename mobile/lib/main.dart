import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/auth_service.dart';
import 'data/missao_config.dart';
import 'firebase_options.dart';
import 'servicos.dart';
import 'ui/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CircuitoApp());
}

Future<Servicos> inicializar() async {
  if (DefaultFirebaseOptions.currentPlatform.apiKey == 'SUBSTITUIR') {
    throw StateError(
      'Firebase ainda não configurado. Rode "flutterfire configure" na pasta mobile/.',
    );
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final uid = await AuthService().garantirLogin();
  final missao = MissaoConfig();
  await missao.iniciar();
  return Servicos(visitanteId: uid, missao: missao);
}

class CircuitoApp extends StatelessWidget {
  const CircuitoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const semente = Color(0xFF0B7A5C);
    return MaterialApp(
      title: 'Circuito de Descobertas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: semente, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: semente,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const _Inicializacao(),
    );
  }
}

class _Inicializacao extends StatefulWidget {
  const _Inicializacao();

  @override
  State<_Inicializacao> createState() => _InicializacaoState();
}

class _InicializacaoState extends State<_Inicializacao> {
  late Future<Servicos> _futuro = inicializar();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Servicos>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.hasData) return HomeScreen(servicos: snap.data!);
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Não foi possível iniciar o app',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('${snap.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => setState(() => _futuro = inicializar()),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
