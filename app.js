const express = require('express');
const path = require('path');
const app = express();
const bcrypt = require('bcryptjs');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
const PORT = process.env.PORT || 3000;

// ==========================================
// MOCK DATABASE (IN-MEMORY)
// ==========================================
let users = [
  {
    id_usuario: 1,
    nome: 'Administrador',
    usuario: 'admin',
    email: 'admin@gmail.com',
    senha: '123',
    role: 'admin'
  },
  {
    id_usuario: 2,
    nome: 'Teste Normal',
    usuario: 'teste',
    email: 'teste@gmail.com',
    senha: '123',
    role: 'user'
  }
];
let tasks = [];
// ==========================================

app.use(express.static('public'));
app.use(express.static(path.join(__dirname, 'public')));

app.get('/cadastro', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'cadastro.html'));
});

app.get('/landingpage', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'landingpage.html'));
});

app.get('/tarefas', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'tarefas.html'));
});

app.get('/foco', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'foco.html'));
});

app.get('/apps', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'apps.html'));
});

app.get('/addTarefas', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'addTarefas.html'));
});

app.get('/attTarefas', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'attTarefas.html'));
});

app.get('/ranking', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'ranking.html'));
});

// LOGIN ENDPOINT
app.post('/api/login', (req, res) => {
  const { email, senha } = req.body;

  if (!email || !senha) {
    console.log('Diagnóstico: Faltando Email ou Senha (Erro 400).');
    return res.status(400).json({ success: false, message: 'Email e senha são obrigatórios.' });
  }

  console.log(`Diagnóstico: Tentando login para ${email}`);

  // Busca no "banco" de memória
  const user = users.find(u => u.email === email);

  if (!user) {
    return res.status(401).json({ success: false, message: 'Credenciais inválidas.' });
  }

  const isMatch = (senha === user.senha); // Comparação simples

  if (isMatch) {
    return res.json({
      success: true,
      message: 'Login realizado com sucesso!',
      user: { id: user.id_usuario, nome: user.nome, email: user.email, role: user.role }
    });
  } else {
    return res.status(401).json({ success: false, message: 'Credenciais inválidas.' });
  }
});

// CADASTRO ENDPOINT
app.post('/cadastro', (req, res) => {
  const { nome, usuario, email, senha, confirmacao_senha, telefone } = req.body;

  if (users.find(u => u.email === email || u.usuario === usuario)) {
    return res.status(409).json({ success: false, message: 'Cadastro inválido. Usuário ou Email já existem.' });
  }

  const newUser = {
    id_usuario: users.length + 1,
    nome,
    usuario,
    email,
    senha,
    telefone,
    role: 'user' // default role
  };

  users.push(newUser);
  console.log(`Diagnóstico: Novo usuário cadastrado: ${email}`);

  return res.status(201).json({
    success: true,
    message: 'Cadastro realizado com sucesso!',
    user: { id: newUser.id_usuario, login: newUser.usuario, email: newUser.email, role: newUser.role }
  });
});

// ADD TAREFA ENDPOINT
app.post('/addTarefa', (req, res) => {
  const { titulo, prioridade, data_inicio, data_fim, descricao, andamento } = req.body;

  const newTarefa = {
    id_tarefa: tasks.length + 1,
    titulo,
    prioridade,
    data_inicio,
    data_fim,
    descricao,
    andamento
  };

  tasks.push(newTarefa);
  console.log(`Diagnóstico: Nova tarefa adicionada: ${titulo}`);

  // Retorna uma URL apenas para manter compatibilidade com o código original
  res.send(`http://localhost:${PORT}/tarefas`);
});

// GET TAREFAS (Para o Flutter)
app.get('/api/tarefas', (req, res) => {
  res.json(tasks);
});

app.listen(PORT, () => {
  console.log(`==========================================`);
  console.log(`SERVIDOR RODANDO (MODO MOCK / SEM BANCO)`);
  console.log(`IP LOCAL: http://192.168.0.168:${PORT}`);
  console.log(`Acesse por: http://localhost:${PORT}`);
  console.log(`==========================================`);
});