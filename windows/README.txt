================================================================================
                    ELIPSE HR PORTAL - WINDOWS EDITION
================================================================================

All Windows executables, launchers, installers, and automation tools are
organized in this folder.

--------------------------------------------------------------------------------
1. APPLICATION EXECUTABLES & LAUNCHERS
--------------------------------------------------------------------------------
* Elipse HR Portal.exe
  - Standalone portable desktop application. Double-click to run anywhere.

* Elipse HR Portal Setup.exe
  - Full Windows installer that creates Desktop and Start Menu shortcuts.

* START_HR_PORTAL.cmd
  - One-click launcher script to immediately start the desktop application.

* BUILD_WINDOWS_EXE.cmd
  - Re-compiles the frontend and builds updated .exe files whenever you modify code.

* LAUNCH_DESKTOP_APP.cmd
  - Runs the desktop application in developer mode directly from source.

--------------------------------------------------------------------------------
2. HARDWARE ATTENDANCE SYNC & BACKUPS
--------------------------------------------------------------------------------
* START_ZK_SYNC_AGENT.cmd
  - Manually starts the ZKTeco K40 attendance machine LAN synchronization daemon.

* run_zk_sync_hidden.vbs
  - Runs the sync agent silently in the background (no black CMD window).

* RUN_DATABASE_BACKUP.cmd
  - Manually executes a complete snapshot backup of all Supabase database tables.

--------------------------------------------------------------------------------
3. STANDALONE DISTRIBUTION PACKAGE
--------------------------------------------------------------------------------
* Standalone-Package/
  - A clean, self-contained distribution folder containing the standalone .exe,
    hardware agent, database setup script, and .env configuration.
  - You can copy this folder to any computer or flash drive.
================================================================================
