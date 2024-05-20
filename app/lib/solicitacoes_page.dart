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
  List<dynamic> _filteredSolicitacoes = [];
  String _searchQuery = '';
  String _selectedStatus = 'Todos';

  @override
  void initState() {
    super.initState();
    _webSocketService = WebSocketService('ws://10.0.2.2:8080');
    _webSocketService.messages.listen((data) {
      if (data['action'] == 'solicitacoesData') {
        setState(() {
          _solicitacoes = data['data'];
          _filteredSolicitacoes = _solicitacoes;
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

  void _filterSolicitacoes() {
    setState(() {
      _filteredSolicitacoes = _solicitacoes.where((solicitacao) {
        final matchesStatus = _selectedStatus == 'Todos' || solicitacao['status'] == _selectedStatus;
        final matchesQuery = solicitacao['linha_solicitante'].toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesStatus && matchesQuery;
      }).toList();
    });
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
        title: Text('Solicitações'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Pesquisar...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    onChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                        _filterSolicitacoes();
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: <String>['Todos', 'ABERTO', 'FECHADO', 'FAZENDO']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedStatus = newValue!;
                      _filterSolicitacoes();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: _filteredSolicitacoes.length,
                itemBuilder: (context, index) {
                  final solicitacao = _filteredSolicitacoes[index];
                  final DateTime horaSolicitacao = DateTime.parse(solicitacao['hora_solicitacao']);
                  final String horaFormatada = DateFormat('HH:mm').format(horaSolicitacao);
                  final bool isToday = DateFormat('yyyy-MM-dd').format(horaSolicitacao) ==
                      DateFormat('yyyy-MM-dd').format(DateTime.now());

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 5,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: getStatusColor(solicitacao['status']),
                        child: Icon(
                          getStatusIcon(solicitacao['status']),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        solicitacao['linha_solicitante'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ID: ${solicitacao['id_solicitacao']}'),
                              Text('Hora: $horaFormatada'),
                            ],
                          ),
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isToday ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isToday ? 'Hoje' : 'Antiga',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Icon(
                        getStatusIcon(solicitacao['status']),
                        color: getStatusColor(solicitacao['status']),
                        size: 30,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
