
import 'package:flutter/material.dart';
import 'package:temulapak_app/utils/loading/loading_component.dart';
import 'package:temulapak_app/utils/logger.dart';

class Loading {
  static void show(BuildContext context) {
    Logger.log("Show Loading");
    LoadingComponent.instance.show(context);
  }

  static void hide() {
    Logger.log("Remove Loading");
    LoadingComponent.instance.hide();
  }
}
