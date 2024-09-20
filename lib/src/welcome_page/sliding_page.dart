import 'package:flutter/material.dart';
import 'package:extrack/src/welcome_page/welcome_page.dart';

class SlidePage extends StatefulWidget {
  const SlidePage({super.key});

  @override
  _SlidePageState createState() => _SlidePageState();
}

class _SlidePageState extends State<SlidePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _quotes = [
    {
      'image': 'assets/img/financial1.png',
      'quote': '“An investment in knowledge pays the best interest.” — Benjamin Franklin',
    },
    {
      'image': 'assets/img/financial2.png',
      'quote': '“Do not save what is left after spending, but spend what is left after saving.” — Warren Buffet',
    },
    {
      'image': 'assets/img/financial3.png',
      'quote': '“The stock market is filled with individuals who know the price of everything, but the value of nothing.” — Phillip Fisher',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _quotes.length,
            itemBuilder: (context, index) {
              return buildPageContent(
                imagePath: _quotes[index]['image']!,
                quote: _quotes[index]['quote']!,
              );
            },
          ),
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    _pageController.animateToPage(
                      _quotes.length - 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('skip', style: TextStyle(color: Colors.blue)),
                ),
                Row(
                  children: List.generate(_quotes.length, (index) => buildDot(index, context)),
                ),
                TextButton(
                  onPressed: () {
                    if (_currentPage == _quotes.length - 1) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const WelcomePage()),
                      );
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: const Text(
                    'next',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPageContent({required String imagePath, required String quote}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 6, // Adjust this to control the space occupied by the image
            child: Image.asset(
              imagePath, 
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 40), // Increased spacing
          Expanded(
            flex: 2, // Adjust this to give more space to the text
            child: Text(
              quote,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index, BuildContext context) {
    return Container(
      height: 10,
      width: _currentPage == index ? 12 : 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _currentPage == index ? Colors.blue : Colors.grey,
      ),
    );
  }
}
