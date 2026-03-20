import 'package:flutter/material.dart';

/// Paints a recognizable Philippine archipelago silhouette as a backdrop.
/// Uses simplified outline derived from actual geographic SVG data.
/// Renders as a single filled shape at low opacity.
class PhilippineMapPainter extends CustomPainter {
  final bool isDark;
  final Color color;

  PhilippineMapPainter({required this.isDark, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: isDark ? 0.07 : 0.05);

    // Scale the SVG viewBox (roughly 800x1200) to fit our canvas
    // centered with padding
    final svgWidth = 800.0;
    final svgHeight = 1200.0;
    final scaleX = size.width * 0.85 / svgWidth;
    final scaleY = size.height * 0.9 / svgHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final offsetX = (size.width - svgWidth * scale) / 2;
    final offsetY = (size.height - svgHeight * scale) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    // Draw each major island group
    _drawLuzon(canvas, paint);
    _drawMindanao(canvas, paint);
    _drawVisayas(canvas, paint);
    _drawPalawan(canvas, paint);
    _drawMindoro(canvas, paint);
    _drawSamar(canvas, paint);
    _drawLeyte(canvas, paint);
    _drawNegros(canvas, paint);
    _drawPanay(canvas, paint);
    _drawCebu(canvas, paint);

    canvas.restore();
  }

  void _drawLuzon(Canvas canvas, Paint paint) {
    // Simplified Luzon outline (~40 points tracing the recognizable shape)
    final path = Path();
    path.moveTo(480, 80);
    path.lineTo(500, 60);
    path.lineTo(530, 50);
    path.lineTo(560, 55);
    path.lineTo(590, 70);
    path.lineTo(610, 95);
    path.lineTo(620, 130);
    path.lineTo(625, 170);
    path.lineTo(615, 200);
    path.lineTo(630, 230); // Bicol peninsula starts
    path.lineTo(640, 270);
    path.lineTo(650, 310);
    path.lineTo(660, 350);
    path.lineTo(665, 390);
    path.lineTo(660, 420);
    path.lineTo(645, 450);
    path.lineTo(625, 470); // Bicol tip
    path.lineTo(600, 460);
    path.lineTo(580, 440);
    path.lineTo(555, 420);
    path.lineTo(530, 400);
    path.lineTo(510, 380);
    path.lineTo(490, 360);
    path.lineTo(470, 340);
    path.lineTo(450, 320);
    path.lineTo(430, 310);
    path.lineTo(410, 300);
    path.lineTo(390, 280);
    path.lineTo(375, 260);
    path.lineTo(365, 240); // Manila Bay area
    path.lineTo(360, 220);
    path.lineTo(355, 195);
    path.lineTo(360, 170);
    path.lineTo(370, 150);
    path.lineTo(385, 135);
    path.lineTo(400, 120);
    path.lineTo(420, 105);
    path.lineTo(445, 90);
    path.lineTo(465, 82);
    path.close();
    canvas.drawPath(path, paint);

    // Bataan peninsula
    final bataan = Path();
    bataan.moveTo(355, 220);
    bataan.lineTo(340, 235);
    bataan.lineTo(335, 260);
    bataan.lineTo(345, 275);
    bataan.lineTo(360, 270);
    bataan.lineTo(365, 250);
    bataan.close();
    canvas.drawPath(bataan, paint);
  }

  void _drawMindanao(Canvas canvas, Paint paint) {
    final path = Path();
    path.moveTo(420, 820);
    path.lineTo(450, 800);
    path.lineTo(490, 790);
    path.lineTo(530, 785);
    path.lineTo(570, 790);
    path.lineTo(610, 800);
    path.lineTo(640, 815);
    path.lineTo(660, 835);
    path.lineTo(670, 860);
    path.lineTo(680, 890);
    path.lineTo(685, 920);
    path.lineTo(675, 950);
    path.lineTo(660, 975);
    path.lineTo(640, 990);
    path.lineTo(615, 1000);
    // Zamboanga peninsula
    path.lineTo(580, 1010);
    path.lineTo(540, 1020);
    path.lineTo(500, 1015);
    path.lineTo(460, 1005);
    path.lineTo(430, 990);
    // Zamboanga arm going west
    path.lineTo(400, 975);
    path.lineTo(370, 960);
    path.lineTo(340, 950);
    path.lineTo(320, 940);
    path.lineTo(310, 920);
    path.lineTo(320, 900);
    path.lineTo(340, 885);
    path.lineTo(360, 870);
    path.lineTo(380, 855);
    path.lineTo(400, 840);
    path.close();
    canvas.drawPath(path, paint);

    // Davao Gulf indent
    final davao = Path();
    davao.moveTo(610, 900);
    davao.lineTo(595, 920);
    davao.lineTo(590, 940);
    davao.lineTo(600, 955);
    davao.lineTo(620, 950);
    davao.lineTo(630, 935);
    davao.close();
    canvas.drawPath(davao, Paint()..color = Colors.transparent);
  }

  void _drawVisayas(Canvas canvas, Paint paint) {
    // Bohol
    final bohol = Path();
    bohol.moveTo(530, 700);
    bohol.lineTo(555, 690);
    bohol.lineTo(575, 695);
    bohol.lineTo(580, 715);
    bohol.lineTo(565, 725);
    bohol.lineTo(540, 720);
    bohol.close();
    canvas.drawPath(bohol, paint);
  }

  void _drawPalawan(Canvas canvas, Paint paint) {
    // Long thin island going SW
    final path = Path();
    path.moveTo(260, 380);
    path.lineTo(275, 370);
    path.lineTo(285, 385);
    path.lineTo(280, 410);
    path.lineTo(270, 440);
    path.lineTo(260, 470);
    path.lineTo(250, 500);
    path.lineTo(240, 535);
    path.lineTo(230, 570);
    path.lineTo(220, 600);
    path.lineTo(210, 630);
    path.lineTo(200, 660);
    path.lineTo(190, 690);
    path.lineTo(185, 710);
    path.lineTo(175, 700);
    path.lineTo(180, 670);
    path.lineTo(190, 640);
    path.lineTo(200, 610);
    path.lineTo(210, 580);
    path.lineTo(220, 545);
    path.lineTo(230, 510);
    path.lineTo(240, 475);
    path.lineTo(248, 440);
    path.lineTo(252, 410);
    path.lineTo(255, 390);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawMindoro(Canvas canvas, Paint paint) {
    final path = Path();
    path.moveTo(340, 400);
    path.lineTo(365, 390);
    path.lineTo(380, 405);
    path.lineTo(385, 430);
    path.lineTo(375, 460);
    path.lineTo(355, 475);
    path.lineTo(335, 465);
    path.lineTo(325, 440);
    path.lineTo(330, 415);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSamar(Canvas canvas, Paint paint) {
    final path = Path();
    path.moveTo(620, 530);
    path.lineTo(650, 520);
    path.lineTo(670, 535);
    path.lineTo(675, 560);
    path.lineTo(665, 590);
    path.lineTo(645, 600);
    path.lineTo(625, 590);
    path.lineTo(615, 565);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawLeyte(Canvas canvas, Paint paint) {
    final path = Path();
    path.moveTo(590, 580);
    path.lineTo(610, 570);
    path.lineTo(620, 590);
    path.lineTo(625, 620);
    path.lineTo(620, 660);
    path.lineTo(610, 680);
    path.lineTo(595, 675);
    path.lineTo(585, 650);
    path.lineTo(580, 620);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawNegros(Canvas canvas, Paint paint) {
    final path = Path();
    path.moveTo(440, 600);
    path.lineTo(465, 590);
    path.lineTo(480, 605);
    path.lineTo(485, 640);
    path.lineTo(480, 680);
    path.lineTo(465, 710);
    path.lineTo(445, 705);
    path.lineTo(435, 670);
    path.lineTo(430, 635);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawPanay(Canvas canvas, Paint paint) {
    final path = Path();
    path.moveTo(390, 560);
    path.lineTo(420, 550);
    path.lineTo(440, 565);
    path.lineTo(445, 595);
    path.lineTo(435, 625);
    path.lineTo(415, 630);
    path.lineTo(395, 615);
    path.lineTo(385, 590);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCebu(Canvas canvas, Paint paint) {
    // Long thin island
    final path = Path();
    path.moveTo(510, 590);
    path.lineTo(520, 585);
    path.lineTo(525, 600);
    path.lineTo(530, 630);
    path.lineTo(535, 660);
    path.lineTo(530, 690);
    path.lineTo(525, 720);
    path.lineTo(515, 730);
    path.lineTo(508, 720);
    path.lineTo(505, 690);
    path.lineTo(500, 660);
    path.lineTo(500, 630);
    path.lineTo(505, 605);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
