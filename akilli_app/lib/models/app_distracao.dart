class AppDistracao {
  final int? id;
  final int? idUsuario;
  final String packageName;
  final String nomeDisplay;
  final String? iconeUrl;
  final bool ativo;

  AppDistracao({
    this.id,
    this.idUsuario,
    required this.packageName,
    required this.nomeDisplay,
    this.iconeUrl,
    this.ativo = true,
  });

  factory AppDistracao.fromJson(Map<String, dynamic> json) {
    return AppDistracao(
      id: json['id'],
      idUsuario: json['id_usuario'],
      packageName: json['package_name'],
      nomeDisplay: json['nome_display'],
      iconeUrl: json['icone_url'],
      ativo: json['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (idUsuario != null) 'id_usuario': idUsuario,
        'package_name': packageName,
        'nome_display': nomeDisplay,
        if (iconeUrl != null) 'icone_url': iconeUrl,
        'ativo': ativo,
      };
}
