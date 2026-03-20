class Tarefa {
  final String? id; // Adicionado ID opcional para caso venha do backend
  final String titulo;
  final String prioridade; // Alta, Média, Baixa
  final String dataInicio;
  final String dataFim;
  final String descricao;
  final String andamento; // Pendente, Em Andamento, Concluída

  Tarefa({
    this.id,
    required this.titulo,
    required this.prioridade,
    required this.dataInicio,
    required this.dataFim,
    required this.descricao,
    required this.andamento,
  });

  factory Tarefa.fromJson(Map<String, dynamic> json) {
    return Tarefa(
      id: json['id']?.toString(),
      titulo: json['titulo'] ?? '',
      prioridade: json['prioridade'] ?? 'Baixa',
      dataInicio: json['data_inicio'] ?? '',
      dataFim: json['data_fim'] ?? '',
      descricao: json['descricao'] ?? '',
      andamento: json['andamento'] ?? 'Pendente',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'titulo': titulo,
        'prioridade': prioridade,
        'data_inicio': dataInicio,
        'data_fim': dataFim,
        'descricao': descricao,
        'andamento': andamento,
      };
}
