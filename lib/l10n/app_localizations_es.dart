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
  String get score1 => 'Insufrible';

  @override
  String get score2 => 'Malo';

  @override
  String get score3 => 'Flojo';

  @override
  String get score4 => 'Meh';

  @override
  String get score5 => 'Regular';

  @override
  String get score6 => 'Está bien';

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
  String authPasswordNewHint(int n) {
    return 'Contraseña (mínimo $n caracteres)';
  }

  @override
  String get authPasswordHint => 'Contraseña';

  @override
  String get authEmailHint => 'Correo';

  @override
  String get authShowPassword => 'Mostrar contraseña';

  @override
  String get authHidePassword => 'Ocultar contraseña';

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
  String get rateSheetPrompt => 'Toca o desliza para elegir tu nota';

  @override
  String get rateSheetCommentHint => 'Agregar un comentario (opcional)';

  @override
  String get rateSheetSave => 'Guardar en mi diario';

  @override
  String get rateSheetUpdate => 'Actualizar mi nota';

  @override
  String get rateSheetDelete => 'Borrar nota';

  @override
  String get usernameCurrent => 'Ese es tu @usuario actual.';

  @override
  String get usernameChecking => 'Comprobando…';

  @override
  String usernameAvailable(String username) {
    return '@$username está libre.';
  }

  @override
  String get usernameOffline => 'No se pudo comprobar. Revisa tu conexión.';

  @override
  String get usernameHint => 'tu_usuario';

  @override
  String get welcomeTitleStart => 'Tu diario de ';

  @override
  String get welcomeTitleAccent => 'discos';

  @override
  String get welcomeTitleEnd => ' empieza aquí.';

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
  String get signInTitleStart => 'Hola de ';

  @override
  String get signInTitleAccent => 'nuevo';

  @override
  String get signInTitleEnd => '.';

  @override
  String get signInSubtitle => 'Entra con tu correo y tu contraseña.';

  @override
  String get signInNoAccount => '¿Aún no tienes cuenta? ';

  @override
  String get signInCreateOne => 'Créala';

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
  String get signUpTitleStart => 'Crea tu ';

  @override
  String get signUpTitleAccent => 'cuenta';

  @override
  String get signUpTitleEnd => '.';

  @override
  String get signUpSubtitle =>
      'Con tu correo y una contraseña. Después eliges tu nombre, tu color y tu @usuario.';

  @override
  String get signUpHaveAccount => '¿Ya tienes cuenta? ';

  @override
  String get signUpSignIn => 'Inicia sesión';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get usernameTitleStart => 'Elige tu ';

  @override
  String get usernameTitleAccent => '@usuario';

  @override
  String get usernameTitleEnd => '.';

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
  String get linkTitleStart => 'Guarda tu ';

  @override
  String get linkTitleAccent => 'cuenta';

  @override
  String linkTitleEnd(String name) {
    return ', $name.';
  }

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
  String get onboardingTitleStart => 'Así te ';

  @override
  String get onboardingTitleAccent => 'verán';

  @override
  String get onboardingTitleEnd => '.';

  @override
  String get onboardingSubtitle =>
      'Tu nombre, tu color y un @usuario único para que te encuentren. Todo se puede cambiar después.';

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
  String get yourUsernameLabel => 'TU @USUARIO';

  @override
  String get yourColorLabel => 'TU COLOR';

  @override
  String get bannerPlaceholder => 'Foto de fondo';

  @override
  String get homePopular => 'Popular';

  @override
  String get homeActivity => 'Actividad';

  @override
  String get homeActivitySubtitle => 'De tus amigos';

  @override
  String get homeFollowTitle => 'Sigue a tus amigos';

  @override
  String get homeFollowBody =>
      'Aquí verás lo que califican las personas que sigues. Búscalas en la pestaña Buscar por su nombre o su @usuario.';

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
  String get loadMore => 'Cargar más';

  @override
  String get searchRecent => 'RECIENTES';

  @override
  String get searchSuggestions => 'PARA EMPEZAR';

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
  String notificationsNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nuevas',
      one: '1 nueva',
    );
    return '$_temp0';
  }

  @override
  String notificationsError(String error) {
    return 'No se pudieron cargar: $error';
  }

  @override
  String get notificationsEmptyTitle => 'Nada por ahora';

  @override
  String get notificationsEmptyBody =>
      'Aquí verás cuando alguien te siga, le guste una de tus notas o guarde una de tus listas.';

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
  String get sortBy => 'ORDENAR POR';

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
  String get listDescriptionHint => 'Descripción (opcional)';

  @override
  String get listFormKind => 'TIPO';

  @override
  String get listKindListHint => 'Sin orden fijo';

  @override
  String get listKindRankingHint => 'Numerado, del 1 en adelante';

  @override
  String get listFormContent => '¿DE QUÉ?';

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
  String get artistUnrated =>
      'Nadie ha calificado un disco de este artista todavía';

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
  String get listCoverHint => 'Una foto en lugar del mosaico';

  @override
  String get listCoverRemove => 'Quitar portada';

  @override
  String get listCoverRemoveHint =>
      'Vuelve el mosaico con las portadas de la lista';

  @override
  String get listGoneBody => 'Su autor la borró.';

  @override
  String get listYours => 'Tu lista';

  @override
  String listBy(String name) {
    return 'por $name';
  }

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
  String get albumSelectHint => 'Toca las que quieras agregar';

  @override
  String get albumLongPressHint =>
      'Mantén pulsada una para agregarla a una lista';

  @override
  String seeMore(int n) {
    return 'Ver más ($n)';
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
  String get albumUnratedByAnyone => 'Nadie ha calificado este disco todavía';

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
  String get favoritesMine => 'Tres discos y tres artistas que te definen';

  @override
  String get favoritesTheirs => 'Tres discos y tres artistas que le definen';

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
  String get listsMine => 'Tus listas';

  @override
  String listsOf(String name) {
    return 'Listas de $name';
  }

  @override
  String get listsMineSubtitle => 'Listas y rankings de canciones o discos';

  @override
  String get listsTheirsSubtitle => 'Sus listas y rankings';

  @override
  String get listsEmptyMine =>
      'Todavía no tienes listas. Crea una con \"Nueva lista\" o desde la pantalla de un disco.';

  @override
  String get listsEmptyTheirs => 'Todavía no tiene listas.';

  @override
  String get listsSaved => 'Guardadas';

  @override
  String get listsSavedSubtitle =>
      'Listas de otras personas que guardaste. Solo tú las ves aquí.';

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
  String listsMineTab(int n) {
    return 'Mías ($n)';
  }

  @override
  String listsSavedTab(int n) {
    return 'Guardadas ($n)';
  }

  @override
  String get listsSearchHint => 'Buscar por nombre o por lo que tiene';

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
  String get listsClearFilters => 'Quitar filtros';

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
}
