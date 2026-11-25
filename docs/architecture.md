# Architecture

The UIKit controller calls `H2ConfigManager` to save a binary plist at `/var/mobile/Library/Preferences/com.h2changer.config.plist`. It contains `schema` (integer `1`), `enabled` (boolean), `profile` (`Test A` or `Test B`), and `enabledApps` (bundle ID array). Saving uses an atomic file write and posts `com.h2changer.config.changed`. The tweak rereads the file on each hooked API call. Invalid or absent configuration defaults to Fake OFF and DeviceTest as the selected app.

The independent manager is the future Agent boundary. A Windows C# controller can later communicate with an on-device agent, which validates requests and writes the same schema. The current MVP has no network listener or Windows dependency.

Debug Logs reads `/var/mobile/Library/Preferences/com.h2changer.debug.log`. Logs record config changes, not the device's original identifier values. The filter plist loads in UIKit apps; the runtime guard returns fake values only when global Fake is ON and the current bundle ID is in `enabledApps`. Apple system apps and H2Changer itself always return original values.
