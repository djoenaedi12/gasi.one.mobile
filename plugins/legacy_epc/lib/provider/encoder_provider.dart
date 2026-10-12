import 'dart:convert';

class EncoderProvider {
  Codec<String, String> stringToBase64 = utf8.fuse(base64);
  
  String encode(String text) {  
    String encoded = stringToBase64.encode(text);
    return encoded;
  }

  String decode(String text) {
    String decoded = stringToBase64.decode(text);
    return decoded;
  }
}