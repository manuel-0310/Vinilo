import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';

import '../models/affinity.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/music_list.dart';
import '../models/rating.dart';
import '../models/user_profile.dart';
import '../theme/oklch.dart';

/// Tamaño lógico de las tarjetas ("Vinilo Compartir.dc.html"): se dibujan
/// a 360 de ancho y se exportan a 3× (1080×1920 y 1080×1080).
enum ShareCardFormat {
  story(Size(360, 640)),
  square(Size(360, 360));

  const ShareCardFormat(this.size);
  final Size size;
}

/// Escala de la exportación.
const double shareCardPixelRatio = 3;

/// Los tonos de una portada en las tarjetas (siempre oscuras): el fondo a
/// luminosidad 0,24, la nota a 0,78 y el artista a 0,76. Sin color de
/// portada, salen del énfasis.
class CardTones {
  const CardTones({required this.background, required this.score, required this.artist});

  factory CardTones.from(Color color) {
    final o = Oklch.fromColor(color);
    return CardTones(
      background: coverShade(color, lightness: 0.24),
      score: Oklch(0.78, math.min(o.c, 0.12), o.h).toColor(),
      artist: Oklch(0.76, math.min(o.c, 0.10), o.h).toColor(),
    );
  }

  final Color background;
  final Color score;
  final Color artist;
}

/// Las 10 columnas de la regla de "Historia · disco": la elegida al 100 %
/// de alto y opaca; las demás bajan 12 puntos y se apagan con la distancia.
({double height, double opacity}) cardRulerCell(int k, int score) {
  final d = (k - score).abs();
  if (d == 0) return (height: 1, opacity: 1);
  return (
    height: math.max(22, 78 - d * 12) / 100,
    opacity: math.max(0.16, 0.62 - (d - 1) * 0.11),
  );
}

/// Un disco que califiqué ("Historia · disco", "Cuadrado · disco" y, si hay
/// comentario, "Historia · reseña").
class AlbumCardData {
  const AlbumCardData({
    required this.album,
    required this.score,
    required this.ratedAt,
    required this.person,
    this.note = '',
  });

  /// `person` es quien calificó; sin ella se usa lo que trae la nota (el
  /// nombre, porque la nota no guarda el @usuario).
  factory AlbumCardData.fromRating(RatingEntry r, {CardPerson? person}) => AlbumCardData(
        album: r.album,
        score: r.score,
        ratedAt: r.updatedAt,
        note: r.note.trim(),
        person: person ??
            CardPerson(
              name: r.user.name,
              handle: '',
              color: Color(r.user.colorValue),
              avatarUrl: r.user.avatarUrl,
            ),
      );

  final Album album;
  final int score;
  final DateTime ratedAt;
  final String note;
  final CardPerson person;

  bool get isReview => note.isNotEmpty;
}

/// Quien comparte (o el amigo) tal como sale en el pie de las tarjetas.
class CardPerson {
  const CardPerson({required this.name, required this.handle, required this.color, this.avatarUrl});

  factory CardPerson.fromProfile(UserProfile p) =>
      CardPerson(name: p.name, handle: p.handle, color: p.color, avatarUrl: p.avatarUrl);

  final String name;

  /// "@usuario" (vacío si no tiene).
  final String handle;
  final Color color;
  final String? avatarUrl;

  /// Lo que va en el pie: el @usuario o, sin él, el nombre.
  String get label => handle.isNotEmpty ? handle : name;

  /// El primer nombre ("Mateo" de "Mateo Salazar").
  String get firstName {
    final t = name.trim();
    if (t.isEmpty) return handle;
    return t.split(RegExp(r'\s+')).first;
  }
}

/// Las portadas de la rejilla de una lista: primero las distintas y, si no
/// alcanzan (canciones del mismo disco), se repiten hasta llenar tantas
/// celdas como elementos haya, con un máximo de `cells`. Las que faltan
/// quedan vacías (`null`).
List<String?> listGridCovers(MusicList list, int cells) {
  final distinct = <String>[];
  for (final item in list.items) {
    final url = item.smallCover;
    if (url != null && url.isNotEmpty && !distinct.contains(url)) distinct.add(url);
    if (distinct.length == cells) break;
  }
  final filled = math.min(cells, list.items.length);
  return [
    for (var i = 0; i < cells; i++)
      if (i < filled && distinct.isNotEmpty) distinct[i % distinct.length] else null,
  ];
}

/// "Historia · artista": mi promedio en sus discos, cuántos califiqué de
/// cuántos tiene y mis 3 mejores.
class ArtistCardData {
  const ArtistCardData({
    required this.artist,
    required this.average,
    required this.rated,
    required this.total,
    required this.top,
    required this.person,
  });

  final Artist artist;
  final double average;
  final int rated;
  final int total;
  final List<RatingEntry> top;
  final CardPerson person;
}

/// Arma la tarjeta del artista con mis notas. Cuenta solo las notas de
/// discos suyos (por `artistIds`) y sin repetir disco; null si no califiqué
/// ninguno.
ArtistCardData? artistCardFrom({
  required Artist artist,
  required Iterable<RatingEntry> myRatings,
  required int totalAlbums,
  required CardPerson person,
}) {
  final seen = <String>{};
  final mine = [
    for (final r in myRatings)
      if (r.album.artistIds.contains(artist.id) && seen.add(r.albumId)) r,
  ];
  if (mine.isEmpty) return null;
  final average = mine.fold<int>(0, (s, r) => s + r.score) / mine.length;
  final top = [...mine]
    ..sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : b.updatedAt.compareTo(a.updatedAt);
    });
  return ArtistCardData(
    artist: artist,
    average: average,
    rated: mine.length,
    total: math.max(totalAlbums, mine.length),
    top: top.take(3).toList(),
    person: person,
  );
}

/// "Historia · mi perfil".
class ProfileCardData {
  const ProfileCardData({required this.profile, required this.reviews});

  final UserProfile profile;

  /// Notas con comentario.
  final int reviews;
}

/// Cuántas de mis notas tienen comentario.
int reviewsIn(Iterable<RatingEntry> ratings) =>
    ratings.where((r) => r.note.trim().isNotEmpty).length;

/// "Historia · mi semana": lo que califiqué en los últimos 7 días (hoy y
/// los 6 anteriores), lo más reciente primero, con un máximo de 5 filas.
class WeekCardData {
  const WeekCardData({required this.from, required this.to, required this.count, required this.rows, required this.person});

  final DateTime from;
  final DateTime to;

  /// Todos los discos de la semana (las filas son hasta 5).
  final int count;
  final List<RatingEntry> rows;
  final CardPerson person;

  static const int maxRows = 5;
}

WeekCardData? weekCardFrom(Iterable<RatingEntry> ratings, {required DateTime now, required CardPerson person}) {
  final today = DateTime(now.year, now.month, now.day);
  final from = today.subtract(const Duration(days: 6));
  final seen = <String>{};
  final week = [
    for (final r in ratings)
      if (!r.updatedAt.isBefore(from) && !r.updatedAt.isAfter(now) && seen.add(r.albumId)) r,
  ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  if (week.isEmpty) return null;
  return WeekCardData(
    from: from,
    to: today,
    count: week.length,
    rows: week.take(WeekCardData.maxRows).toList(),
    person: person,
  );
}

/// "15–21 sep" o, si cruza de mes, "28 ago – 3 sep" (VMono lo pasa a
/// mayúsculas).
String weekRange(DateTime from, DateTime to, String locale) {
  String dm(DateTime d) => DateFormat('d MMM', locale).format(d).replaceAll('.', '');
  if (from.month == to.month && from.year == to.year) {
    return '${from.day}–${dm(to)}';
  }
  return '${dm(from)} – ${dm(to)}';
}

/// Frase de "Historia · amigo" según la afinidad.
enum FriendVerdict { almostAll, quiteALot, opposites }

FriendVerdict friendVerdict(int percent) => percent >= 80
    ? FriendVerdict.almostAll
    : percent >= 50
        ? FriendVerdict.quiteALot
        : FriendVerdict.opposites;

/// Una fila de la comparación: el disco y si coincidimos o no.
class FriendRow {
  const FriendRow(this.album, {required this.agree});

  final CommonAlbum album;
  final bool agree;
}

/// "Historia · amigo": la afinidad, las dos personas y 3 filas.
class FriendCardData {
  const FriendCardData({required this.percent, required this.me, required this.friend, required this.rows});

  final int percent;
  final CardPerson me;
  final CardPerson friend;
  final List<FriendRow> rows;
}

/// Elige las filas de la comparación entre los discos en común (ya
/// ordenados de menor a mayor diferencia, ver `affinityBetween`): 2 en los
/// que coincidimos y 1 en el que más nos separamos. Si en todos pusimos lo
/// mismo, las 3 son coincidencias.
List<FriendRow> friendRows(List<CommonAlbum> albums) {
  if (albums.isEmpty) return const [];
  final sorted = [...albums]
    ..sort((a, b) {
      final byDiff = a.difference.compareTo(b.difference);
      return byDiff != 0 ? byDiff : b.at.compareTo(a.at);
    });
  final differ = sorted.length >= 2 && sorted.last.difference > 0 ? sorted.last : null;
  final rest = differ == null ? sorted : sorted.sublist(0, sorted.length - 1);
  return [
    for (final a in rest.take(differ == null ? 3 : 2)) FriendRow(a, agree: true),
    if (differ != null) FriendRow(differ, agree: false),
  ];
}

FriendCardData? friendCardFrom({
  required int? percent,
  required List<CommonAlbum> albums,
  required CardPerson me,
  required CardPerson friend,
}) {
  if (percent == null || albums.isEmpty) return null;
  return FriendCardData(percent: percent, me: me, friend: friend, rows: friendRows(albums));
}
