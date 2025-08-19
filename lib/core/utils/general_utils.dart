// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';
// import 'dart:async';
//
// class GeneralUtils {
//   // Format currency
//   static String formatCurrency(double amount, {String symbol = '\$'}) {
//     return '$symbol${amount.toStringAsFixed(2)}';
//   }
//
//   // Format number with commas
//   static String formatNumber(int number) {
//     return number.toString().replaceAllMapped(
//       RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
//       (Match match) => '${match[1]},',
//     );
//   }
//
//   // Format file size
//   static String formatFileSize(int bytes) {
//     if (bytes <= 0) return '0 B';
//     const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
//     var i = (log(bytes) / log(1024)).floor();
//     return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
//   }
//
//   // Format date
//   static String formatDate(DateTime date, {String format = 'yyyy-MM-dd'}) {
//     final year = date.year.toString();
//     final month = date.month.toString().padLeft(2, '0');
//     final day = date.day.toString().padLeft(2, '0');
//
//     return format
//         .replaceAll('yyyy', year)
//         .replaceAll('MM', month)
//         .replaceAll('dd', day);
//   }
//
//   // Format time
//   static String formatTime(DateTime time, {String format = 'HH:mm'}) {
//     final hour = time.hour.toString().padLeft(2, '0');
//     final minute = time.minute.toString().padLeft(2, '0');
//     final second = time.second.toString().padLeft(2, '0');
//
//     return format
//         .replaceAll('HH', hour)
//         .replaceAll('mm', minute)
//         .replaceAll('ss', second);
//   }
//
//   // Format date time
//   static String formatDateTime(DateTime dateTime, {String format = 'yyyy-MM-dd HH:mm'}) {
//     return formatDate(dateTime, format: format.split(' ')[0]) +
//            ' ' +
//            formatTime(dateTime, format: format.split(' ')[1]);
//   }
//
//   // Get time ago
//   static String getTimeAgo(DateTime dateTime) {
//     final now = DateTime.now();
//     final difference = now.difference(dateTime);
//
//     if (difference.inDays > 365) {
//       return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() == 1 ? '' : 's'} ago';
//     } else if (difference.inDays > 30) {
//       return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
//     } else if (difference.inDays > 0) {
//       return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
//     } else {
//       return 'Just now';
//     }
//   }
//
//   // Generate random string
//   static String generateRandomString(int length) {
//     const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
//     final random = Random();
//     return String.fromCharCodes(
//       Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
//     );
//   }
//
//   // Generate simple hash (placeholder for MD5)
//   static String generateSimpleHash(String input) {
//     return input.hashCode.toString();
//   }
//
//   // Capitalize first letter
//   static String capitalizeFirst(String text) {
//     if (text.isEmpty) return text;
//     return text[0].toUpperCase() + text.substring(1);
//   }
//
//   // Capitalize each word
//   static String capitalizeWords(String text) {
//     if (text.isEmpty) return text;
//     return text.split(' ').map((word) => capitalizeFirst(word)).join(' ');
//   }
//
//   // Truncate text
//   static String truncateText(String text, int maxLength, {String suffix = '...'}) {
//     if (text.length <= maxLength) return text;
//     return text.substring(0, maxLength - suffix.length) + suffix;
//   }
//
//   // Check if string is numeric
//   static bool isNumeric(String str) {
//     return double.tryParse(str) != null;
//   }
//
//   // Check if string is integer
//   static bool isInteger(String str) {
//     return int.tryParse(str) != null;
//   }
//
//   // Get initials from name
//   static String getInitials(String name) {
//     if (name.isEmpty) return '';
//     final words = name.trim().split(' ');
//     if (words.length == 1) {
//       return words[0][0].toUpperCase();
//     }
//     return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
//   }
//
//   // Debounce function
//   static Function debounce(Function func, Duration wait) {
//     Timer? timer;
//     return () {
//       timer?.cancel();
//       timer = Timer(wait, () => func());
//     };
//   }
//
//   // Throttle function
//   static Function throttle(Function func, Duration wait) {
//     Timer? timer;
//     bool isThrottled = false;
//     return () {
//       if (!isThrottled) {
//         func();
//         isThrottled = true;
//         timer = Timer(wait, () => isThrottled = false);
//       }
//     };
//   }
//
//   // Deep copy of map
//   static Map<String, dynamic> deepCopyMap(Map<String, dynamic> map) {
//     return json.decode(json.encode(map));
//   }
//
//   // Deep copy of list
//   static List<dynamic> deepCopyList(List<dynamic> list) {
//     return json.decode(json.encode(list));
//   }
//
//   // Check if device is connected to internet
//   static Future<bool> isConnectedToInternet() async {
//     try {
//       final result = await InternetAddress.lookup('google.com');
//       return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
//     } on SocketException catch (_) {
//       return false;
//     }
//   }
//
//   // Get device info
//   static Map<String, String> getDeviceInfo() {
//     return {
//       'platform': Platform.operatingSystem,
//       'version': Platform.operatingSystemVersion,
//       'locale': Platform.localeName,
//     };
//   }
//
//   // Validate JSON
//   static bool isValidJson(String jsonString) {
//     try {
//       json.decode(jsonString);
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   // Safe JSON decode
//   static dynamic safeJsonDecode(String jsonString) {
//     try {
//       return json.decode(jsonString);
//     } catch (e) {
//       return null;
//     }
//   }
//
//   // Safe JSON encode
//   static String? safeJsonEncode(dynamic data) {
//     try {
//       return json.encode(data);
//     } catch (e) {
//       return null;
//     }
//   }
//
//   // Check if string contains only letters
//   static bool isOnlyLetters(String str) {
//     return RegExp(r'^[a-zA-Z\s]+$').hasMatch(str);
//   }
//
//   // Check if string contains only numbers
//   static bool isOnlyNumbers(String str) {
//     return RegExp(r'^[0-9]+$').hasMatch(str);
//   }
//
//   // Check if string contains only alphanumeric
//   static bool isOnlyAlphanumeric(String str) {
//     return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(str);
//   }
//
//   // Remove special characters
//   static String removeSpecialCharacters(String str) {
//     return str.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
//   }
//
//   // Remove extra spaces
//   static String removeExtraSpaces(String str) {
//     return str.replaceAll(RegExp(r'\s+'), ' ').trim();
//   }
//
//   // Convert to camel case
//   static String toCamelCase(String str) {
//     if (str.isEmpty) return str;
//     final words = str.toLowerCase().split(' ');
//     return words[0] + words.skip(1).map((word) => capitalizeFirst(word)).join('');
//   }
//
//   // Convert to snake case
//   static String toSnakeCase(String str) {
//     return str.toLowerCase().replaceAll(' ', '_');
//   }
//
//   // Convert to kebab case
//   static String toKebabCase(String str) {
//     return str.toLowerCase().replaceAll(' ', '-');
//   }
//
//   // Convert to title case
//   static String toTitleCase(String str) {
//     if (str.isEmpty) return str;
//     return str.split(' ').map((word) => capitalizeFirst(word.toLowerCase())).join(' ');
//   }
// }