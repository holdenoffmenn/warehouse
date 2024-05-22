import 'package:flutter/material.dart';
import 'dart:convert';
import 'websocket_service.dart';
import 'leitura_page.dart';

class ItensPage extends StatefulWidget {
  final String idSolicitacao;
  final WebSocketService webSocketService;

  ItensPage({required this.idSolicitacao, required this.webSocketService});

  @override
  _ItensPageState createState() => _ItensPageState();
}

class _ItensPageState extends State<ItensPage> with RouteAware {
  late WebSocketService _localWebSocketService;
  List<dynamic> _itens = [];
  dynamic _selectedItem; // Variável para armazenar o item selecionado

  @override
  void initState() {
    super.initState();
    _localWebSocketService = widget.webSocketService;
    _loadData();
    _localWebSocketService.messages.listen((data) {
      if (data['action'] == 'itensData') {
        setState(() {
          _itens = data['data'];
        });
      } else if (data['action'] == 'updateLampadaSuccess') {
        _showLoadingDialog();
        Future.delayed(Duration(seconds: 3)).then((_) {
          Navigator.pop(context); // Fechar o diálogo de carregamento
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LeituraPage(
                idItem: _selectedItem['id_item'],
                quantidadeSolicitada: _selectedItem['quantidade_solicitada'],
                quantidadeColetada: _selectedItem['quantidade_coletada'],
                webSocketService: _localWebSocketService,
                idSolicitacao: widget.idSolicitacao,
              ),
            ),
          ).then((_) => _loadData());
        });
      }
    });
  }

  void _loadData() {
    _localWebSocketService.sendMessage(json.encode({'action': 'getItens', 'id_solicitacao': widget.idSolicitacao}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final observer = ModalRoute.of(context)?.settings.arguments as RouteObserver<ModalRoute<void>>?;
    if (observer != null) {
      observer.subscribe(this, ModalRoute.of(context)!);
    }
  }

  @override
  void didPopNext() {
    _loadData();
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

  void _showActionDialog(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Escolha uma ação'),
          content: Text('Você deseja iluminar ou cancelar?'),
          actions: <Widget>[
            TextButton(
              child: Text('Iluminar'),
              onPressed: () {
                // Armazenar o item selecionado
                _selectedItem = item;

                // Atualizar a coluna lampada para 'LIGAR'
                _localWebSocketService.sendMessage(json.encode({
                  'action': 'updateLampadaStatus',
                  'id_item': item['id_item'],
                  'lampada': 'LIGAR'
                }));


                // Fechar o diálogo
                Navigator.of(context).pop();


                // Mostrar animação de carregamento
                _showLoadingDialog();



                // Fechar o diálogo de ação
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Aguarde...'),
              ],
            ),
          ),
        );
      },
    );
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
            return GestureDetector(
              onTap: item['status_item'] == 'FECHADO'
                  ? null
                  : () {
                _showActionDialog(context, item);
              },
              child: Card(
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
                  trailing: item['status_item'] == 'FECHADO'
                      ? Icon(Icons.lock, color: Colors.red)
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
