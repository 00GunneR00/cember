# Runs the app on a USB-connected physical phone against the local backend.
# The default API URL (10.0.2.2) only works in the Android emulator, so this forwards the
# phone's localhost ports to this PC over USB and points the app at localhost instead.
#
#   .\scripts\run_on_device.ps1              # first connected device
#   .\scripts\run_on_device.ps1 -Device R5CX82F0AJV

param([string]$Device)

$ErrorActionPreference = 'Stop'

$adbArgs = @()
if ($Device) { $adbArgs = @('-s', $Device) }

# 5080 = Cember.Api, 9000 = MinIO (photo URLs are presigned against it).
foreach ($port in 5080, 9000) {
    & adb @adbArgs reverse "tcp:$port" "tcp:$port" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "adb reverse tcp:$port failed - is the phone connected with USB debugging on?" }
}

$flutterArgs = @('run', '--dart-define=API_BASE_URL=http://localhost:5080/api/v1')

# Push notifications need the Firebase app settings; without this file the app runs with push off.
# Copy config/firebase.example.json to config/firebase.json and fill it in.
$firebaseConfig = Join-Path $PSScriptRoot '..\config\firebase.json'
if (Test-Path $firebaseConfig) { $flutterArgs += "--dart-define-from-file=$firebaseConfig" }
if ($Device) { $flutterArgs += @('-d', $Device) }

& flutter @flutterArgs
