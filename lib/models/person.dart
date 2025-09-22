import 'package:flutter/foundation.dart';

/// A comprehensive Person class that represents a person entity with all necessary
/// attributes and operations. This class follows Flutter/Dart best practices
/// and provides a complete implementation for person-related functionality.
class Person with Diagnosticable {
  // Private fields with proper naming conventions
  final String _id;
  final String _firstName;
  final String _lastName;
  final String _email;
  final String _phoneNumber;
  final DateTime _dateOfBirth;
  final String _address;
  final String _nationality;
  final Gender _gender;
  final DateTime _createdAt;
  DateTime _updatedAt;
  bool _isActive;
  String? _profileImageUrl;
  String? _middleName;
  String? _occupation;
  String? _emergencyContact;

  /// Constructor with required and optional parameters
  /// 
  /// [id] - Unique identifier for the person
  /// [firstName] - Person's first name (required)
  /// [lastName] - Person's last name (required)
  /// [email] - Person's email address (required)
  /// [phoneNumber] - Person's phone number (required)
  /// [dateOfBirth] - Person's date of birth (required)
  /// [address] - Person's address (required)
  /// [nationality] - Person's nationality (required)
  /// [gender] - Person's gender (required)
  /// [middleName] - Person's middle name (optional)
  /// [profileImageUrl] - URL to person's profile image (optional)
  /// [occupation] - Person's occupation (optional)
  /// [emergencyContact] - Emergency contact information (optional)
  /// [isActive] - Whether the person is active (defaults to true)
  Person({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required DateTime dateOfBirth,
    required String address,
    required String nationality,
    required Gender gender,
    String? middleName,
    String? profileImageUrl,
    String? occupation,
    String? emergencyContact,
    bool isActive = true,
  }) : _id = id,
       _firstName = firstName,
       _lastName = lastName,
       _email = email,
       _phoneNumber = phoneNumber,
       _dateOfBirth = dateOfBirth,
       _address = address,
       _nationality = nationality,
       _gender = gender,
       _isActive = isActive,
       _profileImageUrl = profileImageUrl,
       _middleName = middleName,
       _occupation = occupation,
       _emergencyContact = emergencyContact,
       _createdAt = DateTime.now(),
       _updatedAt = DateTime.now() {
    // Validation in constructor
    _validateEmail(email);
    _validatePhoneNumber(phoneNumber);
    _validateNames(firstName, lastName);
  }

  /// Factory constructor to create Person from JSON
  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      address: json['address'] as String,
      nationality: json['nationality'] as String,
      gender: Gender.values.firstWhere(
        (g) => g.toString().split('.').last == json['gender'],
      ),
      middleName: json['middleName'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      occupation: json['occupation'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    ).._updatedAt = DateTime.parse(json['updatedAt'] as String);
  }

  /// Copy constructor for creating modified instances
  Person copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? address,
    String? nationality,
    Gender? gender,
    String? middleName,
    String? profileImageUrl,
    String? occupation,
    String? emergencyContact,
    bool? isActive,
  }) {
    return Person(
      id: _id,
      firstName: firstName ?? _firstName,
      lastName: lastName ?? _lastName,
      email: email ?? _email,
      phoneNumber: phoneNumber ?? _phoneNumber,
      dateOfBirth: dateOfBirth ?? _dateOfBirth,
      address: address ?? _address,
      nationality: nationality ?? _nationality,
      gender: gender ?? _gender,
      middleName: middleName ?? this.middleName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      occupation: occupation ?? this.occupation,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      isActive: isActive ?? _isActive,
    ).._updatedAt = DateTime.now();
  }

  // Getters with proper naming conventions
  String get id => _id;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get email => _email;
  String get phoneNumber => _phoneNumber;
  DateTime get dateOfBirth => _dateOfBirth;
  String get address => _address;
  String get nationality => _nationality;
  Gender get gender => _gender;
  DateTime get createdAt => _createdAt;
  DateTime get updatedAt => _updatedAt;
  bool get isActive => _isActive;
  String? get profileImageUrl => _profileImageUrl;
  String? get middleName => _middleName;
  String? get occupation => _occupation;
  String? get emergencyContact => _emergencyContact;

  /// Computed properties
  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$_firstName $_middleName $_lastName';
    }
    return '$_firstName $_lastName';
  }

  String get initials {
    String firstInitial = _firstName.isNotEmpty ? _firstName[0].toUpperCase() : '';
    String lastInitial = _lastName.isNotEmpty ? _lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  int get age {
    final now = DateTime.now();
    int age = now.year - _dateOfBirth.year;
    if (now.month < _dateOfBirth.month || 
        (now.month == _dateOfBirth.month && now.day < _dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  bool get isAdult => age >= 18;
  bool get isMinor => age < 18;
  bool get isSenior => age >= 65;

  /// Business logic methods
  
  /// Updates the person's profile image URL
  void updateProfileImage(String? imageUrl) {
    _profileImageUrl = imageUrl;
    _updatedAt = DateTime.now();
  }

  /// Updates the person's occupation
  void updateOccupation(String? newOccupation) {
    _occupation = newOccupation;
    _updatedAt = DateTime.now();
  }

  /// Updates the person's emergency contact
  void updateEmergencyContact(String? contact) {
    _emergencyContact = contact;
    _updatedAt = DateTime.now();
  }

  /// Activates the person
  void activate() {
    _isActive = true;
    _updatedAt = DateTime.now();
  }

  /// Deactivates the person
  void deactivate() {
    _isActive = false;
    _updatedAt = DateTime.now();
  }

  /// Checks if the person's birthday is today
  bool get isBirthdayToday {
    final now = DateTime.now();
    return now.month == _dateOfBirth.month && now.day == _dateOfBirth.day;
  }

  /// Gets the number of days until the person's next birthday
  int get daysUntilBirthday {
    final now = DateTime.now();
    final thisYearBirthday = DateTime(now.year, _dateOfBirth.month, _dateOfBirth.day);
    
    if (thisYearBirthday.isAfter(now)) {
      return thisYearBirthday.difference(now).inDays;
    } else {
      final nextYearBirthday = DateTime(now.year + 1, _dateOfBirth.month, _dateOfBirth.day);
      return nextYearBirthday.difference(now).inDays;
    }
  }

  /// Validation methods
  void _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      throw ArgumentError('Invalid email format: $email');
    }
  }

  void _validatePhoneNumber(String phoneNumber) {
    final phoneRegex = RegExp(r'^[\+]?[1-9][\d]{1,14}$');
    if (!phoneRegex.hasMatch(phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      throw ArgumentError('Invalid phone number format: $phoneNumber');
    }
  }

  void _validateNames(String firstName, String lastName) {
    if (firstName.trim().isEmpty) {
      throw ArgumentError('First name cannot be empty');
    }
    if (lastName.trim().isEmpty) {
      throw ArgumentError('Last name cannot be empty');
    }
  }

  /// Utility methods
  
  /// Converts the person to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'firstName': _firstName,
      'lastName': _lastName,
      'middleName': middleName,
      'email': _email,
      'phoneNumber': _phoneNumber,
      'dateOfBirth': _dateOfBirth.toIso8601String(),
      'address': _address,
      'nationality': _nationality,
      'gender': _gender.toString().split('.').last,
      'profileImageUrl': _profileImageUrl,
      'occupation': occupation,
      'emergencyContact': emergencyContact,
      'isActive': _isActive,
      'createdAt': _createdAt.toIso8601String(),
      'updatedAt': _updatedAt.toIso8601String(),
      'age': age,
      'fullName': fullName,
      'initials': initials,
    };
  }

  /// Returns a formatted string representation of the person
  String toStringSimple() {
    return 'Person(id: $_id, name: $fullName, email: $_email, age: $age, active: $_isActive)';
  }

  /// Equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Person && other._id == _id;
  }

  /// Hash code
  @override
  int get hashCode => _id.hashCode;

  /// Debug information
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties.add(StringProperty('id', _id));
    properties.add(StringProperty('fullName', fullName));
    properties.add(StringProperty('email', _email));
    properties.add(IntProperty('age', age));
    properties.add(FlagProperty('isActive', value: _isActive, ifTrue: 'active', ifFalse: 'inactive'));
    properties.add(DiagnosticsProperty<Gender>('gender', _gender));
    properties.add(StringProperty('nationality', _nationality));
  }
}

/// Enum for gender options
enum Gender {
  male,
  female,
  other,
  preferNotToSay;

  /// Returns a human-readable string for the gender
  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case Gender.preferNotToSay:
        return 'Prefer not to say';
    }
  }
}

/// Extension methods for Person class
extension PersonExtensions on Person {
  /// Checks if the person is from a specific country
  bool isFromCountry(String country) {
    return nationality.toLowerCase() == country.toLowerCase();
  }

  /// Gets a greeting message for the person
  String getGreeting([String timeOfDay = 'day']) {
    String greeting;
    switch (timeOfDay.toLowerCase()) {
      case 'morning':
        greeting = 'Good morning';
        break;
      case 'afternoon':
        greeting = 'Good afternoon';
        break;
      case 'evening':
        greeting = 'Good evening';
        break;
      default:
        greeting = 'Hello';
    }
    return '$greeting, $firstName!';
  }

  /// Checks if the person can vote (assuming voting age is 18)
  bool get canVote => isAdult;

  /// Checks if the person needs parental consent (for minors)
  bool get needsParentalConsent => isMinor;
}

/// Utility class for Person-related operations
class PersonUtils {
  /// Creates a list of sample persons for testing
  static List<Person> createSamplePersons() {
    return [
      Person(
        id: '1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        phoneNumber: '+1234567890',
        dateOfBirth: DateTime(1990, 5, 15),
        address: '123 Main St, City, Country',
        nationality: 'American',
        gender: Gender.male,
        occupation: 'Software Engineer',
      ),
      Person(
        id: '2',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane.smith@example.com',
        phoneNumber: '+1987654321',
        dateOfBirth: DateTime(1985, 8, 22),
        address: '456 Oak Ave, City, Country',
        nationality: 'Canadian',
        gender: Gender.female,
        middleName: 'Marie',
        occupation: 'Doctor',
      ),
    ];
  }

  /// Sorts persons by age (ascending)
  static List<Person> sortByAge(List<Person> persons, {bool ascending = true}) {
    final sorted = List<Person>.from(persons);
    sorted.sort((a, b) => ascending ? a.age.compareTo(b.age) : b.age.compareTo(a.age));
    return sorted;
  }

  /// Filters persons by age range
  static List<Person> filterByAgeRange(List<Person> persons, int minAge, int maxAge) {
    return persons.where((person) => person.age >= minAge && person.age <= maxAge).toList();
  }

  /// Groups persons by nationality
  static Map<String, List<Person>> groupByNationality(List<Person> persons) {
    final Map<String, List<Person>> grouped = {};
    for (final person in persons) {
      grouped.putIfAbsent(person.nationality, () => []).add(person);
    }
    return grouped;
  }
}