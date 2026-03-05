// lib/widgets/phone_number_validator.dart

bool isValidIndianPhoneNumber(String phone) {
  final regExp = RegExp(r'^[6-9]\d{9}$');
  return regExp.hasMatch(phone);
}