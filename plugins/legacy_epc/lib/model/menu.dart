
import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/menu_type.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class Menu extends BaseModel {
  String name;
  String title;
  String? classStr;
  String url;
  int sequence;
  bool visible;
  Menu? parent;
  int? parentId;
  List<Menu> childs = [];
  bool? child;
  MenuType? menuType;
  String? module;

  Menu(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.name,
    this.title,
    this.classStr,
    this.url,
    this.sequence,
    this.visible,
    this.parent,
    this.parentId,
    this.childs,
    this.child,
    this.menuType,
    this.module,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Menu? fromJson(dynamic json) {
    if (json == null) return null;

    List<Menu> childs = [];
    for (var i = 0; i < json['childs'].length; i++) {
      var child = Menu.fromJson(json['childs'][i]);
      if(child != null) {
        childs.add(child);
      }
    }
    
    return Menu(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['name'],
      json['title'],
      json['class_str'],
      json['url'],
      json['sequence'],
      json['visible'],
      Menu.fromJson(json['parent']),
      Menu.fromJson(json['parent'])?.id,
      childs,
      json['child'],
      EnumProvider.fromString(MenuType.values, json['menu_type']),
      json['module'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "creator": creator,
      "creation_time": creationTime,
      "updater": updater,
      "update_time": updateTime,
      "version": version,
      "custom_values": customValues,
      "medais": medias,
      "name": name,
      "title": title,
      "class_str": classStr,
      "url": url,
      "sequence": sequence,
      "visible": visible,
      "parent": parent,
      "parent_id": parent!.id,
      "childs": childs,
      "child": child,
      "menu_type": menuType,
      "module": module,
    };
  }
}
