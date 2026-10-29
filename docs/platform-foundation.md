# Platform startup foundation

Main berisi core-api, core-starter, core-ui, platform-app, dan plugins/legacy_epc.
Paket auth/business_context/attendance beserta wiring-nya berada di CR.

Platform memiliki bootstrap, StartupGate, shared services, MaterialApp,
navigator/theme/localization, dan generic AppEntryPage/PluginRouteBridge.
Firebase/native service diinisialisasi satu kali dan didispose oleh platform;
soft restart mempertahankan service yang sama.

LegacyEpcModule menyediakan AuthRestorer melalui public integration surface.
Restore membaca installed company/session, memakai repository existing untuk
user/license/parameter/device/manager, lalu memilih legacy verification/Home.
FCM registration bersifat best effort. Restore yang ditinggalkan tidak boleh
memasang context kembali setelah module didispose. Legacy juga mengekspos typed
BusinessContextProvider untuk pemanggil baru tanpa membuka Config kepada core.

HTTP/session/storage/runtime berada di core-starter. Generic request data
adapters juga ada di core-starter. Request controllers, localization, workspace,
filter/sort/summary container, form/detail, selection/bulk dan picker ada di
core-ui. Plugin baru mengonsumsi fondasi ini dari CR.

Gunakan `bash tool/verify.sh --format --apk` untuk format, architecture/analyzer,
test dan build Android debug. Existing legacy lint debt dipisahkan dari analisis
kode modular. Device dan release validation mengikuti integration runbook.
