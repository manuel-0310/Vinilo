import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/widgets/pull_stretch.dart';

void main() {
  test('pullScale crece lo que se tira', () {
    expect(pullScale(200, 0), 1);
    expect(pullScale(200, 50), 1.25);
    expect(pullScale(140, 140), 2);
    expect(pullScale(0, 30), 1);
  });

  testWidgets('al tirar hacia abajo arriba del todo, la portada crece pegada al borde y los botones no bajan',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          controller: scroll,
          physics: pullPhysics,
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  PullStretch(
                    controller: scroll,
                    height: 400,
                    child: const SizedBox(key: ValueKey('cover'), width: 400, height: 400),
                  ),
                  PullPinned(
                    controller: scroll,
                    child: const SizedBox(key: ValueKey('buttons'), width: 400, height: 40),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 2000)),
          ],
        ),
      ),
    ));

    expect(tester.getRect(find.byKey(const ValueKey('cover'))), const Rect.fromLTWH(0, 0, 400, 400));

    final gesture = await tester.startGesture(const Offset(200, 300));
    await gesture.moveBy(const Offset(0, 60));
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();

    final extra = pullExtent(scroll);
    expect(extra, greaterThan(0));
    final cover = tester.getRect(find.byKey(const ValueKey('cover')));
    // Sigue pegada arriba, crece `extra` de alto y se agranda centrada.
    expect(cover.top, moreOrLessEquals(0, epsilon: 0.01));
    expect(cover.height, moreOrLessEquals(400 + extra, epsilon: 0.01));
    expect(cover.center.dx, moreOrLessEquals(200, epsilon: 0.01));
    expect(tester.getTopLeft(find.byKey(const ValueKey('buttons'))).dy, moreOrLessEquals(0, epsilon: 0.01));

    // Al soltar vuelve con el rebote.
    await gesture.up();
    await tester.pumpAndSettle();
    expect(pullExtent(scroll), 0);
    expect(tester.getRect(find.byKey(const ValueKey('cover'))), const Rect.fromLTWH(0, 0, 400, 400));

    // Al bajar normalmente no crece: se va con el contenido.
    scroll.jumpTo(100);
    await tester.pump();
    expect(tester.getRect(find.byKey(const ValueKey('cover'))), const Rect.fromLTWH(0, -100, 400, 400));
    expect(tester.getTopLeft(find.byKey(const ValueKey('buttons'))).dy, -100);
  });
}
