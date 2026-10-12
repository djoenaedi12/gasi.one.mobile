class SystemAnnouncement {
  
  int id;
  String subject;
  String content;
  int version;

  SystemAnnouncement(
    this.id,
    this.subject,
    this.content,
    this.version,
  );

  static SystemAnnouncement? fromJson(dynamic json) {
    if (json == null) return null;
    
    return SystemAnnouncement(
      json['id'],
      json['subject'],
      json['content'],
      json['version'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "subject": subject,
      "content": content,
      "version": version,
    };
  }
  
}