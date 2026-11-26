# Selected App Complete Profile Design

When Fake is ON, every selected app reads one coherent device profile across supported native APIs and its embedded `WKWebView`; selecting Safari applies the same browser profile to Safari. Profiles own device, OS, display, memory/CPU, network identity, location, battery, sensor, and browser-facing values. Unselected apps and Fake OFF retain original behavior.

The implementation extends stable Objective-C/C API hooks already used by the tweak and expands the document-start user script. It does not claim to change the kernel, modem, physical SIM, WebKit engine, TLS fingerprint, public IP, app extensions with different identities, or every private fingerprint surface.
