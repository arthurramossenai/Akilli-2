const supabase = require('../config/supabase');

exports.addTarefa = async (req, res) => {
  const { titulo, prioridade, data_inicio, data_fim, descricao, andamento } = req.body;

  try {
    const { error } = await supabase
      .from('tarefas')
      .insert([
        { titulo, prioridade, data_inicio, data_fim, descricao, andamento }
      ]);

    if (error) throw error;

    res.send(`http://${req.get('host')}/tarefas`);
  } catch (err) {
    console.error('Erro no banco de dados ao adicionar tarefa:', err);
    res.status(500).send('Erro interno no banco de dados.');
  }
};

exports.getTarefas = async (req, res) => {
  try {
    const { data: tarefas, error } = await supabase
      .from('tarefas')
      .select('*');

    if (error) throw error;

    res.json(tarefas);
  } catch (err) {
    console.error('Erro no banco de dados ao buscar tarefas:', err);
    res.status(500).json([]);
  }
};
