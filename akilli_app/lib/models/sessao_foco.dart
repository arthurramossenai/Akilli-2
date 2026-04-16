class SessaoFoco {
  final int? id;
  final int? idUsuario;
  final int? idTarefa; // Opcional, se a sessão não foi atrelada a uma tarefa específica
  final DateTime inicioSessao;
  final DateTime fimSessao;
  final int duracaoMinutos;
  final String statusSessao; // 'Sucesso', 'Falha'
  final String? appsBloqueados; // Resumo JSON
  final int falhas;
  final int pontosGanhos;

  SessaoFoco({
    this.id,
    this.idUsuario,
    this.idTarefa,
    required this.inicioSessao,
    required this.fimSessao,
    required this.duracaoMinutos,
    required this.statusSessao,
    this.appsBloqueados,
    this.falhas = 0,
    this.pontosGanhos = 0,
  });

  factory SessaoFoco.fromJson(Map<String, dynamic> json) {
    return SessaoFoco(
      id: json['id'],
      idUsuario: json['id_usuario'],
      idTarefa: json['id_tarefa'],
      inicioSessao: DateTime.parse(json['inicio_sessao']),
      fimSessao: DateTime.parse(json['fim_sessao']),
      duracaoMinutos: json['duracao_minutos'] ?? 0,
      statusSessao: json['status_sessao'] ?? 'Desconhecido',
      appsBloqueados: json['apps_bloqueados'],
      falhas: json['falhas'] ?? 0,
      pontosGanhos: json['pontos_ganhos'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (idUsuario != null) 'id_usuario': idUsuario,
        if (idTarefa != null) 'id_tarefa': idTarefa,
        'inicio_sessao': inicioSessao.toIso8601String(),
        'fimSessao': fimSessao.toIso8601String(),
        'duracao_minutos': duracaoMinutos,
        'status_sessao': statusSessao,
        if (appsBloqueados != null) 'apps_bloqueados': appsBloqueados,
        'falhas': falhas,
        'pontos_ganhos': pontosGanhos,
      };
}
