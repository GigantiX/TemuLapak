import 'package:flutter/material.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/view/listmerchant_page/listmerchant_viewmodel.dart';

class ListMerchantPage extends StatelessWidget {
  final MerchantCategory category;
  
  const ListMerchantPage({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          category.displayName,
          style: TextStyle(
            color: MyColor.blackPlain,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: MyColor.blackPlain),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Text(
          'Coming Soon: ${category.displayName} Merchants',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}