class AccompanimentOption {
  String id;
  String name;
  AccompanimentOption({required this.id, required this.name});
  factory AccompanimentOption.fromJson(Map<String, dynamic> j) =>
      AccompanimentOption(id: j['id'] ?? '', name: j['name'] ?? '');
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class AccompanimentGroup {
  String id;
  String name;          // e.g. "Starch"
  String type;          // 'fixed' (always included) | 'choice' (pick one/some)
  List<AccompanimentOption> options;
  AccompanimentGroup(
      {required this.id, required this.name, required this.type,
       required this.options});
  factory AccompanimentGroup.fromJson(Map<String, dynamic> j) =>
      AccompanimentGroup(
        id: j['id'] ?? '', name: j['name'] ?? '', type: j['type'] ?? 'choice',
        options: (j['options'] as List? ?? [])
            .map((o) => AccompanimentOption.fromJson(o)).toList(),
      );
  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'type': type,
        'options': options.map((o) => o.toJson()).toList(),
      };
}