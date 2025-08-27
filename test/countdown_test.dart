import 'package:drawly/features/draw_game/draw_game_room_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';

// Simple concrete implementation used only for testing the view model logic.
class _TestViewModel extends GamePageViewModel {
  @override
  Widget build(BuildContext context) => Container();
}

void main() {
  test('startCountdown updates remaining time', () {
    final vm = _TestViewModel();

    fakeAsync((async) {
      vm.startCountdown(300);
      expect(vm.rxTimeLeft.value, 0);

      async.elapse(const Duration(milliseconds: 100));
      expect(vm.rxTimeLeft.value, 200);

      async.elapse(const Duration(milliseconds: 200));
      expect(vm.rxTimeLeft.value, 0);
    });
  });
}
