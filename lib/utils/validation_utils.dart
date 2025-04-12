class ValidationUtils {
  // Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email address';
    }
    
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  // Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
  
  // Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    
    return null;
  }
  
  // Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }
    
    final phoneRegExp = RegExp(r'^\(\d{3}\) \d{3}-\d{4}$|^\d{10}$');
    if (!phoneRegExp.hasMatch(value.replaceAll(RegExp(r'\D'), ''))) {
      return 'Please enter a valid 10-digit phone number';
    }
    
    return null;
  }
  
  // Validate ZIP code
  static String? validateZipCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a ZIP code';
    }
    
    if (value.length != 5 || int.tryParse(value) == null) {
      return 'Please enter a valid 5-digit ZIP code';
    }
    
    return null;
  }
  
  // Validate credit card number
  static String? validateCreditCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a card number';
    }
    
    String digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 13 || digitsOnly.length > 19) {
      return 'Card number must be between 13-19 digits';
    }
    
    return null;
  }
  
  // Validate expiry date MM/YY
  static String? validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter expiry date';
    }
    
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Use format MM/YY';
    }
    
    try {
      final parts = value.split('/');
      final month = int.parse(parts[0]);
      final year = int.parse('20${parts[1]}');
      
      final now = DateTime.now();
      final expiryDate = DateTime(year, month + 1, 0);
      
      if (month < 1 || month > 12) {
        return 'Invalid month';
      }
      
      if (expiryDate.isBefore(now)) {
        return 'Card has expired';
      }
    } catch (e) {
      return 'Invalid date format';
    }
    
    return null;
  }
  
  // Validate CVV
  static String? validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter CVV';
    }
    
    if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
      return 'CVV must be 3-4 digits';
    }
    
    return null;
  }
}