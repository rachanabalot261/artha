import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/models/transaction_model.dart';
import '../core/database/database_helper.dart';

class SmsService {
  static final SmsService instance = SmsService._();
  SmsService._();

  final _tel = Telephony.instance;

  // Merchant keyword → Category mapping
  // If SMS contains any of these words, it gets that category
  static const Map<String, List<String>> _cats = {
    'Food': [
      'swiggy', 'zomato', 'dominos', 'pizza', 'kfc', 'mcdonalds',
      'burger king', 'cafe', 'restaurant', 'blinkit', 'zepto',
      'bigbasket', 'dunzo', 'instamart', 'haldiram', 'subway',
      'mcd', 'food', 'bakery', 'dhaba', 'biryani'
    ],
    'Transport': [
      'uber', 'ola', 'rapido', 'metro', 'irctc', 'railway', 'bus',
      'petrol', 'fuel', 'hp gas', 'indane', 'auto', 'cab',
      'makemytrip', 'yatra', 'redbus', 'indigo', 'spicejet',
      'air india', 'go first', 'akasa', 'fasttag'
    ],
    'Entertainment': [
      'netflix', 'spotify', 'prime video', 'hotstar', 'disney',
      'zee5', 'sonyliv', 'jiosaavn', 'gaana', 'bookmyshow',
      'pvr', 'inox', 'cinepolis', 'steam', 'youtube premium'
    ],
    'Shopping': [
      'amazon', 'flipkart', 'myntra', 'ajio', 'nykaa', 'meesho',
      'reliance digital', 'croma', 'vijay sales', 'dmart',
      'lifestyle', 'shoppers stop', 'zara', 'h&m', 'westside'
    ],
    'Health': [
      'pharmacy', 'medical', 'hospital', 'clinic', 'doctor',
      'apollo', 'medplus', 'netmeds', 'pharmeasy', '1mg',
      'lab', 'diagnostic', 'dentist', 'cult fit', 'healthify'
    ],
    'Utilities': [
      'electricity', 'bescom', 'mseb', 'tata power', 'water',
      'bwssb', 'piped gas', 'broadband', 'jio fiber', 'airtel',
      'bsnl', 'vodafone', 'vi ', 'recharge', 'dth', 'tatasky'
    ],
    'Education': [
      'school', 'college', 'tuition', 'coaching', 'udemy',
      'coursera', 'byju', 'unacademy', 'vedantu', 'stationery'
    ],
    'Rent': [
      'rent', 'house rent', 'pg rent', 'hostel', 'maintenance',
      'society fee', 'apartment'
    ],
    'Subscriptions': [
      'subscription', 'annual plan', 'monthly plan', 'membership',
      'linkedin', 'github', 'notion', 'adobe', 'microsoft 365',
      'google one', 'icloud'
    ],
  };

  // Regex patterns — each matches a specific bank's SMS format

  // Matches amounts like "Rs.450.00" or "₹1,200"
  static final _amount = RegExp(
      r'(?:Rs\.?|₹|INR)\s*(\d{1,3}(?:,\d{2,3})*(?:\.\d{2})?)',
      caseSensitive: false);

  // HDFC: "debited ... to VPA swiggy@icici"
  static final _hdfcDebit = RegExp(
      r'debited.*?(?:to VPA\s+(\S+)|to\s+([^.]+?))\s*(?:\.|UPI|Ref)',
      caseSensitive: false);

  // HDFC credit: "credited ... by VPA abc@upi"
  static final _hdfcCredit = RegExp(
      r'credited.*?(?:by VPA\s+(\S+)|from\s+([^.]+?))\s*(?:\.|UPI|Ref)',
      caseSensitive: false);

  // Paytm: "Rs. 200 paid to Merchant via Paytm"
  static final _paytm = RegExp(
      r'Rs\.?\s*\d+.*?(?:paid|sent)\s+to\s+([^.]+?)\s+(?:via|using)',
      caseSensitive: false);

  // Generic UPI: "paid Rs 500 to merchant@upi"
  static final _genericUpi = RegExp(
      r'(?:paid|sent|transferred)\s+(?:Rs\.?|₹)?\s*\d+.*?(?:to|at)\s+([^\s.]+)',
      caseSensitive: false);

  // VPA (UPI address) pattern as fallback
  static final _vpa =
      RegExp(r'VPA\s+(\S+@\S+)', caseSensitive: false);

  // UPI reference number — used to prevent duplicate imports
  static final _upiRef = RegExp(
      r'(?:UPI\s*Ref|Ref\s*No\.?|UTR)[:\s]*(\d{10,})',
      caseSensitive: false);

  // Date pattern covering formats like "15-04-25", "15 Apr 2025"
  static final _date = RegExp(
      r'(\d{1,2})[-/\s]?(\d{1,2}|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))[-/\s]?(\d{2,4})',
      caseSensitive: false);

  // Main method — takes one SMS body, returns a transaction or null
  TransactionModel? parse(String body, DateTime fallbackDate) {
    final lower = body.toLowerCase();
    if (!_isTransaction(lower)) return null; // ignore non-financial SMS

    final amount = _parseAmount(body);
    if (amount == null || amount <= 0) return null;

    final type = _type(lower);
    final merchant = _merchant(body);
    final category = _categorize(merchant, lower);
    final upiRef = _upiRef.firstMatch(body)?.group(1);
    final date = _parseDate(body) ?? fallbackDate;

    return TransactionModel(
      merchant: merchant,
      amount: amount,
      category: category,
      type: type,
      date: date,
      source: 'sms',
      rawSms: body,
      upiRef: upiRef,
    );
  }

  // Check if SMS is a financial transaction
  bool _isTransaction(String lower) => [
        'debited', 'credited', 'paid', 'received', 'transferred',
        'withdrawn', 'upi', 'imps', 'neft', 'rs.', '₹', 'inr'
      ].any(lower.contains);

  // Detect debit vs credit
  String _type(String lower) {
    return ['credited', 'received', 'credit', 'deposited', 'refund']
            .any(lower.contains)
        ? 'credit'
        : 'debit';
  }

  // Extract the amount number from the SMS
  double? _parseAmount(String body) {
    final clean = body.replaceAll(',', ''); // remove commas from 1,000
    final m = _amount.firstMatch(clean);
    return m != null ? double.tryParse(m.group(1)!) : null;
  }

  // Try each bank's pattern to find the merchant name
  String _merchant(String body) {
    String? raw;
    raw = _hdfcDebit.firstMatch(body)?.group(1) ??
        _hdfcDebit.firstMatch(body)?.group(2) ??
        _hdfcCredit.firstMatch(body)?.group(1) ??
        _hdfcCredit.firstMatch(body)?.group(2) ??
        _paytm.firstMatch(body)?.group(1) ??
        _genericUpi.firstMatch(body)?.group(1) ??
        _vpa.firstMatch(body)?.group(1);
    return _clean(raw ?? 'Unknown');
  }

  // Clean up merchant name — remove @bank part, title case
  String _clean(String raw) {
    var s = raw
        .trim()
        .replaceAll(RegExp(r'@\w+'), '')    // remove @hdfc, @icici etc
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .trim();
    if (s.isEmpty) return 'Unknown';
    return s
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  // Match merchant name against category keywords
  String _categorize(String merchant, String lower) {
    final combined = '${merchant.toLowerCase()} $lower';
    for (final entry in _cats.entries) {
      if (entry.value.any(combined.contains)) return entry.key;
    }
    return 'Other';
  }

  // Parse date from SMS text
  DateTime? _parseDate(String body) {
    final m = _date.firstMatch(body);
    if (m == null) return null;
    try {
      final day = int.parse(m.group(1)!);
      final monthRaw = m.group(2)!;
      final yearRaw = m.group(3)!;
      int month;
      if (int.tryParse(monthRaw) != null) {
        month = int.parse(monthRaw);
      } else {
        const names = {
          'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
          'may': 5, 'jun': 6, 'jul': 7, 'aug': 8,
          'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
        };
        month =
            names[monthRaw.toLowerCase().substring(0, 3)] ?? 1;
      }
      int year = int.parse(yearRaw);
      if (year < 100) year += 2000; // convert "25" to "2025"
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  // Read entire inbox and import last 12 months of transactions
  Future<int> importInbox() async {
    if (!await Permission.sms.request().then((s) => s.isGranted)) {
      return 0; // user denied permission
    }

    int count = 0;
    try {
      final msgs = await _tel.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.DATE)
            .greaterThanOrEqualTo(
          DateTime.now()
              .subtract(const Duration(days: 365))
              .millisecondsSinceEpoch
              .toString(),
        ),
      );

      for (final msg in msgs) {
        final body = msg.body ?? '';
        final date = msg.date != null
            ? DateTime.fromMillisecondsSinceEpoch(msg.date!)
            : DateTime.now();
        final tx = parse(body, date);
        if (tx != null) {
          final r = await DatabaseHelper.instance.insert(tx);
          if (r != -1) count++; // -1 means duplicate, skip
        }
      }
    } catch (_) {}

    return count;
  }

  // Listen for new SMS in real time while app is open
  void startListening() {
    _tel.listenIncomingSms(
      onNewMessage: (msg) async {
        final body = msg.body ?? '';
        final tx = parse(body, DateTime.now());
        if (tx != null) await DatabaseHelper.instance.insert(tx);
      },
      listenInBackground: false,
    );
  }
}