import 'package:flutter/material.dart';
import 'login_page.dart'; // Certifique-se de importar a LoginPage
import 'solicitacoes_page.dart'; // Certifique-se de importar a SolicitacoesPage

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
      home: LoginPage(),
    );
  }
}