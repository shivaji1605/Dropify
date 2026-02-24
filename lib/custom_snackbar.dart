import 'package:flutter/material.dart';

class CustomSnackbar {
  showCustomSnackbar(
    BuildContext context,
    String message,{
      Color bgColor = Colors.green,
    }
  ){
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message),
    backgroundColor: bgColor,));
  }
}