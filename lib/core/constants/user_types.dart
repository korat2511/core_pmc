class UserTypes {
  static const Map<int, String> userType = {
    1: "Project Coordinator",
    2: "Senior Executive", 
    3: "Supervisor",
    4: "Site Executive",
    5: "Owner",
    6: "Agency",
    7: "Design Team",
    8: "Vendor",
  };

  static String getUserTypeName(int? userTypeId) {
    return userType[userTypeId] ?? "Unknown";
  }
} 