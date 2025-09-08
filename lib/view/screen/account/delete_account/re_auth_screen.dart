import 'package:touchhealth/core/utils/constant/image.dart';
import 'package:touchhealth/core/router/routes.dart';
import 'package:touchhealth/view/screen/account/change_password/old_password_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ReAuthScreen extends StatelessWidget {
  const ReAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OldPasswordScreen(
      appBarTitle: "Delete Account",
      stepTitleOne: "Password",
      stepTitleTwo: "Delete Account",
      stepIconTwo: ImageManager.deteteAccountIcon,
      navigator: RouteManager.deleteAccount,
    );
  }
}
