class User {
  final String email;
  final String fullName;

  User({
    required this.email,
    required this.fullName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'],
      fullName: json['fullName'],
    );
  }
}
