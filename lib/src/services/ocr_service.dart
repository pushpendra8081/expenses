import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../models/expense.dart';
import 'dart:developer' as developer;



// OCR result model
class OCRResult {
  final double? amount;
  final DateTime? date;
  final String? merchant;
  final String rawText;
  final List<String> extractedLines;

  const OCRResult({
    this.amount,
    this.date,
    this.merchant,
    required this.rawText,
    required this.extractedLines,
  });

  @override
  String toString() {
    return 'OCRResult(amount: $amount, date: $date, merchant: $merchant, rawText: $rawText)';
  }
}

class OCRService {
  static final TextRecognizer _textRecognizer = TextRecognizer();
  static final ImagePicker _imagePicker = ImagePicker();

  // Pick image from camera
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      throw Exception('Failed to pick image from camera: $e');
    }
  }

  // Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  // Process image and extract text

  // Process image and extract text
  static Future<OCRResult> processImage(File imageFile) async {
    try {
      final InputImage inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      final String rawText = recognizedText.text;
      final List<String> lines = rawText.split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      // 🔹 Log everything for debugging
      developer.log("🔍 RAW OCR TEXT:\n$rawText");
      for (int i = 0; i < lines.length; i++) {
        developer.log("Line[$i]: ${lines[i]}");
      }

      // Extract information from the text
      final double? amount = _extractAmount(rawText, lines);
      final DateTime? date = _extractDate(rawText, lines);
      final String? merchant = _extractMerchant(rawText, lines);

      developer.log("✅ Extracted Amount: $amount");
      developer.log("✅ Extracted Date: $date");
      developer.log("✅ Extracted Merchant: $merchant");

      return OCRResult(
        amount: amount,
        date: date,
        merchant: merchant,
        rawText: rawText,
        extractedLines: lines,
      );
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }


  // Extract amount from text
  static double? _extractAmount(String rawText, List<String> lines) {
    final lineAmountMap = <String, double>{};

    for (final line in lines) {
      final lower = line.toLowerCase();

      // Skip lines that are clearly NOT totals
      if (lower.contains("tel") ||
          lower.contains("phone") ||
          lower.contains("approval") ||
          lower.contains("card") ||
          lower.contains("code") ||
          RegExp(r'\d{3,}[- ]?\d+').hasMatch(line)) {
        continue; // phone or card number
      }
      if (RegExp(r'\d{2}:\d{2}').hasMatch(line)) continue; // time
      if (RegExp(r'\d{2}[-/]\d{2}[-/]\d{2,4}').hasMatch(line)) continue; // date

      // Extract amounts
      final matches = RegExp(r'([0-9]+\.?[0-9]*)').allMatches(line);
      if (matches.isNotEmpty) {
        final amountStr = matches.last.group(1);
        if (amountStr != null) {
          final amount = double.tryParse(amountStr);

          // Filter out integers > 999 (likely not amounts)
          if (amount != null && amount > 0 && amount < 10000) {
            if (!(amount % 1 == 0 && amount > 999)) {
              lineAmountMap[lower] = amount;
            }
          }
        }
      }
    }

    // 1. Prefer "total"
    for (final entry in lineAmountMap.entries) {
      if (entry.key.contains("total")) {
        return entry.value;
      }
    }

    // 2. Then "balance"
    for (final entry in lineAmountMap.entries) {
      if (entry.key.contains("balance")) {
        return entry.value;
      }
    }

    // 3. Fallback: largest amount
    if (lineAmountMap.values.isNotEmpty) {
      return lineAmountMap.values.reduce((a, b) => a > b ? a : b);
    }

    return null;
  }

  // Extract date from text
  static DateTime? _extractDate(String rawText, List<String> lines) {
    final List<RegExp> datePatterns = [
      RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'), // MM/DD/YYYY
      RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})'), // MM-DD-YYYY
      RegExp(r'(\d{4})/(\d{1,2})/(\d{1,2})'), // YYYY/MM/DD
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'), // YYYY-MM-DD
      RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})'), // MM.DD.YYYY
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(rawText);
      if (match != null) {
        try {
          int year, month, day;
          
          if (pattern.pattern.startsWith(r'(\d{4})')) {
            // YYYY/MM/DD or YYYY-MM-DD format
            year = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            day = int.parse(match.group(3)!);
          } else {
            // MM/DD/YYYY format
            month = int.parse(match.group(1)!);
            day = int.parse(match.group(2)!);
            year = int.parse(match.group(3)!);
          }
          
          if (year >= 2000 && year <= DateTime.now().year + 1 &&
              month >= 1 && month <= 12 &&
              day >= 1 && day <= 31) {
            return DateTime(year, month, day);
          }
        } catch (e) {
          continue;
        }
      }
    }

    // If no specific date found, try to find today's date or recent dates
    final now = DateTime.now();
    final todayPatterns = [
      RegExp(r'today', caseSensitive: false),
      RegExp(r'${now.day}/${now.month}/${now.year}'),
    ];

    for (final pattern in todayPatterns) {
      if (pattern.hasMatch(rawText)) {
        return now;
      }
    }

    return null;
  }

  // Extract merchant name from text
  static String? _extractMerchant(String rawText, List<String> lines) {
    if (lines.isEmpty) return null;

    // Common merchant indicators
    final merchantKeywords = [
      'store', 'shop', 'market', 'restaurant', 'cafe', 'coffee',
      'gas', 'station', 'pharmacy', 'hotel', 'mall', 'center'
    ];

    // Look for lines that might contain merchant names
    // Usually the first few lines or lines with certain keywords
    final potentialMerchants = <String>[];

    // Check first few lines (often contain merchant name)
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      if (line.length > 3 && line.length < 50) {
        // Skip lines that are mostly numbers or symbols
        if (!RegExp(r'^[0-9\s\-\.\$#]+$').hasMatch(line)) {
          potentialMerchants.add(line);
        }
      }
    }

    // Look for lines with merchant keywords
    for (final line in lines) {
      for (final keyword in merchantKeywords) {
        if (line.toLowerCase().contains(keyword)) {
          potentialMerchants.add(line);
          break;
        }
      }
    }

    // Return the most likely merchant name
    if (potentialMerchants.isNotEmpty) {
      // Prefer shorter, cleaner names
      potentialMerchants.sort((a, b) => a.length.compareTo(b.length));
      return potentialMerchants.first.trim();
    }

    // Fallback: return the first non-empty line if it looks like a name
    if (lines.isNotEmpty) {
      final firstLine = lines.first;
      if (firstLine.length > 3 && firstLine.length < 50 &&
          !RegExp(r'^[0-9\s\-\.\$#]+$').hasMatch(firstLine)) {
        return firstLine.trim();
      }
    }

    return null;
  }

  // Clean up extracted text
  static String cleanText(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s\$\.\-\/:]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Dispose resources
  static Future<void> dispose() async {
    await _textRecognizer.close();
  }

  // Validate extracted data
  static bool isValidAmount(double? amount) {
    return amount != null && amount > 0 && amount < 10000;
  }

  static bool isValidDate(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));
    final oneYearFromNow = now.add(const Duration(days: 365));
    return date.isAfter(oneYearAgo) && date.isBefore(oneYearFromNow);
  }

  static bool isValidMerchant(String? merchant) {
    return merchant != null && 
           merchant.trim().isNotEmpty && 
           merchant.length >= 2 && 
           merchant.length <= 100;
  }

  // Extract expense data from OCR result
  static Expense extractExpenseData(OCRResult ocrResult, {
    String? overrideCategory,
    String? overrideDescription,
  }) {
    final amount = ocrResult.amount ?? 0.0;
    final date = ocrResult.date ?? DateTime.now();
    final merchantName = ocrResult.merchant ?? 'Unknown';
    
    // Determine category from merchant name or raw text
    final category = overrideCategory ?? 
        ExpenseCategoryHelper.categories.first; // Default to first category
    
    // Use override description in notes if provided, otherwise use merchant
    final finalMerchant = overrideDescription ?? merchantName;
    final now = DateTime.now();
    
    return Expense(
      id: now.millisecondsSinceEpoch.toString(),
      amount: amount,
      merchant: finalMerchant,
      category: category,
      date: date,
      notes: ocrResult.rawText.isNotEmpty ? 'Scanned from receipt' : null,
      createdAt: now,
      updatedAt: now,
      isFromReceipt: true,
    );
  }

  // Process image and create expense directly
  static Future<Expense> processImageToExpense(File imageFile, {
    String? overrideCategory,
    String? overrideDescription,
  }) async {
    final ocrResult = await processImage(imageFile);
    return extractExpenseData(
      ocrResult,
      overrideCategory: overrideCategory,
      overrideDescription: overrideDescription,
    );
  }

  // Scan receipt from camera or gallery and create expense
  static Future<Expense?> scanReceipt({
    ImageSource source = ImageSource.camera,
    String? overrideCategory,
    String? overrideDescription,
  }) async {
    try {
      File? imageFile;
      
      if (source == ImageSource.camera) {
        imageFile = await pickImageFromCamera();
      } else {
        imageFile = await pickImageFromGallery();
      }
      
      if (imageFile == null) {
        return null; // User cancelled image selection
      }
      
      return await processImageToExpense(
        imageFile,
        overrideCategory: overrideCategory,
        overrideDescription: overrideDescription,
      );
    } catch (e) {
      throw Exception('Failed to scan receipt: $e');
    }
  }
}