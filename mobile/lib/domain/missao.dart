import 'estande.dart';

/// Converte o parâmetro `missao_estandes` do Remote Config ("a, b,c")
/// na lista de ids, ignorando espaços e entradas vazias.
List<String> parseMissaoEstandes(String csv) => csv
    .split(',')
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();

/// Estandes que participam da missão: destacados no Remote Config
/// **e** ativos, na mesma ordem da lista recebida.
List<Estande> estandesDaMissao(List<Estande> ativos, List<String> ids) {
  final destacados = ids.toSet();
  return ativos.where((e) => e.ativo && destacados.contains(e.id)).toList();
}
