import 'package:flutter/material.dart';

enum MiningArtKind { book, grass, map, crown, pickaxe, gem, diamond }

/// Native pixel illustrations stay sharp at every device density.
class MiningArt extends StatelessWidget {
  const MiningArt(this.kind, {super.key, this.size = 52});
  final MiningArtKind kind;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _MiningArtPainter(kind)),
  );
}

class _MiningArtPainter extends CustomPainter {
  const _MiningArtPainter(this.kind);
  final MiningArtKind kind;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 28, size.height / 28);
    final paint = Paint()..isAntiAlias = false;
    void rect(double x, double y, double w, double h, int color) {
      paint.color = Color(color);
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);
    }

    void polygon(List<Offset> points, int color) {
      paint.color = Color(color);
      canvas.drawPath(Path()..addPolygon(points, true), paint);
    }

    rect(5, 24, 19, 2, 0x33000000);
    switch (kind) {
      case MiningArtKind.diamond:
        polygon(const [
          Offset(7, 2),
          Offset(21, 2),
          Offset(28, 9),
          Offset(15, 27),
          Offset(12, 27),
          Offset(0, 9),
        ], 0xFF006683);
        polygon(const [
          Offset(7, 4),
          Offset(20, 4),
          Offset(25, 9),
          Offset(14, 24),
          Offset(3, 9),
        ], 0xFF22E7FF);
        polygon(const [
          Offset(7, 4),
          Offset(12, 4),
          Offset(9, 9),
          Offset(3, 9),
        ], 0xFFF2FFFF);
        polygon(const [
          Offset(13, 4),
          Offset(18, 4),
          Offset(21, 9),
          Offset(10, 9),
        ], 0xFF8BFAFF);
        polygon(const [
          Offset(4, 10),
          Offset(10, 10),
          Offset(14, 23),
        ], 0xFFB6FFFF);
        polygon(const [
          Offset(11, 10),
          Offset(20, 10),
          Offset(14, 23),
        ], 0xFF2BE5FF);
        polygon(const [
          Offset(21, 10),
          Offset(25, 10),
          Offset(14, 23),
        ], 0xFF009BD9);
        rect(7, 2, 13, 1, 0xFFE8FFFF);
        rect(3, 8, 22, 1, 0xFFDDFFFF);
      case MiningArtKind.gem:
        polygon(const [
          Offset(10, 1),
          Offset(18, 1),
          Offset(18, 4),
          Offset(23, 7),
          Offset(26, 14),
          Offset(23, 23),
          Offset(17, 27),
          Offset(10, 27),
          Offset(4, 22),
          Offset(1, 14),
          Offset(5, 6),
          Offset(10, 4),
        ], 0xFF005B65);
        polygon(const [
          Offset(10, 3),
          Offset(17, 3),
          Offset(23, 10),
          Offset(24, 16),
          Offset(19, 24),
          Offset(11, 25),
          Offset(4, 18),
          Offset(4, 12),
        ], 0xFF00E6DA);
        polygon(const [
          Offset(11, 6),
          Offset(17, 7),
          Offset(19, 14),
          Offset(16, 22),
          Offset(10, 19),
          Offset(8, 12),
        ], 0xFF9AFFF0);
        rect(11, 2, 5, 3, 0xFFE3FFF7);
        rect(5, 10, 3, 7, 0xFF43FFE9);
        rect(19, 12, 3, 8, 0xFF00A7B4);
        rect(12, 9, 3, 9, 0xFFF0FFFD);
        rect(16, 22, 3, 3, 0xFF50FFF1);
      case MiningArtKind.pickaxe:
        for (var i = 0; i < 15; i++) {
          rect(3.0 + i, 24.0 - i, 4, 4, 0xFF392718);
          rect(4.0 + i, 24.0 - i, 2, 3, i.isEven ? 0xFFC08744 : 0xFF865226);
        }
        polygon(const [
          Offset(7, 3),
          Offset(18, 2),
          Offset(25, 8),
          Offset(26, 17),
          Offset(22, 17),
          Offset(21, 10),
          Offset(17, 7),
          Offset(10, 7),
        ], 0xFF25313B);
        polygon(const [
          Offset(9, 4),
          Offset(18, 4),
          Offset(23, 9),
          Offset(24, 15),
          Offset(23, 15),
          Offset(22, 9),
          Offset(17, 6),
          Offset(11, 6),
        ], 0xFFE4F1F4);
        rect(13, 5, 6, 2, 0xFF8FABB5);
        rect(18, 7, 3, 2, 0xFFB1CED6);
      case MiningArtKind.book:
        polygon(const [
          Offset(3, 6),
          Offset(18, 1),
          Offset(25, 5),
          Offset(25, 23),
          Offset(10, 28),
          Offset(3, 24),
        ], 0xFF382214);
        polygon(const [
          Offset(5, 7),
          Offset(19, 3),
          Offset(22, 5),
          Offset(9, 9),
        ], 0xFFB7803C);
        polygon(const [
          Offset(10, 10),
          Offset(23, 6),
          Offset(23, 22),
          Offset(10, 26),
        ], 0xFFCFAB70);
        polygon(const [
          Offset(12, 11),
          Offset(22, 8),
          Offset(22, 20),
          Offset(12, 23),
        ], 0xFFFFEDBD);
        polygon(const [
          Offset(5, 8),
          Offset(9, 10),
          Offset(9, 25),
          Offset(5, 23),
        ], 0xFF865025);
        rect(6, 10, 2, 10, 0xFFC88A42);
        polygon(const [
          Offset(15, 5),
          Offset(18, 4),
          Offset(18, 11),
          Offset(15, 10),
        ], 0xFFD83F25);
        polygon(const [
          Offset(15, 23),
          Offset(18, 22),
          Offset(18, 28),
          Offset(16, 26),
          Offset(15, 28),
        ], 0xFFD83F25);
        for (var i = 0; i < 3; i++) {
          polygon([
            Offset(14, 13.0 + i * 3),
            Offset(20, 11.0 + i * 3),
            Offset(20, 12.0 + i * 3),
            Offset(14, 14.0 + i * 3),
          ], 0xFFB8A486);
        }
      case MiningArtKind.grass:
        polygon(const [
          Offset(2, 7),
          Offset(14, 1),
          Offset(26, 7),
          Offset(26, 22),
          Offset(14, 28),
          Offset(2, 22),
        ], 0xFF49321A);
        polygon(const [
          Offset(3, 8),
          Offset(14, 13),
          Offset(14, 26),
          Offset(3, 21),
        ], 0xFFA56A30);
        polygon(const [
          Offset(14, 13),
          Offset(25, 8),
          Offset(25, 21),
          Offset(14, 26),
        ], 0xFF74431F);
        for (var i = 0; i < 14; i++) {
          rect(
            4.0 + (i * 7 % 20),
            12.0 + (i * 5 % 10),
            2,
            2,
            i.isEven ? 0xFFBB8749 : 0xFF5D3B21,
          );
        }
        polygon(const [
          Offset(2, 7),
          Offset(14, 1),
          Offset(26, 7),
          Offset(14, 13),
        ], 0xFF7ED628);
        polygon(const [
          Offset(2, 7),
          Offset(14, 13),
          Offset(14, 17),
          Offset(10, 15),
          Offset(10, 13),
          Offset(6, 12),
          Offset(6, 14),
          Offset(2, 12),
        ], 0xFF4B9F18);
        polygon(const [
          Offset(14, 13),
          Offset(26, 7),
          Offset(26, 12),
          Offset(22, 14),
          Offset(22, 12),
          Offset(18, 14),
          Offset(18, 17),
          Offset(14, 19),
        ], 0xFF347B15);
        rect(12, 5, 3, 2, 0xFFA2E84F);
        rect(18, 7, 3, 1, 0xFF5AB61E);
      case MiningArtKind.map:
        polygon(const [
          Offset(1, 5),
          Offset(9, 1),
          Offset(18, 4),
          Offset(27, 1),
          Offset(27, 23),
          Offset(18, 27),
          Offset(9, 24),
          Offset(1, 27),
        ], 0xFF634322);
        polygon(const [
          Offset(3, 7),
          Offset(9, 4),
          Offset(18, 7),
          Offset(25, 4),
          Offset(25, 21),
          Offset(18, 24),
          Offset(9, 21),
          Offset(3, 24),
        ], 0xFFFFDA90);
        polygon(const [
          Offset(5, 9),
          Offset(10, 6),
          Offset(17, 10),
          Offset(23, 7),
          Offset(23, 19),
          Offset(17, 22),
          Offset(10, 19),
          Offset(5, 21),
        ], 0xFF72AF2E);
        polygon(const [
          Offset(8, 8),
          Offset(11, 8),
          Offset(14, 13),
          Offset(19, 14),
          Offset(21, 18),
          Offset(18, 19),
          Offset(16, 16),
          Offset(12, 16),
        ], 0xFF38BFE2);
        rect(9, 4, 1, 17, 0x55FFFFFF);
        rect(18, 7, 1, 17, 0x55846127);
        rect(6, 17, 3, 2, 0xFFEAC44E);
      case MiningArtKind.crown:
        polygon(const [
          Offset(1, 7),
          Offset(8, 13),
          Offset(14, 1),
          Offset(20, 13),
          Offset(27, 7),
          Offset(24, 23),
          Offset(4, 23),
        ], 0xFF9A5700);
        polygon(const [
          Offset(3, 8),
          Offset(9, 16),
          Offset(14, 4),
          Offset(19, 16),
          Offset(25, 8),
          Offset(22, 21),
          Offset(6, 21),
        ], 0xFFFFC821);
        polygon(const [
          Offset(3, 8),
          Offset(8, 14),
          Offset(9, 19),
          Offset(6, 19),
        ], 0xFFFFE979);
        rect(6, 22, 17, 4, 0xFFD98A04);
        rect(6, 22, 17, 1, 0xFFFFEC87);
        rect(11, 22, 7, 2, 0xFFFFCA32);
        rect(12, 12, 4, 5, 0xFFFFEF91);
        rect(13, 11, 2, 7, 0xFFFFF4B8);
    }
  }

  @override
  bool shouldRepaint(_MiningArtPainter oldDelegate) => kind != oldDelegate.kind;
}
