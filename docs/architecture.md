# Architecture

The UIKit controller calls `H2ConfigManager` to save a binary plist at `/var/mobile/Library/Preferences/com.h2changer.config.plist`. It contains `schema` (integer `1`), `enabled` (boolean), and `profile` (`Test A` or `Test B`). Saving uses an atomic file write and posts `com.h2changer.config.changed`. The tweak rereads the file on each hooked API call, so it sees changes without restarting DeviceTest. Invalid or absent configuration defaults to Fake OFF.

The independent manager is the future Agent boundary. A Windows C# controller can later communicate with an on-device agent, which validates requests and writes the same schema. The current MVP has no network listener or Windows dependency.

Debug Logs reads `/var/mobile/Library/Preferences/com.h2changer.debug.log`. Logs record config changes and tweak loading, not the device's original identifier values. The filter plist and a runtime bundle check both restrict hook initialization to `com.h2phone.devicetest`.
