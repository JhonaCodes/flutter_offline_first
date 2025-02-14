class LocalDbModel {
  final String id;
  final String hash;
  final Map<String, dynamic> data;

  LocalDbModel({
    required this.id,
    required this.hash,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'hash': hash,
    'data': data,
  };

  factory LocalDbModel.fromJson(Map<String, dynamic> json) => LocalDbModel(
    id: json['id'],
    hash: json['hash'],
    data: json['data'],
  );

  @override
  String toString() {
    return 'LocalDbModel{id: $id, hash: $hash, data: $data}';
  }

  LocalDbModel copyWith({String? id, String? hash, Map<String, dynamic>? data}) => LocalDbModel(
    id: id ?? this.id,
    hash: hash ?? this.hash,
    data: data ?? this.data,
  );
}