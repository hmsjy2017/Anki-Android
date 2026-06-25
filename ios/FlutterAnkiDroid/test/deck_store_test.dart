import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ankidroid/main.dart';

void main() {
  test('creates and sorts local decks', () {
    final store = LocalDeckStore();
    store.createDeck(' Japanese ');
    store.createDeck('Biology');

    expect(store.decks.map((deck) => deck.name), ['Biology', 'Default', 'Japanese']);
  });

  test('rejects empty and duplicate deck names', () {
    final store = LocalDeckStore();

    expect(() => store.createDeck('   '), throwsArgumentError);
    expect(() => store.createDeck('default'), throwsArgumentError);
  });
}
