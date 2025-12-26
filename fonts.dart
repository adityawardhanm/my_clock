import 'dart:io';

void main() {
  final fontsDir = Directory('fonts');
  final fontFamilies = <String>{};
  
  for (final file in fontsDir.listSync()) {
    if (file.path.endsWith('.otf') || file.path.endsWith('.ttf')) {
      final filename = file.uri.pathSegments.last;
      final family = filename.split('-').first.split('.').first;
      fontFamilies.add(family);
    }
  }
  
  final output = '''
const List<String> availableFonts = [
${fontFamilies.map((f) => "  '$f',").join('\n')}
];
''';
  File('lib/font_list.dart').writeAsStringSync(output);
}