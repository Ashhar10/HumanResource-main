================================================================================
                    ELIPSE HR PORTAL - ANDROID APPLICATION
================================================================================

1. WHAT IS THIS?
----------------
This is the official native Android build of Elipse HR Portal.
It connects to the EXACT same cloud database as the Windows app and Website:
- Supabase Cloud URL: https://rbqjanevxnmllpvsssth.supabase.co
- All employee data, attendance logs, leaves, and payroll stay in sync in real time.


2. FILE OVERVIEW
----------------
- Elipse HR Portal.apk       : Ready-to-install Android application package.
- INSTALL_ON_PHONE.cmd       : Installs APK via USB directly to phone (using ADB).
- BUILD_ANDROID_APK.cmd      : One-click script to recompile APK after code changes.
- OPEN_IN_ANDROID_STUDIO.cmd : Opens project inside Android Studio.
- app/                       : Native Android source code and Gradle assets.


3. HOW TO INSTALL ON ANY ANDROID PHONE / TABLET
------------------------------------------------
METHOD A (Easiest - Send via WhatsApp / Google Drive / Email / USB):
1. Copy "Elipse HR Portal.apk" to your phone (via USB cable, WhatsApp, Google Drive, or email).
2. Open the file on your Android phone (Files / Downloads app).
3. If prompted with "For your security, your phone is not allowed to install unknown apps":
   -> Tap "Settings" -> Toggle ON "Allow from this source" -> Tap "Install".
4. The Elipse HR Portal app icon will appear on your home screen and app drawer!

METHOD B (Direct USB Install with PC):
1. Connect your Android phone to this PC with a USB cable.
2. On your phone: enable "Developer Options" -> turn ON "USB Debugging".
3. Double-click "INSTALL_ON_PHONE.cmd" in this folder.
4. The app will be automatically installed onto your phone!


4. HOW TO REBUILD THE APK (AFTER UPDATING WEB CODE)
---------------------------------------------------
1. Double-click "BUILD_ANDROID_APK.cmd".
2. The script will rebuild the web code, sync assets, compile the Android APK, 
   and replace "Elipse HR Portal.apk" with the latest version.
================================================================================
