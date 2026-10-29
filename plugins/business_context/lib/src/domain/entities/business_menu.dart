final class BusinessMenu {
  BusinessMenu({
    required this.id,
    required this.name,
    required this.title,
    required this.path,
    required this.sequence,
    required this.visible,
    required this.module,
    required List<BusinessMenu> children,
  }) : children = List.unmodifiable(children);

  final int? id;
  final String name;
  final String title;
  final String path;
  final int sequence;
  final bool visible;
  final String? module;
  final List<BusinessMenu> children;
}
