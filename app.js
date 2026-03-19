const express = require('express');
const path = require('path');
const app = express();
const bcrypt = require('bcryptjs');
const mysql = require('mysql2');
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
const PORT = process.env.PORT || 3000;

const connection = mysql.createConnection({

  host: 'localhost',
  user: 'root',
  password: 'mendesarmy1998*',
  database: 'akili'

});

connection.connect(err => {
  if (err) {
    console.error('Erro ao conectar no MySQL:', err.message);
    return;
  }
  console.log('Conexão com MySQL estabelecida com sucesso!');
});

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

app.post('/api/login', (req, res) => {

  const { email, senha } = req.body;

  if (!email || !senha) {
    // ⭐️ 2. Mensagem mais clara para o console em caso de erro 400
    console.log('Diagnóstico: Faltando Email ou Senha (Erro 400).');
    return res.status(400).json({ success: false, message: 'Email e senha são obrigatórios.' });
  }

  console.log('Diagnóstico: Email e Senha recebidos corretamente. Tentando consultar DB...');

  // ⭐️ SQL: Adicionando 'nome' para o retorno de sucesso
  const sql = 'SELECT id_usuario, email, senha, nome FROM usuarios WHERE email = ?';

  // O callback deve ser 'async' para o futuro bcrypt.compare, mas o await só será usado dentro
  connection.query(sql, [email], async (err, results) => {
    if (err) {
      console.error('Erro fatal ao executar consulta SQL (Login - 500):', err);
      return res.status(500).json({ success: false, message: 'Erro interno do servidor.' });
    }

    if (results.length === 0) {
      return res.status(401).json({ success: false, message: 'Credenciais inválidas.' });
    }

    const user = results[0];
    const senhaBanco = user.senha;

    // 2. Lógica de Verificação de Senha 
    // Para usar bcrypt, você usaria: 
    // const isMatch = await bcrypt.compare(senha, senhaBanco); 
    const isMatch = (senha === senhaBanco); // SIMULAÇÃO (INSEGURO!)

    if (isMatch) {
      // Sucesso no login
      return res.json({
        success: true,
        message: 'Login realizado com sucesso!',
        // ⭐️ Retorno corrigido: Usando nome e email do banco
        user: { id: user.id_usuario, nome: user.nome, email: user.email }
      });
    } else {
      // Senha incorreta
      return res.status(401).json({ success: false, message: 'Credenciais inválidas.' });
    }
  });
});

app.post('/cadastro', (req, res) => {
  const { nome, usuario, email, senha, confirmacao_senha, telefone } = req.body;

  // Por favor, certifique-se de que está usando criptografia de senha (hash) aqui na vida real!
  const sql = 'INSERT INTO usuarios (nome, usuario, email, senha, confirmacao_senha, telefone) VALUES (?, ?, ?, ?, ?, ?)';


  // ⭐️ ATENÇÃO: Adicionei o argumento 'results' no callback da query
  connection.query(sql, [nome, usuario, email, senha, confirmacao_senha, telefone], (err, results) => {

    if (err) {
      // Logar o erro no servidor é uma boa prática
      console.error('Erro ao inserir novo usuário:', err);
      // O status 409 (Conflict) ou 400 (Bad Request) pode ser melhor que 401 (Unauthorized)
      return res.status(409).json({ success: false, message: 'Cadastro inválido. Usuário ou Email já existem.' });

    } else {
      // ⭐️ MUDANÇA AQUI: Usamos os dados que temos ou o ID de inserção (results.insertId)
      return res.status(201).json({ // Status 201 é o ideal para "Created"
        success: true,
        message: 'Cadastro realizado com sucesso!',
        // Retorna apenas as informações necessárias, usando o ID gerado pelo DB
        user: { id: results.insertId, login: usuario, email: email }
      });
    }
  });
});

app.post('/addTarefa', (req, res) => {

  const { titulo, prioridade, data_inicio, data_fim, descricao, andamento } = req.body;

  const sql = 'INSERT INTO tarefas (titulo, prioridade, data_inicio, data_fim, descricao, andamento) VALUES (?, ?, ?, ?, ?, ?)';

  connection.query(sql, [titulo, prioridade, data_inicio, data_fim, descricao, andamento], (err) => {

    if (err) {

      console.error('Erro ao adicionar tarefa:', err.message);

      return res.send();

    }

    res.send('http://localhost:${PORT}/tarefas');
  });

});

app.listen(PORT, () => {
  console.log(`Servidor rodando em http://localhost:${PORT}/cadastro`);
});

app.listen(PORT, () => {
  console.log(`Servidor rodando em http://localhost:${PORT}/landingpage`);
});

app.listen(PORT, () => {
  console.log(`Servidor rodando em http://localhost:${PORT}/tarefas`);
});
app.listen(PORT, () => {
  console.log(`Página de foco em http://localhost:${PORT}/foco`);
});
app.listen(PORT, () => {
  console.log(`Página apps de distração em http://localhost:${PORT}/apps`);
});
app.listen(PORT, () => {
  console.log(`Página de tarefas em http://localhost:${PORT}/addTarefas`);
});
app.listen(PORT, () => {
  console.log(`Página de adicionar tarefas em http://localhost:${PORT}/attTarefas`);
});
app.listen(PORT, () => {
  console.log(`Página de ranking em http://localhost:${PORT}/ranking`);
});