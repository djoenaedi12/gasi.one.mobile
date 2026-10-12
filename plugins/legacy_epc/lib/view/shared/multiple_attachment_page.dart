
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/storage_provider.dart';
import 'package:epeoplecare/repository/media_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/image_detail.dart';
import 'package:epeoplecare/view/shared/pdf_viewer.dart';
import 'package:epeoplecare/view/shared/picker_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';


class MultipleAttachmentPage extends StatefulWidget {
  
  final List<Media> medias;
  final bool editable;
  final bool isExpand;
  final String? attachment;
  final bool filePicker;
  final bool galleryPicker;
  final CameraDevice preferredCameraDevice;
  final double padding;
  final Function? onPickerFile;
  const MultipleAttachmentPage({Key? key, this.medias = const [], this.editable = false, this.isExpand = true, this.attachment, this.filePicker = true, this.galleryPicker = true, this.preferredCameraDevice = CameraDevice.rear, this.padding = 10.0, this.onPickerFile}) : super(key: key);

  @override
  State<StatefulWidget>  createState() => _MultipleAttachmentPageState();
}

class _MultipleAttachmentPageState extends State<MultipleAttachmentPage> {
  
  bool _isExpand = true;
  final MediaRepository _mediaRepository = Repository().getMediaRepository();

  @override
  void initState() {
    super.initState();
    _isExpand = widget.isExpand;
    if(widget.attachment != null && widget.attachment != "") {
      widget.medias.add(
        Media(
          null, 
          null, 
          null, 
          null, 
          null, 
          null, 
          null, 
          null, 
          null,
          null,
          widget.attachment ?? "",
          "",
          "",
          0,
          "",
          true,
          ""
        )
      );
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 15.0,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.padding),
          child: Column(
            children: [
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  setState(() {
                    _isExpand = !_isExpand;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if(widget.editable) {
                          if(widget.onPickerFile != null) {
                            widget.onPickerFile!();
                          } else {
                            showModalBottomSheet(
                              context: Config.navigatorKey.currentContext!,
                              builder: (BuildContext bc) {
                                return PickerFile(
                                  filePicker: widget.filePicker,
                                  galleryPicker: widget.galleryPicker,
                                  preferredCameraDevice: widget.preferredCameraDevice,
                                );
                              },
                            ).then((value) {
                              if(value != null) {
                                EasyLoading.show(status: "Please Wait".tr());
                                _mediaRepository.upload(value, "file", null).then((value) {
                                  setState(() {
                                    widget.medias.add(value.data);
                                  });
                                }).whenComplete(() {
                                  EasyLoading.dismiss();
                                });
                              }
                            });
                          }
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Visibility(
                            visible: widget.editable,
                            child: Icon(
                              Icons.add_circle,
                              color: Config.DEFAULT_COLOR,
                            ),
                          ),
                          SizedBox(
                            width: widget.editable ? 5.0 : 0.0,
                          ),
                          Text(
                            "${"Attachments".tr()} (${widget.medias.length})",
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      !_isExpand ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      size: 25.0, 
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 15.0,
              ),
              Divider(height: 1, color: Colors.grey.shade300),
            ],
          ),
        ),
        Visibility(
          visible: _isExpand,
          child: Container(
            color: Colors.grey[100],
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  constraints: const BoxConstraints(
                    minHeight: 100,
                  ),
                  child: widget.medias.isNotEmpty 
                    ? ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.medias.length,
                        separatorBuilder: (BuildContext bc, int index){
                          return Divider(color: Colors.grey[400]);
                        },
                        itemBuilder: (BuildContext bc, int index){
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Visibility(
                                visible: widget.editable,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      widget.medias.removeAt(index);
                                    });
                                  },
                                  child: const Icon(
                                    Icons.remove_circle,
                                    size: 25.0, 
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              GestureDetector(
                                onTap: () {
                                  if(widget.medias[index].contentType.contains("image")) {
                                    String? latitude = "", longitude = "", address = "";
                                    if(widget.medias[index].property != null) {
                                      try {
                                        Map<String, dynamic> property = json.decode(widget.medias[index].property ?? "{}");
                                        if(property.containsKey("latitude")) {
                                          latitude = property["latitude"];
                                        }
                                        if(property.containsKey("longitude")) {
                                          longitude = property["longitude"];
                                        }
                                        if(property.containsKey("address")) {
                                          address = property["address"];
                                        }
                                      } catch (e) {
                                      }
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ImageDetail(
                                          url: "${Repository().getBaseUrl()}/api/v1/media/download/${widget.medias[index].id}",
                                          latitude: latitude,
                                          longitude: longitude,
                                          address: address,
                                        ),
                                      ),
                                    );
                                  } else if (widget.medias[index].contentType.contains("pdf")) {
                                    EasyLoading.show(status: "Please Wait".tr());
                                    _mediaRepository.download(widget.medias[index].name).then((value) async {
                                      if(value != null) {
                                        String dir = await StorageProvider().getExternalStorage();
                                        File file = File('$dir/${widget.medias[index].name}');
                                        await file.writeAsBytes(value);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PdfViewer(path: file.path)
                                          ),
                                        );
                                      }
                                    }).whenComplete(() {
                                      EasyLoading.dismiss();
                                    });
                                  } else {
                                    EasyLoading.show(status: "Please Wait".tr());
                                    _mediaRepository.download(widget.medias[index].name).then((value) async {
                                      if(value != null) {
                                        if(Platform.isIOS) {
                                          String dir = await StorageProvider().getExternalStorage();
                                          File file = File('$dir/${widget.medias[index].name}');
                                          await file.writeAsBytes(value);
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
                                          File file = File('${dir.path}/${widget.medias[index].name}');
                                          await file.writeAsBytes(value);
                                          AlertProvider.showAlertDialog(message: "${"File stored to folder".tr()} ${dir.path.replaceAll("/storage/emulated/0/", "")}");
                                        }
                                      }
                                    }).whenComplete(() {
                                      EasyLoading.dismiss();
                                    });
                                  }
                                },
                                child: Icon(
                                  Icons.download,
                                  size: 25.0, 
                                  color: Config.DEFAULT_COLOR,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(widget.medias[index].name)
                              ),
                            ],
                          );
                        }
                      )
                    : Center(
                      child: Text(
                        "No Data Found".tr(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}