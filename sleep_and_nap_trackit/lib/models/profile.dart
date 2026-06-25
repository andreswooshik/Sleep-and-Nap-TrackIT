class Profile {
  const Profile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleInitial,
    required this.dateOfBirth,
    required this.usualBedtime,
    required this.usualWakeUpTime,
    this.gender,
    this.sleepGoalHours = 8,
    this.napHabit = 'Sometimes',
    this.notificationsEnabled = true,
    this.createdAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? middleInitial;
  final DateTime dateOfBirth;
  final String usualBedtime;
  final String usualWakeUpTime;
  final String? gender;
  final int sleepGoalHours;
  final String napHabit;
  final bool notificationsEnabled;
  final DateTime? createdAt;

  String get fullName {
    final mi = middleInitial != null && middleInitial!.isNotEmpty
        ? ' $middleInitial.'
        : '';
    return '$lastName, $firstName$mi';
  }

  Profile copyWith({
    String? gender,
    int? sleepGoalHours,
    String? napHabit,
    bool? notificationsEnabled,
  }) {
    return Profile(
      id: id,
      firstName: firstName,
      lastName: lastName,
      middleInitial: middleInitial,
      dateOfBirth: dateOfBirth,
      usualBedtime: usualBedtime,
      usualWakeUpTime: usualWakeUpTime,
      gender: gender ?? this.gender,
      sleepGoalHours: sleepGoalHours ?? this.sleepGoalHours,
      napHabit: napHabit ?? this.napHabit,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'middle_initial': middleInitial,
        'date_of_birth': '${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}',
        'usual_bedtime': usualBedtime,
        'usual_wake_up_time': usualWakeUpTime,
        'gender': gender,
        'sleep_goal_hours': sleepGoalHours,
        'nap_habit': napHabit,
        'notifications_enabled': notificationsEnabled,
      };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        middleInitial: json['middle_initial'] as String?,
        dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
        usualBedtime: json['usual_bedtime'] as String,
        usualWakeUpTime: json['usual_wake_up_time'] as String,
        gender: json['gender'] as String?,
        sleepGoalHours: json['sleep_goal_hours'] as int? ?? 8,
        napHabit: json['nap_habit'] as String? ?? 'Sometimes',
        notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );
}
