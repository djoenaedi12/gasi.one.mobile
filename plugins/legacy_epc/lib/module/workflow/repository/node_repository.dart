import 'dart:collection';
import 'dart:convert';

import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/workflow/model/node.dart';
import 'package:epeoplecare/module/workflow/model/route_type.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class NodeRepository extends BaseRepository<Node> {

  NodeRepository(String url, String accessToken, String refreshToken, String language): super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/workflow/node");
  }

  Future<List<Node>> getOverrideNode(Employee employee, RouteType routeType) async {
    Map<String, dynamic> parameters = HashMap();
    parameters['employee'] = employee.id;
    parameters['routeType'] = EnumProvider.convertToString(routeType);

    List<Node> result = [];
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/getoverridenode${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        for (var i = 0; i < json['data'].length; i++) {
          Node? item = fromJson(json['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  @override
  Node? fromJson(Map<String, dynamic>? json) {
    return Node.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(Node entity) {
    return entity.toJson();
  }
}