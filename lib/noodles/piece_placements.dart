// /lib/noodles/piece_placements.dart
//
// Turns a piece VARIANT (a list of mini-grid cells) into every legal placement
// on the 11x5 board, represented as a single 55-bit mask (stored in an int).

import 'piece_definitions.dart' show Cell, PieceDef;

const int boardWidth = 11;
const int boardHeight = 5;

/// 1-based board coords for readability (row 1..5, col 1..11).
class Placement {
  final String pieceId;     // 'A'..'L'
  final int variantIndex;   // 0..n-1
  final int row;            // 1-based
  final int col;            // 1-based
  final int mask;           // 55-bit occupancy mask

  const Placement({
    required this.pieceId,
    required this.variantIndex,
    required this.row,
    required this.col,
    required this.mask,
  });

  @override
  String toString() =>
      'Placement(piece=$pieceId v=$variantIndex at=($row,$col) mask=$mask)';
}

/// Our numbering:
/// Row 1:  1..11
/// Row 2: 12..22
/// ...
/// Row 5: 45..55
///
/// Internally we use 0-based bit positions 0..54 so we can do (1 << bit0).
int bitIndex0({required int row1, required int col1}) {
  final r0 = row1 - 1;
  final c0 = col1 - 1;
  return (r0 * boardWidth) + c0; // 0..54
}

/// Build a full-board mask for a variant placed with its mini-grid origin
/// anchored at (anchorRow1, anchorCol1) on the board (both 1-based).
int buildMaskForVariantAt({
  required List<Cell> variantCells, // normalized mini-grid cells
  required int anchorRow1,
  required int anchorCol1,
}) {
  var mask = 0;

  for (final p in variantCells) {
    final boardRow1 = anchorRow1 + p.r;
    final boardCol1 = anchorCol1 + p.c;

    final b0 = bitIndex0(row1: boardRow1, col1: boardCol1);
    mask |= (1 << b0);
  }

  return mask;
}

/// Compute bounding box size of a variant (mini-grid), assuming it is normalized.
({int h, int w}) variantSize(List<Cell> cells) {
  var maxR = 0, maxC = 0;
  for (final p in cells) {
    if (p.r > maxR) maxR = p.r;
    if (p.c > maxC) maxC = p.c;
  }
  return (h: maxR + 1, w: maxC + 1);
}

/// Generate all placements for ONE piece given its variants.
List<Placement> generatePlacementsForPiece({
  required PieceDef piece,
  required List<List<Cell>> variants, // output of your uniqueVariants(...)
}) {
  final out = <Placement>[];

  for (var v = 0; v < variants.length; v++) {
    final cells = variants[v];
    final sz = variantSize(cells);
    final h = sz.h;
    final w = sz.w;

    // anchors where the variant stays in-bounds
    final maxAnchorRow = boardHeight - h + 1;
    final maxAnchorCol = boardWidth - w + 1;

    for (var row1 = 1; row1 <= maxAnchorRow; row1++) {
      for (var col1 = 1; col1 <= maxAnchorCol; col1++) {
        final mask = buildMaskForVariantAt(
          variantCells: cells,
          anchorRow1: row1,
          anchorCol1: col1,
        );

        out.add(Placement(
          pieceId: piece.id,
          variantIndex: v,
          row: row1,
          col: col1,
          mask: mask,
        ));
      }
    }
  }

  return out;
}

// Helper to create placements for all pieces
Map<String, List<Placement>> buildPlacementsByPieceId(List<Placement> all) {
  final map = <String, List<Placement>>{};
  for (final p in all) {
    (map[p.pieceId] ??= <Placement>[]).add(p);
  }
  return map;
}

Map<int, List<Placement>> buildPlacementsCoveringBit(List<Placement> all) {
  final map = <int, List<Placement>>{};
  for (final p in all) {
    for (var bit = 0; bit < 55; bit++) {
      if (((p.mask >> bit) & 1) == 1) {
        (map[bit] ??= <Placement>[]).add(p);
      }
    }
  }
  return map;
}
