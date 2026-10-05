import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShellIndex extends Notifier<int> {
  @override
  int build() => 0;

  void set(int i) => state = i;
}

final shellIndexProvider = NotifierProvider<ShellIndex, int>(ShellIndex.new);