import 'package:flutter/material.dart';
import 'package:aknoodle/noodles/piece_definitions.dart';
import 'package:aknoodle/noodles/piece_transformations.dart';
import 'package:aknoodle/noodles/piece_placements.dart';
import 'package:aknoodle/solver.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanoodler',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyBoardScreen(title: 'Kanoodler'),
    );
  }
}

class MyBoardScreen extends StatefulWidget {
  const MyBoardScreen({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyBoardScreen> createState() => _MyBoardScreenState();
}

class _MyBoardScreenState extends State<MyBoardScreen> {
  // 55 cells (11*5). null = empty.
  late List<Color?> boardColors;

  Map<int, List<Placement>> placementsCoveringBit = {};
  Map<String, List<Placement>> placementsByPieceId = {}; // currently unused
  Map<String, Color> colorByPieceId = {};

  int hideN = 5;              // difficulty: how many pieces to hide

  List<Placement> currentSolution = [];
  Set<String> currentHiddenIds = {};

  // Is board blank? Helps show Are You Sure? alert only if board isn't blank
  bool get isBoardNotBlank => boardColors.any((c) => c != null);

  Future<void> showDifficultyModal() async {
    var temp = hideN;

    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: false,
      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Difficulty',
                        style: TextStyle(color: Colors.white, fontSize: 32),
                      ),
                      const Spacer(),
                      Text(
                        '$temp hidden',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 170, 170, 170),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: temp.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$temp',
                    onChanged: (v) => setModalState(() => temp = v.round()),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(temp),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (picked == null) return;

    setState(() => hideN = picked);
    await newPuzzleWithConfirm(() => newPuzzleAtDifficulty(hideN));
  }


  Future<void> newPuzzleWithConfirm(VoidCallback action) async {
    if (!isBoardNotBlank) {
      action();
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start a new puzzle?'),
        content: const Text('This will clear the current board.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (ok == true) action();
  }

  Future<void> revealWithConfirm() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reveal solution?'),
        content: const Text('This will show the full solution.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reveal'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    if (currentSolution.isEmpty) return;

    paintSolution(currentSolution);
  }

  @override
  void initState() {
    super.initState();

    final totalCells = pieceDefs.fold<int>(0, (sum, p) => sum + p.cells.length);
    debugPrint('Total piece cells = $totalCells (should be 55)');

    boardColors = List<Color?>.filled(55, null);

    final allPlacements = <Placement>[];
    colorByPieceId = {for (final p in pieceDefs) p.id: p.color};

    for (final piece in pieceDefs) {
      final variants = uniqueVariants(piece.cells, includeMirror: true);
      allPlacements.addAll(
        generatePlacementsForPiece(piece: piece, variants: variants),
      );
    }

    placementsByPieceId = buildPlacementsByPieceId(allPlacements);
    placementsCoveringBit = buildPlacementsCoveringBit(allPlacements);
  }

  void newPuzzleAtDifficulty(int hidePieces) {
    final ids = pieceDefs.map((p) => p.id).toList();

    final result = solveExactCoverByCells(
      pieceIds: ids,
      placementsCoveringBit: placementsCoveringBit,
    );
    if (!result.ok) return;

    currentSolution = result.placements;

    final pieceAtBit = buildPieceAtBit(currentSolution);
    currentHiddenIds =
        pickPiecesToHideFromRight(pieceAtBit: pieceAtBit, n: hidePieces);

    final visible =
        currentSolution.where((p) => !currentHiddenIds.contains(p.pieceId)).toList();

    paintSolution(visible);
  }

  void clearBoard() {
    setState(() {
      boardColors = List<Color?>.filled(55, null);
    });
  }

  void paintMask(int mask, Color color) {
    setState(() {
      for (var bit = 0; bit < 55; bit++) {
        final isSet = ((mask >> bit) & 1) == 1;
        if (isSet) boardColors[bit] = color;
      }
    });
  }

  void paintSolution(List<Placement> solution) {
    setState(() {
      boardColors = List<Color?>.filled(55, null);

      for (final pl in solution) {
        final color = colorByPieceId[pl.pieceId] ?? Colors.white;
        for (var bit = 0; bit < 55; bit++) {
          if (((pl.mask >> bit) & 1) == 1) {
            boardColors[bit] = color;
          }
        }
      }
    });
  }

  List<String?> buildPieceAtBit(List<Placement> solution) {
    final pieceAtBit = List<String?>.filled(55, null);

    for (final pl in solution) {
      for (var bit = 0; bit < 55; bit++) {
        if (((pl.mask >> bit) & 1) == 1) {
          pieceAtBit[bit] = pl.pieceId;
        }
      }
    }

    return pieceAtBit;
  }

  Widget diffButton(String label, int hideN) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: 88,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => newPuzzleWithConfirm(() => newPuzzleAtDifficulty(hideN)),
          icon: const Icon(Icons.refresh),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Set<String> pickPiecesToHideFromRight({
    required List<String?> pieceAtBit,
    required int n,
  }) {
    final hidden = <String>{};

    for (var col = 11; col >= 1; col--) {
      for (var row = 1; row <= 5; row++) { // row=1 is bottom in your numbering
        final pos1 = (row - 1) * 11 + col; // 1..55; row 1 => 1..11 (bottom)
        final bit = pos1 - 1;              // 0..54

        final pid = pieceAtBit[bit];
        if (pid == null) continue;

        hidden.add(pid);                   // set ignores duplicates automatically
        if (hidden.length >= n) return hidden;
      }
    }

    return hidden;
  }

  void solveAndPaint() {
    debugPrint('SOLVE: start');

    final ids = pieceDefs.map((p) => p.id).toList();
    final result = solveExactCoverByCells(
      pieceIds: ids,
      placementsCoveringBit: placementsCoveringBit,
    );

    debugPrint('SOLVE: done ok=${result.ok} placements=${result.placements.length}');
    if (!result.ok) return;

    paintSolution(result.placements);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRect(
              child: Image.asset(
                'assets/icon_small.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 64),
            Text(widget.title),
            const SizedBox(width: 64),
            ClipRect(
              child: Image.asset(
                'assets/icon_small.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
        titleTextStyle: const TextStyle(
          color: Color.fromARGB(255, 146, 146, 146),
          fontSize: 24,
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 22, 22, 22),
      body: SafeArea(
        top: true,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Column(
                  children: [
                    const Spacer(),
                    const Text(
                      'New game',
                      style: TextStyle(
                        color: Color.fromARGB(255, 140, 140, 140),
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),

                    // NEW button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => newPuzzleWithConfirm(() => newPuzzleAtDifficulty(hideN)),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.center,
                        ),
                        child: const Icon(Icons.refresh, size: 18),
                      ),
                    ),


                    const SizedBox(height: 12),

                    const Text(
                      'Difficulty',
                      style: TextStyle(
                        color: Color.fromARGB(255, 140, 140, 140),
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),

                    // Difficulty button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => showDifficultyModal(),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.center,
                        ),
                        child: const Icon(Icons.tune, size: 18),
                      ),
                    ),

                    const Spacer(),

                    Text(
                      'Hiding $hideN/12 noodles',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromARGB(255, 140, 140, 140),
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),

                    // Reveal button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => revealWithConfirm(),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.center,
                        ),
                        child: const Icon(Icons.visibility, size: 18),
                      ),
                    ),


                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const columns = 11;
                    const rows = 5;
                    const spacing = 2.0;

                    final availableWidth =
                        constraints.maxWidth - (columns - 1) * spacing;
                    final availableHeight =
                        constraints.maxHeight - (rows - 1) * spacing;

                    final cellWidth = availableWidth / columns;
                    final cellHeight = availableHeight / rows;
                    final aspectRatio = cellWidth / cellHeight;

                    return GridView.count(
                      padding: EdgeInsets.zero,
                      crossAxisCount: columns,
                      childAspectRatio: aspectRatio,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(columns * rows, (index) {
                        final color = boardColors[index] ?? Colors.black;
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color.fromARGB(255, 100, 100, 100),
                            ),
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
