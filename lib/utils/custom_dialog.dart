import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String? cancelText;
  final IconData icon;
  final Color iconColor;
  final Color dialogColor;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = "Yes",
    this.cancelText = "No",
    required this.icon,
    this.iconColor = Colors.white,
    required this.dialogColor,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
                color: dialogColor,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20))),
            child: Icon(icon, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Row(
              mainAxisAlignment: cancelText != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
              children: [if (cancelText != null && onCancel != null) ...[
                TextButton(
                  onPressed: onCancel,
                  child: Text(cancelText ?? "No",
                      style: TextStyle(color: Colors.black, fontSize: 18)),
                ),
                ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(confirmText, style: TextStyle(fontSize: 18)),
                ),
              ]
              ]
            ),
          ),
        ],
      ),
    );
  }
}
