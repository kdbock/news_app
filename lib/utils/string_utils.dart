class StringUtils {
  // Remove HTML tags from a string
  static String stripHtml(String htmlString) {
    final RegExp htmlRegExp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(htmlRegExp, '');
  }
  
  // Truncate a string to a specific length with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  // Convert a string to title case
  static String toTitleCase(String text) {
    if (text.isEmpty) return '';
    
    final List<String> words = text.toLowerCase().split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    });
    
    return capitalizedWords.join(' ');
  }
  
  // Get initials from name
  static String getInitials(String fullName) {
    if (fullName.isEmpty) return '';
    
    List<String> names = fullName.trim().split(' ');
    String initials = '';
    
    if (names.isNotEmpty) {
      initials += names[0][0];
    }
    
    if (names.length > 1) {
      initials += names[names.length - 1][0];
    }
    
    return initials.toUpperCase();
  }
  
  // Check if a string is a valid email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  // Format phone number as (XXX) XXX-XXXX
  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digits
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    // Return formatted string if we have exactly 10 digits
    if (digitsOnly.length == 10) {
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    }
    
    // Otherwise return the original
    return phoneNumber;
  }
}