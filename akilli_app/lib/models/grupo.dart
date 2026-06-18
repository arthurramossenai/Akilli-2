class Grupo {
  final int? idGrupo;
  final String nome;
  final String codigo;
  final int? idCriador;
  final String? criadoEm;

  Grupo({
    this.idGrupo,
    required this.nome,
    required this.codigo,
    this.idCriador,
    this.criadoEm,
  });

  factory Grupo.fromJson(Map<String, dynamic> json) {
    return Grupo(
      idGrupo: json['id_grupo'],
      nome: json['nome'] ?? '',
      codigo: json['codigo'] ?? '',
      idCriador: json['id_criador'],
      criadoEm: json['criado_em']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (idGrupo != null) 'id_grupo': idGrupo,
        'nome': nome,
        'codigo': codigo,
        if (idCriador != null) 'id_criador': idCriador,
      };
}
