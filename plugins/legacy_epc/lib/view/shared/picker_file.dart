// ignore_for_file: empty_catches, use_build_context_synchronously

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/view/shared/in_app_camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PickerFile extends StatelessWidget {
  final bool isRemoveable;
  final bool filePicker;
  final bool imagePicker;
  final bool galleryPicker;
  final CameraDevice preferredCameraDevice;

  PickerFile({Key? key, this.isRemoveable= false, this.filePicker = false, this.imagePicker = true, this.galleryPicker = true, this.preferredCameraDevice = CameraDevice.rear}) : super(key: key);

  final _imagePicker = ImagePicker();

  void _checkPermission(BuildContext context, ImageSource source) async {
    _getFile(context, source);
  }

  void _getFile(BuildContext context, ImageSource source) async {
    File? file;
    try {
      final pickedFile = await _imagePicker.pickImage(source: source, imageQuality: 25, preferredCameraDevice: preferredCameraDevice);
      if (pickedFile != null) {
        file = File(pickedFile.path);
      }
    } catch (e) {
    }

    Navigator.pop(context, file);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Wrap(
        children: <Widget>[
          ListTile(
            title: Text("Where to Choose File".tr()),
          ),
          Divider(
            height: 1,
            color: Colors.grey.shade300
          ),
          Visibility(
            visible: imagePicker,
            child: ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: Config.DEFAULT_COLOR,
              ),
              title: Text("Camera".tr()),
              onTap: () {
                Config.cameraPreference == "system" 
                ? _checkPermission(context, ImageSource.camera)
                : Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InAppCameraPage(
                      preferredLensDirection: preferredCameraDevice == CameraDevice.front ? CameraLensDirection.front : CameraLensDirection.back,
                    ),
                  ),
                ).then((value) {
                  Navigator.pop(context, value);
                });
              },
            ),
          ),
          Visibility(
            visible: galleryPicker,
            child: ListTile(
              leading: Icon(
                Icons.photo_library,
                color: Config.DEFAULT_COLOR,
              ),
              title: Text("Photo Library".tr()),
              onTap: () {
                _checkPermission(context, ImageSource.gallery);
              },
            ),
          ),
          Visibility(
            visible: filePicker,
            child: ListTile(
              leading: Icon(
                Icons.folder,
                color: Config.DEFAULT_COLOR,
              ),
              title: Text("File".tr()),
              onTap: () async {
                File? file;
                final pickedFile = await FilePicker.pickFile();
                final path = pickedFile?.path;
                if (path != null) {
                  file = File(path);
                }
                
                Navigator.pop(context, file);
              },
            ),
          ),
          Visibility(
            visible: isRemoveable,
            child: ListTile(
              leading: Icon(
                Icons.delete,
                color: Config.DEFAULT_COLOR,
              ),
              title: Text("Remove Photo Profile".tr()),
              onTap: () {
                AlertProvider.showConfirmationDialog(message: "Remove Photo Profile".tr()).then((value) {
                  if (value == true) {
                    Navigator.pop(context, true);
                  }
                });
              },
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.cancel,
              color: Config.DEFAULT_COLOR,
            ),
            title: Text("Cancel".tr()),
            onTap: () {
              Navigator.pop(context, null);
            },
          ),
        ],
      ),
    );
  }
}
