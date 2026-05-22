import 'package:flutter/material.dart';

class CategoryIconHelper {
  static const Map<String, IconData> iconMap = {
    'flight': Icons.flight,
    'church': Icons.church,
    'people_outline': Icons.people_outline,
    'computer': Icons.computer,
    'security': Icons.security,
    'campaign': Icons.campaign,
    'map': Icons.map,
    'business_center': Icons.business_center,
    'face': Icons.face,
    'pregnant_woman': Icons.pregnant_woman,
    'volunteer_activism': Icons.volunteer_activism,
    'groups': Icons.groups,
    'restaurant': Icons.restaurant,
    'hotel': Icons.hotel,
    'swap_horiz': Icons.swap_horiz,
    'local_cafe': Icons.local_cafe,
    'description': Icons.description,
    'card_giftcard': Icons.card_giftcard,
    'phone_android': Icons.phone_android,
    'print': Icons.print,
    'more_horiz': Icons.more_horiz,
    'payments': Icons.payments,
    'monetization_on': Icons.monetization_on,
    'settings_backup_restore': Icons.settings_backup_restore,
    'shopping_cart': Icons.shopping_cart,
    'work': Icons.work,
    'school': Icons.school,
    'build': Icons.build,
    'directions_car': Icons.directions_car,
    'medical_services': Icons.medical_services,
    'house': Icons.house,
    'movie': Icons.movie,
    'sports_esports': Icons.sports_esports,
    'fitness_center': Icons.fitness_center,
    'pets': Icons.pets,
  };

  static IconData getIcon(String? name) {
    if (name == null) return Icons.category;
    return iconMap[name] ?? Icons.category;
  }
}
