String? normalizeTrPhone(String input) {
  var d = input.replaceAll(RegExp(r'\D'), '');
  if (d.startsWith('90') && d.length == 12) d = d.substring(2);
  if (d.startsWith('0') && d.length == 11) d = d.substring(1);
  if (d.length == 10 && d.startsWith('5')) return '+90$d';
  return null;
}

String formatTrPhone(String phone) {
  final n = normalizeTrPhone(phone);
  if (n == null) return phone;
  final d = n.substring(3);
  return '0 (${d.substring(0, 3)}) ${d.substring(3, 6)} ${d.substring(6, 8)} ${d.substring(8, 10)}';
}