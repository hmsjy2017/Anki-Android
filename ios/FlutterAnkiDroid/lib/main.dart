import 'package:flutter/material.dart';

void main() => runApp(const AnkiDroidFlutterApp());

class LocalDeck {
  LocalDeck({required this.id, required this.name, this.newCount = 0, this.learningCount = 0, this.reviewCount = 0});

  final int id;
  final String name;
  final int newCount;
  final int learningCount;
  final int reviewCount;

  int get dueCount => newCount + learningCount + reviewCount;
}

class LocalDeckStore extends ChangeNotifier {
  final List<LocalDeck> _decks = [LocalDeck(id: 1, name: 'Default')];

  List<LocalDeck> get decks {
    final sortedDecks = [..._decks]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List.unmodifiable(sortedDecks);
  }

  void createDeck(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Deck name cannot be empty.');
    }
    if (_decks.any((deck) => deck.name.toLowerCase() == trimmed.toLowerCase())) {
      throw ArgumentError('A deck named $trimmed already exists.');
    }
    final nextId = _decks.map((deck) => deck.id).fold<int>(0, (max, id) => id > max ? id : max) + 1;
    _decks.add(LocalDeck(id: nextId, name: trimmed));
    notifyListeners();
  }
}

class AnkiDroidFlutterApp extends StatelessWidget {
  const AnkiDroidFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnkiDroid',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: DeckHome(store: LocalDeckStore()),
    );
  }
}

class DeckHome extends StatefulWidget {
  const DeckHome({required this.store, super.key});

  final LocalDeckStore store;

  @override
  State<DeckHome> createState() => _DeckHomeState();
}

class _DeckHomeState extends State<DeckHome> {
  final TextEditingController _deckNameController = TextEditingController();

  @override
  void dispose() {
    _deckNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AnkiDroid')),
      body: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const ListTile(
              leading: Icon(Icons.memory),
              title: Text('Official Rust backend'),
              subtitle: Text('Bundled through AnkiBackendFFI when the iOS XCFramework is built.'),
            ),
            const SizedBox(height: 12),
            Text('Decks', style: Theme.of(context).textTheme.titleLarge),
            for (final deck in widget.store.decks)
              Card(
                child: ListTile(
                  title: Text(deck.name),
                  subtitle: Text('${deck.newCount} new • ${deck.learningCount} learning • ${deck.reviewCount} review'),
                  trailing: Text('${deck.dueCount} due'),
                ),
              ),
            const SizedBox(height: 12),
            TextField(controller: _deckNameController, decoration: const InputDecoration(labelText: 'New deck name')),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create local deck'),
              onPressed: () {
                try {
                  widget.store.createDeck(_deckNameController.text);
                  _deckNameController.clear();
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
