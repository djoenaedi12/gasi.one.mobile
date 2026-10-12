import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:epeoplecare/config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:share_plus/share_plus.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/storage_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

class ImageDetail extends StatelessWidget {
  final String url;
  final String? latitude;
  final String? longitude;
  final String? address;
  
  const ImageDetail({
    super.key,
    this.url = "",
    this.latitude = "",
    this.longitude = "",
    this.address = "",
  });
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Image Viewer",
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
              final response = await http.get(Uri.parse(url), headers: Repository().generateHeader());
              if(response.statusCode == 200) {
                final bytes = response.bodyBytes;
                if(Platform.isIOS) {
                  String dir = await StorageProvider().getExternalStorage();
                  File file = File('$dir/${p.basename(url)}');
                  await file.writeAsBytes(bytes);
                  final box = context.findRenderObject() as RenderBox?;
                  await SharePlus.instance.share(
                    ShareParams(
                      files: [XFile(file.path)],
                      sharePositionOrigin: box == null
                          ? null
                          : box.localToGlobal(Offset.zero) & box.size,
                    ),
                  );
                } else {
                  Directory dir = Directory("/storage/emulated/0/Download");
                  if(!await dir.exists()) dir = (await getExternalStorageDirectory())!;
                  File file = File('${dir.path}/${p.basename(url)}');
                  await file.writeAsBytes(bytes);
                  AlertProvider.showAlertDialog(message: "${"File stored to folder".tr()} ${dir.path.replaceAll("/storage/emulated/0/", "")}");
                }
              }
              EasyLoading.dismiss();
            }
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: "image",
                child: PhotoView(
                  backgroundDecoration: const BoxDecoration(color: Colors.black),
                  imageProvider: CachedNetworkImageProvider(
                    url,
                    headers: Repository().generateHeader(),

                  ),
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset("assets/img/no-image-available.png");
                  },
                ),
              ),
            ),
            Visibility(
              visible: latitude != null && latitude!.isNotEmpty,
              child: Positioned(
                left: 0.0,
                bottom: 40.0,
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  height: 125,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Colors.black45
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$latitude, $longitude",
                        style: TextStyle(
                          color: Colors.white
                        ),
                      ),
                      Text(
                        "$address",
                        style: TextStyle(
                          color: Colors.white
                        ),
                      ),
                    ],
                  )
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}