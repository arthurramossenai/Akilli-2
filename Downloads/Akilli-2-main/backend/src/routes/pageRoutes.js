const express = require('express');
const router = express.Router();
const path = require('path');

const publicPath = path.join(__dirname, '..', '..', 'public');

router.get('/cadastro', (req, res) => res.sendFile(path.join(publicPath, 'cadastro.html')));
router.get('/landingpage', (req, res) => res.sendFile(path.join(publicPath, 'landingpage.html')));
router.get('/tarefas', (req, res) => res.sendFile(path.join(publicPath, 'tarefas.html')));
router.get('/foco', (req, res) => res.sendFile(path.join(publicPath, 'foco.html')));
router.get('/apps', (req, res) => res.sendFile(path.join(publicPath, 'apps.html')));
router.get('/addTarefas', (req, res) => res.sendFile(path.join(publicPath, 'addTarefas.html')));
router.get('/attTarefas', (req, res) => res.sendFile(path.join(publicPath, 'attTarefas.html')));
router.get('/ranking', (req, res) => res.sendFile(path.join(publicPath, 'ranking.html')));

module.exports = router;
