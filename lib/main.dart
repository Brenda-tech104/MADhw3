import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameState(),
      child: MemoryGame(),
    ),
  );
}

class MemoryGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Memory Flip Card Game')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<GameState>(
            builder: (context, gameState, child) {
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 by 4
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: gameState.cards.length,
                itemBuilder: (context, index) {
                  return CardWidget(card: gameState.cards[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// Data model for each card
class CardModel {
  final String emoji;
  bool isFlipped;
  bool isMatched;

  CardModel({required this.emoji})
      : isFlipped = false,
        isMatched = false;
}

// State management class using ChangeNotifier
class GameState extends ChangeNotifier {
  List<CardModel> cards = [];
  CardModel? firstFlipped;
  bool waitingForFlip = false;

  GameState() {
    _initializeGame();
  }

  void _initializeGame() {
    List<String> emojis = ['🎃', '👻', '🦇', '🕷️', '🍬', '🪦', '🧛', '🧟'];
    List<String> deck = List.from(emojis)
      ..addAll(emojis); // Duplicate for pairs
    deck.shuffle(); // Shuffle the deck
    cards = deck.map((emoji) => CardModel(emoji: emoji)).toList();
    notifyListeners(); // Notify listeners of state changes
  }

  void flipCard(CardModel card) {
    if (waitingForFlip || card.isFlipped || card.isMatched) return;

    card.isFlipped = true;
    notifyListeners();

    if (firstFlipped == null) {
      firstFlipped = card;
    } else {
      if (firstFlipped!.emoji == card.emoji) {
        // Match found
        firstFlipped!.isMatched = true;
        card.isMatched = true;
        firstFlipped = null;
      } else {
        // No match:
        waitingForFlip = true;
        Future.delayed(Duration(seconds: 1), () {
          card.isFlipped = false;
          firstFlipped!.isFlipped = false;
          firstFlipped = null;
          waitingForFlip = false;
          notifyListeners();
        });
      }
    }
  }
}

// Widget to display each card with animation
class CardWidget extends StatefulWidget {
  final CardModel card;

  CardWidget({required this.card});

  @override
  _CardWidgetState createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context, listen: false);

    return GestureDetector(
      onTap: () {
        if (!widget.card.isFlipped) {
          _controller.forward();
          gameState.flipCard(widget.card);
        }
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(_animation.value * pi),
            child: Container(
              decoration: BoxDecoration(
                color: widget.card.isFlipped ? Colors.white : Colors.orange,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: widget.card.isFlipped
                  ? Text(
                      widget.card.emoji,
                      style: TextStyle(fontSize: 32),
                    )
                  : Container(), // Face-down card is now empty
            ),
          );
        },
      ),
    );
  }
}
