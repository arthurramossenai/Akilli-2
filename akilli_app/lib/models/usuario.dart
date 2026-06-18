class Usuario {
  final int? idUsuario;
  final String nome;
  final String usuario;
  final String email;
  final String? telefone;
  final String? planoAssinatura;
  final int? pontos;
  final String? cadastradoEm;
  final String? avatarUrl;

  Usuario({
    this.idUsuario,
    required this.nome,
    required this.usuario,
    required this.email,
    this.telefone,
    this.planoAssinatura,
    this.pontos,
    this.cadastradoEm,
    this.avatarUrl,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['id_usuario'],
      nome: json['nome'] ?? '',
      usuario: json['usuario'] ?? '',
      email: json['email'] ?? '',
      telefone: json['telefone'],
      planoAssinatura: json['plano_assinatura'],
      pontos: json['pontos'],
      cadastradoEm: json['cadastrado_em']?.toString(),
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        if (idUsuario != null) 'id_usuario': idUsuario,
        'nome': nome,
        'usuario': usuario,
        'email': email,
        'telefone': telefone,
        'plano_assinatura': planoAssinatura,
        'pontos': pontos,
        'avatar_url': avatarUrl,
      };
}
