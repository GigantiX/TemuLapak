import 'package:flutter/material.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/utils/custom_dialog.dart';

class LiveTrackingDialog {
  /// Show confirmation dialog for enabling live tracking
  static Future<bool?> showEnableDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: "Aktifkan Live Tracking?",
          content: "Fitur ini akan terus memperbarui lokasi toko Anda secara otomatis setiap 20 meter perpindahan.\n\n"
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

  /// Show error dialog for live tracking failures
  static void showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: "Live Tracking Error",
          content: "Terjadi kesalahan saat mengatur live tracking:\n\n$error\n\n"
              "Pastikan:\n"
              "• GPS/Lokasi sudah diaktifkan\n"
              "• Izin lokasi sudah diberikan\n"
              "• Koneksi internet stabil",
          confirmText: "OK",
          icon: Icons.error,
          iconColor: Colors.white,
          dialogColor: MyColor.red,
          onConfirm: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  /// Show success dialog when live tracking is enabled
  static void showSuccessEnableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: "Live Tracking Aktif!",
          content: "Lokasi toko Anda sekarang akan diperbarui secara otomatis.\n\n"
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
}