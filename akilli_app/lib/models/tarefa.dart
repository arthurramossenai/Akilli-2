class Tarefa {
  final int? idTarefa;
  final int? idUsuario;
  final String titulo;
  final String prioridade; // Tarefa Normal, Modo foco (prioridade_enum)
  final String? dataInicio;
  final String? dataFim;
  final String descricao;
  final String andamento; // Pendente, Em Andamento, Concluída, Cancelada (andamento_enum)

  Tarefa({
    this.idTarefa,
    this.idUsuario,
    required this.titulo,
    required this.prioridade,
    this.dataInicio,
    this.dataFim,
    required this.descricao,
    required this.andamento,
  });

  factory Tarefa.fromJson(Map<String, dynamic> json) {
    return Tarefa(
      idTarefa: json['id_tarefa'],
      idUsuario: json['id_usuario'],
      titulo: json['titulo'] ?? '',
      prioridade: json['prioridade'] ?? 'Tarefa Normal',
      dataInicio: json['data_inicio']?.toString(),
      dataFim: json['data_fim']?.toString(),
      descricao: json['descricao'] ?? '',
      andamento: json['andamento'] ?? 'Pendente',
    );
  }

  Map<String, dynamic> toJson() => {
        if (idTarefa != null) 'id_tarefa': idTarefa,
        if (idUsuario != null) 'id_usuario': idUsuario,
        'titulo': titulo,
        'prioridade': prioridade,
        'data_inicio': dataInicio,
        'data_fim': dataFim,
        'descricao': descricao,
        'andamento': andamento,
      };
}
