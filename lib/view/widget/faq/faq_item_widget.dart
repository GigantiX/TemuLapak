import 'package:flutter/material.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/model/faq/faq.dart';

class FaqItemWidget extends StatelessWidget {
  final FaqItem item;

  const FaqItemWidget({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          item.question,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: MyColor.blackPlain,
          ),
        ),
        iconColor: MyColor.orange,
        collapsedIconColor: Colors.grey[600],
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              item.answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
