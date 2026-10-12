import 'dart:collection';

import 'package:epeoplecare/module/letter/model/letter.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class LetterRepository extends BaseRepository<Letter> {
  
  LetterRepository(String url, String accessToken, String refreshToken, String language): super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/letter");
  }

  Future<dynamic> print(List<int> ids) async {
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("id", () => ids);

    dynamic result;
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/print${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      result = response.bodyBytes;
    }

    return result;
  }

  @override
  Letter? fromJson(Map<String, dynamic>? json) {
    return Letter.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(Letter entity) {
    return entity.toJson();
  }

}