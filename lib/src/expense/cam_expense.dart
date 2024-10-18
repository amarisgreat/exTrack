import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ScanBillPage extends StatefulWidget {
  const ScanBillPage({super.key});

  @override
  _ScanBillPageState createState() => _ScanBillPageState();
}

class _ScanBillPageState extends State<ScanBillPage> {
  bool _isLoading = false;
  String _statusMessage = "Scan a bill to extract the amount";
  String? _extractedAmount;

  // Function to handle bill scanning and transaction saving
  Future<void> _scanBillAndStoreTransaction() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = "Scanning the bill...";
      });

      // Step 1: Capture image from the camera
      final imageFile = await ImagePicker().pickImage(source: ImageSource.camera);
      if (imageFile == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = "No image selected.";
        });
        return;
      }

      // Step 2: Extract text from the image using Google ML Kit's Text Recognizer
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final textRecognizer = TextRecognizer(); // Create a text recognizer
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      textRecognizer.close(); // Always close the recognizer when done

      // Step 3: Extract the amount from the recognized text
      String? extractedAmount;
      List<double> detectedAmounts = [];

      // Regular expression to detect amounts, including those with currency symbols
      final amountRegex = RegExp(r'(\$?\d{1,3}(?:,\d{3})*(?:\.\d{2})?)|(\d{1,3}(?:,\d{3})*(?:\.\d{2})?\s?(?:USD|usd)?)');

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final matches = amountRegex.allMatches(line.text);
          for (var match in matches) {
            String matchedText = match.group(0)!;
            matchedText = matchedText.replaceAll(RegExp(r'[^0-9.]'), ''); // Clean up the number, removing any currency symbols

            if (matchedText.isNotEmpty) {
              try {
                double amount = double.parse(matchedText);
                detectedAmounts.add(amount); // Collect all detected amounts
              } catch (e) {
                // Ignore invalid numbers
              }
            }
          }
        }
      }

      // Step 4: Determine the highest amount, assuming it is the total bill amount
      if (detectedAmounts.isNotEmpty) {
        extractedAmount = detectedAmounts.reduce((a, b) => a > b ? a : b).toStringAsFixed(2);
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = "No valid amount detected from the bill.";
        });
        return;
      }

      setState(() {
        _extractedAmount = extractedAmount;
        _statusMessage = "Amount extracted: \$$extractedAmount";
      });

      // Step 5: Store the transaction in Firebase
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;

        DatabaseReference ref = FirebaseDatabase.instance.ref()
            .child('transactions')
            .child(userId)
            .push();

        await ref.set({
          'amount': double.parse(extractedAmount),
          'category': 'Bill',  // You can modify this or allow user input for categories
          'date': DateTime.now().toIso8601String(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'transactionType': 'Expense',  // Assuming the scanned bill is an expense
          'notes': 'Scanned from bill',
        });

        setState(() {
          _isLoading = false;
          _statusMessage = "Transaction saved successfully.";
        });
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = "User is not logged in.";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error occurred: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Bill'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isLoading
                ? const CircularProgressIndicator()
                : const Icon(
                    Icons.receipt_long,
                    size: 100,
                    color: Colors.blue,
                  ),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            if (_extractedAmount != null)
              Text(
                'Extracted Amount: \$$_extractedAmount',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _scanBillAndStoreTransaction,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Bill'),
            ),
          ],
        ),
      ),
    );
  }
}
