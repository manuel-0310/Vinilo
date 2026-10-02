// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Vinilo';

  @override
  String get timeNow => 'ahora';

  @override
  String timeMinutesAgo(int n) {
    return 'hace $n min';
  }

  @override
  String timeHoursAgo(int n) {
    return 'hace $n h';
  }

  @override
  String get timeYesterday => 'ayer';

  @override
  String timeDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'hace $n días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get errorGeneric => 'Algo falló. Vuelve a intentarlo.';

  @override
  String get errorOffline =>
      'Sin conexión. Revisa tu internet y vuelve a intentar.';

  @override
  String get errorPermissionDenied => 'No tienes permiso para hacer eso.';

  @override
  String get authEmailInUse =>
      'Ese correo ya tiene una cuenta. Inicia sesión o usa otro.';

  @override
  String get authInvalidEmail => 'Ese correo no parece válido.';

  @override
  String get authWeakPassword =>
      'La contraseña es muy débil: usa al menos 6 caracteres.';

  @override
  String get authMissingPassword => 'Escribe tu contraseña.';

  @override
  String get authWrongCredentials => 'Correo o contraseña incorrectos.';

  @override
  String get authUserDisabled => 'Esta cuenta está deshabilitada.';

  @override
  String get authTooManyRequests =>
      'Demasiados intentos. Espera un momento y vuelve a probar.';

  @override
  String get authOperationNotAllowed =>
      'El acceso con correo y contraseña no está habilitado todavía.';

  @override
  String get authCredentialInUse =>
      'Ese correo ya pertenece a otra cuenta. Inicia sesión con ella o usa otro correo.';

  @override
  String get authProviderLinked => 'Esta sesión ya tiene un correo vinculado.';

  @override
  String get authRequiresRecentLogin =>
      'Por seguridad, vuelve a iniciar sesión antes de hacer esto.';

  @override
  String get authSessionExpired => 'Tu sesión venció. Vuelve a iniciar sesión.';

  @override
  String usernameTaken(String username) {
    return '@$username ya está en uso. Prueba con otro.';
  }

  @override
  String get usernameEmpty => 'Elige tu @usuario.';

  @override
  String usernameTooShort(int n) {
    return 'Mínimo $n caracteres.';
  }

  @override
  String usernameTooLong(int n) {
    return 'Máximo $n caracteres.';
  }

  @override
  String get usernameBadChars =>
      'Solo letras minúsculas, números, punto y guion bajo.';

  @override
  String get listKindList => 'Lista';

  @override
  String get listKindRanking => 'Ranking';

  @override
  String get listTypeTracks => 'Canciones';

  @override
  String get listTypeAlbums => 'Discos';

  @override
  String countTracks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n canciones',
      one: '1 canción',
    );
    return '$_temp0';
  }

  @override
  String countAlbums(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n discos',
      one: '1 disco',
    );
    return '$_temp0';
  }

  @override
  String addedTracks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Se agregaron $n canciones',
      one: 'Se agregó 1 canción',
    );
    return '$_temp0';
  }

  @override
  String addedAlbums(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Se agregaron $n discos',
      one: 'Se agregó 1 disco',
    );
    return '$_temp0';
  }

  @override
  String get listAddTracks => 'Agregar canciones';

  @override
  String get listAddAlbums => 'Agregar discos';

  @override
  String get listFullTypeTrackList => 'Lista de canciones';

  @override
  String get listFullTypeTrackRanking => 'Ranking de canciones';

  @override
  String get listFullTypeAlbumList => 'Lista de discos';

  @override
  String get listFullTypeAlbumRanking => 'Ranking de discos';

  @override
  String get addAlreadyInList => 'Ya estaba en la lista';

  @override
  String addDuplicates(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ya estaban',
      one: '1 ya estaba',
    );
    return '$_temp0';
  }

  @override
  String addOverflow(int n, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n no cupieron (tope de $max)',
      one: '1 no cupo (tope de $max)',
    );
    return '$_temp0';
  }

  @override
  String get score1 => 'Terrible';

  @override
  String get score2 => 'Muy malo';

  @override
  String get score3 => 'Malo';

  @override
  String get score4 => 'Flojo';

  @override
  String get score5 => 'Regular';

  @override
  String get score6 => 'Aceptable';

  @override
  String get score7 => 'Bueno';

  @override
  String get score8 => 'Muy bueno';

  @override
  String get score9 => 'Excelente';

  @override
  String get score10 => 'Obra maestra';

  @override
  String get albumTypeSingle => 'Sencillo';

  @override
  String get albumTypeCompilation => 'Recopilatorio';

  @override
  String get albumTypeAlbum => 'Álbum';

  @override
  String notifFollow(String name) {
    return '$name empezó a seguirte';
  }

  @override
  String notifLikeRating(String name, String album) {
    return 'A $name le gustó tu nota de $album';
  }

  @override
  String get notifSomeAlbum => 'un disco';

  @override
  String notifLikeList(String name, String list) {
    return 'A $name le gustó tu lista $list';
  }

  @override
  String notifSaveList(String name, String list) {
    return '$name guardó tu lista $list';
  }

  @override
  String get deleteErrorNoEndpoint =>
      'Falta la URL de la función (--dart-define=SPOTIFY_FN_URL=…).';

  @override
  String get deleteErrorWrongPassword => 'La contraseña no es correcta.';

  @override
  String deleteErrorReauth(String code) {
    return 'No se pudo comprobar tu contraseña ($code).';
  }

  @override
  String get deleteErrorNoSession => 'No hay sesión.';

  @override
  String get deleteErrorTimeout =>
      'El borrado está tardando más de la cuenta. Vuelve a intentarlo: retoma donde quedó.';

  @override
  String get deleteErrorRecentLogin =>
      'Vuelve a escribir tu contraseña para borrar la cuenta.';

  @override
  String deleteErrorServer(String status) {
    return 'No se pudo borrar la cuenta ($status). Vuelve a intentarlo.';
  }

  @override
  String get spotifyNotConfigured =>
      'Falta la URL de la función de Spotify. Corre la app con --dart-define=SPOTIFY_FN_URL=…';

  @override
  String get spotifyTimeout => 'Spotify tardó demasiado en responder.';

  @override
  String spotifyServerError(String status) {
    return 'Spotify no respondió bien (error $status).';
  }

  @override
  String get spotifyUnexpected => 'Respuesta inesperada de Spotify.';

  @override
  String get listGone => 'La lista ya no existe.';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get feedRatedSuffix => ' calificó';

  @override
  String couldNotSave(String error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String get follow => 'Seguir';

  @override
  String get following => 'Siguiendo';

  @override
  String get cropTitle => 'Ajusta tu foto';

  @override
  String cropFailed(String error) {
    return 'No se pudo recortar: $error';
  }

  @override
  String get cropHint =>
      'Mueve y haz zoom con dos dedos. Doble toque para reiniciar.';

  @override
  String cropOpenFailed(String error) {
    return 'No se pudo abrir la imagen: $error';
  }

  @override
  String get cropUse => 'Usar foto';

  @override
  String get cancel => 'Cancelar';

  @override
  String get photoCamera => 'Tomar foto';

  @override
  String get photoGallery => 'Elegir de la galería';

  @override
  String get photoRemove => 'Quitar foto';

  @override
  String get photoNoCamera => 'No hay cámara disponible.';

  @override
  String photoGalleryFailed(String error) {
    return 'No se pudo abrir la galería: $error';
  }

  @override
  String get rateSheetCommentHint => 'Agregar un comentario (opcional)';

  @override
  String get rateSheetDelete => 'Borrar nota';

  @override
  String get usernameOffline => 'No se pudo comprobar. Revisa tu conexión.';

  @override
  String get usernameHint => 'tu_usuario';

  @override
  String get welcomeBody =>
      'Busca un álbum, ponle nota del 1 al 10 y mira lo que opina la comunidad. Sin estrellas: aquí se habla en números.';

  @override
  String get welcomeSignUp => 'Crear cuenta';

  @override
  String get welcomeSignIn => 'Ya tengo cuenta';

  @override
  String resetSent(String email) {
    return 'Te mandamos un correo a $email con un enlace para cambiar tu contraseña.';
  }

  @override
  String get signInNoAccount => '¿No tienes cuenta? ';

  @override
  String get signInCreateOne => 'Crear cuenta';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get resetTitle => 'Recuperar contraseña';

  @override
  String get resetBody =>
      'Te mandamos un enlace para elegir una contraseña nueva.';

  @override
  String get send => 'Enviar';

  @override
  String get signUpHaveAccount => '¿Ya tienes cuenta? ';

  @override
  String get signUpSignIn => 'Iniciar sesión';

  @override
  String get continueLabel => 'Continuar';

  @override
  String usernameSubtitle(int min, int max) {
    return 'Así te encuentran tus amigos. Minúsculas, números, punto y guion bajo; de $min a $max caracteres. Puedes cambiarlo después desde tu perfil.';
  }

  @override
  String get linkOtherTitle => '¿Entrar con otra cuenta?';

  @override
  String linkOtherBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n notas',
      one: '1 nota',
    );
    return 'Esta sesión tiene $_temp0 y tu perfil. Si entras con otra cuenta, todo eso queda fuera de tu alcance. Para conservarlo, guarda esta sesión con un correo y una contraseña.';
  }

  @override
  String get back => 'Volver';

  @override
  String get linkOtherConfirm => 'Entrar de todos modos';

  @override
  String linkSubtitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n notas',
      one: '1 nota',
    );
    return 'Vinilo ahora entra con correo y contraseña. Vincúlalos a esta sesión y conservas $_temp0, tus favoritos y tu perfil en cualquier dispositivo.';
  }

  @override
  String get linkHaveAccount => 'Ya tengo una cuenta';

  @override
  String get linkSubmit => 'Guardar mi cuenta';

  @override
  String onboardingSignedInAs(String email) {
    return 'Entraste como $email · ';
  }

  @override
  String get onboardingSignOut => 'Salir';

  @override
  String get onboardingStart => 'Empezar';

  @override
  String splashError(String error) {
    return 'No se pudo iniciar sesión.\n$error';
  }

  @override
  String get retry => 'Reintentar';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsSubtitle =>
      'Se guarda en tu perfil y te sigue en cualquier dispositivo.';

  @override
  String get settingsProfile => 'PERFIL';

  @override
  String get settingsAppearance => 'APARIENCIA';

  @override
  String get settingsLanguage => 'IDIOMA';

  @override
  String get settingsAccent => 'COLOR DE ÉNFASIS';

  @override
  String get settingsAccentBody =>
      'Tiñe botones, enlaces, la pestaña activa y la escala de las notas. También es el color de tu avatar.';

  @override
  String get settingsAccount => 'CUENTA';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountHint =>
      'Borra tu perfil y todo lo tuyo. No se puede deshacer.';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get signOutTitle => '¿Cerrar sesión?';

  @override
  String get signOutBody =>
      'Tu perfil y tus notas se quedan en tu cuenta. Para volver, entra con tu correo y tu contraseña.';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get deletePasswordMissing => 'Escribe tu contraseña para confirmar.';

  @override
  String get deleteCannotUndo => 'No se puede deshacer';

  @override
  String get deleteIntro => 'Se borra para siempre todo lo tuyo:';

  @override
  String get deleteItemProfile => 'Tu perfil, tu @usuario, tu foto y tu fondo.';

  @override
  String get deleteItemRatings =>
      'Tus notas y comentarios (los promedios de los discos se recalculan) y tus \"me gusta\".';

  @override
  String get deleteItemLists => 'Tus listas y las que guardaste.';

  @override
  String get deleteItemFollows => 'A quién sigues y quién te sigue.';

  @override
  String get deleteItemNotifications => 'Tus notificaciones.';

  @override
  String get deleteConfirmPrompt => 'Para confirmar, escribe tu contraseña.';

  @override
  String get deleteInProgress => 'Borrando tu cuenta…';

  @override
  String get deleteConfirm => 'Eliminar mi cuenta';

  @override
  String get editProfileTitle => 'Tu perfil';

  @override
  String get save => 'Guardar';

  @override
  String get profilePhotoTitle => 'Tu foto de perfil';

  @override
  String get bannerPhotoTitle => 'Tu foto de fondo';

  @override
  String get bannerRemove => 'Quitar fondo';

  @override
  String get bannerChange => 'Cambiar fondo';

  @override
  String get bannerChoose => 'Elegir foto de fondo';

  @override
  String get photoChange => 'Cambiar foto';

  @override
  String get photoChoose => 'Elegir una foto';

  @override
  String get nameHint => '¿Cómo te llamamos?';

  @override
  String get yourColorLabel => 'TU COLOR';

  @override
  String get bannerPlaceholder => 'Foto de fondo';

  @override
  String get homeQuietTitle => 'Todo tranquilo por aquí';

  @override
  String get homeQuietBody =>
      'Las personas que sigues todavía no han calificado nada. Cuando lo hagan, aparecerá aquí.';

  @override
  String homeActivityError(String error) {
    return 'No se pudo cargar la actividad: $error';
  }

  @override
  String loadMoreFailed(String error) {
    return 'No se pudo cargar más: $error';
  }

  @override
  String get searchTitle => 'Buscar';

  @override
  String get searchHint => 'Álbum, artista o @persona';

  @override
  String get spotifyNoResponse => 'Spotify no respondió';

  @override
  String get searchNothingTitle => 'Nada por aquí';

  @override
  String get searchNoUsername => 'Nadie tiene un @usuario que empiece así.';

  @override
  String get searchNothingBody =>
      'Prueba con otro nombre, o busca por el artista.';

  @override
  String get searchPeople => 'Personas';

  @override
  String get searchArtists => 'Artistas';

  @override
  String get searchAlbums => 'Álbumes';

  @override
  String get searchEnd => 'Eso es todo lo que encontró Spotify';

  @override
  String get searchRecent => 'Recientes';

  @override
  String get searchSuggestions => 'Para empezar';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabSearch => 'Buscar';

  @override
  String get tabProfile => 'Perfil';

  @override
  String get loading => 'Cargando…';

  @override
  String get notificationsAllCaughtUp => 'Todo al día';

  @override
  String notificationsError(String error) {
    return 'No se pudieron cargar: $error';
  }

  @override
  String get commentsTitle => 'Comentarios';

  @override
  String countComments(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n comentarios',
      one: '1 comentario',
    );
    return '$_temp0';
  }

  @override
  String get commentsEmptyTitle => 'Sin comentarios';

  @override
  String get commentsEmptyBody =>
      'Nadie ha escrito nada sobre este disco todavía.';

  @override
  String get diaryMine => 'Tu diario';

  @override
  String diaryOf(String name) {
    return 'Diario de $name';
  }

  @override
  String countRatedAlbums(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n discos calificados',
      one: '1 disco calificado',
    );
    return '$_temp0';
  }

  @override
  String get diarySearchHint => 'Disco o artista';

  @override
  String get diaryNoMatch =>
      'Ningún disco del diario coincide con esa búsqueda o ese filtro.';

  @override
  String get filterAll => 'Todas';

  @override
  String get sortDate => 'Fecha';

  @override
  String get sortScore => 'Nota';

  @override
  String get followersTitle => 'Seguidores';

  @override
  String followersMine(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n personas siguen tu diario',
      one: '1 persona sigue tu diario',
    );
    return '$_temp0';
  }

  @override
  String followersOf(int n, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n personas siguen a $name',
      one: '1 persona sigue a $name',
    );
    return '$_temp0';
  }

  @override
  String followingMine(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n personas seguidas',
      one: '1 persona seguida',
    );
    return '$_temp0';
  }

  @override
  String followingOf(int n, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$name sigue a $n personas',
      one: '$name sigue a 1 persona',
    );
    return '$_temp0';
  }

  @override
  String get followersEmptyTitle => 'Nadie todavía';

  @override
  String get followingEmptyTitle => 'A nadie todavía';

  @override
  String get followersEmptyMine => 'Cuando alguien te siga, aparecerá aquí.';

  @override
  String followersEmptyOf(String name) {
    return 'Nadie sigue a $name todavía.';
  }

  @override
  String get followingEmptyMine =>
      'Busca a tus amigos en la pestaña Buscar y sigue su diario.';

  @override
  String followingEmptyOf(String name) {
    return '$name no sigue a nadie todavía.';
  }

  @override
  String get listEdit => 'Editar lista';

  @override
  String get listNew => 'Nueva lista';

  @override
  String get listFormSubtitle =>
      'Un ranking va numerado y se ordena arrastrando.';

  @override
  String get listNameHint => 'Nombre de la lista';

  @override
  String get listFormKind => 'Tipo';

  @override
  String get listKindListHint => 'Sin orden fijo';

  @override
  String get listKindRankingHint => 'Numerado, del 1 en adelante';

  @override
  String get listFormContent => 'Contenido';

  @override
  String get listTypeTracksHint => 'De cualquier disco';

  @override
  String get listTypeAlbumsHint => 'Álbumes completos';

  @override
  String get listCreate => 'Crear lista';

  @override
  String listCreateFailed(String error) {
    return 'No se pudo crear la lista: $error';
  }

  @override
  String get pickerTitle => 'Agregar a una lista';

  @override
  String get pickerSubtitleTracks => 'Tus listas de canciones';

  @override
  String get pickerSubtitleAlbums => 'Tus listas de discos';

  @override
  String get pickerEmptyTracks =>
      'Todavía no tienes listas de canciones. Crea una arriba.';

  @override
  String get pickerEmptyAlbums =>
      'Todavía no tienes listas de discos. Crea una arriba.';

  @override
  String addFailed(String error) {
    return 'No se pudo agregar: $error';
  }

  @override
  String get addToListTitle => 'Agregar a la lista';

  @override
  String addPickTracksSubtitle(String artist) {
    return '$artist · elige las canciones';
  }

  @override
  String get addBackToResults => 'Volver a los resultados';

  @override
  String get addChooseTracks => 'Elige canciones';

  @override
  String addSelected(String count) {
    return 'Agregar $count';
  }

  @override
  String get addSearchTrackAlbum => 'Busca el disco de la canción';

  @override
  String get addSearchAlbum => 'Busca un disco';

  @override
  String get addPromptTracks =>
      'Escribe el nombre de un disco o artista; después eliges las canciones.';

  @override
  String get addPromptAlbums => 'Escribe el nombre de un disco o artista.';

  @override
  String get addNothingBody => 'Prueba con otro nombre.';

  @override
  String get albumLoadFailed => 'No se pudo cargar el disco';

  @override
  String get selectNone => 'Ninguna';

  @override
  String get addAlreadyHere => 'ya está';

  @override
  String get done => 'Listo';

  @override
  String get artistLabel => 'Artista';

  @override
  String get artistDiscography => 'Discografía';

  @override
  String get artistNoAlbumsTitle => 'Sin discos';

  @override
  String get artistNoAlbumsBody => 'Spotify no tiene álbumes de este artista.';

  @override
  String artistAlbumsError(String error) {
    return 'No se pudo cargar la discografía: $error';
  }

  @override
  String get spotifyCredit => 'Datos y portadas de Spotify';

  @override
  String get ratingLabel => 'CALIFICACIÓN';

  @override
  String countRatings(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n notas',
      one: '1 nota',
    );
    return '$_temp0';
  }

  @override
  String get listReorderFailed => 'No se pudo reordenar';

  @override
  String get listRemoveFailed => 'No se pudo quitar';

  @override
  String listRemoved(String name) {
    return 'Quitaste \"$name\"';
  }

  @override
  String get undo => 'Deshacer';

  @override
  String get undoFailed => 'No se pudo deshacer';

  @override
  String listDeleteTitle(String name) {
    return '¿Borrar \"$name\"?';
  }

  @override
  String get listDeleteBody =>
      'No se puede deshacer. Quien la haya guardado dejará de verla.';

  @override
  String get listDelete => 'Borrar lista';

  @override
  String deleteFailed(String error) {
    return 'No se pudo borrar: $error';
  }

  @override
  String get listCoverTitle => 'Portada de la lista';

  @override
  String get listCoverUploading => 'Subiendo portada…';

  @override
  String listCoverFailed(String error) {
    return 'No se pudo cambiar la portada: $error';
  }

  @override
  String listCoverRemoveFailed(String error) {
    return 'No se pudo quitar la portada: $error';
  }

  @override
  String get listMenuEdit => 'Editar nombre y descripción';

  @override
  String get listMenuAddHint => 'Busca un disco y elige';

  @override
  String get listCoverChoose => 'Elegir portada';

  @override
  String get listCoverChange => 'Cambiar portada';

  @override
  String get listCoverHint => 'Una foto propia para la lista';

  @override
  String get listCoverRemove => 'Quitar portada';

  @override
  String get listCoverRemoveHint => 'Vuelve la portada de su primer elemento';

  @override
  String get listGoneBody => 'Su autor la borró.';

  @override
  String get listYours => 'Tu lista';

  @override
  String get listEmptyMineTitle => 'Tu lista está vacía';

  @override
  String get listEmptyTheirsTitle => 'Todavía no tiene nada';

  @override
  String get listEmptyMineTracks =>
      'Busca un disco y elige sus canciones. También puedes hacerlo desde la pantalla de cualquier disco.';

  @override
  String get listEmptyMineAlbums =>
      'Busca un disco y agrégalo. También puedes hacerlo desde la pantalla de cualquier disco.';

  @override
  String listEmptyTheirs(String name) {
    return 'Cuando $name agregue algo, aparecerá aquí.';
  }

  @override
  String get listFooterOwner =>
      'Mantén pulsado un elemento para moverlo. En \"Editar\" puedes quitar.';

  @override
  String get add => 'Agregar';

  @override
  String get edit => 'Editar';

  @override
  String get like => 'Me gusta';

  @override
  String get saved => 'Guardada';

  @override
  String get ratingSaved => 'Guardado en tu diario';

  @override
  String get ratingDeleted => 'Nota borrada de tu diario';

  @override
  String ratingDeleteFailed(String error) {
    return 'No se pudo borrar la nota: $error';
  }

  @override
  String get viewList => 'Ver lista';

  @override
  String get albumAddToList => 'Agregar el disco a una lista';

  @override
  String get albumAddToListHint =>
      'A una de tus listas de discos, o a una nueva';

  @override
  String get albumCreateList => 'Crear lista con este disco';

  @override
  String get albumCreateListHint =>
      'Todas sus canciones, en orden, listas para ordenar';

  @override
  String get albumWaitTracks => 'Espera a que carguen las canciones';

  @override
  String get albumListFromAlbum => 'Lista con este disco';

  @override
  String albumDetailError(String error) {
    return 'No se pudo cargar el detalle: $error';
  }

  @override
  String moreBy(String artist) {
    return 'Más de $artist';
  }

  @override
  String releasedOn(String date) {
    return 'Publicado el $date';
  }

  @override
  String get yourRating => 'Tu nota';

  @override
  String get unrated => 'Sin calificar';

  @override
  String get rateThisAlbum => 'Calificar este disco';

  @override
  String get addToList => 'Agregar a lista';

  @override
  String get profileNotFound => 'Perfil no encontrado';

  @override
  String get profileNotFoundBody => 'Esta persona ya no está en Vinilo.';

  @override
  String statAlbums(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'DISCOS',
      one: 'DISCO',
    );
    return '$_temp0';
  }

  @override
  String get statAverage => 'PROMEDIO';

  @override
  String get profileListsTab => 'Listas';

  @override
  String get favorites => 'Favoritos';

  @override
  String get favoritesMine => 'Tres discos y tres artistas que me definen';

  @override
  String get favoritesAlbumsLabel => 'DISCOS';

  @override
  String get favoritesArtistsLabel => 'ARTISTAS';

  @override
  String get diary => 'Diario';

  @override
  String get diaryEmptyMine => 'Tu diario está vacío';

  @override
  String get diaryEmptyTheirs => 'Aún no hay notas';

  @override
  String get diaryEmptyMineBody =>
      'Busca un disco y ponle nota. Aquí quedará tu historial, mes a mes.';

  @override
  String diaryEmptyTheirsBody(String name) {
    return 'Cuando $name califique algo, aparecerá aquí.';
  }

  @override
  String get listsMine => 'Mías';

  @override
  String get listsEmptyMine =>
      'Todavía no tienes listas. Crea una con \"Nueva lista\" o desde la pantalla de un disco.';

  @override
  String get listsEmptyTheirs => 'Todavía no tiene listas.';

  @override
  String get listsSaved => 'Guardadas';

  @override
  String get listsSavedEmpty =>
      'Guarda listas de otras personas y aparecerán aquí.';

  @override
  String countLists(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n listas',
      one: '1 lista',
    );
    return '$_temp0';
  }

  @override
  String get pick => 'Elegir';

  @override
  String get affinity => 'AFINIDAD MUSICAL';

  @override
  String get affinityNone => 'Todavía no tienen discos en común';

  @override
  String affinityBasis(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Según $n discos en común',
      one: 'Según 1 disco en común',
    );
    return '$_temp0';
  }

  @override
  String get affinityAll => 'Todos';

  @override
  String get affinityMatch => 'Coinciden';

  @override
  String get affinityDiffer => 'Discrepan';

  @override
  String get affinityMostSimilar => 'Más parecidos primero';

  @override
  String get affinityMostDifferent => 'Más distintos primero';

  @override
  String get affinityYou => 'Tú';

  @override
  String get affinitySameScore => 'Misma nota';

  @override
  String affinityPointsApart(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'A $n puntos',
      one: 'A 1 punto',
    );
    return '$_temp0';
  }

  @override
  String get affinityEmptyTitle => 'Nada por aquí';

  @override
  String get affinityEmptyMatch => 'No coinciden en ningún disco todavía.';

  @override
  String get affinityEmptyDiffer =>
      'No discrepan en ningún disco: sus notas siempre están a 1 punto o menos.';

  @override
  String get favoritesPickerTitle => 'Tus discos';

  @override
  String get favoritesPickerHint =>
      'Elige hasta tres, en el orden que quieras.';

  @override
  String get favoritesSearchHint => 'Buscar en tus discos';

  @override
  String get clear => 'Borrar';

  @override
  String favoritesNoMatch(String query) {
    return 'Ningún disco de tu diario coincide con \"$query\".';
  }

  @override
  String get favoritesSave => 'Guardar discos';

  @override
  String get artistsPickerTitle => 'Tus artistas';

  @override
  String get artistsPickerHint => 'Busca en Spotify y elige hasta tres.';

  @override
  String get artistsSearchHint => 'Nombre del artista';

  @override
  String get artistsPrompt => 'Escribe el nombre de un artista para buscarlo.';

  @override
  String get artistsSave => 'Guardar artistas';

  @override
  String get bioLabel => 'BIOGRAFÍA';

  @override
  String get bioHint => 'Cuéntale a la gente qué escuchas (opcional)';

  @override
  String get ratedBy => 'Calificado por';

  @override
  String countFriends(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n amigos',
      one: '1 amigo',
    );
    return '$_temp0';
  }

  @override
  String get listsFilterLists => 'Listas';

  @override
  String get listsFilterRankings => 'Rankings';

  @override
  String get listsSortRecent => 'Recientes';

  @override
  String get listsSortName => 'A–Z';

  @override
  String get listsSortSize => 'Más elementos';

  @override
  String get listsSortLikes => 'Más me gusta';

  @override
  String listsShowing(int shown, int total) {
    return 'Mostrando $shown de $total';
  }

  @override
  String get listsNoMatchTitle => 'Ninguna lista coincide';

  @override
  String get listsNoMatchBody =>
      'Prueba con otra búsqueda o quita los filtros.';

  @override
  String get notificationsClear => 'Borrar todas';

  @override
  String get notificationsClearTitle => '¿Borrar todas las notificaciones?';

  @override
  String get notificationsClearBody =>
      'Se borran de tu lista. No afecta a quien las provocó.';

  @override
  String followersWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'seguidores',
      one: 'seguidor',
    );
    return '$_temp0';
  }

  @override
  String followingWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'seguidos',
      one: 'seguido',
    );
    return '$_temp0';
  }

  @override
  String notifReply(String name, String album, String text) {
    return '$name respondió a tu nota de $album: «$text»';
  }

  @override
  String notifMention(String name, String album, String text) {
    return '$name te respondió en una nota de $album: «$text»';
  }

  @override
  String get threadTitle => 'Respuestas';

  @override
  String threadRatedWhen(String when) {
    return 'Calificó $when';
  }

  @override
  String threadScoreOutOf(String label) {
    return '$label · de 10';
  }

  @override
  String threadRepliesCount(int n) {
    return 'Respuestas · $n';
  }

  @override
  String countReplies(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n respuestas',
      one: '1 respuesta',
      zero: 'Sin respuestas',
    );
    return '$_temp0';
  }

  @override
  String get replyAction => 'Responder';

  @override
  String get replyHint => 'Escribe una respuesta…';

  @override
  String replyHintTo(String name) {
    return 'Responder a $name…';
  }

  @override
  String replyingTo(String handle) {
    return 'Respondiendo a $handle';
  }

  @override
  String get replySend => 'Enviar';

  @override
  String get replyDelete => 'Borrar respuesta';

  @override
  String get replyDeleteHint => 'Se quita del hilo para todas las personas.';

  @override
  String get replyDeleted => 'Respuesta borrada';

  @override
  String replySendFailed(String error) {
    return 'No se pudo enviar: $error';
  }

  @override
  String replyDeleteFailed(String error) {
    return 'No se pudo borrar: $error';
  }

  @override
  String get threadEmptyTitle => 'Nadie ha respondido todavía';

  @override
  String threadEmptyBody(String name) {
    return 'Sé la primera persona en responderle a $name.';
  }

  @override
  String get threadRatingGoneTitle => 'Esta nota ya no existe';

  @override
  String get threadRatingGoneBody =>
      'Quien la escribió la borró, y con ella sus respuestas.';

  @override
  String mentionNotFound(String handle) {
    return 'No encontramos a $handle';
  }

  @override
  String get shareAction => 'Compartir';

  @override
  String get linkCopied => 'Enlace copiado';

  @override
  String shareListMine(String name) {
    return 'Mira mi lista «$name» en Vinilo';
  }

  @override
  String shareRankingMine(String name) {
    return 'Mira mi ranking «$name» en Vinilo';
  }

  @override
  String shareListOf(String name, String owner) {
    return 'Mira la lista «$name» de $owner en Vinilo';
  }

  @override
  String shareRankingOf(String name, String owner) {
    return 'Mira el ranking «$name» de $owner en Vinilo';
  }

  @override
  String shareAlbum(String album, String artist) {
    return '$album de $artist, en Vinilo';
  }

  @override
  String shareRatingMine(int score, String album, String artist) {
    return 'Le di $score/10 a $album de $artist en Vinilo';
  }

  @override
  String shareRatingOf(String name, int score, String album) {
    return '$name le dio $score/10 a $album en Vinilo';
  }

  @override
  String shareArtist(String artist) {
    return '$artist en Vinilo: mira cómo califica la comunidad sus discos';
  }

  @override
  String get shareProfileMine => 'Sigue mi diario de discos en Vinilo';

  @override
  String shareProfileOf(String name) {
    return 'Mira el diario de discos de $name en Vinilo';
  }

  @override
  String get welcomeIssue => 'Nº 001';

  @override
  String get welcomeOverline => 'Diario de discos';

  @override
  String get welcomeHeadline => 'Tu diario de discos empieza aquí.';

  @override
  String get welcomeTryIt => 'Pruébalo';

  @override
  String get signInTitle => 'Iniciar\nsesión';

  @override
  String get signInIdentifierLabel => 'Correo o usuario';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authShow => 'Mostrar';

  @override
  String get authHide => 'Ocultar';

  @override
  String get signInSubmit => 'Entrar';

  @override
  String get authOr => 'o';

  @override
  String get authApple => 'Continuar con Apple';

  @override
  String get authGoogle => 'Continuar con Google';

  @override
  String get signInEmailOnly => 'Por ahora entra con tu correo';

  @override
  String get authEmailMissing => 'Escribe tu correo.';

  @override
  String get signUpTitle => 'Crear\ncuenta';

  @override
  String get authNameLabel => 'Nombre';

  @override
  String get authNameMissing => 'Escribe tu nombre.';

  @override
  String get authUsernameLabel => 'Usuario';

  @override
  String get usernameStatusAvailable => 'Disponible';

  @override
  String get usernameStatusChecking => 'Comprobando…';

  @override
  String get usernameStatusTaken => 'Ocupado';

  @override
  String get authEmailLabel => 'Correo';

  @override
  String get authEmailPlaceholder => 'tu@correo.com';

  @override
  String authPasswordNewPlaceholder(int n) {
    return 'Mínimo $n caracteres';
  }

  @override
  String authPasswordTooShort(int n) {
    return 'La contraseña necesita al menos $n caracteres.';
  }

  @override
  String get signUpTermsStart => 'Al crear tu cuenta aceptas los ';

  @override
  String get signUpTerms => 'Términos';

  @override
  String get signUpTermsMiddle => ' y la ';

  @override
  String get signUpPrivacy => 'Política de privacidad';

  @override
  String get signUpTermsEnd => '.';

  @override
  String get signUpSubmit => 'Crear cuenta';

  @override
  String get onboardingTitle => 'Completa tu\nperfil';

  @override
  String get onboardingBody =>
      'Tu cuenta ya existe. Falta tu nombre y un @usuario para que tus amigos te encuentren.';

  @override
  String get usernameTitle => 'Elige tu\n@usuario';

  @override
  String get linkTitle => 'Guarda tu\ncuenta';

  @override
  String get homePopularWeek => 'Popular esta semana';

  @override
  String get seeAll => 'Ver todo';

  @override
  String get seeAllPlural => 'Ver todos';

  @override
  String get homeFriendsActivity => 'Actividad de tus amigos';

  @override
  String homeActivityNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nuevas',
      one: '1 nueva',
    );
    return '$_temp0';
  }

  @override
  String get feedLiked => 'Te gusta';

  @override
  String get feedLike => 'Me gusta';

  @override
  String get feedComment => 'Comentar';

  @override
  String feedReplies(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n respuestas',
      one: '1 respuesta',
    );
    return '$_temp0';
  }

  @override
  String get popularTitle => 'Popular esta semana';

  @override
  String get popularSubtitle =>
      'Los discos más calificados de los últimos 7 días';

  @override
  String get popularEmptyTitle => 'Semana tranquila';

  @override
  String get popularEmptyBody =>
      'Nadie ha calificado un disco en los últimos 7 días.';

  @override
  String notificationsUnread(int n) {
    return '$n sin leer';
  }

  @override
  String get groupToday => 'Hoy';

  @override
  String get groupYesterday => 'Ayer';

  @override
  String get groupThisWeek => 'Esta semana';

  @override
  String get searchAllArtists => 'Artistas';

  @override
  String get searchAllAlbums => 'Álbumes';

  @override
  String searchAllFor(String query) {
    return 'Resultados de «$query»';
  }

  @override
  String get searchClear => 'Borrar búsqueda';

  @override
  String get albumYourRatingEdit => 'Tu nota · editar';

  @override
  String albumCommunity(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n notas',
      one: '1 nota',
    );
    return 'Comunidad · $_temp0';
  }

  @override
  String get albumHoldToAdd => 'Mantén pulsada para agregar';

  @override
  String get albumFeaturedComments => 'Comentarios destacados';

  @override
  String albumCommentsShown(int shown, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total comentarios',
      one: '1 comentario',
    );
    return '$shown de $_temp0';
  }

  @override
  String get albumSeeArtist => 'Ver artista';

  @override
  String get rateSheetHint => 'Toca o desliza';

  @override
  String get rateSheetSaveMine => 'Guardar mi nota';

  @override
  String rateCompare(int n) {
    return 'Otros discos calificados con $n';
  }

  @override
  String get rateCompareNone => 'ninguno';

  @override
  String get rateCompareTitle => 'Tus discos con';

  @override
  String rateCompareEmpty(int n) {
    return 'Aún no has calificado ningún disco con $n.';
  }

  @override
  String pickerOverlineTrack(String name) {
    return 'Canción · $name';
  }

  @override
  String pickerOverlineAlbum(String name) {
    return 'Disco · $name';
  }

  @override
  String get listFormName => 'Nombre';

  @override
  String get listFormDescription => 'Descripción';

  @override
  String get listFormOptional => 'Opcional';

  @override
  String get artistSortBest => 'Mejor calificados';

  @override
  String get artistNoRatings => 'Sin notas';

  @override
  String get profileFollowsYou => 'te sigue';

  @override
  String get followAction => '+ Seguir';

  @override
  String get profileHowIRate => 'Cómo califico';

  @override
  String get profileHowTheyRate => 'Cómo califica';

  @override
  String profileAverageLabel(String avg) {
    return 'Promedio $avg';
  }

  @override
  String get listsSearchLabel => 'Buscar';

  @override
  String get listsSearchPlaceholder => 'por nombre o por lo que tiene';

  @override
  String get listNewPlus => '+ Nueva lista';

  @override
  String get diaryFilterScore => 'Filtrar por nota';

  @override
  String get listAddPlus => '+ Agregar';

  @override
  String listTracksWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'canciones',
      one: 'canción',
    );
    return '$_temp0';
  }

  @override
  String listAlbumsWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'discos',
      one: 'disco',
    );
    return '$_temp0';
  }

  @override
  String get shareCardRated => 'califiqué';

  @override
  String shareCardListBy(String handle) {
    return 'lista de $handle';
  }

  @override
  String shareCardRankingBy(String handle) {
    return 'ranking de $handle';
  }

  @override
  String get shareCardList => 'lista';

  @override
  String get shareCardRanking => 'ranking';

  @override
  String shareCardAlbums(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n discos',
      one: '1 disco',
    );
    return '$_temp0';
  }

  @override
  String shareCardTracks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n canciones',
      one: '1 canción',
    );
    return '$_temp0';
  }

  @override
  String shareCardSaves(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n guardados',
      one: '1 guardado',
    );
    return '$_temp0';
  }

  @override
  String get shareCardArtist => 'artista';

  @override
  String get shareCardMyAverage => 'mi nota promedio';

  @override
  String shareCardRatedOf(int rated, int total) {
    return '$rated de $total discos';
  }

  @override
  String shareCardSince(String handle, String year) {
    return '$handle · en vinilo desde $year';
  }

  @override
  String get shareCardStatAlbums => 'discos';

  @override
  String get shareCardStatReviews => 'reseñas';

  @override
  String get shareCardStatAverage => 'nota media';

  @override
  String shareCardFavorites(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'mis $n favoritos',
      one: 'mi favorito',
    );
    return '$_temp0';
  }

  @override
  String get shareCardFollowMe => 'Sígueme en Vinilo';

  @override
  String shareCardMyWeek(String range) {
    return 'mi semana · $range';
  }

  @override
  String shareCardWeekCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n discos.',
      one: '1 disco.',
    );
    return '$_temp0';
  }

  @override
  String get shareCardCompatibility => 'compatibilidad';

  @override
  String shareCardFriendAlmostAll(String name) {
    return '$name y yo coincidimos en casi todo.';
  }

  @override
  String shareCardFriendQuiteALot(String name) {
    return '$name y yo coincidimos bastante.';
  }

  @override
  String shareCardFriendOpposites(String name) {
    return '$name y yo somos opuestos musicales.';
  }

  @override
  String get shareCardMe => 'yo';

  @override
  String get shareCardAgree => 'coincidimos';

  @override
  String get shareCardDisagree => 'no coincidimos';

  @override
  String get shareTabStory => 'Historia';

  @override
  String get shareTabSquare => 'Cuadrado';

  @override
  String get shareTargetStories => 'historias';

  @override
  String get shareTargetWhatsapp => 'whatsapp';

  @override
  String get shareTargetSave => 'guardar';

  @override
  String get shareTargetLink => 'enlace';

  @override
  String get shareToStories => 'Compartir en Historias';

  @override
  String get shareImage => 'Compartir imagen';

  @override
  String get shareImageSaved => 'Imagen guardada';

  @override
  String get shareSaveDenied =>
      'Vinilo no tiene permiso para guardar en tus fotos. Actívalo en Ajustes.';

  @override
  String get shareImageFailed =>
      'No se pudo preparar la imagen. Inténtalo de nuevo.';

  @override
  String get shareImageUnsupported =>
      'Esta versión de la app todavía no puede compartir imágenes.';

  @override
  String get menuShareProfile => 'Compartir perfil';

  @override
  String get menuMute => 'Silenciar';

  @override
  String get menuMuteHint => 'No verás su actividad';

  @override
  String get menuUnmute => 'Dejar de silenciar';

  @override
  String get menuUnmuteHint => 'Volverás a ver su actividad';

  @override
  String menuReportUser(String handle) {
    return 'Reportar a $handle';
  }

  @override
  String menuBlockUser(String handle) {
    return 'Bloquear a $handle';
  }

  @override
  String menuUnblockUser(String handle) {
    return 'Desbloquear a $handle';
  }

  @override
  String menuRatingOf(String handle) {
    return 'Calificación de $handle';
  }

  @override
  String menuReplyOf(String handle) {
    return 'Respuesta de $handle';
  }

  @override
  String get menuHideComment => 'Ocultar este comentario';

  @override
  String get menuHideHint => 'Solo para ti';

  @override
  String get menuReportComment => 'Reportar comentario';

  @override
  String get menuMore => 'Más opciones';

  @override
  String get commentHidden => 'Comentario oculto';

  @override
  String userMuted(String handle) {
    return 'Silenciaste a $handle';
  }

  @override
  String userUnmuted(String handle) {
    return 'Ya no silencias a $handle';
  }

  @override
  String reportOverlineComment(String handle) {
    return 'Reportar comentario de $handle';
  }

  @override
  String get reportTitle => '¿Qué está pasando?';

  @override
  String reportAnonymous(String handle) {
    return 'Tu reporte es anónimo. $handle no sabrá que fuiste tú.';
  }

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonSpamHint => 'Publicidad, enlaces o mensajes repetidos';

  @override
  String get reportReasonHarassment => 'Acoso o bullying';

  @override
  String get reportReasonHarassmentHint => 'Ataques o insultos a alguien';

  @override
  String get reportReasonHarassmentShort => 'Acoso';

  @override
  String get reportReasonHate => 'Discurso de odio';

  @override
  String get reportReasonHateHint => 'Contra un grupo o identidad';

  @override
  String get reportReasonHateShort => 'Odio';

  @override
  String get reportReasonSexual => 'Contenido sexual';

  @override
  String get reportReasonSexualHint => 'Texto o imagen explícita';

  @override
  String get reportReasonSexualShort => 'Sexual';

  @override
  String get reportReasonImpersonation => 'Suplantación';

  @override
  String get reportReasonImpersonationHint => 'Se hace pasar por otra persona';

  @override
  String get reportReasonViolence => 'Violencia o amenazas';

  @override
  String get reportReasonViolenceHint => 'Daño a alguien o a sí mismo';

  @override
  String get reportReasonViolenceShort => 'Violencia';

  @override
  String get reportReasonOther => 'Otro';

  @override
  String get reportReasonOtherHint => 'Cuéntanos en los detalles';

  @override
  String get reportDetailsHint => 'Agrega detalles (opcional)';

  @override
  String get reportSend => 'Enviar reporte';

  @override
  String reportFailed(String error) {
    return 'No se pudo enviar el reporte: $error';
  }

  @override
  String reportNumber(String n) {
    return 'Reporte Nº $n';
  }

  @override
  String get reportSentTitle => 'Gracias por avisarnos';

  @override
  String get reportSentBodyComment =>
      'Ya ocultamos este comentario para ti. Nuestro equipo lo revisa en menos de 24 horas y te avisamos qué decidimos.';

  @override
  String get reportSentBodyUser =>
      'Nuestro equipo revisa esta cuenta en menos de 24 horas y te avisamos qué decidimos.';

  @override
  String reportAlsoBlock(String handle) {
    return 'Bloquear también a $handle';
  }

  @override
  String get reportAlsoBlockHint => 'No podrá ver tu perfil ni responderte';

  @override
  String get reportSeeMine => 'Ver mis reportes en Ajustes';

  @override
  String blockTitle(String handle) {
    return '¿Bloquear a $handle?';
  }

  @override
  String get blockRule1 => 'No podrá ver tu perfil, tus notas ni tus listas.';

  @override
  String get blockRule2 => 'No podrá seguirte, responderte ni mencionarte.';

  @override
  String get blockRule3 => 'Dejarán de seguirse mutuamente.';

  @override
  String get blockRule4 =>
      'Sus calificaciones y comentarios desaparecen de tu inicio.';

  @override
  String get blockNote =>
      'No le avisaremos. Puedes desbloquearlo cuando quieras en Ajustes.';

  @override
  String get blockConfirm => 'Bloquear';

  @override
  String blockFailed(String error) {
    return 'No se pudo bloquear: $error';
  }

  @override
  String userBlocked(String handle) {
    return 'Bloqueaste a $handle';
  }

  @override
  String get blockedTag => 'Bloqueado';

  @override
  String get blockedTitle => 'Bloqueaste a esta cuenta';

  @override
  String get blockedBody =>
      'No ves su actividad y no puede interactuar contigo.';

  @override
  String get unblock => 'Desbloquear';

  @override
  String get unblockedTag => 'Desbloqueado';

  @override
  String get unblockedTitle => 'Ya no está bloqueado';

  @override
  String get unblockedBody =>
      'Pueden volver a verse. Tendrás que seguirlo de nuevo si quieres.';

  @override
  String get followPlain => 'Seguir';

  @override
  String get followingPlain => 'Siguiendo';

  @override
  String unblockFailed(String error) {
    return 'No se pudo desbloquear: $error';
  }

  @override
  String get settingsPrivacy => 'Privacidad';

  @override
  String get privacyTitle => 'Privacidad y seguridad';

  @override
  String get privacyFilter => 'Filtrar comentarios ofensivos';

  @override
  String get privacyFilterHint =>
      'Ocultamos palabras ofensivas automáticamente';

  @override
  String get privacyMyReports => 'Mis reportes';

  @override
  String get privacyMuted => 'Cuentas silenciadas';

  @override
  String get privacyBlocked => 'Cuentas bloqueadas';

  @override
  String get privacyNoBlocked => 'No tienes cuentas bloqueadas.';

  @override
  String privacyBlockedAgo(String when) {
    return 'Bloqueado $when';
  }

  @override
  String privacyMutedAgo(String when) {
    return 'Silenciado $when';
  }

  @override
  String get privacyNoMuted => 'No has silenciado a nadie.';

  @override
  String get privacyNoReports => 'No has enviado reportes.';

  @override
  String get privacySupportLead => '¿Algo urgente? Escríbenos a ';

  @override
  String get emailCopied => 'Correo copiado';

  @override
  String get reportStatusOpen => 'En revisión';

  @override
  String get reportStatusDismissed => 'Revisado · sin cambios';

  @override
  String get reportStatusRemoved => 'Revisado · contenido retirado';

  @override
  String reportTargetUser(String handle) {
    return 'Cuenta de $handle';
  }

  @override
  String reportTargetComment(String handle) {
    return 'Comentario de $handle';
  }

  @override
  String get timeToday => 'hoy';

  @override
  String timeWeeksAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'hace $n semanas',
      one: 'hace 1 semana',
    );
    return '$_temp0';
  }

  @override
  String timeMonthsAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'hace $n meses',
      one: 'hace 1 mes',
    );
    return '$_temp0';
  }

  @override
  String timeYearsAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'hace $n años',
      one: 'hace 1 año',
    );
    return '$_temp0';
  }

  @override
  String countAccounts(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cuentas',
      one: '1 cuenta',
    );
    return '$_temp0';
  }

  @override
  String countReports(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n reportes',
      one: '1 reporte',
    );
    return '$_temp0';
  }

  @override
  String get commentHiddenBody =>
      'Lo ocultaste o lo reportaste, así que ya no aparece para ti.';

  @override
  String get commentShowAgain => 'Mostrar de nuevo';

  @override
  String get onboardStep1 => 'Paso 1 de 2';

  @override
  String get onboardStep1Label => 'Tus gustos';

  @override
  String get onboardTastesTitle => 'Elige 3 discos que te encanten';

  @override
  String get onboardTastesBody =>
      'Con eso armamos tu inicio y te mostramos gente con gustos parecidos.';

  @override
  String get onboardSearchHint => 'un disco o artista';

  @override
  String get genrePopular => 'Populares';

  @override
  String get genreRock => 'Rock';

  @override
  String get genreLatinPop => 'Pop latino';

  @override
  String get genreHipHop => 'Hip hop';

  @override
  String get genreElectronic => 'Electrónica';

  @override
  String get genrePop => 'Pop';

  @override
  String get genreRnb => 'R&B';

  @override
  String get genreIndie => 'Indie';

  @override
  String onboardPicked(int n) {
    return '$n de 3';
  }

  @override
  String onboardPickedReady(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n elegidos · listo',
      one: '1 elegido · listo',
    );
    return '$_temp0';
  }

  @override
  String get onboardContinue => 'Continuar';

  @override
  String get onboardTastesError => 'No pudimos cargar los discos.';

  @override
  String onboardNoResults(String query) {
    return 'No encontramos “$query”. Prueba con otro nombre.';
  }

  @override
  String get onboardStep2 => 'Paso 2 de 2 · opcional';

  @override
  String get onboardSkip => 'Saltar';

  @override
  String get onboardFollowTitle => 'Sigue a gente con tu oído';

  @override
  String get onboardFollowBody =>
      'Así tu inicio no empieza vacío. Puedes hacerlo después.';

  @override
  String get onboardContacts => 'Buscar en tus contactos';

  @override
  String get onboardContactsHint => 'Encuentra amigos que ya usan Vinilo';

  @override
  String onboardByTastes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Por tus $n discos',
      one: 'Por tu disco',
    );
    return '$_temp0';
  }

  @override
  String get onboardPopularPeople => 'Populares en Vinilo';

  @override
  String suggestSameTen(String album) {
    return 'También le puso 10 a $album';
  }

  @override
  String suggestRated(String album, int score) {
    return 'Calificó $album con $score';
  }

  @override
  String suggestPopular(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n seguidores',
      one: '1 seguidor',
    );
    return 'Popular en Vinilo · $_temp0';
  }

  @override
  String get onboardStartAlone => 'Empezar sin seguir a nadie';

  @override
  String onboardStartFollowing(int n) {
    return 'Empezar · sigues a $n';
  }

  @override
  String get onboardNoSuggestions =>
      'Todavía no hay a quién sugerirte. Puedes buscar gente después, en Buscar.';

  @override
  String get findPeopleTitle => 'Buscar personas';

  @override
  String get findPeopleHint => 'Nombre o @usuario';

  @override
  String get findPeopleEmpty => 'Nadie con ese nombre.';

  @override
  String get findPeopleBody =>
      'Sigue a quien califica lo que te gusta y tu inicio se llena solo.';

  @override
  String get profileStatsTab => 'Estadísticas';

  @override
  String get statsPeriodMonth => 'Este mes';

  @override
  String get statsPeriodYear => 'Este año';

  @override
  String get statsPeriodAll => 'Siempre';

  @override
  String get statsRated => 'Discos calificados';

  @override
  String get statsMyAverage => 'Tu nota promedio';

  @override
  String statsCompareHigher(String amount, String average) {
    return 'Calificas *$amount puntos más alto* que la comunidad. Su promedio en los mismos discos es $average.';
  }

  @override
  String statsCompareLower(String amount, String average) {
    return 'Calificas *$amount puntos más bajo* que la comunidad. Su promedio en los mismos discos es $average.';
  }

  @override
  String statsCompareSame(String average) {
    return 'Calificas *igual* que la comunidad. Su promedio en los mismos discos es $average.';
  }

  @override
  String get statsHowYouRate => 'Cómo calificas';

  @override
  String statsHistSelected(int n, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n discos',
      one: '1 disco',
    );
    return '$_temp0 con $score';
  }

  @override
  String get statsTopArtists => 'Artistas que más escuchas';

  @override
  String statsArtistAverage(String average) {
    return 'prom. $average';
  }

  @override
  String get statsByDecade => 'Por década';

  @override
  String get statsRhythm => 'Tu ritmo';

  @override
  String statsRhythmLabel(String year) {
    return 'Discos por mes · $year';
  }

  @override
  String statsStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n semanas',
      one: '1 semana',
    );
    return 'Racha actual: *$_temp0* calificando al menos un disco.';
  }

  @override
  String get statsStreakNone =>
      'Sin racha por ahora: califica un disco esta semana para empezar una.';

  @override
  String get statsTime => 'Tiempo escuchando';

  @override
  String get statsTimeLabel => 'Suma de tus discos';

  @override
  String statsTimeHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'horas',
      one: 'hora',
    );
    return '$_temp0';
  }

  @override
  String statsTimeDays(String days) {
    return '≈ $days días seguidos';
  }

  @override
  String statsTimeAlbums(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n discos',
      one: '1 disco',
    );
    return '≈ $_temp0';
  }

  @override
  String statsTimeLoading(int done, int total) {
    return 'Calculando · $done de $total';
  }

  @override
  String get statsGenres => 'Géneros';

  @override
  String get statsGenreOther => 'Otros';

  @override
  String get statsCountries => 'De dónde vienen';

  @override
  String statsCountriesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n países',
      one: '1 país',
    );
    return '$_temp0';
  }

  @override
  String get statsFriends => 'Afinidad con amigos';

  @override
  String get statsMostAffine => 'Más afín';

  @override
  String get statsLeastAffine => 'Menos afín';

  @override
  String statsCommon(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n discos en común',
      one: '1 disco en común',
    );
    return '$_temp0';
  }

  @override
  String get statsShare => 'Compartir mis estadísticas';

  @override
  String get statsEmptyPeriod => 'Todavía no calificas nada en este periodo.';

  @override
  String get shareStatsTitleYear => 'Mi año\nen discos';

  @override
  String get shareStatsTitleMonth => 'Mi mes\nen discos';

  @override
  String get shareStatsTitleAll => 'Mi vida\nen discos';

  @override
  String get shareStatsAlbums => 'Discos';

  @override
  String get shareStatsAverage => 'Promedio';

  @override
  String shareStatsMode(int score) {
    return 'Mi nota más común: $score';
  }

  @override
  String get shareStatsArtistYear => 'Artista del año';

  @override
  String get shareStatsArtistMonth => 'Artista del mes';

  @override
  String get shareStatsArtistAll => 'Artista más escuchado';

  @override
  String shareStatsSince(String year) {
    return 'Desde $year';
  }

  @override
  String get shareStatsStories => 'Historias';

  @override
  String get shareStatsWhatsapp => 'WhatsApp';

  @override
  String get shareStatsSave => 'Guardar';

  @override
  String get shareStatsCopy => 'Copiar link';

  @override
  String get shareStatsMine => 'Mis estadísticas en Vinilo';

  @override
  String recoverStep(int n) {
    return 'Paso $n de 3';
  }

  @override
  String get recoverTitle => 'Recuperar\ncontraseña';

  @override
  String get recoverEmailBody =>
      'Escribe el correo de tu cuenta y te mandamos un código de 6 dígitos.';

  @override
  String get recoverSendCode => 'Enviar código';

  @override
  String get recoverRemembered => '¿Ya la recordaste? ';

  @override
  String get recoverCodeTitle => 'Revisa tu\ncorreo';

  @override
  String recoverCodeBody(String email) {
    return 'Mandamos un código a *$email*. Vence en 10 minutos.';
  }

  @override
  String recoverWrongCode(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Código incorrecto · te quedan $n intentos',
      one: 'Código incorrecto · te queda 1 intento',
    );
    return '$_temp0';
  }

  @override
  String recoverResendIn(String time) {
    return 'Reenviar en $time';
  }

  @override
  String get recoverResend => 'Reenviar código';

  @override
  String get recoverExpired => 'El código venció. Pide otro.';

  @override
  String get recoverTooMany => 'Demasiados intentos. Pide un código nuevo.';

  @override
  String recoverThrottled(int n) {
    return 'Espera $n s para pedir otro código.';
  }

  @override
  String get recoverCodeSent => 'Te mandamos un código nuevo.';

  @override
  String get recoverNewTitle => 'Nueva\ncontraseña';

  @override
  String get recoverNewLabel => 'Contraseña nueva';

  @override
  String get recoverRepeatLabel => 'Repetir contraseña';

  @override
  String get recoverRuleLength => 'Al menos 8 caracteres';

  @override
  String get recoverRuleNumber => 'Un número';

  @override
  String get recoverRuleDifferent => 'Distinta a la anterior';

  @override
  String get recoverMismatch => 'Las contraseñas no coinciden.';

  @override
  String get recoverSamePassword => 'Es la misma de antes: elige otra.';

  @override
  String get recoverWeak => 'Usa al menos 8 caracteres y un número.';

  @override
  String get recoverSave => 'Guardar y entrar';

  @override
  String get recoverDoneLabel => 'Contraseña';

  @override
  String get recoverDoneUpdated => 'Actualizada';

  @override
  String recoverDoneTitle(String name) {
    return 'Todo listo, $name';
  }

  @override
  String get recoverDoneTitleNoName => 'Todo listo';

  @override
  String get recoverDoneBody =>
      'Cambiaste tu contraseña. Cerramos tu sesión en otros dispositivos por seguridad.';

  @override
  String get recoverGo => 'Ir a Vinilo';

  @override
  String get recoverServer =>
      'No pudimos hacerlo ahora. Vuelve a intentarlo en un momento.';

  @override
  String get signInWrongPassword =>
      'La contraseña no coincide con ese usuario.';

  @override
  String get keypadDelete => 'Borrar';

  @override
  String get offlineOverline => 'Sin señal';

  @override
  String get offlineSide => 'Lado B';

  @override
  String get offlineTitle => 'Sin conexión';

  @override
  String get offlineBody =>
      'Revisa tu wifi o tus datos. Las notas que guardes mientras tanto se suben cuando vuelvas a tener señal.';

  @override
  String get offlineConnecting => 'Conectando…';

  @override
  String get offlineSaved => 'Ver mis discos guardados';

  @override
  String get offlineBanner => 'Sin conexión · mostrando lo último guardado';

  @override
  String get serverErrorTitle => 'Se rayó el disco';

  @override
  String get serverErrorBody =>
      'Algo falló de nuestro lado. No es tu conexión. Inténtalo de nuevo en unos segundos.';

  @override
  String serverErrorCode(String code) {
    return 'Código · $code';
  }

  @override
  String get serverErrorRetry => 'Intentar de nuevo';

  @override
  String get serverErrorReport => 'Reportar el problema';

  @override
  String get problemReported => 'Gracias. Ya recibimos el aviso.';

  @override
  String problemCopied(String email) {
    return 'Código copiado. Escríbenos a $email.';
  }

  @override
  String get rateSaveFailedTitle => 'No pudimos guardar tu nota';

  @override
  String get rateSaveFailedBody =>
      'No perdiste nada, la guardamos en tu teléfono.';

  @override
  String get ratePendingLabel => 'Tu nota · por subir';

  @override
  String get homeEmptyTitle => 'Tu inicio está muy callado';

  @override
  String get homeEmptyBody =>
      'Aquí verás lo que califican las personas que sigues. Empieza por gente con gustos parecidos a los tuyos.';

  @override
  String get homeEmptyFind => 'Encontrar gente';

  @override
  String get homeEmptyRate => 'Calificar un disco';

  @override
  String get profileEmptyTitle => 'Tu diario está en blanco';

  @override
  String get profileEmptyBody =>
      'Califica tu primer disco y aquí empezarán a aparecer tus notas, favoritos y estadísticas.';

  @override
  String get profileEmptyAction => 'Calificar mi primer disco';

  @override
  String get searchZeroResults => '0 resultados';

  @override
  String searchNotFound(String query) {
    return 'No encontramos “$query”';
  }

  @override
  String get searchNotFoundBody =>
      'Revisa cómo está escrito o busca solo por artista.';

  @override
  String get searchDidYouMean => '¿Quisiste decir?';

  @override
  String get searchMissingLead => '¿Falta un disco en Vinilo? ';

  @override
  String get searchMissingAction => 'Pídenos que lo agreguemos';

  @override
  String searchRequestSent(String query) {
    return 'Anotado: vamos a buscar “$query”.';
  }

  @override
  String get notificationsUpToDate => 'Al día';

  @override
  String get notificationsNothingNew => 'Nada nuevo por ahora';

  @override
  String get notificationsNothingNewBody =>
      'Te avisaremos cuando alguien te siga, responda a tus notas o le guste lo que escribes.';
}
