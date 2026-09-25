import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// Nombre de la app
  ///
  /// In es, this message translates to:
  /// **'Vinilo'**
  String get appName;

  /// No description provided for @timeNow.
  ///
  /// In es, this message translates to:
  /// **'ahora'**
  String get timeNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In es, this message translates to:
  /// **'hace {n} min'**
  String timeMinutesAgo(int n);

  /// No description provided for @timeHoursAgo.
  ///
  /// In es, this message translates to:
  /// **'hace {n} h'**
  String timeHoursAgo(int n);

  /// No description provided for @timeYesterday.
  ///
  /// In es, this message translates to:
  /// **'ayer'**
  String get timeYesterday;

  /// No description provided for @timeDaysAgo.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{hace 1 día} other{hace {n} días}}'**
  String timeDaysAgo(int n);

  /// No description provided for @errorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Algo falló. Vuelve a intentarlo.'**
  String get errorGeneric;

  /// No description provided for @errorOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Revisa tu internet y vuelve a intentar.'**
  String get errorOffline;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para hacer eso.'**
  String get errorPermissionDenied;

  /// No description provided for @authEmailInUse.
  ///
  /// In es, this message translates to:
  /// **'Ese correo ya tiene una cuenta. Inicia sesión o usa otro.'**
  String get authEmailInUse;

  /// No description provided for @authInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Ese correo no parece válido.'**
  String get authInvalidEmail;

  /// No description provided for @authWeakPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es muy débil: usa al menos 6 caracteres.'**
  String get authWeakPassword;

  /// No description provided for @authMissingPassword.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu contraseña.'**
  String get authMissingPassword;

  /// No description provided for @authWrongCredentials.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos.'**
  String get authWrongCredentials;

  /// No description provided for @authUserDisabled.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta está deshabilitada.'**
  String get authUserDisabled;

  /// No description provided for @authTooManyRequests.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Espera un momento y vuelve a probar.'**
  String get authTooManyRequests;

  /// No description provided for @authOperationNotAllowed.
  ///
  /// In es, this message translates to:
  /// **'El acceso con correo y contraseña no está habilitado todavía.'**
  String get authOperationNotAllowed;

  /// No description provided for @authCredentialInUse.
  ///
  /// In es, this message translates to:
  /// **'Ese correo ya pertenece a otra cuenta. Inicia sesión con ella o usa otro correo.'**
  String get authCredentialInUse;

  /// No description provided for @authProviderLinked.
  ///
  /// In es, this message translates to:
  /// **'Esta sesión ya tiene un correo vinculado.'**
  String get authProviderLinked;

  /// No description provided for @authRequiresRecentLogin.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, vuelve a iniciar sesión antes de hacer esto.'**
  String get authRequiresRecentLogin;

  /// No description provided for @authSessionExpired.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión venció. Vuelve a iniciar sesión.'**
  String get authSessionExpired;

  /// No description provided for @usernameTaken.
  ///
  /// In es, this message translates to:
  /// **'@{username} ya está en uso. Prueba con otro.'**
  String usernameTaken(String username);

  /// No description provided for @usernameEmpty.
  ///
  /// In es, this message translates to:
  /// **'Elige tu @usuario.'**
  String get usernameEmpty;

  /// No description provided for @usernameTooShort.
  ///
  /// In es, this message translates to:
  /// **'Mínimo {n} caracteres.'**
  String usernameTooShort(int n);

  /// No description provided for @usernameTooLong.
  ///
  /// In es, this message translates to:
  /// **'Máximo {n} caracteres.'**
  String usernameTooLong(int n);

  /// No description provided for @usernameBadChars.
  ///
  /// In es, this message translates to:
  /// **'Solo letras minúsculas, números, punto y guion bajo.'**
  String get usernameBadChars;

  /// No description provided for @listKindList.
  ///
  /// In es, this message translates to:
  /// **'Lista'**
  String get listKindList;

  /// No description provided for @listKindRanking.
  ///
  /// In es, this message translates to:
  /// **'Ranking'**
  String get listKindRanking;

  /// No description provided for @listTypeTracks.
  ///
  /// In es, this message translates to:
  /// **'Canciones'**
  String get listTypeTracks;

  /// No description provided for @listTypeAlbums.
  ///
  /// In es, this message translates to:
  /// **'Discos'**
  String get listTypeAlbums;

  /// No description provided for @countTracks.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 canción} other{{n} canciones}}'**
  String countTracks(int n);

  /// No description provided for @countAlbums.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 disco} other{{n} discos}}'**
  String countAlbums(int n);

  /// No description provided for @addedTracks.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Se agregó 1 canción} other{Se agregaron {n} canciones}}'**
  String addedTracks(int n);

  /// No description provided for @addedAlbums.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Se agregó 1 disco} other{Se agregaron {n} discos}}'**
  String addedAlbums(int n);

  /// No description provided for @listAddTracks.
  ///
  /// In es, this message translates to:
  /// **'Agregar canciones'**
  String get listAddTracks;

  /// No description provided for @listAddAlbums.
  ///
  /// In es, this message translates to:
  /// **'Agregar discos'**
  String get listAddAlbums;

  /// No description provided for @listFullTypeTrackList.
  ///
  /// In es, this message translates to:
  /// **'Lista de canciones'**
  String get listFullTypeTrackList;

  /// No description provided for @listFullTypeTrackRanking.
  ///
  /// In es, this message translates to:
  /// **'Ranking de canciones'**
  String get listFullTypeTrackRanking;

  /// No description provided for @listFullTypeAlbumList.
  ///
  /// In es, this message translates to:
  /// **'Lista de discos'**
  String get listFullTypeAlbumList;

  /// No description provided for @listFullTypeAlbumRanking.
  ///
  /// In es, this message translates to:
  /// **'Ranking de discos'**
  String get listFullTypeAlbumRanking;

  /// No description provided for @addAlreadyInList.
  ///
  /// In es, this message translates to:
  /// **'Ya estaba en la lista'**
  String get addAlreadyInList;

  /// No description provided for @addDuplicates.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 ya estaba} other{{n} ya estaban}}'**
  String addDuplicates(int n);

  /// No description provided for @addOverflow.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 no cupo (tope de {max})} other{{n} no cupieron (tope de {max})}}'**
  String addOverflow(int n, int max);

  /// No description provided for @score1.
  ///
  /// In es, this message translates to:
  /// **'Terrible'**
  String get score1;

  /// No description provided for @score2.
  ///
  /// In es, this message translates to:
  /// **'Muy malo'**
  String get score2;

  /// No description provided for @score3.
  ///
  /// In es, this message translates to:
  /// **'Malo'**
  String get score3;

  /// No description provided for @score4.
  ///
  /// In es, this message translates to:
  /// **'Flojo'**
  String get score4;

  /// No description provided for @score5.
  ///
  /// In es, this message translates to:
  /// **'Regular'**
  String get score5;

  /// No description provided for @score6.
  ///
  /// In es, this message translates to:
  /// **'Aceptable'**
  String get score6;

  /// No description provided for @score7.
  ///
  /// In es, this message translates to:
  /// **'Bueno'**
  String get score7;

  /// No description provided for @score8.
  ///
  /// In es, this message translates to:
  /// **'Muy bueno'**
  String get score8;

  /// No description provided for @score9.
  ///
  /// In es, this message translates to:
  /// **'Excelente'**
  String get score9;

  /// No description provided for @score10.
  ///
  /// In es, this message translates to:
  /// **'Obra maestra'**
  String get score10;

  /// No description provided for @albumTypeSingle.
  ///
  /// In es, this message translates to:
  /// **'Sencillo'**
  String get albumTypeSingle;

  /// No description provided for @albumTypeCompilation.
  ///
  /// In es, this message translates to:
  /// **'Recopilatorio'**
  String get albumTypeCompilation;

  /// No description provided for @albumTypeAlbum.
  ///
  /// In es, this message translates to:
  /// **'Álbum'**
  String get albumTypeAlbum;

  /// No description provided for @notifFollow.
  ///
  /// In es, this message translates to:
  /// **'{name} empezó a seguirte'**
  String notifFollow(String name);

  /// No description provided for @notifLikeRating.
  ///
  /// In es, this message translates to:
  /// **'A {name} le gustó tu nota de {album}'**
  String notifLikeRating(String name, String album);

  /// No description provided for @notifSomeAlbum.
  ///
  /// In es, this message translates to:
  /// **'un disco'**
  String get notifSomeAlbum;

  /// No description provided for @notifLikeList.
  ///
  /// In es, this message translates to:
  /// **'A {name} le gustó tu lista {list}'**
  String notifLikeList(String name, String list);

  /// No description provided for @notifSaveList.
  ///
  /// In es, this message translates to:
  /// **'{name} guardó tu lista {list}'**
  String notifSaveList(String name, String list);

  /// No description provided for @deleteErrorNoEndpoint.
  ///
  /// In es, this message translates to:
  /// **'Falta la URL de la función (--dart-define=SPOTIFY_FN_URL=…).'**
  String get deleteErrorNoEndpoint;

  /// No description provided for @deleteErrorWrongPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña no es correcta.'**
  String get deleteErrorWrongPassword;

  /// No description provided for @deleteErrorReauth.
  ///
  /// In es, this message translates to:
  /// **'No se pudo comprobar tu contraseña ({code}).'**
  String deleteErrorReauth(String code);

  /// No description provided for @deleteErrorNoSession.
  ///
  /// In es, this message translates to:
  /// **'No hay sesión.'**
  String get deleteErrorNoSession;

  /// No description provided for @deleteErrorTimeout.
  ///
  /// In es, this message translates to:
  /// **'El borrado está tardando más de la cuenta. Vuelve a intentarlo: retoma donde quedó.'**
  String get deleteErrorTimeout;

  /// No description provided for @deleteErrorRecentLogin.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a escribir tu contraseña para borrar la cuenta.'**
  String get deleteErrorRecentLogin;

  /// No description provided for @deleteErrorServer.
  ///
  /// In es, this message translates to:
  /// **'No se pudo borrar la cuenta ({status}). Vuelve a intentarlo.'**
  String deleteErrorServer(String status);

  /// No description provided for @spotifyNotConfigured.
  ///
  /// In es, this message translates to:
  /// **'Falta la URL de la función de Spotify. Corre la app con --dart-define=SPOTIFY_FN_URL=…'**
  String get spotifyNotConfigured;

  /// No description provided for @spotifyTimeout.
  ///
  /// In es, this message translates to:
  /// **'Spotify tardó demasiado en responder.'**
  String get spotifyTimeout;

  /// No description provided for @spotifyServerError.
  ///
  /// In es, this message translates to:
  /// **'Spotify no respondió bien (error {status}).'**
  String spotifyServerError(String status);

  /// No description provided for @spotifyUnexpected.
  ///
  /// In es, this message translates to:
  /// **'Respuesta inesperada de Spotify.'**
  String get spotifyUnexpected;

  /// No description provided for @listGone.
  ///
  /// In es, this message translates to:
  /// **'La lista ya no existe.'**
  String get listGone;

  /// No description provided for @notificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificationsTitle;

  /// No description provided for @authForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get authForgotPassword;

  /// Va justo después del nombre, en la tarjeta de la actividad
  ///
  /// In es, this message translates to:
  /// **' calificó'**
  String get feedRatedSuffix;

  /// No description provided for @couldNotSave.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar: {error}'**
  String couldNotSave(String error);

  /// No description provided for @follow.
  ///
  /// In es, this message translates to:
  /// **'Seguir'**
  String get follow;

  /// No description provided for @following.
  ///
  /// In es, this message translates to:
  /// **'Siguiendo'**
  String get following;

  /// No description provided for @cropTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajusta tu foto'**
  String get cropTitle;

  /// No description provided for @cropFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo recortar: {error}'**
  String cropFailed(String error);

  /// No description provided for @cropHint.
  ///
  /// In es, this message translates to:
  /// **'Mueve y haz zoom con dos dedos. Doble toque para reiniciar.'**
  String get cropHint;

  /// No description provided for @cropOpenFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la imagen: {error}'**
  String cropOpenFailed(String error);

  /// No description provided for @cropUse.
  ///
  /// In es, this message translates to:
  /// **'Usar foto'**
  String get cropUse;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @photoCamera.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get photoCamera;

  /// No description provided for @photoGallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get photoGallery;

  /// No description provided for @photoRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar foto'**
  String get photoRemove;

  /// No description provided for @photoNoCamera.
  ///
  /// In es, this message translates to:
  /// **'No hay cámara disponible.'**
  String get photoNoCamera;

  /// No description provided for @photoGalleryFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la galería: {error}'**
  String photoGalleryFailed(String error);

  /// No description provided for @rateSheetPrompt.
  ///
  /// In es, this message translates to:
  /// **'Toca o desliza para elegir tu nota'**
  String get rateSheetPrompt;

  /// No description provided for @rateSheetCommentHint.
  ///
  /// In es, this message translates to:
  /// **'Agregar un comentario (opcional)'**
  String get rateSheetCommentHint;

  /// No description provided for @rateSheetSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar en mi diario'**
  String get rateSheetSave;

  /// No description provided for @rateSheetUpdate.
  ///
  /// In es, this message translates to:
  /// **'Actualizar mi nota'**
  String get rateSheetUpdate;

  /// No description provided for @rateSheetDelete.
  ///
  /// In es, this message translates to:
  /// **'Borrar nota'**
  String get rateSheetDelete;

  /// No description provided for @usernameOffline.
  ///
  /// In es, this message translates to:
  /// **'No se pudo comprobar. Revisa tu conexión.'**
  String get usernameOffline;

  /// No description provided for @usernameHint.
  ///
  /// In es, this message translates to:
  /// **'tu_usuario'**
  String get usernameHint;

  /// No description provided for @welcomeBody.
  ///
  /// In es, this message translates to:
  /// **'Busca un álbum, ponle nota del 1 al 10 y mira lo que opina la comunidad. Sin estrellas: aquí se habla en números.'**
  String get welcomeBody;

  /// No description provided for @welcomeSignUp.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get welcomeSignUp;

  /// No description provided for @welcomeSignIn.
  ///
  /// In es, this message translates to:
  /// **'Ya tengo cuenta'**
  String get welcomeSignIn;

  /// No description provided for @resetSent.
  ///
  /// In es, this message translates to:
  /// **'Te mandamos un correo a {email} con un enlace para cambiar tu contraseña.'**
  String resetSent(String email);

  /// No description provided for @signInNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? '**
  String get signInNoAccount;

  /// No description provided for @signInCreateOne.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get signInCreateOne;

  /// No description provided for @signIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get signIn;

  /// No description provided for @resetTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get resetTitle;

  /// No description provided for @resetBody.
  ///
  /// In es, this message translates to:
  /// **'Te mandamos un enlace para elegir una contraseña nueva.'**
  String get resetBody;

  /// No description provided for @send.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get send;

  /// No description provided for @signUpHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? '**
  String get signUpHaveAccount;

  /// No description provided for @signUpSignIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get signUpSignIn;

  /// No description provided for @continueLabel.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueLabel;

  /// No description provided for @usernameSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Así te encuentran tus amigos. Minúsculas, números, punto y guion bajo; de {min} a {max} caracteres. Puedes cambiarlo después desde tu perfil.'**
  String usernameSubtitle(int min, int max);

  /// No description provided for @linkOtherTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Entrar con otra cuenta?'**
  String get linkOtherTitle;

  /// No description provided for @linkOtherBody.
  ///
  /// In es, this message translates to:
  /// **'Esta sesión tiene {n, plural, =1{1 nota} other{{n} notas}} y tu perfil. Si entras con otra cuenta, todo eso queda fuera de tu alcance. Para conservarlo, guarda esta sesión con un correo y una contraseña.'**
  String linkOtherBody(int n);

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get back;

  /// No description provided for @linkOtherConfirm.
  ///
  /// In es, this message translates to:
  /// **'Entrar de todos modos'**
  String get linkOtherConfirm;

  /// No description provided for @linkSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Vinilo ahora entra con correo y contraseña. Vincúlalos a esta sesión y conservas {n, plural, =1{1 nota} other{{n} notas}}, tus favoritos y tu perfil en cualquier dispositivo.'**
  String linkSubtitle(int n);

  /// No description provided for @linkHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'Ya tengo una cuenta'**
  String get linkHaveAccount;

  /// No description provided for @linkSubmit.
  ///
  /// In es, this message translates to:
  /// **'Guardar mi cuenta'**
  String get linkSubmit;

  /// No description provided for @onboardingSignedInAs.
  ///
  /// In es, this message translates to:
  /// **'Entraste como {email} · '**
  String onboardingSignedInAs(String email);

  /// No description provided for @onboardingSignOut.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get onboardingSignOut;

  /// No description provided for @onboardingStart.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get onboardingStart;

  /// No description provided for @splashError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión.\n{error}'**
  String splashError(String error);

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Se guarda en tu perfil y te sigue en cualquier dispositivo.'**
  String get settingsSubtitle;

  /// No description provided for @settingsProfile.
  ///
  /// In es, this message translates to:
  /// **'PERFIL'**
  String get settingsProfile;

  /// No description provided for @settingsAppearance.
  ///
  /// In es, this message translates to:
  /// **'APARIENCIA'**
  String get settingsAppearance;

  /// No description provided for @settingsLanguage.
  ///
  /// In es, this message translates to:
  /// **'IDIOMA'**
  String get settingsLanguage;

  /// No description provided for @settingsAccent.
  ///
  /// In es, this message translates to:
  /// **'COLOR DE ÉNFASIS'**
  String get settingsAccent;

  /// No description provided for @settingsAccentBody.
  ///
  /// In es, this message translates to:
  /// **'Tiñe botones, enlaces, la pestaña activa y la escala de las notas. También es el color de tu avatar.'**
  String get settingsAccentBody;

  /// No description provided for @settingsAccount.
  ///
  /// In es, this message translates to:
  /// **'CUENTA'**
  String get settingsAccount;

  /// No description provided for @deleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get deleteAccount;

  /// No description provided for @deleteAccountHint.
  ///
  /// In es, this message translates to:
  /// **'Borra tu perfil y todo lo tuyo. No se puede deshacer.'**
  String get deleteAccountHint;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @languageSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get languageSystem;

  /// No description provided for @editProfile.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get editProfile;

  /// No description provided for @signOutTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar sesión?'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil y tus notas se quedan en tu cuenta. Para volver, entra con tu correo y tu contraseña.'**
  String get signOutBody;

  /// No description provided for @signOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get signOut;

  /// No description provided for @deletePasswordMissing.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu contraseña para confirmar.'**
  String get deletePasswordMissing;

  /// No description provided for @deleteCannotUndo.
  ///
  /// In es, this message translates to:
  /// **'No se puede deshacer'**
  String get deleteCannotUndo;

  /// No description provided for @deleteIntro.
  ///
  /// In es, this message translates to:
  /// **'Se borra para siempre todo lo tuyo:'**
  String get deleteIntro;

  /// No description provided for @deleteItemProfile.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil, tu @usuario, tu foto y tu fondo.'**
  String get deleteItemProfile;

  /// No description provided for @deleteItemRatings.
  ///
  /// In es, this message translates to:
  /// **'Tus notas y comentarios (los promedios de los discos se recalculan) y tus \"me gusta\".'**
  String get deleteItemRatings;

  /// No description provided for @deleteItemLists.
  ///
  /// In es, this message translates to:
  /// **'Tus listas y las que guardaste.'**
  String get deleteItemLists;

  /// No description provided for @deleteItemFollows.
  ///
  /// In es, this message translates to:
  /// **'A quién sigues y quién te sigue.'**
  String get deleteItemFollows;

  /// No description provided for @deleteItemNotifications.
  ///
  /// In es, this message translates to:
  /// **'Tus notificaciones.'**
  String get deleteItemNotifications;

  /// No description provided for @deleteConfirmPrompt.
  ///
  /// In es, this message translates to:
  /// **'Para confirmar, escribe tu contraseña.'**
  String get deleteConfirmPrompt;

  /// No description provided for @deleteInProgress.
  ///
  /// In es, this message translates to:
  /// **'Borrando tu cuenta…'**
  String get deleteInProgress;

  /// No description provided for @deleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mi cuenta'**
  String get deleteConfirm;

  /// No description provided for @editProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil'**
  String get editProfileTitle;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @profilePhotoTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu foto de perfil'**
  String get profilePhotoTitle;

  /// No description provided for @bannerPhotoTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu foto de fondo'**
  String get bannerPhotoTitle;

  /// No description provided for @bannerRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar fondo'**
  String get bannerRemove;

  /// No description provided for @bannerChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar fondo'**
  String get bannerChange;

  /// No description provided for @bannerChoose.
  ///
  /// In es, this message translates to:
  /// **'Elegir foto de fondo'**
  String get bannerChoose;

  /// No description provided for @photoChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get photoChange;

  /// No description provided for @photoChoose.
  ///
  /// In es, this message translates to:
  /// **'Elegir una foto'**
  String get photoChoose;

  /// No description provided for @nameHint.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te llamamos?'**
  String get nameHint;

  /// No description provided for @yourUsernameLabel.
  ///
  /// In es, this message translates to:
  /// **'TU @USUARIO'**
  String get yourUsernameLabel;

  /// No description provided for @yourColorLabel.
  ///
  /// In es, this message translates to:
  /// **'TU COLOR'**
  String get yourColorLabel;

  /// No description provided for @bannerPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Foto de fondo'**
  String get bannerPlaceholder;

  /// No description provided for @homeFollowTitle.
  ///
  /// In es, this message translates to:
  /// **'Sigue a tus amigos'**
  String get homeFollowTitle;

  /// No description provided for @homeFollowBody.
  ///
  /// In es, this message translates to:
  /// **'Aquí verás lo que califican las personas que sigues. Búscalas en la pestaña Buscar por su nombre o su @usuario.'**
  String get homeFollowBody;

  /// No description provided for @homeQuietTitle.
  ///
  /// In es, this message translates to:
  /// **'Todo tranquilo por aquí'**
  String get homeQuietTitle;

  /// No description provided for @homeQuietBody.
  ///
  /// In es, this message translates to:
  /// **'Las personas que sigues todavía no han calificado nada. Cuando lo hagan, aparecerá aquí.'**
  String get homeQuietBody;

  /// No description provided for @homeActivityError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la actividad: {error}'**
  String homeActivityError(String error);

  /// No description provided for @loadMoreFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar más: {error}'**
  String loadMoreFailed(String error);

  /// No description provided for @searchTitle.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In es, this message translates to:
  /// **'Álbum, artista o @persona'**
  String get searchHint;

  /// No description provided for @spotifyNoResponse.
  ///
  /// In es, this message translates to:
  /// **'Spotify no respondió'**
  String get spotifyNoResponse;

  /// No description provided for @searchNothingTitle.
  ///
  /// In es, this message translates to:
  /// **'Nada por aquí'**
  String get searchNothingTitle;

  /// No description provided for @searchNoUsername.
  ///
  /// In es, this message translates to:
  /// **'Nadie tiene un @usuario que empiece así.'**
  String get searchNoUsername;

  /// No description provided for @searchNothingBody.
  ///
  /// In es, this message translates to:
  /// **'Prueba con otro nombre, o busca por el artista.'**
  String get searchNothingBody;

  /// No description provided for @searchPeople.
  ///
  /// In es, this message translates to:
  /// **'Personas'**
  String get searchPeople;

  /// No description provided for @searchArtists.
  ///
  /// In es, this message translates to:
  /// **'Artistas'**
  String get searchArtists;

  /// No description provided for @searchAlbums.
  ///
  /// In es, this message translates to:
  /// **'Álbumes'**
  String get searchAlbums;

  /// No description provided for @searchEnd.
  ///
  /// In es, this message translates to:
  /// **'Eso es todo lo que encontró Spotify'**
  String get searchEnd;

  /// No description provided for @searchRecent.
  ///
  /// In es, this message translates to:
  /// **'Recientes'**
  String get searchRecent;

  /// No description provided for @searchSuggestions.
  ///
  /// In es, this message translates to:
  /// **'Para empezar'**
  String get searchSuggestions;

  /// No description provided for @tabHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get tabHome;

  /// No description provided for @tabSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get tabSearch;

  /// No description provided for @tabProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get tabProfile;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando…'**
  String get loading;

  /// No description provided for @notificationsAllCaughtUp.
  ///
  /// In es, this message translates to:
  /// **'Todo al día'**
  String get notificationsAllCaughtUp;

  /// No description provided for @notificationsError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar: {error}'**
  String notificationsError(String error);

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Nada por ahora'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Aquí verás cuando alguien te siga, le guste una de tus notas o guarde una de tus listas.'**
  String get notificationsEmptyBody;

  /// No description provided for @commentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Comentarios'**
  String get commentsTitle;

  /// No description provided for @countComments.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 comentario} other{{n} comentarios}}'**
  String countComments(int n);

  /// No description provided for @commentsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin comentarios'**
  String get commentsEmptyTitle;

  /// No description provided for @commentsEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Nadie ha escrito nada sobre este disco todavía.'**
  String get commentsEmptyBody;

  /// No description provided for @diaryMine.
  ///
  /// In es, this message translates to:
  /// **'Tu diario'**
  String get diaryMine;

  /// No description provided for @diaryOf.
  ///
  /// In es, this message translates to:
  /// **'Diario de {name}'**
  String diaryOf(String name);

  /// No description provided for @countRatedAlbums.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 disco calificado} other{{n} discos calificados}}'**
  String countRatedAlbums(int n);

  /// No description provided for @diarySearchHint.
  ///
  /// In es, this message translates to:
  /// **'Disco o artista'**
  String get diarySearchHint;

  /// No description provided for @diaryNoMatch.
  ///
  /// In es, this message translates to:
  /// **'Ningún disco del diario coincide con esa búsqueda o ese filtro.'**
  String get diaryNoMatch;

  /// No description provided for @filterAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get filterAll;

  /// No description provided for @sortBy.
  ///
  /// In es, this message translates to:
  /// **'ORDENAR POR'**
  String get sortBy;

  /// No description provided for @sortDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get sortDate;

  /// No description provided for @sortScore.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get sortScore;

  /// No description provided for @followersTitle.
  ///
  /// In es, this message translates to:
  /// **'Seguidores'**
  String get followersTitle;

  /// No description provided for @followersMine.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 persona sigue tu diario} other{{n} personas siguen tu diario}}'**
  String followersMine(int n);

  /// No description provided for @followersOf.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 persona sigue a {name}} other{{n} personas siguen a {name}}}'**
  String followersOf(int n, String name);

  /// No description provided for @followingMine.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 persona seguida} other{{n} personas seguidas}}'**
  String followingMine(int n);

  /// No description provided for @followingOf.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{{name} sigue a 1 persona} other{{name} sigue a {n} personas}}'**
  String followingOf(int n, String name);

  /// No description provided for @followersEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Nadie todavía'**
  String get followersEmptyTitle;

  /// No description provided for @followingEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'A nadie todavía'**
  String get followingEmptyTitle;

  /// No description provided for @followersEmptyMine.
  ///
  /// In es, this message translates to:
  /// **'Cuando alguien te siga, aparecerá aquí.'**
  String get followersEmptyMine;

  /// No description provided for @followersEmptyOf.
  ///
  /// In es, this message translates to:
  /// **'Nadie sigue a {name} todavía.'**
  String followersEmptyOf(String name);

  /// No description provided for @followingEmptyMine.
  ///
  /// In es, this message translates to:
  /// **'Busca a tus amigos en la pestaña Buscar y sigue su diario.'**
  String get followingEmptyMine;

  /// No description provided for @followingEmptyOf.
  ///
  /// In es, this message translates to:
  /// **'{name} no sigue a nadie todavía.'**
  String followingEmptyOf(String name);

  /// No description provided for @listEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar lista'**
  String get listEdit;

  /// No description provided for @listNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva lista'**
  String get listNew;

  /// No description provided for @listFormSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Un ranking va numerado y se ordena arrastrando.'**
  String get listFormSubtitle;

  /// No description provided for @listNameHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la lista'**
  String get listNameHint;

  /// No description provided for @listDescriptionHint.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get listDescriptionHint;

  /// No description provided for @listFormKind.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get listFormKind;

  /// No description provided for @listKindListHint.
  ///
  /// In es, this message translates to:
  /// **'Sin orden fijo'**
  String get listKindListHint;

  /// No description provided for @listKindRankingHint.
  ///
  /// In es, this message translates to:
  /// **'Numerado, del 1 en adelante'**
  String get listKindRankingHint;

  /// No description provided for @listFormContent.
  ///
  /// In es, this message translates to:
  /// **'Contenido'**
  String get listFormContent;

  /// No description provided for @listTypeTracksHint.
  ///
  /// In es, this message translates to:
  /// **'De cualquier disco'**
  String get listTypeTracksHint;

  /// No description provided for @listTypeAlbumsHint.
  ///
  /// In es, this message translates to:
  /// **'Álbumes completos'**
  String get listTypeAlbumsHint;

  /// No description provided for @listCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear lista'**
  String get listCreate;

  /// No description provided for @listCreateFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo crear la lista: {error}'**
  String listCreateFailed(String error);

  /// No description provided for @pickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Agregar a una lista'**
  String get pickerTitle;

  /// No description provided for @pickerSubtitleTracks.
  ///
  /// In es, this message translates to:
  /// **'Tus listas de canciones'**
  String get pickerSubtitleTracks;

  /// No description provided for @pickerSubtitleAlbums.
  ///
  /// In es, this message translates to:
  /// **'Tus listas de discos'**
  String get pickerSubtitleAlbums;

  /// No description provided for @pickerEmptyTracks.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes listas de canciones. Crea una arriba.'**
  String get pickerEmptyTracks;

  /// No description provided for @pickerEmptyAlbums.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes listas de discos. Crea una arriba.'**
  String get pickerEmptyAlbums;

  /// No description provided for @addFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo agregar: {error}'**
  String addFailed(String error);

  /// No description provided for @addToListTitle.
  ///
  /// In es, this message translates to:
  /// **'Agregar a la lista'**
  String get addToListTitle;

  /// No description provided for @addPickTracksSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{artist} · elige las canciones'**
  String addPickTracksSubtitle(String artist);

  /// No description provided for @addBackToResults.
  ///
  /// In es, this message translates to:
  /// **'Volver a los resultados'**
  String get addBackToResults;

  /// No description provided for @addChooseTracks.
  ///
  /// In es, this message translates to:
  /// **'Elige canciones'**
  String get addChooseTracks;

  /// No description provided for @addSelected.
  ///
  /// In es, this message translates to:
  /// **'Agregar {count}'**
  String addSelected(String count);

  /// No description provided for @addSearchTrackAlbum.
  ///
  /// In es, this message translates to:
  /// **'Busca el disco de la canción'**
  String get addSearchTrackAlbum;

  /// No description provided for @addSearchAlbum.
  ///
  /// In es, this message translates to:
  /// **'Busca un disco'**
  String get addSearchAlbum;

  /// No description provided for @addPromptTracks.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre de un disco o artista; después eliges las canciones.'**
  String get addPromptTracks;

  /// No description provided for @addPromptAlbums.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre de un disco o artista.'**
  String get addPromptAlbums;

  /// No description provided for @addNothingBody.
  ///
  /// In es, this message translates to:
  /// **'Prueba con otro nombre.'**
  String get addNothingBody;

  /// No description provided for @albumLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el disco'**
  String get albumLoadFailed;

  /// No description provided for @selectNone.
  ///
  /// In es, this message translates to:
  /// **'Ninguna'**
  String get selectNone;

  /// No description provided for @addAlreadyHere.
  ///
  /// In es, this message translates to:
  /// **'ya está'**
  String get addAlreadyHere;

  /// No description provided for @done.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get done;

  /// No description provided for @artistLabel.
  ///
  /// In es, this message translates to:
  /// **'Artista'**
  String get artistLabel;

  /// No description provided for @artistDiscography.
  ///
  /// In es, this message translates to:
  /// **'Discografía'**
  String get artistDiscography;

  /// No description provided for @artistNoAlbumsTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin discos'**
  String get artistNoAlbumsTitle;

  /// No description provided for @artistNoAlbumsBody.
  ///
  /// In es, this message translates to:
  /// **'Spotify no tiene álbumes de este artista.'**
  String get artistNoAlbumsBody;

  /// No description provided for @artistAlbumsError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la discografía: {error}'**
  String artistAlbumsError(String error);

  /// No description provided for @spotifyCredit.
  ///
  /// In es, this message translates to:
  /// **'Datos y portadas de Spotify'**
  String get spotifyCredit;

  /// No description provided for @artistUnrated.
  ///
  /// In es, this message translates to:
  /// **'Nadie ha calificado un disco de este artista todavía'**
  String get artistUnrated;

  /// No description provided for @ratingLabel.
  ///
  /// In es, this message translates to:
  /// **'CALIFICACIÓN'**
  String get ratingLabel;

  /// No description provided for @countRatings.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 nota} other{{n} notas}}'**
  String countRatings(int n);

  /// No description provided for @listReorderFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo reordenar'**
  String get listReorderFailed;

  /// No description provided for @listRemoveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo quitar'**
  String get listRemoveFailed;

  /// No description provided for @listRemoved.
  ///
  /// In es, this message translates to:
  /// **'Quitaste \"{name}\"'**
  String listRemoved(String name);

  /// No description provided for @undo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get undo;

  /// No description provided for @undoFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo deshacer'**
  String get undoFailed;

  /// No description provided for @listDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar \"{name}\"?'**
  String listDeleteTitle(String name);

  /// No description provided for @listDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'No se puede deshacer. Quien la haya guardado dejará de verla.'**
  String get listDeleteBody;

  /// No description provided for @listDelete.
  ///
  /// In es, this message translates to:
  /// **'Borrar lista'**
  String get listDelete;

  /// No description provided for @deleteFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo borrar: {error}'**
  String deleteFailed(String error);

  /// No description provided for @listCoverTitle.
  ///
  /// In es, this message translates to:
  /// **'Portada de la lista'**
  String get listCoverTitle;

  /// No description provided for @listCoverUploading.
  ///
  /// In es, this message translates to:
  /// **'Subiendo portada…'**
  String get listCoverUploading;

  /// No description provided for @listCoverFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cambiar la portada: {error}'**
  String listCoverFailed(String error);

  /// No description provided for @listCoverRemoveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo quitar la portada: {error}'**
  String listCoverRemoveFailed(String error);

  /// No description provided for @listMenuEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar nombre y descripción'**
  String get listMenuEdit;

  /// No description provided for @listMenuAddHint.
  ///
  /// In es, this message translates to:
  /// **'Busca un disco y elige'**
  String get listMenuAddHint;

  /// No description provided for @listCoverChoose.
  ///
  /// In es, this message translates to:
  /// **'Elegir portada'**
  String get listCoverChoose;

  /// No description provided for @listCoverChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar portada'**
  String get listCoverChange;

  /// No description provided for @listCoverHint.
  ///
  /// In es, this message translates to:
  /// **'Una foto en lugar del mosaico'**
  String get listCoverHint;

  /// No description provided for @listCoverRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar portada'**
  String get listCoverRemove;

  /// No description provided for @listCoverRemoveHint.
  ///
  /// In es, this message translates to:
  /// **'Vuelve el mosaico con las portadas de la lista'**
  String get listCoverRemoveHint;

  /// No description provided for @listGoneBody.
  ///
  /// In es, this message translates to:
  /// **'Su autor la borró.'**
  String get listGoneBody;

  /// No description provided for @listYours.
  ///
  /// In es, this message translates to:
  /// **'Tu lista'**
  String get listYours;

  /// No description provided for @listBy.
  ///
  /// In es, this message translates to:
  /// **'por {name}'**
  String listBy(String name);

  /// No description provided for @listEmptyMineTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu lista está vacía'**
  String get listEmptyMineTitle;

  /// No description provided for @listEmptyTheirsTitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tiene nada'**
  String get listEmptyTheirsTitle;

  /// No description provided for @listEmptyMineTracks.
  ///
  /// In es, this message translates to:
  /// **'Busca un disco y elige sus canciones. También puedes hacerlo desde la pantalla de cualquier disco.'**
  String get listEmptyMineTracks;

  /// No description provided for @listEmptyMineAlbums.
  ///
  /// In es, this message translates to:
  /// **'Busca un disco y agrégalo. También puedes hacerlo desde la pantalla de cualquier disco.'**
  String get listEmptyMineAlbums;

  /// No description provided for @listEmptyTheirs.
  ///
  /// In es, this message translates to:
  /// **'Cuando {name} agregue algo, aparecerá aquí.'**
  String listEmptyTheirs(String name);

  /// No description provided for @listFooterOwner.
  ///
  /// In es, this message translates to:
  /// **'Mantén pulsado un elemento para moverlo. En \"Editar\" puedes quitar.'**
  String get listFooterOwner;

  /// No description provided for @add.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @like.
  ///
  /// In es, this message translates to:
  /// **'Me gusta'**
  String get like;

  /// No description provided for @saved.
  ///
  /// In es, this message translates to:
  /// **'Guardada'**
  String get saved;

  /// No description provided for @ratingSaved.
  ///
  /// In es, this message translates to:
  /// **'Guardado en tu diario'**
  String get ratingSaved;

  /// No description provided for @ratingDeleted.
  ///
  /// In es, this message translates to:
  /// **'Nota borrada de tu diario'**
  String get ratingDeleted;

  /// No description provided for @ratingDeleteFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo borrar la nota: {error}'**
  String ratingDeleteFailed(String error);

  /// No description provided for @viewList.
  ///
  /// In es, this message translates to:
  /// **'Ver lista'**
  String get viewList;

  /// No description provided for @albumAddToList.
  ///
  /// In es, this message translates to:
  /// **'Agregar el disco a una lista'**
  String get albumAddToList;

  /// No description provided for @albumAddToListHint.
  ///
  /// In es, this message translates to:
  /// **'A una de tus listas de discos, o a una nueva'**
  String get albumAddToListHint;

  /// No description provided for @albumCreateList.
  ///
  /// In es, this message translates to:
  /// **'Crear lista con este disco'**
  String get albumCreateList;

  /// No description provided for @albumCreateListHint.
  ///
  /// In es, this message translates to:
  /// **'Todas sus canciones, en orden, listas para ordenar'**
  String get albumCreateListHint;

  /// No description provided for @albumWaitTracks.
  ///
  /// In es, this message translates to:
  /// **'Espera a que carguen las canciones'**
  String get albumWaitTracks;

  /// No description provided for @albumListFromAlbum.
  ///
  /// In es, this message translates to:
  /// **'Lista con este disco'**
  String get albumListFromAlbum;

  /// No description provided for @albumDetailError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el detalle: {error}'**
  String albumDetailError(String error);

  /// No description provided for @albumSelectHint.
  ///
  /// In es, this message translates to:
  /// **'Toca las que quieras agregar'**
  String get albumSelectHint;

  /// No description provided for @albumLongPressHint.
  ///
  /// In es, this message translates to:
  /// **'Mantén pulsada una para agregarla a una lista'**
  String get albumLongPressHint;

  /// No description provided for @seeMore.
  ///
  /// In es, this message translates to:
  /// **'Ver más ({n})'**
  String seeMore(int n);

  /// No description provided for @moreBy.
  ///
  /// In es, this message translates to:
  /// **'Más de {artist}'**
  String moreBy(String artist);

  /// No description provided for @releasedOn.
  ///
  /// In es, this message translates to:
  /// **'Publicado el {date}'**
  String releasedOn(String date);

  /// No description provided for @yourRating.
  ///
  /// In es, this message translates to:
  /// **'Tu nota'**
  String get yourRating;

  /// No description provided for @unrated.
  ///
  /// In es, this message translates to:
  /// **'Sin calificar'**
  String get unrated;

  /// No description provided for @rateThisAlbum.
  ///
  /// In es, this message translates to:
  /// **'Calificar este disco'**
  String get rateThisAlbum;

  /// No description provided for @addToList.
  ///
  /// In es, this message translates to:
  /// **'Agregar a lista'**
  String get addToList;

  /// No description provided for @albumUnratedByAnyone.
  ///
  /// In es, this message translates to:
  /// **'Nadie ha calificado este disco todavía'**
  String get albumUnratedByAnyone;

  /// No description provided for @profileNotFound.
  ///
  /// In es, this message translates to:
  /// **'Perfil no encontrado'**
  String get profileNotFound;

  /// No description provided for @profileNotFoundBody.
  ///
  /// In es, this message translates to:
  /// **'Esta persona ya no está en Vinilo.'**
  String get profileNotFoundBody;

  /// No description provided for @statAlbums.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{DISCO} other{DISCOS}}'**
  String statAlbums(int n);

  /// No description provided for @statAverage.
  ///
  /// In es, this message translates to:
  /// **'PROMEDIO'**
  String get statAverage;

  /// No description provided for @profileListsTab.
  ///
  /// In es, this message translates to:
  /// **'Listas'**
  String get profileListsTab;

  /// No description provided for @favorites.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get favorites;

  /// No description provided for @favoritesMine.
  ///
  /// In es, this message translates to:
  /// **'Tres discos y tres artistas que te definen'**
  String get favoritesMine;

  /// No description provided for @favoritesTheirs.
  ///
  /// In es, this message translates to:
  /// **'Tres discos y tres artistas que le definen'**
  String get favoritesTheirs;

  /// No description provided for @favoritesAlbumsLabel.
  ///
  /// In es, this message translates to:
  /// **'DISCOS'**
  String get favoritesAlbumsLabel;

  /// No description provided for @favoritesArtistsLabel.
  ///
  /// In es, this message translates to:
  /// **'ARTISTAS'**
  String get favoritesArtistsLabel;

  /// No description provided for @diary.
  ///
  /// In es, this message translates to:
  /// **'Diario'**
  String get diary;

  /// No description provided for @diaryEmptyMine.
  ///
  /// In es, this message translates to:
  /// **'Tu diario está vacío'**
  String get diaryEmptyMine;

  /// No description provided for @diaryEmptyTheirs.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay notas'**
  String get diaryEmptyTheirs;

  /// No description provided for @diaryEmptyMineBody.
  ///
  /// In es, this message translates to:
  /// **'Busca un disco y ponle nota. Aquí quedará tu historial, mes a mes.'**
  String get diaryEmptyMineBody;

  /// No description provided for @diaryEmptyTheirsBody.
  ///
  /// In es, this message translates to:
  /// **'Cuando {name} califique algo, aparecerá aquí.'**
  String diaryEmptyTheirsBody(String name);

  /// No description provided for @listsMine.
  ///
  /// In es, this message translates to:
  /// **'Tus listas'**
  String get listsMine;

  /// No description provided for @listsOf.
  ///
  /// In es, this message translates to:
  /// **'Listas de {name}'**
  String listsOf(String name);

  /// No description provided for @listsMineSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Listas y rankings de canciones o discos'**
  String get listsMineSubtitle;

  /// No description provided for @listsTheirsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sus listas y rankings'**
  String get listsTheirsSubtitle;

  /// No description provided for @listsEmptyMine.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes listas. Crea una con \"Nueva lista\" o desde la pantalla de un disco.'**
  String get listsEmptyMine;

  /// No description provided for @listsEmptyTheirs.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tiene listas.'**
  String get listsEmptyTheirs;

  /// No description provided for @listsSaved.
  ///
  /// In es, this message translates to:
  /// **'Guardadas'**
  String get listsSaved;

  /// No description provided for @listsSavedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Listas de otras personas que guardaste. Solo tú las ves aquí.'**
  String get listsSavedSubtitle;

  /// No description provided for @listsSavedEmpty.
  ///
  /// In es, this message translates to:
  /// **'Guarda listas de otras personas y aparecerán aquí.'**
  String get listsSavedEmpty;

  /// No description provided for @countLists.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 lista} other{{n} listas}}'**
  String countLists(int n);

  /// No description provided for @pick.
  ///
  /// In es, this message translates to:
  /// **'Elegir'**
  String get pick;

  /// No description provided for @affinity.
  ///
  /// In es, this message translates to:
  /// **'AFINIDAD MUSICAL'**
  String get affinity;

  /// No description provided for @affinityNone.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienen discos en común'**
  String get affinityNone;

  /// No description provided for @affinityBasis.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Según 1 disco en común} other{Según {n} discos en común}}'**
  String affinityBasis(int n);

  /// No description provided for @favoritesPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus discos'**
  String get favoritesPickerTitle;

  /// No description provided for @favoritesPickerHint.
  ///
  /// In es, this message translates to:
  /// **'Elige hasta tres, en el orden que quieras.'**
  String get favoritesPickerHint;

  /// No description provided for @favoritesSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar en tus discos'**
  String get favoritesSearchHint;

  /// No description provided for @clear.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get clear;

  /// No description provided for @favoritesNoMatch.
  ///
  /// In es, this message translates to:
  /// **'Ningún disco de tu diario coincide con \"{query}\".'**
  String favoritesNoMatch(String query);

  /// No description provided for @favoritesSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar discos'**
  String get favoritesSave;

  /// No description provided for @artistsPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus artistas'**
  String get artistsPickerTitle;

  /// No description provided for @artistsPickerHint.
  ///
  /// In es, this message translates to:
  /// **'Busca en Spotify y elige hasta tres.'**
  String get artistsPickerHint;

  /// No description provided for @artistsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre del artista'**
  String get artistsSearchHint;

  /// No description provided for @artistsPrompt.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre de un artista para buscarlo.'**
  String get artistsPrompt;

  /// No description provided for @artistsSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar artistas'**
  String get artistsSave;

  /// No description provided for @bioLabel.
  ///
  /// In es, this message translates to:
  /// **'BIOGRAFÍA'**
  String get bioLabel;

  /// No description provided for @bioHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntale a la gente qué escuchas (opcional)'**
  String get bioHint;

  /// No description provided for @ratedBy.
  ///
  /// In es, this message translates to:
  /// **'Calificado por'**
  String get ratedBy;

  /// No description provided for @countFriends.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 amigo} other{{n} amigos}}'**
  String countFriends(int n);

  /// No description provided for @listsMineTab.
  ///
  /// In es, this message translates to:
  /// **'Mías ({n})'**
  String listsMineTab(int n);

  /// No description provided for @listsSavedTab.
  ///
  /// In es, this message translates to:
  /// **'Guardadas ({n})'**
  String listsSavedTab(int n);

  /// No description provided for @listsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre o por lo que tiene'**
  String get listsSearchHint;

  /// No description provided for @listsFilterLists.
  ///
  /// In es, this message translates to:
  /// **'Listas'**
  String get listsFilterLists;

  /// No description provided for @listsFilterRankings.
  ///
  /// In es, this message translates to:
  /// **'Rankings'**
  String get listsFilterRankings;

  /// No description provided for @listsSortRecent.
  ///
  /// In es, this message translates to:
  /// **'Recientes'**
  String get listsSortRecent;

  /// No description provided for @listsSortName.
  ///
  /// In es, this message translates to:
  /// **'A–Z'**
  String get listsSortName;

  /// No description provided for @listsSortSize.
  ///
  /// In es, this message translates to:
  /// **'Más elementos'**
  String get listsSortSize;

  /// No description provided for @listsSortLikes.
  ///
  /// In es, this message translates to:
  /// **'Más me gusta'**
  String get listsSortLikes;

  /// No description provided for @listsShowing.
  ///
  /// In es, this message translates to:
  /// **'Mostrando {shown} de {total}'**
  String listsShowing(int shown, int total);

  /// No description provided for @listsClearFilters.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtros'**
  String get listsClearFilters;

  /// No description provided for @listsNoMatchTitle.
  ///
  /// In es, this message translates to:
  /// **'Ninguna lista coincide'**
  String get listsNoMatchTitle;

  /// No description provided for @listsNoMatchBody.
  ///
  /// In es, this message translates to:
  /// **'Prueba con otra búsqueda o quita los filtros.'**
  String get listsNoMatchBody;

  /// No description provided for @notificationsClear.
  ///
  /// In es, this message translates to:
  /// **'Borrar todas'**
  String get notificationsClear;

  /// No description provided for @notificationsClearTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar todas las notificaciones?'**
  String get notificationsClearTitle;

  /// No description provided for @notificationsClearBody.
  ///
  /// In es, this message translates to:
  /// **'Se borran de tu lista. No afecta a quien las provocó.'**
  String get notificationsClearBody;

  /// No description provided for @followersWord.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{seguidor} other{seguidores}}'**
  String followersWord(int n);

  /// No description provided for @followingWord.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{seguido} other{seguidos}}'**
  String followingWord(int n);

  /// No description provided for @notifReply.
  ///
  /// In es, this message translates to:
  /// **'{name} respondió a tu nota de {album}: «{text}»'**
  String notifReply(String name, String album, String text);

  /// No description provided for @notifMention.
  ///
  /// In es, this message translates to:
  /// **'{name} te respondió en una nota de {album}: «{text}»'**
  String notifMention(String name, String album, String text);

  /// No description provided for @threadTitle.
  ///
  /// In es, this message translates to:
  /// **'Respuestas'**
  String get threadTitle;

  /// No description provided for @countReplies.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =0{Sin respuestas} =1{1 respuesta} other{{n} respuestas}}'**
  String countReplies(int n);

  /// No description provided for @replyAction.
  ///
  /// In es, this message translates to:
  /// **'Responder'**
  String get replyAction;

  /// No description provided for @replyHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe una respuesta…'**
  String get replyHint;

  /// No description provided for @replyHintTo.
  ///
  /// In es, this message translates to:
  /// **'Responder a {name}…'**
  String replyHintTo(String name);

  /// No description provided for @replyingTo.
  ///
  /// In es, this message translates to:
  /// **'Respondiendo a {handle}'**
  String replyingTo(String handle);

  /// No description provided for @replySend.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get replySend;

  /// No description provided for @replyDelete.
  ///
  /// In es, this message translates to:
  /// **'Borrar respuesta'**
  String get replyDelete;

  /// No description provided for @replyDeleteHint.
  ///
  /// In es, this message translates to:
  /// **'Se quita del hilo para todas las personas.'**
  String get replyDeleteHint;

  /// No description provided for @replyDeleted.
  ///
  /// In es, this message translates to:
  /// **'Respuesta borrada'**
  String get replyDeleted;

  /// No description provided for @replySendFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar: {error}'**
  String replySendFailed(String error);

  /// No description provided for @replyDeleteFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo borrar: {error}'**
  String replyDeleteFailed(String error);

  /// No description provided for @threadEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Nadie ha respondido todavía'**
  String get threadEmptyTitle;

  /// No description provided for @threadEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Sé la primera persona en responderle a {name}.'**
  String threadEmptyBody(String name);

  /// No description provided for @threadRatingGoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Esta nota ya no existe'**
  String get threadRatingGoneTitle;

  /// No description provided for @threadRatingGoneBody.
  ///
  /// In es, this message translates to:
  /// **'Quien la escribió la borró, y con ella sus respuestas.'**
  String get threadRatingGoneBody;

  /// No description provided for @mentionNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos a {handle}'**
  String mentionNotFound(String handle);

  /// No description provided for @shareAction.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get shareAction;

  /// No description provided for @linkCopied.
  ///
  /// In es, this message translates to:
  /// **'Enlace copiado'**
  String get linkCopied;

  /// No description provided for @shareListMine.
  ///
  /// In es, this message translates to:
  /// **'Mira mi lista «{name}» en Vinilo'**
  String shareListMine(String name);

  /// No description provided for @shareRankingMine.
  ///
  /// In es, this message translates to:
  /// **'Mira mi ranking «{name}» en Vinilo'**
  String shareRankingMine(String name);

  /// No description provided for @shareListOf.
  ///
  /// In es, this message translates to:
  /// **'Mira la lista «{name}» de {owner} en Vinilo'**
  String shareListOf(String name, String owner);

  /// No description provided for @shareRankingOf.
  ///
  /// In es, this message translates to:
  /// **'Mira el ranking «{name}» de {owner} en Vinilo'**
  String shareRankingOf(String name, String owner);

  /// No description provided for @shareAlbum.
  ///
  /// In es, this message translates to:
  /// **'{album} de {artist}, en Vinilo'**
  String shareAlbum(String album, String artist);

  /// No description provided for @shareRatingMine.
  ///
  /// In es, this message translates to:
  /// **'Le di {score}/10 a {album} de {artist} en Vinilo'**
  String shareRatingMine(int score, String album, String artist);

  /// No description provided for @shareRatingOf.
  ///
  /// In es, this message translates to:
  /// **'{name} le dio {score}/10 a {album} en Vinilo'**
  String shareRatingOf(String name, int score, String album);

  /// No description provided for @shareArtist.
  ///
  /// In es, this message translates to:
  /// **'{artist} en Vinilo: mira cómo califica la comunidad sus discos'**
  String shareArtist(String artist);

  /// No description provided for @shareProfileMine.
  ///
  /// In es, this message translates to:
  /// **'Sigue mi diario de discos en Vinilo'**
  String get shareProfileMine;

  /// No description provided for @shareProfileOf.
  ///
  /// In es, this message translates to:
  /// **'Mira el diario de discos de {name} en Vinilo'**
  String shareProfileOf(String name);

  /// No description provided for @welcomeIssue.
  ///
  /// In es, this message translates to:
  /// **'Nº 001'**
  String get welcomeIssue;

  /// No description provided for @welcomeOverline.
  ///
  /// In es, this message translates to:
  /// **'Diario de discos'**
  String get welcomeOverline;

  /// No description provided for @welcomeHeadline.
  ///
  /// In es, this message translates to:
  /// **'Tu diario de discos empieza aquí.'**
  String get welcomeHeadline;

  /// No description provided for @signInTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar\nsesión'**
  String get signInTitle;

  /// No description provided for @signInIdentifierLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo o usuario'**
  String get signInIdentifierLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authPasswordLabel;

  /// No description provided for @authShow.
  ///
  /// In es, this message translates to:
  /// **'Mostrar'**
  String get authShow;

  /// No description provided for @authHide.
  ///
  /// In es, this message translates to:
  /// **'Ocultar'**
  String get authHide;

  /// No description provided for @signInSubmit.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get signInSubmit;

  /// No description provided for @authOr.
  ///
  /// In es, this message translates to:
  /// **'o'**
  String get authOr;

  /// No description provided for @authApple.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Apple'**
  String get authApple;

  /// No description provided for @authGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get authGoogle;

  /// No description provided for @signInEmailOnly.
  ///
  /// In es, this message translates to:
  /// **'Por ahora entra con tu correo'**
  String get signInEmailOnly;

  /// No description provided for @authEmailMissing.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu correo.'**
  String get authEmailMissing;

  /// No description provided for @signUpTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear\ncuenta'**
  String get signUpTitle;

  /// No description provided for @authNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get authNameLabel;

  /// No description provided for @authNameMissing.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu nombre.'**
  String get authNameMissing;

  /// No description provided for @authUsernameLabel.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get authUsernameLabel;

  /// No description provided for @usernameStatusAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get usernameStatusAvailable;

  /// No description provided for @usernameStatusChecking.
  ///
  /// In es, this message translates to:
  /// **'Comprobando…'**
  String get usernameStatusChecking;

  /// No description provided for @usernameStatusTaken.
  ///
  /// In es, this message translates to:
  /// **'Ocupado'**
  String get usernameStatusTaken;

  /// No description provided for @authEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get authEmailLabel;

  /// No description provided for @authEmailPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'tu@correo.com'**
  String get authEmailPlaceholder;

  /// No description provided for @authPasswordNewPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Mínimo {n} caracteres'**
  String authPasswordNewPlaceholder(int n);

  /// No description provided for @authPasswordTooShort.
  ///
  /// In es, this message translates to:
  /// **'La contraseña necesita al menos {n} caracteres.'**
  String authPasswordTooShort(int n);

  /// No description provided for @signUpTermsStart.
  ///
  /// In es, this message translates to:
  /// **'Al crear tu cuenta aceptas los '**
  String get signUpTermsStart;

  /// No description provided for @signUpTerms.
  ///
  /// In es, this message translates to:
  /// **'Términos'**
  String get signUpTerms;

  /// No description provided for @signUpTermsMiddle.
  ///
  /// In es, this message translates to:
  /// **' y la '**
  String get signUpTermsMiddle;

  /// No description provided for @signUpPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get signUpPrivacy;

  /// No description provided for @signUpTermsEnd.
  ///
  /// In es, this message translates to:
  /// **'.'**
  String get signUpTermsEnd;

  /// No description provided for @signUpSubmit.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get signUpSubmit;

  /// No description provided for @onboardingTitle.
  ///
  /// In es, this message translates to:
  /// **'Completa tu\nperfil'**
  String get onboardingTitle;

  /// No description provided for @onboardingBody.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta ya existe. Falta tu nombre y un @usuario para que tus amigos te encuentren.'**
  String get onboardingBody;

  /// No description provided for @usernameTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige tu\n@usuario'**
  String get usernameTitle;

  /// No description provided for @linkTitle.
  ///
  /// In es, this message translates to:
  /// **'Guarda tu\ncuenta'**
  String get linkTitle;

  /// No description provided for @homePopularWeek.
  ///
  /// In es, this message translates to:
  /// **'Popular esta semana'**
  String get homePopularWeek;

  /// No description provided for @seeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todo'**
  String get seeAll;

  /// No description provided for @seeAllPlural.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get seeAllPlural;

  /// No description provided for @homeFriendsActivity.
  ///
  /// In es, this message translates to:
  /// **'Actividad de tus amigos'**
  String get homeFriendsActivity;

  /// No description provided for @homeActivityNew.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 nueva} other{{n} nuevas}}'**
  String homeActivityNew(int n);

  /// No description provided for @feedLiked.
  ///
  /// In es, this message translates to:
  /// **'Te gusta'**
  String get feedLiked;

  /// No description provided for @feedLike.
  ///
  /// In es, this message translates to:
  /// **'Me gusta'**
  String get feedLike;

  /// No description provided for @feedComment.
  ///
  /// In es, this message translates to:
  /// **'Comentar'**
  String get feedComment;

  /// No description provided for @feedReplies.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 respuesta} other{{n} respuestas}}'**
  String feedReplies(int n);

  /// No description provided for @popularTitle.
  ///
  /// In es, this message translates to:
  /// **'Popular esta semana'**
  String get popularTitle;

  /// No description provided for @popularSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Los discos más calificados de los últimos 7 días'**
  String get popularSubtitle;

  /// No description provided for @popularEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Semana tranquila'**
  String get popularEmptyTitle;

  /// No description provided for @popularEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Nadie ha calificado un disco en los últimos 7 días.'**
  String get popularEmptyBody;

  /// No description provided for @notificationsUnread.
  ///
  /// In es, this message translates to:
  /// **'{n} sin leer'**
  String notificationsUnread(int n);

  /// No description provided for @groupToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get groupToday;

  /// No description provided for @groupYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get groupYesterday;

  /// No description provided for @groupThisWeek.
  ///
  /// In es, this message translates to:
  /// **'Esta semana'**
  String get groupThisWeek;

  /// No description provided for @searchAllArtists.
  ///
  /// In es, this message translates to:
  /// **'Artistas'**
  String get searchAllArtists;

  /// No description provided for @searchAllAlbums.
  ///
  /// In es, this message translates to:
  /// **'Álbumes'**
  String get searchAllAlbums;

  /// No description provided for @searchAllFor.
  ///
  /// In es, this message translates to:
  /// **'Resultados de «{query}»'**
  String searchAllFor(String query);

  /// No description provided for @searchClear.
  ///
  /// In es, this message translates to:
  /// **'Borrar búsqueda'**
  String get searchClear;

  /// No description provided for @albumYourRatingEdit.
  ///
  /// In es, this message translates to:
  /// **'Tu nota · editar'**
  String get albumYourRatingEdit;

  /// No description provided for @albumCommunity.
  ///
  /// In es, this message translates to:
  /// **'Comunidad · {n, plural, =1{1 nota} other{{n} notas}}'**
  String albumCommunity(int n);

  /// No description provided for @albumTapToChange.
  ///
  /// In es, this message translates to:
  /// **'Toca para cambiar'**
  String get albumTapToChange;

  /// No description provided for @albumBarsCommunity.
  ///
  /// In es, this message translates to:
  /// **'Barras: comunidad'**
  String get albumBarsCommunity;

  /// No description provided for @albumHoldToAdd.
  ///
  /// In es, this message translates to:
  /// **'Mantén pulsada para agregar'**
  String get albumHoldToAdd;

  /// No description provided for @albumFriendsAverage.
  ///
  /// In es, this message translates to:
  /// **'Promedio amigos'**
  String get albumFriendsAverage;

  /// No description provided for @albumTapPhoto.
  ///
  /// In es, this message translates to:
  /// **'Toca una foto para ver su calificación'**
  String get albumTapPhoto;

  /// No description provided for @albumFeaturedComments.
  ///
  /// In es, this message translates to:
  /// **'Comentarios destacados'**
  String get albumFeaturedComments;

  /// No description provided for @albumCommentsShown.
  ///
  /// In es, this message translates to:
  /// **'{shown} de {total, plural, =1{1 comentario} other{{total} comentarios}}'**
  String albumCommentsShown(int shown, int total);

  /// No description provided for @albumSeeArtist.
  ///
  /// In es, this message translates to:
  /// **'Ver artista'**
  String get albumSeeArtist;

  /// No description provided for @ratingSavedShort.
  ///
  /// In es, this message translates to:
  /// **'Nota guardada'**
  String get ratingSavedShort;

  /// No description provided for @rateSheetHint.
  ///
  /// In es, this message translates to:
  /// **'Toca o desliza'**
  String get rateSheetHint;

  /// No description provided for @rateSheetSaveMine.
  ///
  /// In es, this message translates to:
  /// **'Guardar mi nota'**
  String get rateSheetSaveMine;

  /// No description provided for @pickerOverlineTrack.
  ///
  /// In es, this message translates to:
  /// **'Canción · {name}'**
  String pickerOverlineTrack(String name);

  /// No description provided for @pickerOverlineAlbum.
  ///
  /// In es, this message translates to:
  /// **'Disco · {name}'**
  String pickerOverlineAlbum(String name);

  /// No description provided for @listFormName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get listFormName;

  /// No description provided for @listFormDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get listFormDescription;

  /// No description provided for @listFormOptional.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get listFormOptional;

  /// No description provided for @artistSortBest.
  ///
  /// In es, this message translates to:
  /// **'Mejor calificados'**
  String get artistSortBest;

  /// No description provided for @artistNoRatings.
  ///
  /// In es, this message translates to:
  /// **'Sin notas'**
  String get artistNoRatings;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
