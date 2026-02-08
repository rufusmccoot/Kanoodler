import 'dart:math';
import 'package:aknoodle/noodles/piece_placements.dart';

class SolveResult {
  final bool ok;
  final List<Placement> placements;
  const SolveResult(this.ok, this.placements);
}

SolveResult solveExactCoverByCells({
  required List<String> pieceIds,
  required Map<int, List<Placement>> placementsCoveringBit,
}) {
  final rng = Random();
  final remaining = <String>{...pieceIds};
  final chosen = <Placement>[];
  var occupied = 0;

  int? pickNextUncoveredBit() {
    // pick the first uncovered bit (0..54)
    for (var bit = 0; bit < 55; bit++) {
      if (((occupied >> bit) & 1) == 0) return bit;
    }
    return null;
  }

  bool dfs() {
    if (remaining.isEmpty) return true;

    final bit = pickNextUncoveredBit();
    if (bit == null) return true; // board full

    final options = placementsCoveringBit[bit];
    if (options == null || options.isEmpty) return false;
    final shuffled = List<Placement>.from(options)..shuffle(rng);

    // Try only placements that:
    // 1) belong to a remaining piece
    // 2) don't overlap occupied
    for (final p in shuffled) {
      if (!remaining.contains(p.pieceId)) continue;
      if ((occupied & p.mask) != 0) continue;

      remaining.remove(p.pieceId);
      occupied |= p.mask;
      chosen.add(p);

      if (dfs()) return true;

      chosen.removeLast();
      occupied ^= p.mask;
      remaining.add(p.pieceId);
    }

    return false;
  }

  final ok = dfs();
  return SolveResult(ok, ok ? List<Placement>.from(chosen) : const []);
}
