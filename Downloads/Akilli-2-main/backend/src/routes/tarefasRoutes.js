const express = require('express');
const router = express.Router();
const tarefasController = require('../controllers/tarefasController');

router.post('/addTarefa', tarefasController.addTarefa);
router.get('/api/tarefas', tarefasController.getTarefas);

module.exports = router;
