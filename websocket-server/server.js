const WebSocket = require('ws');
const mysql = require('mysql');
const mqtt = require('mqtt');

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

// Configurar cliente MQTT
const mqttClient = mqtt.connect('mqtt://broker.hivemq.com'); // Use o URL do seu broker MQTT

mqttClient.on('connect', () => {
  console.log('Conectado ao broker MQTT');
});

// Configurar servidor WebSocket
const wss = new WebSocket.Server({ port: 8080 });

let lastHash = '';
let previousLampadaStatus = {}; // Objeto para rastrear o estado anterior dos itens

function hashSolicitacoes(solicitacoes) {
  return require('crypto').createHash('sha256').update(JSON.stringify(solicitacoes)).digest('hex');
}

function checkForUpdates() {
  db.query('SELECT * FROM solicitacoes', (err, results) => {
    if (err) {
      console.error('Erro ao consultar o banco de dados:', err);
    } else {
      const currentHash = hashSolicitacoes(results);
      if (currentHash !== lastHash) {
        lastHash = currentHash;
        wss.clients.forEach(client => {
          if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify({ action: 'solicitacoesData', data: results }));
          }
        });
      }
    }
  });
}

function checkLampadaStatus() {
  db.query('SELECT id_item, endereco, lampada FROM itens', (err, results) => {
    if (err) {
      console.error('Erro ao consultar o banco de dados:', err);
    } else {
      results.forEach(item => {
        const { id_item, endereco, lampada } = item;
        const previousStatus = previousLampadaStatus[id_item];

        if (lampada !== previousStatus) {
          const message = {
            action: lampada,
            endereco: endereco
          };

          mqttClient.publish('lampada/status/holden', JSON.stringify(message), (err) => {
            if (err) {
              console.error('Erro ao publicar mensagem MQTT:', err);
            } else {
              console.log('Mensagem MQTT publicada:', message);
              // Atualizar o estado anterior
              previousLampadaStatus[id_item] = lampada;
            }
          });
        }
      });
    }
  });
}

function checkAndUpdateSolicitacaoStatus(idSolicitacao) {
  db.query('SELECT status_item FROM itens WHERE solicitacao = ?', [idSolicitacao], (err, results) => {
    if (err) {
      console.error('Erro ao consultar itens:', err);
    } else {
      const allClosed = results.every(item => item.status_item === 'FECHADO');
      if (allClosed) {
        db.query('UPDATE solicitacoes SET status = ? WHERE id_solicitacao = ?', ['FECHADO', idSolicitacao], (err) => {
          if (err) {
            console.error('Erro ao atualizar status da solicitação:', err);
          } else {
            checkForUpdates();
          }
        });
      }
    }
  });
}

// Verifica atualizações a cada 5 segundos
setInterval(checkForUpdates, 500);
setInterval(checkLampadaStatus, 500);

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
    } else if (data.action === 'getItens') {
      // Consulta ao banco de dados para obter os itens da solicitação
      db.query('SELECT * FROM itens WHERE solicitacao = ?', [data.id_solicitacao], (err, results) => {
        if (err) {
          ws.send(JSON.stringify({ error: 'Erro ao consultar o banco de dados' }));
        } else {
          ws.send(JSON.stringify({ action: 'itensData', data: results }));
        }
      });
    } else if (data.action === 'updateQuantidadeColetada') {
      db.query('UPDATE itens SET quantidade_coletada = ? WHERE id_item = ?', [data.quantidade_coletada, data.id_item], (err, results) => {
        if (err) {
          ws.send(JSON.stringify({ error: 'Erro ao atualizar a quantidade coletada' }));
        } else {
          checkAndUpdateSolicitacaoStatus(data.id_solicitacao);
          ws.send(JSON.stringify({ action: 'updateSuccess' }));
        }
      });
    } else if (data.action === 'updateItemStatus') {
      db.query('UPDATE itens SET status_item = ?, quantidade_coletada = ?, lampada = ? WHERE id_item = ?', [data.status_item, data.quantidade_coletada, data.lampada, data.id_item], (err, results) => {
        if (err) {
          ws.send(JSON.stringify({ error: 'Erro ao atualizar o status do item' }));
        } else {
          checkAndUpdateSolicitacaoStatus(data.id_solicitacao);
          ws.send(JSON.stringify({ action: 'updateSuccess' }));
        }
      });
    } else if (data.action === 'updateLampadaStatus') {
      db.query('UPDATE itens SET lampada = ? WHERE id_item = ?', [data.lampada, data.id_item], (err, results) => {
        if (err) {
          ws.send(JSON.stringify({ error: 'Erro ao atualizar o status da lâmpada' }));
        } else {
          ws.send(JSON.stringify({ action: 'updateLampadaSuccess' })); // Enviar uma resposta de sucesso
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
