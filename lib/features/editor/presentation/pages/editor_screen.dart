import 'package:flutter/material.dart';


import '../widgets/side_toolbar.dart';
import '../widgets/data_grid.dart';

class EditorScreen extends StatefulWidget {
  final String eventId;
  const EditorScreen({super.key, required this.eventId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  bool _isPanelOpen = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Editor de Participantes'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (!isMobile)
                IconButton(
                  icon: Transform.flip(
                    flipX: _isPanelOpen,
                    child: const Icon(Icons.menu_open),
                  ),
                  tooltip: _isPanelOpen ? 'Esconder Painel' : 'Mostrar Painel',
                  onPressed: () {
                    setState(() {
                      _isPanelOpen = !_isPanelOpen;
                    });
                  },
                ),
              if (isMobile)
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.build_circle_outlined),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                    tooltip: 'Ferramentas',
                  ),
                ),
              if (!isMobile)
                const SizedBox(width: 8),
            ],
          ),
          endDrawer: isMobile ? Drawer(child: SideToolbar(eventId: widget.eventId)) : null,
          body: Column(
            children: [
              const Divider(height: 1),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: DataGrid(eventId: widget.eventId),
                    ),
                    if (!isMobile && _isPanelOpen) ...[
                      const VerticalDivider(width: 1),
                      SideToolbar(eventId: widget.eventId),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
