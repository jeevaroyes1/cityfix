class ChatbotService {
  // Default replies mapped by keywords — no API key needed!
  static const Map<String, String> _defaultReplies = {
    // --- Report Issues ---
    'report an issue':
        'To report an issue:\n1. Go to the Home screen\n2. Tap "Report Issue"\n3. Select the category and subcategory\n4. Add a photo, description, and location\n5. Submit your report!\nYou\'ll receive updates as the status changes.',
    'track my reported issues':
        'To track your reported issues:\n1. Go to your Profile page\n2. Tap "My Reports"\nYou can see the current status (Pending, In Progress, or Completed) for each issue you\'ve submitted.',
    'categories of issues':
        'You can report issues under these categories:\n• Sanitation & Environment (Garbage, Drainage, etc.)\n• Roads & Infrastructure (Potholes, Street Lights, etc.)\n• Water Supply\n• Public Safety\n• Others\nEach category has specific subcategories to choose from.',
    'resolve an issue':
        'Resolution time depends on the issue type and priority. Typically:\n• Minor issues: 3–7 days\n• Major infrastructure: 2–4 weeks\nYou can track progress in "My Reports" on your profile page.',

    // --- Lost & Found ---
    'report a lost item':
        'To report a lost item:\n1. Go to "Lost & Found" from the home screen\n2. Tap the "+" button\n3. Select "Lost Item"\n4. Fill in the item details, date lost, and your contact info\n5. Upload a photo if available\n6. Submit!\nOther users will be able to see your listing.',
    'report a found item':
        'To report a found item:\n1. Go to "Lost & Found" from the home screen\n2. Tap the "+" button\n3. Select "Found Item"\n4. Fill in the item details, date found, and where you found it\n5. Upload a photo\n6. Submit!\nThe owner can then contact you.',
    'search for my lost item':
        'To search for your lost item:\n1. Go to "Lost & Found"\n2. Browse through the "Found Items" tab\n3. Use the search bar to filter by keywords\nIf someone found your item, their contact info will be listed.',

    // --- Community Hub ---
    'create a community post':
        'To create a community post:\n1. Go to "Community Hub"\n2. Tap the "+" or "Create Post" button\n3. Write your message and optionally attach an image\n4. Submit your post!\nIt will be visible to other users in your area.',
    'like or comment':
        'To interact with community posts:\n• Tap the ❤️ icon to like a post\n• Tap the 💬 comment icon to leave a comment\nYour engagement helps build the community!',
    'community guidelines':
        'Community guidelines:\n• Be respectful and courteous\n• No hate speech or harassment\n• No spam or promotional content\n• Keep posts relevant to your local community\n• Report inappropriate content using the flag icon\nViolations may result in post removal or account restrictions.',

    // --- Volunteering ---
    'sign up for volunteering':
        'To sign up for volunteering:\n1. Go to "Volunteering" from the home screen\n2. Browse available volunteer events\n3. Tap on an event to see details\n4. Tap "Join Event" to register\nYou\'ll receive a confirmation and reminders before the event.',
    'volunteer events':
        'To see available volunteer events:\n1. Go to "Volunteering" from the home screen\n2. Browse the list of upcoming events\nEvents include community clean-ups, tree planting, awareness drives, and more!',
    'create a volunteer event':
        'To create a volunteer event:\n1. Go to "Volunteering"\n2. Tap "Create Event"\n3. Fill in the event name, date, time, location, and description\n4. Set the maximum number of volunteers\n5. Submit!\nOther users can then join your event.',

    // --- Donations ---
    'donate to welfare':
        'To donate to welfare:\n1. Go to "Donate to Welfare" from the home screen\n2. Choose a cause or organization\n3. Enter the donation amount\n4. Complete the payment\nYour contribution helps community welfare programs!',
    'payment methods':
        'CityFix supports the following payment methods for donations:\n• UPI (Google Pay, PhonePe, etc.)\n• Credit/Debit Cards\n• Net Banking\nAll transactions are secure and encrypted.',
    'tax deductible':
        'Tax deductibility depends on the organization you\'re donating to. Some registered NGOs offer tax-deductible receipts under Section 80G. Please check with the specific organization for details.',

    // --- Helpline ---
    'emergency numbers':
        'Here are important emergency numbers:\n• Police: 100\n• Fire: 101\n• Ambulance: 102 / 108\n• Women Helpline: 181\n• Child Helpline: 1098\n• Disaster Management: 1078\nYou can also find these in the "Helpline" section of the app.',
    'contact municipal':
        'To contact municipal authorities:\n1. Go to "Helpline" from the home screen\n2. Find the relevant municipal office contact\n3. Tap the number to call directly\nYou can also report issues through the app for a faster response.',
    'customer support':
        'To reach CityFix customer support:\n• Use this AI Assistant chat\n• Email: support@cityfix.app\n• Visit the "Helpline" section for more contacts\nWe\'re here to help!',

    // --- News & Updates ---
    'news updates':
        'To find local news updates:\n1. Go to "News & Updates" from the home screen\n2. Browse the latest articles\nStay informed about local developments, events, and announcements!',
    'news articles sourced':
        'News articles in CityFix are sourced from:\n• Local municipal announcements\n• Community-submitted news\n• Verified local news sources\nAll articles are reviewed before publishing.',

    // --- Account & General ---
    'update my profile':
        'To update your profile:\n1. Tap your profile icon (top-right)\n2. Tap "Edit Profile"\n3. Update your name, phone, email, or profile picture\n4. Save your changes\nKeep your profile updated for the best experience!',
    'change my panchayat':
        'To change your panchayat or ward:\n1. Go to your Profile\n2. Tap "Edit Profile"\n3. Update the Panchayat and Ward fields\n4. Save your changes\nThis ensures you see issues and updates relevant to your area.',
    'what is cityfix':
        'CityFix is a community-driven civic engagement platform that helps citizens:\n• Report and track local issues\n• Connect with their community\n• Volunteer for local causes\n• Stay updated with local news\n• Access emergency helpline numbers\n• Participate in Lost & Found\n\nOur goal is to make your neighborhood better, together! 🏘️',
  };

  // General fallback reply
  static const String _fallbackReply =
      'I\'m sorry, I don\'t have a specific answer for that. Here are some things I can help you with:\n\n'
      '📋 Report Issues — how to report & track issues\n'
      '🔍 Lost & Found — report or search items\n'
      '👥 Community Hub — posts & guidelines\n'
      '🤝 Volunteering — events & sign-ups\n'
      '💰 Donations — how to donate\n'
      '📞 Helpline — emergency numbers\n'
      '📰 News & Updates — local news\n'
      '⚙️ Account — profile & settings\n\n'
      'Try asking about any of the topics above!';

  Future<String> sendMessage(String text) async {
    final query = text.toLowerCase().trim();

    // Try to find a matching default reply by keyword
    for (final entry in _defaultReplies.entries) {
      if (query.contains(entry.key)) {
        return entry.value;
      }
    }

    // Fuzzy matching: check if any keyword words are mostly present in the query
    String? bestMatch;
    int bestScore = 0;

    for (final entry in _defaultReplies.entries) {
      final keywords = entry.key.split(' ');
      final matchCount = keywords.where((kw) => query.contains(kw)).length;
      if (matchCount > bestScore && matchCount >= (keywords.length * 0.5).ceil()) {
        bestScore = matchCount;
        bestMatch = entry.value;
      }
    }

    if (bestMatch != null) {
      return bestMatch;
    }

    return _fallbackReply;
  }
}
