import 'package:flutter/material.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/utils/custom_dialog.dart';
import 'package:temulapak_app/utils/logger.dart';

class LiveTrackingDialog {
  static bool _isShowingErrorDialog = false;

  /// Show confirmation dialog for enabling live tracking
  static Future<bool?> showEnableDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: "Aktifkan Live Tracking?",
          content:
              "Fitur ini akan terus memperbarui lokasi toko Anda secara otomatis setiap 20 meter perpindahan.\n\n"
              "⚠️ PERHATIAN:\n"
              "• Akan menggunakan GPS secara berkelanjutan\n"
              "• Dapat menguras baterai lebih cepat\n"
              "• Membutuhkan koneksi internet\n"
              "• Otomatis nonaktif saat aplikasi ditutup\n\n"
              "Pastikan perangkat Anda memiliki daya baterai yang cukup.",
          confirmText: "Aktifkan",
          cancelText: "Batal",
          icon: Icons.gps_fixed,
          iconColor: Colors.white,
          dialogColor: MyColor.orange,
          onConfirm: () {
            Navigator.of(context).pop(true);
          },
          onCancel: () {
            Navigator.of(context).pop(false);
          },
        );
      },
    );
  }

  /// Show confirmation dialog for disabling live tracking
  static Future<bool?> showDisableDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: "Nonaktifkan Live Tracking?",
          content: "Lokasi toko Anda tidak akan diperbarui secara otomatis.\n\n"
              "Pelanggan mungkin kesulitan menemukan lokasi terkini Anda jika Anda sering berpindah tempat.\n\n"
              "Anda masih bisa memperbarui lokasi secara manual kapan saja.",
          confirmText: "Nonaktifkan",
          cancelText: "Batal",
          icon: Icons.gps_off,
          iconColor: Colors.white,
          dialogColor: MyColor.red,
          onConfirm: () {
            Navigator.of(context).pop(true);
          },
          onCancel: () {
            Navigator.of(context).pop(false);
          },
        );
      },
    );
  }

  static Future<void> showErrorDialog(BuildContext context, String error) {
  // Safety check to prevent multiple dialogs
  if (_isShowingErrorDialog) {
    Logger.log("Error dialog already showing, ignoring new request");
    return Future.value();
  }

  _isShowingErrorDialog = true;
  Logger.log("Showing live tracking error dialog: $error");

  return showDialog(
    context: context,
    barrierDismissible: true,  // Keep this true to allow tapping outside
    barrierColor: Colors.black54,
    builder: (BuildContext dialogContext) { // Use dialogContext instead of context
      return AlertDialog(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MyColor.red,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12),
            Text("Live Tracking Error", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Terjadi kesalahan saat mengatur live tracking:"),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  error.isNotEmpty ? '"$error"' : 'Unknown error',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              SizedBox(height: 16),
              Text("Pastikan:"),
              SizedBox(height: 8),
              _buildBulletPoint("GPS/Lokasi sudah diaktifkan"),
              _buildBulletPoint("Izin lokasi sudah diberikan"),
              _buildBulletPoint("Koneksi internet stabil"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Set flag to false first
              _isShowingErrorDialog = false;
              // Then dismiss the dialog using dialogContext
              Navigator.of(dialogContext).pop();
              Logger.log("Dialog dismissed with OK button");
            },
            style: TextButton.styleFrom(
              backgroundColor: MyColor.red,
              foregroundColor: Colors.white,
            ),
            child: Text("OK"),
          ),
        ],
      );
    },
  ).then((_) {
    // Additional safety: set flag to false when dialog is dismissed
    _isShowingErrorDialog = false;
    Logger.log("Live tracking error dialog dismissed");
  }).catchError((e) {
    // Handle any errors with the dialog itself
    _isShowingErrorDialog = false;
    Logger.error("Error showing live tracking dialog", error: e);
    return null;
  });
}

  /// Show success dialog when live tracking is enabled
  static void showSuccessEnableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: "Live Tracking Aktif!",
          content:
              "Lokasi toko Anda sekarang akan diperbarui secara otomatis.\n\n"
              "💡 Tips:\n"
              "• Biarkan aplikasi tetap terbuka untuk performa terbaik\n"
              "• Pastikan baterai mencukupi\n"
              "• Fitur akan otomatis nonaktif jika aplikasi ditutup paksa",
          confirmText: "Mengerti",
          icon: Icons.check_circle,
          iconColor: Colors.white,
          dialogColor: Colors.green,
          onConfirm: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  /// Show info dialog about live tracking permissions
  static void showPermissionInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: "Izin Lokasi Diperlukan",
          content: "Untuk menggunakan Live Tracking, aplikasi membutuhkan:\n\n"
              "🔹 Izin akses lokasi 'Selalu' atau 'Saat menggunakan aplikasi'\n"
              "🔹 GPS/Lokasi harus diaktifkan\n"
              "🔹 Izin akses lokasi yang tepat/presisi\n\n"
              "Silakan buka Pengaturan untuk memberikan izin yang diperlukan.",
          confirmText: "Buka Pengaturan",
          cancelText: "Batal",
          icon: Icons.location_on,
          iconColor: Colors.white,
          dialogColor: MyColor.orange,
          onConfirm: () {
            Navigator.of(context).pop();
            // You can add code to open app settings here
            // Geolocator.openAppSettings();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  static Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
