import 'package:flutter/cupertino.dart';

class NoMoreWidget extends StatelessWidget {
  const NoMoreWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      alignment: Alignment.center,
      child: const Text("已加载全部"),
    );
  }
}
