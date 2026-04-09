const bcrypt = require('bcryptjs');
const supabase = require('../config/supabase');

exports.login = async (req, res) => {
  const { email, senha } = req.body;

  if (!email || !senha) {
    return res.status(400).json({ success: false, message: 'Email e senha são obrigatórios.' });
  }

  try {
    const { data: users, error } = await supabase
      .from('usuarios')
      .select('*')
      .eq('email', email);

    if (error) throw error;

    if (!users || users.length === 0) {
      return res.status(401).json({ success: false, message: 'Credenciais inválidas.' });
    }

    const user = users[0];
    const isMatch = await bcrypt.compare(senha, user.senha);

    if (isMatch) {
      return res.json({
        success: true,
        message: 'Login realizado com sucesso!',
        user: { id: user.id_usuario, nome: user.nome, email: user.email, role: user.role }
      });
    } else {
      return res.status(401).json({ success: false, message: 'Credenciais inválidas.' });
    }
  } catch (err) {
    console.error('Erro no banco de dados durante o login:', err);
    return res.status(500).json({ success: false, message: 'Erro interno no banco de dados.' });
  }
};

exports.cadastro = async (req, res) => {
  const { nome, usuario, email, senha, confirmacao_senha, telefone } = req.body;

  try {
    const { data: existing, error: existingError } = await supabase
      .from('usuarios')
      .select('*')
      .or(`email.eq.${email},usuario.eq.${usuario}`);

    if (existingError) throw existingError;

    if (existing && existing.length > 0) {
      return res.status(409).json({ success: false, message: 'Cadastro inválido. Usuário ou Email já existem.' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(senha, salt);

    const { data: result, error: insertError } = await supabase
      .from('usuarios')
      .insert([
        { nome, usuario, email, senha: hashedPassword, confirmacao_senha: '', telefone, role: 'user' }
      ])
      .select();

    if (insertError) throw insertError;

    const newUser = result[0];
    return res.status(201).json({
      success: true,
      message: 'Cadastro realizado com sucesso!',
      user: { id: newUser.id_usuario, login: newUser.usuario, email: newUser.email, role: newUser.role }
    });
  } catch (err) {
    console.error('Erro no banco de dados durante o cadastro:', err);
    return res.status(500).json({ success: false, message: 'Erro interno no banco de dados.' });
  }
};
