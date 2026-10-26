/// Install-as-app helpers for the web build. On Android/iOS builds these are
/// no-ops.
library;

export 'pwa_stub.dart' if (dart.library.js_interop) 'pwa_web.dart';
