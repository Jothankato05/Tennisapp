import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

@JS('vtInstallPrompt')
external JSAny? get _installPrompt;

@JS('vtPromptInstall')
external JSPromise<JSBoolean> _promptInstall();

bool get _standalone {
  if (web.window.matchMedia('(display-mode: standalone)').matches) return true;
  // iOS Safari reports home-screen launches through navigator.standalone.
  final standalone = (web.window.navigator as JSObject).getProperty<JSAny?>('standalone'.toJS);
  return standalone.isA<JSBoolean>() && (standalone as JSBoolean).toDart;
}

bool get isIosBrowser {
  final ua = web.window.navigator.userAgent.toLowerCase();
  return ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
}

/// Offer installing when running in a browser tab (not already installed) and
/// either the browser has an install prompt ready or it is iOS Safari.
bool get canOfferInstall => !_standalone && (_installPrompt != null || isIosBrowser);

Future<bool> promptInstall() async {
  try {
    return (await _promptInstall().toDart).toDart;
  } catch (_) {
    return false;
  }
}
