import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:convert';
import 'websocket_service.dart';

class LeituraPage extends StatefulWidget {
  final String idItem;
  final int quantidadeSolicitada;
  final int quantidadeColetada;
  final WebSocketService webSocketService;
  final String idSolicitacao;

  LeituraPage({
    required this.idItem,
    required this.quantidadeSolicitada,
    required this.quantidadeColetada,
    required this.webSocketService,
    required this.idSolicitacao,
  });

  @override
  _LeituraPageState createState() => _LeituraPageState();
}

class _LeituraPageState extends State<LeituraPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  late int quantidadeColetada;

  @override
  void initState() {
    super.initState();
    quantidadeColetada = widget.quantidadeColetada;
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController qrController) {
    setState(() {
      controller = qrController;
    });
    controller!.scannedDataStream.listen((scanData) async {
      controller!.pauseCamera();
      final scannedId = scanData.code;

      if (scannedId == widget.idItem) {
        setState(() {
          quantidadeColetada++;
        });
        if (quantidadeColetada == widget.quantidadeSolicitada) {
          // Atualizar o status do item e definir lampada como 'DESLIGAR'
          widget.webSocketService.sendMessage(json.encode({
            'action': 'updateItemStatus',
            'id_item': widget.idItem,
            'status_item': 'FECHADO',
            'quantidade_coletada': quantidadeColetada,
            'id_solicitacao': widget.idSolicitacao,
            'lampada': 'DESLIGAR'
          }));
          Navigator.pop(context, 'Item coletado com sucesso!');
        } else {
          widget.webSocketService.sendMessage(json.encode({
            'action': 'updateQuantidadeColetada',
            'id_item': widget.idItem,
            'quantidade_coletada': quantidadeColetada,
            'id_solicitacao': widget.idSolicitacao,
          }));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item coletado')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item diferente')));
      }
      await Future.delayed(Duration(seconds: 2));
      controller!.resumeCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leitura do Item'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('ID Item: ${widget.idItem}'),
                  Text('Coletado $quantidadeColetada de ${widget.quantidadeSolicitada}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
