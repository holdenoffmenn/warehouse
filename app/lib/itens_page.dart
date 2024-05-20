import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'websocket_service.dart';

class ItensPage extends StatefulWidget {
  final String idSolicitacao;
  final WebSocketService webSocketService;

  ItensPage({required this.idSolicitacao, required this.webSocketService});

  @override
  _ItensPageState createState() => _ItensPageState();
}

class _ItensPageState extends State<ItensPage> {
  late WebSocketService _localWebSocketService;
  List<dynamic> _itens = [];

  @override
  void initState() {
    super.initState();
    _localWebSocketService = widget.webSocketService.createNewInstance();
    _localWebSocketService.messages.listen((data) {
      if (data['action'] == 'itensData') {
        setState(() {
          _itens = data['data'];
        });
      }
    });

    _localWebSocketService.sendMessage(json.encode({'action': 'getItens', 'id_solicitacao': widget.idSolicitacao}));
  }

  @override
  void dispose() {
    _localWebSocketService.dispose();
    super.dispose();
  }

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

  Color getStatusColor(String status) {
    switch (status) {
      case 'ABERTO':
        return Colors.orange;
      case 'FECHADO':
        return Colors.green;
      case 'FAZENDO':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Itens da Solicitação ${widget.idSolicitacao}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: _itens.length,
          itemBuilder: (context, index) {
            final item = _itens[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 5,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: getStatusColor(item['status_item']),
                  child: Icon(
                    getStatusIcon(item['status_item']),
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  item['nome_item'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID Item: ${item['id_item']}'),
                    Text('Quantidade Solicitada: ${item['quantidade_solicitada']}'),
                    Text('Quantidade Coletada: ${item['quantidade_coletada']}'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
