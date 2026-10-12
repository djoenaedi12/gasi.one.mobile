
import 'package:flutter/material.dart';

class Module {
  String title;
  bool isActive;
  IconData icon;
  void Function() onTap;
  String module;
  int sequence;

  Module(
    this.title,
    this.isActive,
    this.icon,
    this.onTap,
    this.module,
    this.sequence,
  );
}
