const mysql = require('mysql2');

const connection = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'mendesarmy1998*',
  database: 'akili'
});

connection.connect(err => {
  if (err) {
    console.error('Erro ao conectar no MySQL:', err.message);
    process.exit(1);
  }
  
  const sql = 'INSERT INTO usuarios (nome, usuario, email, senha, confirmacao_senha, telefone) VALUES (?, ?, ?, ?, ?, ?)';
  const values = ['Teste', 'teste', 'teste@gmail.com', '123456', '123456', '000000000'];

  connection.query(sql, values, (err, results) => {
    if (err) {
      if (err.code === 'ER_DUP_ENTRY') {
        console.log('Usuário teste@gmail.com já existe.');
      } else {
        console.error('Erro ao inserir usuário:', err.message);
      }
    } else {
      console.log('Usuário teste@gmail.com criado com sucesso!');
    }
    connection.end();
  });
});
