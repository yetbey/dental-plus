import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> callPhone(BuildContext context, String phone) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri(scheme: 'tel', path: phone));
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Arama başlatılamadı. Numara: $phone')));
  }
}