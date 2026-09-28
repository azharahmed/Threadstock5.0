import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ZERO DUMMY DATA GUARD: lib/ contains 0 forbidden demo entities', () {
    const forbiddenPatterns = [
      'Alex Mercer',
      'Emma Carter',
      'Priya Nair',
      'Arun Kapoor',
      'Vikram Singh',
      'Aditya Roy',
      'Rahul Sharma',
      'Giovanni Rossi',
      'Biella',
      'Milano Tessuti',
      'Central Warehouse',
      'Delhi Flagship',
      'Indiranagar',
      'Oxford Linen Shirt',
      'Merino Wool Blazer',
      'Cashmere Sweater',
      'Raw Denim Jeans',
      'Gabardine Trench',
      'Silk Evening Dress',
      'PO-2024-',
      'TRF-2024-',
      'TS-10482',
      'TS-10492',
      'MWB-20188',
      'CS-50155',
      'RDJ-22322',
      'GTC-27193',
      'SED-1666',
      'alex_mercer.jpg',
      'priya_nair.jpg',
      'arun_kapoor.jpg',
      'emma_carter.jpg',
      'vikram_singh.jpg',
      'black_linen_shirt.jpg',
      'merino_wool_blazer.jpg',
      'oxford_linen_shirt.jpg',
      'raw_linen_fabric.jpg',
      'mulberry_silk_fabric.jpg',
      'silk_scarves.jpg',
    ];

    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist');

    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    final violations = <String>[];

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      for (final pattern in forbiddenPatterns) {
        if (content.contains(pattern)) {
          violations.add('${file.path}: contains "$pattern"');
        }
      }
      final lowerContent = content.toLowerCase();
      for (final pattern in forbiddenPatterns) {
        if (lowerContent.contains(pattern.toLowerCase())) {
          violations.add(
            '${file.path}: case-insensitive contains "${pattern.toLowerCase()}"',
          );
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Forbidden demo data found in production source files:\n${violations.join('\n')}',
    );
  });
}
