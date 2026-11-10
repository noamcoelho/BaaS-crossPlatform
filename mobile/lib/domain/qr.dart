const _prefixo = 'circuito://estande/';

/// Extrai o id do estande do conteúdo de um QR do circuito
/// (`circuito://estande/<id>`), ou `null` se o conteúdo não for válido.
String? parseQr(String raw) {
  final texto = raw.trim();
  if (!texto.startsWith(_prefixo)) return null;
  final id = texto.substring(_prefixo.length);
  if (id.isEmpty || id.contains('/')) return null;
  return id;
}
