import 'package:flutter/widgets.dart';

import '../models/music_list.dart';
import '../models/rating.dart';
import '../models/user_profile.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/share_sheet.dart';
import 'album_card.dart';
import 'artist_card.dart';
import 'friend_card.dart';
import 'list_card.dart';
import 'profile_card.dart';
import 'share_card_data.dart';

/// Lo que cada pantalla pasa a la hoja "Compartir": las tarjetas ya armadas
/// con el énfasis de quien comparte (el de la paleta, sin la versión clara
/// de la tinta: las tarjetas son oscuras).
class ShareSpecs {
  ShareSpecs._();

  static Color accentOf(BuildContext context) {
    final me = CurrentUser.maybeOf(context);
    return me == null ? ViniloPalette.defaultAccent : VColors.nearest(me.color);
  }

  static CardPerson? meOf(BuildContext context) {
    final me = CurrentUser.maybeOf(context);
    return me == null ? null : CardPerson.fromProfile(me);
  }

  /// Un disco con nota: historia y cuadrado del disco.
  static List<ShareCardSpec> album(RatingEntry rating, {required CardPerson person, required Color accent}) {
    final data = AlbumCardData.fromRating(rating, person: person);
    return [
      ShareCardSpec(
        square: true,
        images: [data.album.bestCover, person.avatarUrl],
        toneUrl: data.album.smallCover,
        build: (format, tone) => AlbumShareCard(data: data, accent: accent, coverColor: tone, format: format),
      ),
    ];
  }

  /// El hilo de una nota: la reseña si tiene comentario; si no, el disco.
  static List<ShareCardSpec> rating(RatingEntry rating, {required CardPerson person, required Color accent}) {
    final data = AlbumCardData.fromRating(rating, person: person);
    if (!data.isReview) return album(rating, person: person, accent: accent);
    return [
      ShareCardSpec(
        images: [data.album.smallCover, person.avatarUrl],
        toneUrl: data.album.smallCover,
        build: (_, tone) => ReviewShareCard(data: data, accent: accent, coverColor: tone),
      ),
    ];
  }

  static List<ShareCardSpec> list(MusicList list, {required Color accent}) {
    final covers = ListShareCard.coversFor(list, ShareCardFormat.story);
    return [
      ShareCardSpec(
        square: true,
        images: covers,
        toneUrl: covers.firstWhere((c) => c != null, orElse: () => null),
        build: (format, tone) => ListShareCard(list: list, accent: accent, coverColor: tone, format: format),
      ),
    ];
  }

  static List<ShareCardSpec> artist(ArtistCardData? data, {required Color accent}) => data == null
      ? const []
      : [
          ShareCardSpec(
            images: [
              data.artist.image ?? data.artist.imageSmall,
              data.person.avatarUrl,
              for (final r in data.top) r.album.smallCover,
            ],
            build: (_, _) => ArtistShareCard(data: data, accent: accent),
          ),
        ];

  /// Mi perfil y, si califiqué algo esta semana, "mi semana".
  static List<ShareCardSpec> myProfile(
    UserProfile profile,
    Iterable<RatingEntry> ratings, {
    required Color accent,
    DateTime? now,
  }) {
    final person = CardPerson.fromProfile(profile);
    final data = ProfileCardData(profile: profile, reviews: reviewsIn(ratings));
    final week = weekCardFrom(ratings, now: now ?? DateTime.now(), person: person);
    return [
      ShareCardSpec(
        images: [profile.bannerUrl, profile.avatarUrl, for (final a in profile.favorites.take(3)) a.smallCover],
        build: (_, _) => ProfileShareCard(data: data, accent: accent),
      ),
      if (week != null)
        ShareCardSpec(
          images: [for (final r in week.rows) r.album.smallCover],
          build: (_, _) => WeekShareCard(data: week, accent: accent),
        ),
    ];
  }

  static List<ShareCardSpec> friend(FriendCardData? data, {required Color accent}) => data == null
      ? const []
      : [
          ShareCardSpec(
            images: [data.me.avatarUrl, data.friend.avatarUrl],
            build: (_, _) => FriendShareCard(data: data, accent: accent),
          ),
        ];
}
