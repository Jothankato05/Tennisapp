import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../widgets/common.dart';

/// Where the share sheet should anchor (needed on iPad).
Rect? _origin(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Opens the phone's share sheet (WhatsApp, SMS, email…). Falls back to the
/// clipboard if sharing is not available.
Future<void> shareText(BuildContext context, String text, {String? subject}) async {
  final origin = _origin(context);
  try {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject, sharePositionOrigin: origin));
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) showSnack(context, 'Copied — paste it into WhatsApp or your group chat');
  }
}

/// Writes [json] to a file and opens the share sheet so it can be saved to
/// Drive, sent on WhatsApp, etc. Falls back to copying the text.
Future<void> shareBackupFile(BuildContext context, String json) async {
  final origin = _origin(context);
  final now = DateTime.now();
  final stamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final name = 'veritas-tennis-backup-$stamp.json';
  try {
    final XFile file;
    if (kIsWeb) {
      file = XFile.fromData(utf8.encode(json), name: name, mimeType: 'application/json');
    } else {
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/$name');
      await f.writeAsString(json);
      file = XFile(f.path, mimeType: 'application/json', name: name);
    }
    await SharePlus.instance.share(
      ShareParams(files: [file], subject: 'Veritas Tennis backup ($stamp)', sharePositionOrigin: origin),
    );
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: json));
    if (context.mounted) showSnack(context, 'Backup copied as text — paste it somewhere safe');
  }
}

/// Lets the user pick a backup file; returns its text, or null if cancelled.
Future<String?> pickBackupFile() async {
  final files = await FilePicker.pickFiles(type: FileType.any, dialogTitle: 'Choose a Veritas Tennis backup');
  if (files.isEmpty) return null;
  final bytes = await files.first.readAsBytes();
  return utf8.decode(bytes, allowMalformed: true);
}

/// Converts local Nigerian numbers (0803…) to international format (234803…).
String internationalNumber(String phone) {
  var digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.startsWith('+')) return digits.substring(1);
  if (digits.startsWith('00')) return digits.substring(2);
  if (digits.startsWith('0') && digits.length == 11) return '234${digits.substring(1)}';
  return digits;
}

Future<void> callNumber(BuildContext context, String phone) async {
  final ok = await _launch(Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), '')));
  if (!ok && context.mounted) showSnack(context, 'Could not start a call on this device');
}

Future<void> openWhatsApp(BuildContext context, String phone, {String message = ''}) async {
  final uri = Uri.https('wa.me', '/${internationalNumber(phone)}', {if (message.isNotEmpty) 'text': message});
  final ok = await _launch(uri);
  if (!ok && context.mounted) showSnack(context, 'Could not open WhatsApp');
}

Future<bool> _launch(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Keeps the screen on while scoring so the phone doesn't lock between points.
void keepScreenOn(bool on) {
  // Not available in tests or on some platforms; scoring works without it.
  (on ? WakelockPlus.enable() : WakelockPlus.disable()).catchError((Object _) {});
}
