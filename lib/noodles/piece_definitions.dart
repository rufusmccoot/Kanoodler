// /lib/noodles/piece_definitions.dart

import 'dart:ui';

/// A cell inside a piece's *own* mini-grid (top-left is (0,0)).
typedef Cell = ({int r, int c});

class PieceDef {
  final String id;          // e.g. "L", "I4"
  final Color color;        // color of the piece
  final List<Cell> cells;   // filled squares in the smallest bounding box

  const PieceDef({required this.id, required this.color, required this.cells});
}

/// Define each physical piece ONCE, in a "canonical" orientation.
/// Rotations / mirrors / dedupe happen in piece_transformations.dart
/// 
const List<PieceDef> pieceDefs = [
  // L piece in a 3x3 mini-grid:
  // O..
  // O..
  // OOO
  PieceDef(
    id: 'G',
    color: Color.fromARGB(255, 111, 166, 255),
    cells: [
      (r: 0, c: 0),
      (r: 1, c: 0),
      (r: 2, c: 0),
      (r: 2, c: 1),
      (r: 2, c: 2),
    ],
  ),

// L piece in a 4x2 mini-grid:
  // O.
  // O.
  // O.
  // OO
  PieceDef(
    id: 'C',
    color: Color.fromARGB(255, 1, 47, 122),
    cells: [
      (r: 0, c: 0),
      (r: 1, c: 0),
      (r: 2, c: 0),
      (r: 3, c: 0),
      (r: 3, c: 1),
    ],
  ),

// L piece in a 3x2 mini-grid:
  // O.
  // O.
  // OO
  PieceDef(
    id: 'A',
    color: Color.fromARGB(255, 252, 145, 5),
    cells: [
      (r: 0, c: 0),
      (r: 1, c: 0),
      (r: 2, c: 0),
      (r: 2, c: 1),
    ],
  ),

// L piece in a 2x2 mini-grid:
  // O.
  // OO
  PieceDef(
    id: 'F',
    color: Color.fromARGB(255, 235, 219, 199),
    cells: [
      (r: 0, c: 0),
      (r: 1, c: 0),
      (r: 1, c: 1)
    ],
  ),

  // 1x4 "stick" in a 1x4 mini-grid:
  // OOOO
  PieceDef(
    id: 'J',
    color: Color.fromARGB(255, 88, 1, 122),
    cells: [
      (r: 0, c: 0),
      (r: 0, c: 1),
      (r: 0, c: 2),
      (r: 0, c: 3),
    ],
  ),

  // Green Z mini-grid:
  // O.
  // O.
  // OO
  // .O
  PieceDef(
    id: 'E',
    color: Color.fromARGB(255, 24, 100, 1),
    cells: [
      (r: 0, c: 0),
      (r: 1, c: 0),
      (r: 2, c: 0),
      (r: 2, c: 1),
      (r: 3, c: 1),
    ],
  ),

  // Red club mini-grid:
  // O.
  // OO
  // OO
  PieceDef(
    id: 'B',
    color: Color.fromARGB(255, 167, 0, 0),
    cells: [
      (r: 0, c: 0),
      (r: 1, c: 0),
      (r: 1, c: 1),
      (r: 2, c: 0),
      (r: 2, c: 1),
    ],
  ),

  // Plus mini-grid:
  // .O.
  // OOO
  // .O.
  PieceDef(
    id: 'L',
    color: Color.fromARGB(255, 149, 165, 144),
    cells: [
      (r: 0, c: 1),
      (r: 1, c: 0),
      (r: 1, c: 1),
      (r: 1, c: 2),
      (r: 2, c: 1),
    ],
  ),

  // Pink W mini-grid:
  // O..
  // OO.
  // .OO
  PieceDef(
    id: 'H',
    color: Color.fromARGB(255, 236, 65, 199),
    cells: [
      (r: 0, c: 0),
      (r: 1, c: 0),
      (r: 1, c: 1),
      (r: 2, c: 1),
      (r: 2, c: 2),
    ],
  ),

  // Yellow U mini-grid:
  // O.O
  // OOO
  PieceDef(
    id: 'I',
    color: Color.fromARGB(255, 226, 223, 27),
    cells: [
      (r: 0, c: 0),
      (r: 0, c: 2),
      (r: 1, c: 0),
      (r: 1, c: 1),
      (r: 1, c: 2),
    ],
  ),


  // Green square mini-grid:
  // OO
  // OO
  PieceDef(
    id: 'K',
    color: Color.fromARGB(255, 86, 204, 50),
    cells: [
      (r: 0, c: 0),
      (r: 0, c: 1),
      (r: 1, c: 0),
      (r: 1, c: 1),
    ],
  ),


  // Light pink gun mini-grid:
  // O.
  // OO
  // O.
  // O.
  PieceDef(
    id: 'D',
    color: Color.fromARGB(255, 240, 161, 223),
    cells: [
      (r: 0, c: 0),
      (r: 1, c: 0),
      (r: 1, c: 1),
      (r: 2, c: 0),
      (r: 3, c: 0),
    ],
  ),

];
