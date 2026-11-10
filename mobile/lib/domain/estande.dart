/// Estande da feira, como gravado em `estandes/{id}` no Firestore.
class Estande {
  const Estande({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.localizacao,
    required this.ativo,
  });

  factory Estande.fromMap(String id, Map<String, dynamic> m) => Estande(
        id: id,
        nome: (m['nome'] as String?) ?? '',
        descricao: (m['descricao'] as String?) ?? '',
        localizacao: (m['localizacao'] as String?) ?? '',
        ativo: m['ativo'] == true,
      );

  final String id;
  final String nome;
  final String descricao;
  final String localizacao;
  final bool ativo;
}
