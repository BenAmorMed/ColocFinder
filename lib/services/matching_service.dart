import '../models/user_model.dart';
import '../config/constants.dart';

class MatchingService {
  // Calculate compatibility score as a percentage (0-100)
  static int calculateMatchingScore(UserModel user1, UserModel user2) {
    if (user1.lifestylePreferences.isEmpty || user2.lifestylePreferences.isEmpty) {
      return 0;
    }

    int matches = 0;
    int totalCriteria = AppConstants.lifestylePreferences.length;

    user1.lifestylePreferences.forEach((key, value) {
      if (user2.lifestylePreferences.containsKey(key)) {
        if (user2.lifestylePreferences[key] == value) {
          matches++;
        }
      }
    });

    return ((matches / totalCriteria) * 100).round();
  }

  // Get compatibility label based on score
  static String getMatchingLabel(int score) {
    if (score >= 80) return 'Excellent Match';
    if (score >= 60) return 'Good Match';
    if (score >= 40) return 'Fair Match';
    return 'Low Compatibility';
  }
}
