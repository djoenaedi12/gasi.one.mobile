import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:share_plus/share_plus.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:path/path.dart' as p;

class PdfViewer extends StatelessWidget {
  final String path;
  PdfViewer({super.key,this.path = ""});
  late final PdfControllerPinch pdfControllerPinch = PdfControllerPinch(
    document: PdfDocument.openFile(path)
  );
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "PDF Viewer",
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () async {
              EasyLoading.show(status: "Please Wait".tr());
              if(Platform.isIOS) {
                final box = context.findRenderObject() as RenderBox?;
                await SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(path)],
                    sharePositionOrigin: box == null
                        ? null
                        : box.localToGlobal(Offset.zero) & box.size,
                  ),
                );
              } else {
                File sourceFile = File(path);                
                Directory dir = Directory("/storage/emulated/0/Download");
                if(!await dir.exists()) dir = (await getExternalStorageDirectory())!;
                await sourceFile.copy('${dir.path}/${p.basename(path)}');
                AlertProvider.showAlertDialog(message: "${"File stored to folder".tr()} ${dir.path.replaceAll("/storage/emulated/0/", "")}");
              }
              EasyLoading.dismiss();
            }
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: PdfViewPinch(
        controller: pdfControllerPinch
      ),
    );
  }
}