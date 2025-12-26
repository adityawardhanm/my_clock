// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'font_manager.dart';
import 'package:url_launcher/url_launcher.dart';


final FontManager fontManager = FontManager();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await fontManager.init();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ClockApp());
}

Future<void> _openBuyMeACoffee() async {
  final uri = Uri.parse('https://buymeacoffee.com/adityawardhanm');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class ClockApp extends StatelessWidget {
  const ClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme colorScheme;
        
        if (darkDynamic != null) {
          colorScheme = darkDynamic.harmonized();
        } else {
          colorScheme = ColorScheme.fromSeed(
            seedColor: Colors.white,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: colorScheme,
          ),
          home: const ClockScreen(),
        );
      },
    );
  }
}

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();
  bool _showControls = false;
  int _currentFontIndex = 0;

  List<String> get _fonts => fontManager.allFonts;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    
    if (_showControls) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showControls) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _cycleFont() {
    setState(() {
      _currentFontIndex = (_currentFontIndex + 1) % _fonts.length;
    });
  }

  Future<void> _addFont() async {
    final newFont = await fontManager.addUserFont();
    if (newFont != null) {
      setState(() {
        _currentFontIndex = _fonts.indexOf(newFont);
      });
    }
  }

  String _getDayAbbreviation(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            SizedBox.expand(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 300,
                            height: 0.9,
                            fontFamily: _fonts[_currentFontIndex],
                            color: colorScheme.primary,
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -20), 
                          child: Text(
                            '${_getDayAbbreviation(_now.weekday)} ${_now.day}',
                            style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.w400,
                              fontFamily: _fonts[_currentFontIndex],
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_showControls)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _cycleFont,
                      icon: const Icon(Icons.font_download),
                      label: Text(_fonts[_currentFontIndex]),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _addFont,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Font'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: colorScheme.primary,
                      ),
                    ),  
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _openBuyMeACoffee,
                      icon: const Icon(Icons.coffee),
                      label: const Text('Buy me a coffee'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: colorScheme.primary,
                      ),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}