import 'package:flutter/material.dart';

import '../domain/estande.dart';
import '../domain/missao.dart';
import '../servicos.dart';
import 'estande_tile.dart';
import 'missao_screen.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.servicos});

  final Servicos servicos;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<List<Estande>> _ativos = widget.servicos.estandes.ouvirAtivos();

  void _abrirMissao(int qtd) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => MissaoScreen(servicos: widget.servicos, qtdInicial: qtd),
    ));
  }

  void _abrirScanner() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ScannerScreen(servicos: widget.servicos),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final missao = widget.servicos.missao;
    return Scaffold(
      appBar: AppBar(title: const Text('Circuito de Descobertas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirScanner,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Ler QR code'),
      ),
      body: StreamBuilder<List<Estande>>(
        stream: _ativos,
        builder: (context, snap) {
          if (snap.hasError) {
            return _Mensagem(
              icone: Icons.error_outline,
              texto: 'Não foi possível carregar os estandes.\n${snap.error}',
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final ativos = snap.data!;
          return ListenableBuilder(
            listenable: missao,
            builder: (context, _) {
              final daMissao = missao.ativa
                  ? estandesDaMissao(ativos, missao.estandeIds)
                  : const <Estande>[];
              final idsDestaque = daMissao.map((e) => e.id).toSet();
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  if (missao.ativa)
                    _BannerMissao(
                      titulo: missao.titulo,
                      qtd: daMissao.length,
                      onAbrir: () => _abrirMissao(daMissao.length),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Estandes (${ativos.length})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (ativos.isEmpty)
                    const _Mensagem(
                      icone: Icons.storefront,
                      texto: 'Nenhum estande ativo no momento.',
                    ),
                  for (final e in ativos)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: EstandeTile(estande: e, destaque: idsDestaque.contains(e.id)),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _BannerMissao extends StatelessWidget {
  const _BannerMissao({required this.titulo, required this.qtd, required this.onAbrir});

  final String titulo;
  final int qtd;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Card(
      color: cores.tertiary,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onAbrir,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.rocket_launch, color: cores.onTertiary, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: cores.onTertiary),
                    ),
                    Text(
                      qtd == 1
                          ? 'Visite o estande destacado e faça check-in'
                          : 'Visite os $qtd estandes destacados e faça check-in',
                      style: TextStyle(color: cores.onTertiary),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(onPressed: onAbrir, child: const Text('Ver missão')),
            ],
          ),
        ),
      ),
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 40),
            const SizedBox(height: 8),
            Text(texto, textAlign: TextAlign.center),
          ],
        ),
      );
}
