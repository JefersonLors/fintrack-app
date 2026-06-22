import 'package:fin_track/application/ocr/normalized_ocr_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NormalizedOcrGeometry locates amount below section and blocks', () {
    final institution = _line(
      'Banco Exemplo',
      0,
      0,
      120,
      20,
      inInstitutionBlock: true,
    );
    final amount = _line('Valor', 0, 30, 60, 50);
    final abaixo = _line('R\$ 44,00', 0, 60, 80, 80);
    final target = _line('Destino', 0, 90, 80, 110);
    final label = _line('Nome', 0, 120, 60, 140);
    final name = _line('Loja Boa', 70, 120, 160, 140);
    final end = _line('Origem', 0, 150, 80, 170);
    final geometry = NormalizedOcrGeometry(
      lines: [institution, amount, abaixo, target, label, name, end],
      bands: [
        VisualOcrBand(lines: [institution]),
        VisualOcrBand(lines: [amount]),
        VisualOcrBand(lines: [abaixo]),
        VisualOcrBand(lines: [target]),
        VisualOcrBand(lines: [label, name]),
        VisualOcrBand(lines: [end]),
      ],
    );

    expect(
      geometry.nearbyValue(['banco'], ignoreInstitutionBlocks: true),
      isNull,
    );
    expect(geometry.nearbyValue(['valor']), 'R\$ 44,00');
    expect(
      geometry.valueInSection(
        start: ['destino'],
        valueLabels: ['name'],
        end: ['origem'],
      ),
      'Loja Boa',
    );
    expect(geometry.isEmpty, isFalse);
    expect(const NormalizedOcrGeometry(lines: [], bands: []).isEmpty, isTrue);
  });
}

VisualOcrLine _line(
  String text,
  double left,
  double top,
  double right,
  double bottom, {
  bool inInstitutionBlock = false,
}) {
  return VisualOcrLine(
    text: text,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    blockIndex: 0,
    lineIndex: 0,
    inInstitutionBlock: inInstitutionBlock,
  );
}
