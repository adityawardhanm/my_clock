import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class FontManager {
  static const _userFontsKey = 'user_fonts';
  
  static const List<String> defaultFonts = [
    'Aktura',
    'Array',
    'Gambarino',
    'Melodrama',
    'Outfit',
    'Stardom',
  ];

  List<String> _userFonts = [];
  
  List<String> get allFonts => [...defaultFonts, ..._userFonts];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _userFonts = prefs.getStringList(_userFontsKey) ?? [];
    
    for (final fontName in _userFonts) {
      await _loadUserFont(fontName);
    }
  }

  Future<String?> addUserFont() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
    );

    if (result == null || result.files.isEmpty) return null;

    final file = File(result.files.single.path!);
    final filename = result.files.single.name;
    
    final fontFamily = filename.split('-').first.split('.').first;

    final appDir = await getApplicationDocumentsDirectory();
    final fontsDir = Directory('${appDir.path}/user_fonts');
    if (!await fontsDir.exists()) {
      await fontsDir.create(recursive: true);
    }
    
    final destPath = '${fontsDir.path}/$filename';
    await file.copy(destPath);

    await _loadUserFont(fontFamily, destPath);

    if (!_userFonts.contains(fontFamily)) {
      _userFonts.add(fontFamily);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_userFontsKey, _userFonts);
    }

    return fontFamily;
  }

  Future<void> _loadUserFont(String fontFamily, [String? path]) async {
    try {
      final String fontPath;
      if (path != null) {
        fontPath = path;
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final fontsDir = Directory('${appDir.path}/user_fonts');
        final files = await fontsDir.list().toList();
        final fontFile = files.firstWhere(
          (f) => f.path.contains(fontFamily),
          orElse: () => throw Exception('Font file not found'),
        );
        fontPath = fontFile.path;
      }

      final fontLoader = FontLoader(fontFamily);
      final fontData = File(fontPath).readAsBytes();
      fontLoader.addFont(fontData.then((data) => ByteData.view(data.buffer)));
      await fontLoader.load();
    } catch (e) {
      //print('Failed to load font $fontFamily: $e');
    }
  }
}