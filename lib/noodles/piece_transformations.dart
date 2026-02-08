// /lib/noodles/piece_transformations.dart

typedef Cell = ({int r, int c});

/// Rotate 90° clockwise around origin, then we'll normalize.
List<Cell> rotate90(List<Cell> cells) =>
    [for (final p in cells) (r: p.c, c: -p.r)];

/// Mirror horizontally (flip left-right), then we'll normalize.
List<Cell> mirrorX(List<Cell> cells) =>
    [for (final p in cells) (r: p.r, c: -p.c)];

/// Shift so min r/c becomes 0,0 and sort for stable equality.
List<Cell> normalize(List<Cell> cells) {
  var minR = cells.first.r, minC = cells.first.c;
  for (final p in cells) {
    if (p.r < minR) minR = p.r;
    if (p.c < minC) minC = p.c;
  }
  final norm = [
    for (final p in cells) (r: p.r - minR, c: p.c - minC),
  ];
  norm.sort((a, b) => a.r != b.r ? a.r - b.r : a.c - b.c);
  return norm;
}

String keyOf(List<Cell> cells) =>
    normalize(cells).map((p) => '${p.r},${p.c}').join(';');

/// Returns unique variants (rotations + optional mirror) for a piece.
List<List<Cell>> uniqueVariants(List<Cell> baseCells, {bool includeMirror = true}) {
  final seen = <String>{};
  final out = <List<Cell>>[];

  void add(List<Cell> cells) {
    final k = keyOf(cells);
    if (seen.add(k)) out.add(normalize(cells));
  }

  // Rotations of base
  var cur = baseCells;
  for (var i = 0; i < 4; i++) {
    add(cur);
    cur = rotate90(cur);
  }

  if (includeMirror) {
    // Rotations of mirrored base
    cur = mirrorX(baseCells);
    for (var i = 0; i < 4; i++) {
      add(cur);
      cur = rotate90(cur);
    }
  }

  return out;
}

