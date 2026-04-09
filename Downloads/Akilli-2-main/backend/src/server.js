const express = require('express');
const path = require('path');
const fs = require('fs');
const os = require('os');
const app = express();

const authRoutes = require('./routes/authRoutes');
const tarefasRoutes = require('./routes/tarefasRoutes');
const pageRoutes = require('./routes/pageRoutes');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
const PORT = process.env.PORT || 3000;

app.use(express.static(path.join(__dirname, '..', 'public')));

// Rotas da API e Navegação
app.use(authRoutes);
app.use(tarefasRoutes);
app.use(pageRoutes);

// Helper para IP Local
function getLocalIp() {
  const interfaces = os.networkInterfaces();
  let bestIp = '10.0.2.2';

  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        if (name.toLowerCase().includes('wi-fi') || name.toLowerCase().includes('wireless')) {
          return iface.address;
        }
        if (!name.toLowerCase().includes('wsl') && !name.toLowerCase().includes('vethernet')) {
          bestIp = iface.address;
        }
      }
    }
  }
  return bestIp;
}

const localIp = getLocalIp();

app.listen(PORT, '0.0.0.0', () => {
  console.log(`==========================================`);
  console.log(`SERVIDOR RODANDO (MODO MVC + SUPABASE)`);
  console.log(`IP LOCAL: http://${localIp}:${PORT}`);
  console.log(`Acesse por: http://localhost:${PORT}`);
  console.log(`==========================================`);

  try {
    const configContent = `// ARQUIVO GERADO AUTOMATICAMENTE PELO BACKEND (server.js)\n// Nao edite manualmente. Este arquivo é atualizado ao rodar "node server.js".\nclass ApiConfig {\n  static const String baseUrl = "http://${localIp}:${PORT}";\n}\n`;
    const configPath = path.join(__dirname, '..', '..', 'akilli_app', 'lib', 'config.dart');
    if (fs.existsSync(path.dirname(configPath))) {
      // fs.writeFileSync(configPath, configContent); // DESATIVADO PARA NÃO SOBRESCREVER O IP DO ADB/WIFI
      console.log(`[Config Flutter] A escrita automática em config.dart desativada por segurança.`);
    } else {
      console.log(`[Config Flutter] A pasta akilli_app/lib não foi encontrada. Ignorando.`);
    }
  } catch (err) {
    console.log(`[Config Flutter] Erro ao salvar config.dart:`, err.message);
  }
});
