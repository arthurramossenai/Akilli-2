class Usuario {
  final int? id;
  final String nome;
  final String email;
  final String role;

  Usuario({this.id, required this.nome, required this.email, required this.role});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'role': role,
      };
}
