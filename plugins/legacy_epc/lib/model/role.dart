import 'package:epeoplecare/model/access_right.dart';
import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/menu.dart';
import 'package:epeoplecare/model/record_rule.dart';

class Role extends BaseModel{
  
  String name;
  String? ldapMapping;
  List<Menu> menus = [];
  List<RecordRule> recordRules = [];
  List<AccessRight> accessRights = [];

  Role(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.name,
    this.ldapMapping,
    this.menus,
    this.recordRules,
    this.accessRights,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Role? fromJson(dynamic json) {
    if (json == null) return null;

    List<Menu> menus = [];
    for (var i = 0; i < json['menus'].length; i++) {
      var menu = Menu.fromJson(json['menus'][i]);
      if(menu != null) {
        menus.add(menu);
      }
    }

    List<RecordRule> recordRules = [];
    for (var i = 0; i < json['record_rules'].length; i++) {
      var recordRule = RecordRule.fromJson(json['record_rules'][i]);
      if(recordRule != null) {
        recordRules.add(recordRule);
      }
    }

    List<AccessRight> accessRights = [];
    for (var i = 0; i < json['access_rights'].length; i++) {
      var accessRight = AccessRight.fromJson(json['access_rights'][i]);
      if(accessRight != null) {
        accessRights.add(accessRight);
      }
    }

    return Role(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['name'],
      json['ldap_mapping'],
      menus,
      recordRules,
      accessRights,
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
      "medias": medias,
      "name": name,
      "menus": menus,
      "record_rules": recordRules,
      "access_rights": accessRights,
    };
  }
  
}