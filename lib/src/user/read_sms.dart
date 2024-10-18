// import 'package:sms_advanced/sms_advanced.dart';  
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class SmsProcessor {
//   final SmsReceiver receiver = SmsReceiver();  
//   Function(String) onTransactionProcessed;

//   SmsProcessor({required this.onTransactionProcessed});

//   void startListening() {
    
//     receiver.onSmsReceived?.listen((SmsMessage? message) {
//       print('Received SMS: ${message?.body}');
//       _processMessage(message?.body);  
//     });
//   }


//   Future<void> _processMessage(String? message) async {
//     var url = Uri.parse('http://127.0.0.1:5000/process_message');  
//     try {
//       var response = await http.post(url,
//         headers: {"Content-Type": "application/json"},
//         body: json.encode({"message": message}),
//       );

//       if (response.statusCode == 200) {
//         var result = json.decode(response.body);
//         String transactionDetails = '''
//           Transaction Type: ${result['Transaction Type']}
//           Amount: ${result['Amount']}
//           Reference Number: ${result['Reference Number']}
//           Date: ${result['Date']}
//           Time: ${result['Time']}
//         ''';
//         onTransactionProcessed(transactionDetails);  
//       } else {
//         onTransactionProcessed("Failed to process message.");
//       }
//     } catch (e) {
//       print("Error: $e");
//       onTransactionProcessed("Error occurred while processing.");
//     }
//   }
// }
