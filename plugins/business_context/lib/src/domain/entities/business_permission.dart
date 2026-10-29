final class BusinessPermission {
  const BusinessPermission({required this.entity, required this.action});

  final String entity;
  final String action;

  String get key =>
      '${entity.toLowerCase().trim()}_${action.toLowerCase().trim()}';

  @override
  bool operator ==(Object other) =>
      other is BusinessPermission &&
      other.entity == entity &&
      other.action == action;

  @override
  int get hashCode => Object.hash(entity, action);
}
