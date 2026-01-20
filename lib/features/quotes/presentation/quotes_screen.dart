import 'package:flutter/material.dart';

class QuotesScreen extends StatelessWidget {
  const QuotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cotizaciones')),
      body: const Center(child: Text('Modulo de Cotizaciones')),
    );
  }
}
