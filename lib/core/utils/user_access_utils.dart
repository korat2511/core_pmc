// class UserAccessUtils {
//   // Email validation
//   static bool isValidEmail(String email) {
//     final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
//     return emailRegex.hasMatch(email);
//   }
//
//   // Password validation
//   static bool isValidPassword(String password) {
//     // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
//     final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$');
//     return passwordRegex.hasMatch(password);
//   }
//
//   // Phone number validation
//   static bool isValidPhoneNumber(String phone) {
//     // Basic phone validation - can be customized based on requirements
//     final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
//     return phoneRegex.hasMatch(phone);
//   }
//
//   // Username validation
//   static bool isValidUsername(String username) {
//     // 3-20 characters, alphanumeric and underscore only
//     final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
//     return usernameRegex.hasMatch(username);
//   }
//
//   // Name validation
//   static bool isValidName(String name) {
//     // 2-50 characters, letters and spaces only
//     final nameRegex = RegExp(r'^[a-zA-Z\s]{2,50}$');
//     return nameRegex.hasMatch(name);
//   }
//
//   // URL validation
//   static bool isValidUrl(String url) {
//     try {
//       final uri = Uri.parse(url);
//       return uri.hasScheme && uri.hasAuthority;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   // Credit card validation (Luhn algorithm)
//   static bool isValidCreditCard(String cardNumber) {
//     // Remove spaces and dashes
//     final cleanNumber = cardNumber.replaceAll(RegExp(r'[\s\-]'), '');
//
//     if (cleanNumber.length < 13 || cleanNumber.length > 19) {
//       return false;
//     }
//
//     int sum = 0;
//     bool isEven = false;
//
//     // Loop through values starting from the rightmost side
//     for (int i = cleanNumber.length - 1; i >= 0; i--) {
//       int digit = int.parse(cleanNumber[i]);
//
//       if (isEven) {
//         digit *= 2;
//         if (digit > 9) {
//           digit -= 9;
//         }
//       }
//
//       sum += digit;
//       isEven = !isEven;
//     }
//
//     return sum % 10 == 0;
//   }
//
//   // Age validation
//   static bool isValidAge(int age) {
//     return age >= 0 && age <= 150;
//   }
//
//   // Date validation
//   static bool isValidDate(String date) {
//     try {
//       DateTime.parse(date);
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   // Future date validation
//   static bool isFutureDate(String date) {
//     try {
//       final parsedDate = DateTime.parse(date);
//       return parsedDate.isAfter(DateTime.now());
//     } catch (e) {
//       return false;
//     }
//   }
//
//   // Past date validation
//   static bool isPastDate(String date) {
//     try {
//       final parsedDate = DateTime.parse(date);
//       return parsedDate.isBefore(DateTime.now());
//     } catch (e) {
//       return false;
//     }
//   }
//
//   // Minimum age validation
//   static bool isMinimumAge(String birthDate, int minimumAge) {
//     try {
//       final birth = DateTime.parse(birthDate);
//       final now = DateTime.now();
//       final age = now.year - birth.year - (now.month < birth.month || (now.month == birth.month && now.day < birth.day) ? 1 : 0);
//       return age >= minimumAge;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   // File size validation (in bytes)
//   static bool isValidFileSize(int fileSizeInBytes, int maxSizeInMB) {
//     final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
//     return fileSizeInBytes <= maxSizeInBytes;
//   }
//
//   // File extension validation
//   static bool isValidFileExtension(String fileName, List<String> allowedExtensions) {
//     final extension = fileName.split('.').last.toLowerCase();
//     return allowedExtensions.contains(extension);
//   }
//
//   // Strong password validation with custom requirements
//   static Map<String, bool> validatePasswordStrength(String password) {
//     final hasMinLength = password.length >= 8;
//     final hasUppercase = password.contains(RegExp(r'[A-Z]'));
//     final hasLowercase = password.contains(RegExp(r'[a-z]'));
//     final hasNumbers = password.contains(RegExp(r'[0-9]'));
//     final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
//
//     return {
//       'minLength': hasMinLength,
//       'uppercase': hasUppercase,
//       'lowercase': hasLowercase,
//       'numbers': hasNumbers,
//       'specialChar': hasSpecialChar,
//     };
//   }
//
//   // Get password strength score (0-4)
//   static int getPasswordStrengthScore(String password) {
//     final requirements = validatePasswordStrength(password);
//     int score = 0;
//
//     if (requirements['minLength']!) score++;
//     if (requirements['uppercase']!) score++;
//     if (requirements['lowercase']!) score++;
//     if (requirements['numbers']!) score++;
//     if (requirements['specialChar']!) score++;
//
//     return score;
//   }
//
//   // Get password strength text
//   static String getPasswordStrengthText(String password) {
//     final score = getPasswordStrengthScore(password);
//
//     switch (score) {
//       case 0:
//       case 1:
//         return 'Very Weak';
//       case 2:
//         return 'Weak';
//       case 3:
//         return 'Medium';
//       case 4:
//         return 'Strong';
//       case 5:
//         return 'Very Strong';
//       default:
//         return 'Very Weak';
//     }
//   }
//
//   // Validate required fields
//   static Map<String, bool> validateRequiredFields(Map<String, String> fields) {
//     final Map<String, bool> results = {};
//
//     for (final entry in fields.entries) {
//       results[entry.key] = entry.value.trim().isNotEmpty;
//     }
//
//     return results;
//   }
//
//   // Check if all required fields are filled
//   static bool areAllRequiredFieldsFilled(Map<String, String> fields) {
//     return fields.values.every((value) => value.trim().isNotEmpty);
//   }
//
//   // Get validation error message
//   static String getValidationErrorMessage(String fieldName, String validationType) {
//     switch (validationType) {
//       case 'email':
//         return 'Please enter a valid email address';
//       case 'password':
//         return 'Password must be at least 8 characters with uppercase, lowercase, and number';
//       case 'phone':
//         return 'Please enter a valid phone number';
//       case 'username':
//         return 'Username must be 3-20 characters, alphanumeric and underscore only';
//       case 'name':
//         return 'Name must be 2-50 characters, letters and spaces only';
//       case 'required':
//         return '$fieldName is required';
//       case 'minLength':
//         return '$fieldName must be at least the minimum length';
//       case 'maxLength':
//         return '$fieldName must not exceed the maximum length';
//       default:
//         return 'Please enter a valid $fieldName';
//     }
//   }
// }