import 'package:flutter/material.dart';

import '../../shared/screen_header.dart';

/// Segnaposto della tab Chat (la schermata vera arriva con la Fase 9).
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: ScreenHeader(title: 'Chat'),
        ),
      ),
    );
  }
}
