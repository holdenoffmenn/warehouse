import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'websocket_service.dart';
import 'dart:convert';

class LeituraPage extends StatefulWidget {
  final String idItem;
  final int quantidadeSolicitada;
  final int quantidadeColetada;
  final WebSocketService webSocketService;

  LeituraPage({
    required this.idItem,
    required this.quantidadeSolicitada,
    required this.quantidadeColetada,
    required this.webSocketService,
  });

  @override
  _LeituraPageState createState() => _LeituraPageState();
}

class _LeituraPageState extends State<LeituraPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
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
          widget.webSocketService.sendMessage(json.encode({
            'action': 'updateItemStatus',
            'id_item': widget.idItem,
            'status_item': 'FECHADO',
            'quantidade_coletada': quantidadeColetada
          }));
          Navigator.pop(context, 'Item coletado com sucesso!');
        } else {
          widget.webSocketService.sendMessage(json.encode({
            'action': 'updateQuantidadeColetada',
            'id_item': widget.idItem,
            'quantidade_coletada': quantidadeColetada
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
