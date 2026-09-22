/// Artista tal como lo devuelve la Cloud Function o como se guarda de forma
/// compacta en el perfil (favoritos).
class Artist {
  const Artist({
    required this.id,
    required this.name,
    this.image,
    this.imageSmall,
    this.genres = const [],
  });

  final String id;
  final String name;
  final String? image;
  final String? imageSmall;
  final List<String> genres;

  factory Artist.fromJson(Map<String, dynamic> j) => Artist(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        image: j['image'] as String?,
        imageSmall: j['imageSmall'] as String?,
        genres: List<String>.from((j['genres'] as List?) ?? const []),
      );

  factory Artist.fromMap(Map<String, dynamic> m) => Artist(
        id: (m['id'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        image: m['image'] as String?,
        imageSmall: m['imageSmall'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'image': image,
        'imageSmall': imageSmall,
      };

  String? get bestImage => image ?? imageSmall;
  String? get smallImage => imageSmall ?? image;
}
