import 'package:flutter/material.dart';

class DialogService {
  DialogService({required this.context});

  final BuildContext context;

  void showDialogFailure({
    required String content,
    required BuildContext context,
    required String textConfirm,
    required VoidCallback confirm,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              confirm();
              Navigator.of(context).pop();
            },
            child: Text(textConfirm),
          ),
        ],
      ),
    );
  }

  void showDialogSuccess({
    required String content,
    required String textConfirm,
    required VoidCallback confirm,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thành công'),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              confirm();
              Navigator.of(context).pop();
            },
            child: Text(textConfirm),
          ),
        ],
      ),
    );
  }
}
