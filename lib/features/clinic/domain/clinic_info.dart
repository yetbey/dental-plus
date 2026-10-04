class ClinicInfo {
  const ClinicInfo({this.phone = '', this.address = ''});

  final String phone;
  final String address;

  factory ClinicInfo.fromMap(Map<String, dynamic> m) => ClinicInfo(
    phone: m['phone'] as String? ?? '',
    address: m['address'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {'phone': phone, 'address': address};
}