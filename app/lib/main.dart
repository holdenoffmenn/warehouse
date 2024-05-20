import 'package:flutter/material.dart';
import 'solicitacoes_page.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warehouse App',
      navigatorObservers: [routeObserver],
      home: SolicitacoesPage(),
    );
  }
}