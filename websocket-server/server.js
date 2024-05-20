const WebSocket = require('ws');
const mysql = require('mysql');

// Configurar conexão com o banco de dados MySQL
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'smart',
  database: 'warehouse'
});

db.connect(err => {
  if (err) {
    console.error('Erro ao conectar ao banco de dados:', err);
    process.exit(1);
  } else {
    console.log('Conectado ao banco de dados MySQL');
  }
});

// Configurar servidor WebSocket
const wss = new WebSocket.Server({ port: 8080 });

wss.on('connection', ws => {
  console.log('Cliente conectado');

  // Enviar mensagem de boas-vindas
  ws.send(JSON.stringify({ message: 'Bem-vindo ao WebSocket Server' }));

  // Receber mensagens dos clientes
  ws.on('message', message => {
    console.log('Recebido:', message);
    const data = JSON.parse(message);

    if (data.action === 'getSolicitacoes') {
      // Consulta ao banco de dados
      db.query('SELECT * FROM solicitacoes', (err, results) => {
        if (err) {
          ws.send(JSON.stringify({ error: 'Erro ao consultar o banco de dados' }));
        } else {
          ws.send(JSON.stringify({ action: 'solicitacoesData', data: results }));
        }
      });
    }
  });

  // Gerenciar o fechamento da conexão
  ws.on('close', () => {
    console.log('Cliente desconectado');
  });
});

console.log('Servidor WebSocket rodando na porta 8080');