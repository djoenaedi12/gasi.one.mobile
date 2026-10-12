import 'dart:io';

import 'package:path_provider/path_provider.dart';

class StorageProvider {

  Future<String> getExternalStorage() async{
    var dir = "";
    if(Platform.isIOS) {
      dir = (await getTemporaryDirectory()).path;
    } else {
      dir = (await getExternalStorageDirectory())!.path;
    }
    
    return dir;
  }
  
}