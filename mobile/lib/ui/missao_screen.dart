import 'package:flutter/material.dart';

import '../domain/estande.dart';
import '../domain/missao.dart';
import '../servicos.dart';
import 'estande_tile.dart';
import 'scanner_screen.dart';

/// Detalhe da missão surpresa: estandes participantes (destacados e ativos).
class MissaoScreen extends StatefulWidget {
  const MissaoScreen({super.key, required this.servicos, required this.qtdInicial});

  final Servicos servicos;
  final int qtdInicial;

  @override
  State<MissaoScreen> createState() => _MissaoScreenState();
}

class _MissaoScreenState extends State<MissaoScreen> {
  late final Stream<List<Estande>> _ativos = widget.servicos.estandes.ouvirAtivos();

  @override
  void initState() {
    super.initState();
    widget.servicos.analytics.missaoAberta(widget.qtdInicial);
  }

  @override
  Widget build(BuildContext context) {
    final missao = widget.servicos.missao;
    return ListenableBuilder(
      listenable: missao,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(missao.ativa ? missao.titulo : 'Missão')),
        floatingActionButton: missao.ativa
            ? FloatingActionButton.extended(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => ScannerScreen(servicos: widget.servicos),
                )),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Fazer check-in'),
              )
            : null,
        body: !missao.ativa
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Missão encerrada pela organização.\nA lista de estandes e o check-in continuam disponíveis.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : StreamBuilder<List<Estande>>(
                stream: _ativos,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('Erro ao carregar: ${snap.error}'));
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final participantes = estandesDaMissao(snap.data!, missao.estandeIds);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      Text(
                        'Visite os estandes abaixo e leia o QR code de cada um para registrar sua visita.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      if (participantes.isEmpty)
                        const Text('Nenhum estande participante no momento.'),
                      for (final e in participantes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: EstandeTile(estande: e, destaque: true),
                        ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
