import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ntpviewer/providers/ntp_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => NTPProvider(),
      child: const Main(),
    ),
  );
}

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      darkTheme: FluentThemeData.dark(),
      home: const Acrylic(
        child: Column(
          children: [
            AddServerField(),
            Expanded(child: NTPList()),
          ],
        ),
      ),
    );
  }
}

class AddServerField extends StatefulWidget {
  const AddServerField({super.key});

  @override
  State<AddServerField> createState() => _AddServerFieldState();
}

class _AddServerFieldState extends State<AddServerField> {
  late TextEditingController _hostFieldController;

  @override
  void initState() {
    super.initState();
    _hostFieldController = TextEditingController();
  }

  @override
  void dispose() {
    _hostFieldController.dispose();
    super.dispose();
  }

  void addHost() {
    if (_hostFieldController.text.isEmpty) return;
    context.read<NTPProvider>().addNTPServer(_hostFieldController.text);
    _hostFieldController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextBox(
              controller: _hostFieldController,
              placeholder: 'Add a NTP server',
              onEditingComplete: addHost,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: FilledButton(
            onPressed: addHost,
            child: const Icon(FluentIcons.add),
          ),
        ),
      ],
    );
  }
}

class NTPList extends StatefulWidget {
  const NTPList({super.key});

  @override
  State<NTPList> createState() => _NTPListState();
}

class _NTPListState extends State<NTPList> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      context.read<NTPProvider>().refreshServers();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    final ntpData = context.watch<NTPProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Button(
                  onPressed: () {
                    for (final index in _selected) {
                      final server =
                          ntpData.ntpServers.entries.elementAt(index);
                      ntpData.removeNTPServer(server.key);
                    }
                    _selected.clear();
                  },
                  child: Icon(
                    FluentIcons.delete,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        const Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              SizedBox(width: 12),
              Spacer(flex: 4),
              Expanded(child: TimeDisplay(offset: 0)),
              Spacer(),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: ntpData.ntpServers.length,
            itemBuilder: (context, index) {
              final server = ntpData.ntpServers.entries.elementAt(index);

              final serverName = server.key;
              final (ip, offset) = server.value;

              return ListTile.selectable(
                selectionMode: ListTileSelectionMode.multiple,
                title: Row(
                  children: [
                    Expanded(flex: 2, child: Text(serverName)),
                    Expanded(flex: 2, child: Text(ip.address)),
                    Expanded(child: TimeDisplay(offset: offset)),
                    Expanded(
                      child: Text(
                        '${(offset ?? 0) > 0 ? '+' : ''}${offset?.toString() ?? '- '} ms',
                      ),
                    ),
                  ],
                ),
                selected: _selected.contains(index),
                onSelectionChange: (selected) {
                  if (selected) {
                    _selected.add(index);
                  } else {
                    _selected.remove(index);
                  }
                  setState(() {});
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class TimeDisplay extends StatefulWidget {
  const TimeDisplay({required this.offset, super.key});
  final int? offset;

  @override
  State<TimeDisplay> createState() => _TimeDisplayState();
}

class _TimeDisplayState extends State<TimeDisplay> {
  late Ticker ticker;
  DateTime? time;

  @override
  void initState() {
    super.initState();
    ticker = Ticker((_) {
      time = DateTime.now().add(Duration(milliseconds: widget.offset ?? 0));
      setState(() {});
    });
    ticker.start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var timeString = '-';
    if (time != null) {
      timeString = '${time!.hour.toString().padLeft(2, '0')}:'
          '${time!.minute.toString().padLeft(2, '0')}:'
          '${time!.second.toString().padLeft(2, '0')}'
          '.${time!.millisecond.toString().padLeft(3, '0')}';
    }
    return Text(
      timeString,
      style: GoogleFonts.firaMono(
        fontWeight: FontWeight.bold,
        fontSize: 17,
        color: time != null
            ? (Color.lerp(
                Colors.white,
                Colors.blue,
                (time!.millisecond / 1000).clamp(0, 1),
              ))
            : null,
      ),
    );
  }
}
