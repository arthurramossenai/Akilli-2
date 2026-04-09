const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

router.post('/api/login', authController.login);
router.post('/cadastro', authController.cadastro);

module.exports = router;
