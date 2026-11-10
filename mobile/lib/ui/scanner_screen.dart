import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../domain/checkin.dart';
import '../servicos.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, required this.servicos});

  final Servicos servicos;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);

  /// Impede que leituras repetidas do mesmo QR gerem vários check-ins.
  bool _processando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _aoDetectar(BarcodeCapture captura) async {
    if (_processando) return;
    final raw = captura.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (raw == null) return;

    setState(() => _processando = true);
    final s = widget.servicos;
    final resultado = await s.checkin.processar(raw, s.visitanteId);
    if (resultado.status == CheckinStatus.sucesso) {
      // Não bloqueia a confirmação se o Analytics falhar.
      s.analytics.checkinConcluido(resultado.estande!.id).ignore();
    }
    if (!mounted) return;

    final lerOutro = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoResultado(resultado: resultado),
    );
    if (!mounted) return;
    if (lerOutro == true) {
      setState(() => _processando = false);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ler QR code do estande')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _aoDetectar,
            errorBuilder: (context, erro) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  erro.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'Permita o acesso à câmera nas configurações para ler o QR code.'
                      : 'Não foi possível abrir a câmera (${erro.errorCode.name}).',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (_processando)
            const ColoredBox(
              color: Colors.black45,
              child: Center(child: CircularProgressIndicator()),
            ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Text(
              'Aponte a câmera para o QR code exibido no estande',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, shadows: [
                Shadow(blurRadius: 4),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogoResultado extends StatelessWidget {
  const _DialogoResultado({required this.resultado});

  final CheckinResultado resultado;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final (icone, cor) = switch (resultado.status) {
      CheckinStatus.sucesso => (Icons.check_circle, Colors.green),
      CheckinStatus.jaRegistrado => (Icons.info, cores.primary),
      CheckinStatus.inativo => (Icons.block, Colors.orange),
      _ => (Icons.error, cores.error),
    };
    return AlertDialog(
      icon: Icon(icone, color: cor, size: 48),
      title: Text(resultado.mensagem, textAlign: TextAlign.center),
      content: resultado.estande == null
          ? null
          : Text(
              '${resultado.estande!.nome}\n${resultado.estande!.localizacao}',
              textAlign: TextAlign.center,
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Voltar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Ler outro'),
        ),
      ],
    );
  }
}
