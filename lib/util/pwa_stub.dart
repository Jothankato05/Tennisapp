/// Native builds are already installed apps.
bool get canOfferInstall => false;

/// True on iPhone/iPad Safari, where installing is done from the Share menu.
bool get isIosBrowser => false;

/// Shows the browser's install prompt. Returns true if the user installed.
Future<bool> promptInstall() async => false;
