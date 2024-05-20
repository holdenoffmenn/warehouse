import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'websocket_service.dart';

class SolicitacoesPage extends StatefulWidget {
  @override
  _SolicitacoesPageState createState() => _SolicitacoesPageState();
}

class _SolicitacoesPageState extends State<SolicitacoesPage> {
  late WebSocketService _webSocketService;
  List<dynamic> _solicitacoes = [];

  @override
  void initState() {
    super.initState();
    _webSocketService = WebSocketService('ws://10.0.2.2:8080');
    _webSocketService.messages.listen((data) {
      if (data['action'] == 'solicitacoesData') {
        setState(() {
          _solicitacoes = data['data'];
        });
      }
    });

    _webSocketService.sendMessage(json.encode({'action': 'getSolicitacoes'}));
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitações'),
      ),
      body: ListView.builder(
        itemCount: _solicitacoes.length,
        itemBuilder: (context, index) {
          final solicitacao = _solicitacoes[index];
          final DateTime horaSolicitacao = DateTime.parse(solicitacao['hora_solicitacao']);
          final String horaFormatada = DateFormat('HH:mm').format(horaSolicitacao);
          final bool isToday = DateFormat('yyyy-MM-dd').format(horaSolicitacao) == DateFormat('yyyy-MM-dd').format(DateTime.now());

          IconData getStatusIcon(String status) {
            switch (status) {
              case 'ABERTO':
                return Icons.radio_button_unchecked;
              case 'FECHADO':
                return Icons.check_circle;
              case 'FAZENDO':
                return Icons.hourglass_bottom;
              default:
                return Icons.help;
            }
          }

          return Card(
            child: ListTile(
              leading: Icon(getStatusIcon(solicitacao['status'])),
              title: Text(
                solicitacao['linha_solicitante'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: ${solicitacao['id_solicitacao']}'),
                  Text('Hora: $horaFormatada'),
                  if (isToday)
                    Text('Hoje', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  if (!isToday)
                    Text('Antiga', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
