// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Vinilo';

  @override
  String get timeNow => 'now';

  @override
  String timeMinutesAgo(int n) {
    return '$n min ago';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n h ago';
  }

  @override
  String get timeYesterday => 'yesterday';

  @override
  String timeDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorOffline =>
      'No connection. Check your internet and try again.';

  @override
  String get errorPermissionDenied => 'You don\'t have permission to do that.';

  @override
  String get authEmailInUse =>
      'That email already has an account. Sign in or use another one.';

  @override
  String get authInvalidEmail => 'That email doesn\'t look valid.';

  @override
  String get authWeakPassword =>
      'That password is too weak: use at least 6 characters.';

  @override
  String get authMissingPassword => 'Enter your password.';

  @override
  String get authWrongCredentials => 'Wrong email or password.';

  @override
  String get authUserDisabled => 'This account is disabled.';

  @override
  String get authTooManyRequests =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get authOperationNotAllowed =>
      'Email and password sign-in isn\'t enabled yet.';

  @override
  String get authCredentialInUse =>
      'That email already belongs to another account. Sign in with it or use a different email.';

  @override
  String get authProviderLinked => 'This session already has an email linked.';

  @override
  String get authRequiresRecentLogin =>
      'For security, sign in again before doing this.';

  @override
  String get authSessionExpired =>
      'Your session expired. Please sign in again.';

  @override
  String usernameTaken(String username) {
    return '@$username is already taken. Try another one.';
  }

  @override
  String get usernameEmpty => 'Choose your @username.';

  @override
  String usernameTooShort(int n) {
    return 'At least $n characters.';
  }

  @override
  String usernameTooLong(int n) {
    return 'At most $n characters.';
  }

  @override
  String get usernameBadChars =>
      'Only lowercase letters, numbers, periods and underscores.';

  @override
  String get listKindList => 'List';

  @override
  String get listKindRanking => 'Ranking';

  @override
  String get listTypeTracks => 'Songs';

  @override
  String get listTypeAlbums => 'Albums';

  @override
  String countTracks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String countAlbums(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n albums',
      one: '1 album',
    );
    return '$_temp0';
  }

  @override
  String addedTracks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Added $n songs',
      one: 'Added 1 song',
    );
    return '$_temp0';
  }

  @override
  String addedAlbums(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Added $n albums',
      one: 'Added 1 album',
    );
    return '$_temp0';
  }

  @override
  String get listAddTracks => 'Add songs';

  @override
  String get listAddAlbums => 'Add albums';

  @override
  String get listFullTypeTrackList => 'Song list';

  @override
  String get listFullTypeTrackRanking => 'Song ranking';

  @override
  String get listFullTypeAlbumList => 'Album list';

  @override
  String get listFullTypeAlbumRanking => 'Album ranking';

  @override
  String get addAlreadyInList => 'Already in the list';

  @override
  String addDuplicates(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n were already there',
      one: '1 was already there',
    );
    return '$_temp0';
  }

  @override
  String addOverflow(int n, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n didn\'t fit (limit $max)',
      one: '1 didn\'t fit (limit $max)',
    );
    return '$_temp0';
  }

  @override
  String get score1 => 'Terrible';

  @override
  String get score2 => 'Very bad';

  @override
  String get score3 => 'Bad';

  @override
  String get score4 => 'Weak';

  @override
  String get score5 => 'So-so';

  @override
  String get score6 => 'Decent';

  @override
  String get score7 => 'Good';

  @override
  String get score8 => 'Very good';

  @override
  String get score9 => 'Excellent';

  @override
  String get score10 => 'Masterpiece';

  @override
  String get albumTypeSingle => 'Single';

  @override
  String get albumTypeCompilation => 'Compilation';

  @override
  String get albumTypeAlbum => 'Album';

  @override
  String notifFollow(String name) {
    return '$name started following you';
  }

  @override
  String notifLikeRating(String name, String album) {
    return '$name liked your rating of $album';
  }

  @override
  String get notifSomeAlbum => 'an album';

  @override
  String notifLikeList(String name, String list) {
    return '$name liked your list $list';
  }

  @override
  String notifSaveList(String name, String list) {
    return '$name saved your list $list';
  }

  @override
  String get deleteErrorNoEndpoint =>
      'The function URL is missing (--dart-define=SPOTIFY_FN_URL=…).';

  @override
  String get deleteErrorWrongPassword => 'That password isn\'t correct.';

  @override
  String deleteErrorReauth(String code) {
    return 'Couldn\'t verify your password ($code).';
  }

  @override
  String get deleteErrorNoSession => 'You\'re not signed in.';

  @override
  String get deleteErrorTimeout =>
      'Deleting is taking longer than expected. Try again: it picks up where it left off.';

  @override
  String get deleteErrorRecentLogin =>
      'Enter your password again to delete your account.';

  @override
  String deleteErrorServer(String status) {
    return 'Couldn\'t delete the account ($status). Please try again.';
  }

  @override
  String get spotifyNotConfigured =>
      'The Spotify function URL is missing. Run the app with --dart-define=SPOTIFY_FN_URL=…';

  @override
  String get spotifyTimeout => 'Spotify took too long to respond.';

  @override
  String spotifyServerError(String status) {
    return 'Spotify didn\'t respond properly (error $status).';
  }

  @override
  String get spotifyUnexpected => 'Unexpected response from Spotify.';

  @override
  String get listGone => 'This list no longer exists.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get feedRatedSuffix => ' rated';

  @override
  String couldNotSave(String error) {
    return 'Couldn\'t save: $error';
  }

  @override
  String get follow => 'Follow';

  @override
  String get following => 'Following';

  @override
  String get cropTitle => 'Adjust your photo';

  @override
  String cropFailed(String error) {
    return 'Couldn\'t crop: $error';
  }

  @override
  String get cropHint => 'Drag and pinch to zoom. Double-tap to reset.';

  @override
  String cropOpenFailed(String error) {
    return 'Couldn\'t open the image: $error';
  }

  @override
  String get cropUse => 'Use photo';

  @override
  String get cancel => 'Cancel';

  @override
  String get photoCamera => 'Take photo';

  @override
  String get photoGallery => 'Choose from library';

  @override
  String get photoRemove => 'Remove photo';

  @override
  String get photoNoCamera => 'No camera available.';

  @override
  String photoGalleryFailed(String error) {
    return 'Couldn\'t open your photos: $error';
  }

  @override
  String get rateSheetPrompt => 'Tap or slide to choose your score';

  @override
  String get rateSheetCommentHint => 'Add a comment (optional)';

  @override
  String get rateSheetSave => 'Save to my diary';

  @override
  String get rateSheetUpdate => 'Update my rating';

  @override
  String get rateSheetDelete => 'Delete rating';

  @override
  String get usernameOffline => 'Couldn\'t check. Check your connection.';

  @override
  String get usernameHint => 'your_username';

  @override
  String get welcomeBody =>
      'Find an album, rate it from 1 to 10 and see what the community thinks. No stars: here we talk in numbers.';

  @override
  String get welcomeSignUp => 'Create account';

  @override
  String get welcomeSignIn => 'I already have an account';

  @override
  String resetSent(String email) {
    return 'We sent an email to $email with a link to change your password.';
  }

  @override
  String get signInNoAccount => 'Don\'t have an account? ';

  @override
  String get signInCreateOne => 'Create account';

  @override
  String get signIn => 'Sign in';

  @override
  String get resetTitle => 'Reset password';

  @override
  String get resetBody => 'We\'ll send you a link to choose a new password.';

  @override
  String get send => 'Send';

  @override
  String get signUpHaveAccount => 'Already have an account? ';

  @override
  String get signUpSignIn => 'Sign in';

  @override
  String get continueLabel => 'Continue';

  @override
  String usernameSubtitle(int min, int max) {
    return 'This is how your friends find you. Lowercase letters, numbers, periods and underscores; $min to $max characters. You can change it later from your profile.';
  }

  @override
  String get linkOtherTitle => 'Sign in with another account?';

  @override
  String linkOtherBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ratings',
      one: '1 rating',
    );
    return 'This session has $_temp0 and your profile. If you sign in with another account, you\'ll lose access to all of it. To keep it, save this session with an email and a password.';
  }

  @override
  String get back => 'Back';

  @override
  String get linkOtherConfirm => 'Sign in anyway';

  @override
  String linkSubtitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ratings',
      one: '1 rating',
    );
    return 'Vinilo now signs in with email and password. Link them to this session and keep $_temp0, your favorites and your profile on any device.';
  }

  @override
  String get linkHaveAccount => 'I already have an account';

  @override
  String get linkSubmit => 'Save my account';

  @override
  String onboardingSignedInAs(String email) {
    return 'Signed in as $email · ';
  }

  @override
  String get onboardingSignOut => 'Sign out';

  @override
  String get onboardingStart => 'Get started';

  @override
  String splashError(String error) {
    return 'Couldn\'t sign in.\n$error';
  }

  @override
  String get retry => 'Retry';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle =>
      'Saved to your profile, so it follows you on any device.';

  @override
  String get settingsProfile => 'PROFILE';

  @override
  String get settingsAppearance => 'APPEARANCE';

  @override
  String get settingsLanguage => 'LANGUAGE';

  @override
  String get settingsAccent => 'ACCENT COLOR';

  @override
  String get settingsAccentBody =>
      'Tints buttons, links, the active tab and the rating scale. It\'s also your avatar color.';

  @override
  String get settingsAccount => 'ACCOUNT';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountHint =>
      'Deletes your profile and everything you\'ve made. This can\'t be undone.';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageSystem => 'System';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutBody =>
      'Your profile and ratings stay in your account. To come back, sign in with your email and password.';

  @override
  String get signOut => 'Sign out';

  @override
  String get deletePasswordMissing => 'Enter your password to confirm.';

  @override
  String get deleteCannotUndo => 'This can\'t be undone';

  @override
  String get deleteIntro => 'Everything of yours is deleted for good:';

  @override
  String get deleteItemProfile =>
      'Your profile, your @username, your photo and your banner.';

  @override
  String get deleteItemRatings =>
      'Your ratings and comments (album averages are recalculated) and your likes.';

  @override
  String get deleteItemLists => 'Your lists and the ones you saved.';

  @override
  String get deleteItemFollows => 'Who you follow and who follows you.';

  @override
  String get deleteItemNotifications => 'Your notifications.';

  @override
  String get deleteConfirmPrompt => 'To confirm, enter your password.';

  @override
  String get deleteInProgress => 'Deleting your account…';

  @override
  String get deleteConfirm => 'Delete my account';

  @override
  String get editProfileTitle => 'Your profile';

  @override
  String get save => 'Save';

  @override
  String get profilePhotoTitle => 'Your profile photo';

  @override
  String get bannerPhotoTitle => 'Your banner photo';

  @override
  String get bannerRemove => 'Remove banner';

  @override
  String get bannerChange => 'Change banner';

  @override
  String get bannerChoose => 'Choose a banner photo';

  @override
  String get photoChange => 'Change photo';

  @override
  String get photoChoose => 'Choose a photo';

  @override
  String get nameHint => 'What should we call you?';

  @override
  String get yourUsernameLabel => 'YOUR @USERNAME';

  @override
  String get yourColorLabel => 'YOUR COLOR';

  @override
  String get bannerPlaceholder => 'Banner photo';

  @override
  String get homeFollowTitle => 'Follow your friends';

  @override
  String get homeFollowBody =>
      'Here you\'ll see what the people you follow rate. Find them in the Search tab by name or @username.';

  @override
  String get homeQuietTitle => 'All quiet here';

  @override
  String get homeQuietBody =>
      'The people you follow haven\'t rated anything yet. When they do, it\'ll show up here.';

  @override
  String homeActivityError(String error) {
    return 'Couldn\'t load activity: $error';
  }

  @override
  String loadMoreFailed(String error) {
    return 'Couldn\'t load more: $error';
  }

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Album, artist or @person';

  @override
  String get spotifyNoResponse => 'Spotify didn\'t respond';

  @override
  String get searchNothingTitle => 'Nothing here';

  @override
  String get searchNoUsername =>
      'No one has an @username that starts like that.';

  @override
  String get searchNothingBody => 'Try another name, or search by artist.';

  @override
  String get searchPeople => 'People';

  @override
  String get searchArtists => 'Artists';

  @override
  String get searchAlbums => 'Albums';

  @override
  String get searchEnd => 'That\'s everything Spotify found';

  @override
  String get searchRecent => 'Recent';

  @override
  String get searchSuggestions => 'To get started';

  @override
  String get tabHome => 'Home';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabProfile => 'Profile';

  @override
  String get loading => 'Loading…';

  @override
  String get notificationsAllCaughtUp => 'All caught up';

  @override
  String notificationsError(String error) {
    return 'Couldn\'t load them: $error';
  }

  @override
  String get notificationsEmptyTitle => 'Nothing yet';

  @override
  String get notificationsEmptyBody =>
      'You\'ll see here when someone follows you, likes one of your ratings or saves one of your lists.';

  @override
  String get commentsTitle => 'Comments';

  @override
  String countComments(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n comments',
      one: '1 comment',
    );
    return '$_temp0';
  }

  @override
  String get commentsEmptyTitle => 'No comments';

  @override
  String get commentsEmptyBody =>
      'No one has written anything about this album yet.';

  @override
  String get diaryMine => 'Your diary';

  @override
  String diaryOf(String name) {
    return '$name\'s diary';
  }

  @override
  String countRatedAlbums(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n albums rated',
      one: '1 album rated',
    );
    return '$_temp0';
  }

  @override
  String get diarySearchHint => 'Album or artist';

  @override
  String get diaryNoMatch =>
      'No album in the diary matches that search or filter.';

  @override
  String get filterAll => 'All';

  @override
  String get sortBy => 'SORT BY';

  @override
  String get sortDate => 'Date';

  @override
  String get sortScore => 'Score';

  @override
  String get followersTitle => 'Followers';

  @override
  String followersMine(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n people follow your diary',
      one: '1 person follows your diary',
    );
    return '$_temp0';
  }

  @override
  String followersOf(int n, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n people follow $name',
      one: '1 person follows $name',
    );
    return '$_temp0';
  }

  @override
  String followingMine(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Following $n people',
      one: 'Following 1 person',
    );
    return '$_temp0';
  }

  @override
  String followingOf(int n, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$name follows $n people',
      one: '$name follows 1 person',
    );
    return '$_temp0';
  }

  @override
  String get followersEmptyTitle => 'No one yet';

  @override
  String get followingEmptyTitle => 'No one yet';

  @override
  String get followersEmptyMine =>
      'When someone follows you, they\'ll show up here.';

  @override
  String followersEmptyOf(String name) {
    return 'No one follows $name yet.';
  }

  @override
  String get followingEmptyMine =>
      'Find your friends in the Search tab and follow their diary.';

  @override
  String followingEmptyOf(String name) {
    return '$name doesn\'t follow anyone yet.';
  }

  @override
  String get listEdit => 'Edit list';

  @override
  String get listNew => 'New list';

  @override
  String get listFormSubtitle =>
      'A ranking is numbered and you reorder it by dragging.';

  @override
  String get listNameHint => 'List name';

  @override
  String get listDescriptionHint => 'Description (optional)';

  @override
  String get listFormKind => 'TYPE';

  @override
  String get listKindListHint => 'No fixed order';

  @override
  String get listKindRankingHint => 'Numbered, from 1 down';

  @override
  String get listFormContent => 'OF WHAT?';

  @override
  String get listTypeTracksHint => 'From any album';

  @override
  String get listTypeAlbumsHint => 'Whole albums';

  @override
  String get listCreate => 'Create list';

  @override
  String listCreateFailed(String error) {
    return 'Couldn\'t create the list: $error';
  }

  @override
  String get pickerTitle => 'Add to a list';

  @override
  String get pickerSubtitleTracks => 'Your song lists';

  @override
  String get pickerSubtitleAlbums => 'Your album lists';

  @override
  String get pickerEmptyTracks =>
      'You don\'t have any song lists yet. Create one above.';

  @override
  String get pickerEmptyAlbums =>
      'You don\'t have any album lists yet. Create one above.';

  @override
  String addFailed(String error) {
    return 'Couldn\'t add: $error';
  }

  @override
  String get addToListTitle => 'Add to the list';

  @override
  String addPickTracksSubtitle(String artist) {
    return '$artist · pick the songs';
  }

  @override
  String get addBackToResults => 'Back to results';

  @override
  String get addChooseTracks => 'Pick songs';

  @override
  String addSelected(String count) {
    return 'Add $count';
  }

  @override
  String get addSearchTrackAlbum => 'Search for the song\'s album';

  @override
  String get addSearchAlbum => 'Search for an album';

  @override
  String get addPromptTracks =>
      'Type an album or artist name; then pick the songs.';

  @override
  String get addPromptAlbums => 'Type an album or artist name.';

  @override
  String get addNothingBody => 'Try another name.';

  @override
  String get albumLoadFailed => 'Couldn\'t load the album';

  @override
  String get selectNone => 'None';

  @override
  String get addAlreadyHere => 'added';

  @override
  String get done => 'Done';

  @override
  String get artistLabel => 'Artist';

  @override
  String get artistDiscography => 'Discography';

  @override
  String get artistNoAlbumsTitle => 'No albums';

  @override
  String get artistNoAlbumsBody => 'Spotify has no albums for this artist.';

  @override
  String artistAlbumsError(String error) {
    return 'Couldn\'t load the discography: $error';
  }

  @override
  String get spotifyCredit => 'Data and covers from Spotify';

  @override
  String get artistUnrated => 'No one has rated an album by this artist yet';

  @override
  String get ratingLabel => 'RATING';

  @override
  String countRatings(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ratings',
      one: '1 rating',
    );
    return '$_temp0';
  }

  @override
  String get listReorderFailed => 'Couldn\'t reorder';

  @override
  String get listRemoveFailed => 'Couldn\'t remove';

  @override
  String listRemoved(String name) {
    return 'Removed \"$name\"';
  }

  @override
  String get undo => 'Undo';

  @override
  String get undoFailed => 'Couldn\'t undo';

  @override
  String listDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get listDeleteBody =>
      'This can\'t be undone. Anyone who saved it will stop seeing it.';

  @override
  String get listDelete => 'Delete list';

  @override
  String deleteFailed(String error) {
    return 'Couldn\'t delete: $error';
  }

  @override
  String get listCoverTitle => 'List cover';

  @override
  String get listCoverUploading => 'Uploading cover…';

  @override
  String listCoverFailed(String error) {
    return 'Couldn\'t change the cover: $error';
  }

  @override
  String listCoverRemoveFailed(String error) {
    return 'Couldn\'t remove the cover: $error';
  }

  @override
  String get listMenuEdit => 'Edit name and description';

  @override
  String get listMenuAddHint => 'Search for an album and pick';

  @override
  String get listCoverChoose => 'Choose cover';

  @override
  String get listCoverChange => 'Change cover';

  @override
  String get listCoverHint => 'A photo instead of the mosaic';

  @override
  String get listCoverRemove => 'Remove cover';

  @override
  String get listCoverRemoveHint =>
      'Brings back the mosaic of the list\'s covers';

  @override
  String get listGoneBody => 'Its author deleted it.';

  @override
  String get listYours => 'Your list';

  @override
  String listBy(String name) {
    return 'by $name';
  }

  @override
  String get listEmptyMineTitle => 'Your list is empty';

  @override
  String get listEmptyTheirsTitle => 'Nothing here yet';

  @override
  String get listEmptyMineTracks =>
      'Search for an album and pick its songs. You can also do it from any album\'s screen.';

  @override
  String get listEmptyMineAlbums =>
      'Search for an album and add it. You can also do it from any album\'s screen.';

  @override
  String listEmptyTheirs(String name) {
    return 'When $name adds something, it\'ll show up here.';
  }

  @override
  String get listFooterOwner =>
      'Press and hold an item to move it. Use \"Edit\" to remove.';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get like => 'Like';

  @override
  String get saved => 'Saved';

  @override
  String get ratingSaved => 'Saved to your diary';

  @override
  String get ratingDeleted => 'Rating removed from your diary';

  @override
  String ratingDeleteFailed(String error) {
    return 'Couldn\'t delete the rating: $error';
  }

  @override
  String get viewList => 'View list';

  @override
  String get albumAddToList => 'Add the album to a list';

  @override
  String get albumAddToListHint => 'To one of your album lists, or a new one';

  @override
  String get albumCreateList => 'Create a list from this album';

  @override
  String get albumCreateListHint => 'All its songs, in order, ready to rank';

  @override
  String get albumWaitTracks => 'Wait for the songs to load';

  @override
  String get albumListFromAlbum => 'List from this album';

  @override
  String albumDetailError(String error) {
    return 'Couldn\'t load the details: $error';
  }

  @override
  String get albumSelectHint => 'Tap the ones you want to add';

  @override
  String get albumLongPressHint => 'Press and hold one to add it to a list';

  @override
  String seeMore(int n) {
    return 'See more ($n)';
  }

  @override
  String moreBy(String artist) {
    return 'More by $artist';
  }

  @override
  String releasedOn(String date) {
    return 'Released $date';
  }

  @override
  String get yourRating => 'Your rating';

  @override
  String get unrated => 'Not rated';

  @override
  String get rateThisAlbum => 'Rate this album';

  @override
  String get addToList => 'Add to list';

  @override
  String get albumUnratedByAnyone => 'No one has rated this album yet';

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String get profileNotFoundBody => 'This person is no longer on Vinilo.';

  @override
  String statAlbums(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ALBUMS',
      one: 'ALBUM',
    );
    return '$_temp0';
  }

  @override
  String get statAverage => 'AVERAGE';

  @override
  String get profileListsTab => 'Lists';

  @override
  String get favorites => 'Favorites';

  @override
  String get favoritesMine => 'Three albums and three artists that define you';

  @override
  String get favoritesTheirs =>
      'Three albums and three artists that define them';

  @override
  String get favoritesAlbumsLabel => 'ALBUMS';

  @override
  String get favoritesArtistsLabel => 'ARTISTS';

  @override
  String get diary => 'Diary';

  @override
  String get diaryEmptyMine => 'Your diary is empty';

  @override
  String get diaryEmptyTheirs => 'No ratings yet';

  @override
  String get diaryEmptyMineBody =>
      'Find an album and rate it. Your history will build up here, month by month.';

  @override
  String diaryEmptyTheirsBody(String name) {
    return 'When $name rates something, it\'ll show up here.';
  }

  @override
  String get listsMine => 'Your lists';

  @override
  String listsOf(String name) {
    return '$name\'s lists';
  }

  @override
  String get listsMineSubtitle => 'Lists and rankings of songs or albums';

  @override
  String get listsTheirsSubtitle => 'Their lists and rankings';

  @override
  String get listsEmptyMine =>
      'You don\'t have lists yet. Create one with \"New list\" or from an album\'s screen.';

  @override
  String get listsEmptyTheirs => 'No lists yet.';

  @override
  String get listsSaved => 'Saved';

  @override
  String get listsSavedSubtitle =>
      'Other people\'s lists you saved. Only you see them here.';

  @override
  String get listsSavedEmpty =>
      'Save other people\'s lists and they\'ll show up here.';

  @override
  String countLists(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n lists',
      one: '1 list',
    );
    return '$_temp0';
  }

  @override
  String get pick => 'Choose';

  @override
  String get affinity => 'MUSICAL AFFINITY';

  @override
  String get affinityNone => 'You don\'t have albums in common yet';

  @override
  String affinityBasis(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Based on $n albums in common',
      one: 'Based on 1 album in common',
    );
    return '$_temp0';
  }

  @override
  String get favoritesPickerTitle => 'Your albums';

  @override
  String get favoritesPickerHint => 'Pick up to three, in any order you like.';

  @override
  String get favoritesSearchHint => 'Search your albums';

  @override
  String get clear => 'Clear';

  @override
  String favoritesNoMatch(String query) {
    return 'No album in your diary matches \"$query\".';
  }

  @override
  String get favoritesSave => 'Save albums';

  @override
  String get artistsPickerTitle => 'Your artists';

  @override
  String get artistsPickerHint => 'Search Spotify and pick up to three.';

  @override
  String get artistsSearchHint => 'Artist name';

  @override
  String get artistsPrompt => 'Type an artist\'s name to search for them.';

  @override
  String get artistsSave => 'Save artists';

  @override
  String get bioLabel => 'BIO';

  @override
  String get bioHint => 'Tell people what you listen to (optional)';

  @override
  String get ratedBy => 'Rated by';

  @override
  String countFriends(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n friends',
      one: '1 friend',
    );
    return '$_temp0';
  }

  @override
  String listsMineTab(int n) {
    return 'Mine ($n)';
  }

  @override
  String listsSavedTab(int n) {
    return 'Saved ($n)';
  }

  @override
  String get listsSearchHint => 'Search by name or what\'s inside';

  @override
  String get listsFilterLists => 'Lists';

  @override
  String get listsFilterRankings => 'Rankings';

  @override
  String get listsSortRecent => 'Recent';

  @override
  String get listsSortName => 'A–Z';

  @override
  String get listsSortSize => 'Most items';

  @override
  String get listsSortLikes => 'Most liked';

  @override
  String listsShowing(int shown, int total) {
    return 'Showing $shown of $total';
  }

  @override
  String get listsClearFilters => 'Clear filters';

  @override
  String get listsNoMatchTitle => 'No lists match';

  @override
  String get listsNoMatchBody => 'Try another search or clear the filters.';

  @override
  String get notificationsClear => 'Clear all';

  @override
  String get notificationsClearTitle => 'Clear all notifications?';

  @override
  String get notificationsClearBody =>
      'They\'re removed from your list. It doesn\'t affect whoever caused them.';

  @override
  String followersWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'followers',
      one: 'follower',
    );
    return '$_temp0';
  }

  @override
  String followingWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'following',
    );
    return '$_temp0';
  }

  @override
  String notifReply(String name, String album, String text) {
    return '$name replied to your rating of $album: “$text”';
  }

  @override
  String notifMention(String name, String album, String text) {
    return '$name replied to you on a rating of $album: “$text”';
  }

  @override
  String get threadTitle => 'Replies';

  @override
  String countReplies(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n replies',
      one: '1 reply',
      zero: 'No replies',
    );
    return '$_temp0';
  }

  @override
  String get replyAction => 'Reply';

  @override
  String get replyHint => 'Write a reply…';

  @override
  String replyHintTo(String name) {
    return 'Reply to $name…';
  }

  @override
  String replyingTo(String handle) {
    return 'Replying to $handle';
  }

  @override
  String get replySend => 'Send';

  @override
  String get replyDelete => 'Delete reply';

  @override
  String get replyDeleteHint => 'It\'s removed from the thread for everyone.';

  @override
  String get replyDeleted => 'Reply deleted';

  @override
  String replySendFailed(String error) {
    return 'Couldn\'t send: $error';
  }

  @override
  String replyDeleteFailed(String error) {
    return 'Couldn\'t delete: $error';
  }

  @override
  String get threadEmptyTitle => 'No replies yet';

  @override
  String threadEmptyBody(String name) {
    return 'Be the first to reply to $name.';
  }

  @override
  String get threadRatingGoneTitle => 'This rating is gone';

  @override
  String get threadRatingGoneBody =>
      'Its author deleted it, along with its replies.';

  @override
  String mentionNotFound(String handle) {
    return 'Couldn\'t find $handle';
  }

  @override
  String get shareAction => 'Share';

  @override
  String get linkCopied => 'Link copied';

  @override
  String shareListMine(String name) {
    return 'Check out my list “$name” on Vinilo';
  }

  @override
  String shareRankingMine(String name) {
    return 'Check out my ranking “$name” on Vinilo';
  }

  @override
  String shareListOf(String name, String owner) {
    return 'Check out “$name”, a list by $owner on Vinilo';
  }

  @override
  String shareRankingOf(String name, String owner) {
    return 'Check out “$name”, a ranking by $owner on Vinilo';
  }

  @override
  String shareAlbum(String album, String artist) {
    return '$album by $artist, on Vinilo';
  }

  @override
  String shareRatingMine(int score, String album, String artist) {
    return 'I gave $album by $artist a $score/10 on Vinilo';
  }

  @override
  String shareRatingOf(String name, int score, String album) {
    return '$name gave $album a $score/10 on Vinilo';
  }

  @override
  String shareArtist(String artist) {
    return '$artist on Vinilo: see how the community rates their albums';
  }

  @override
  String get shareProfileMine => 'Follow my album diary on Vinilo';

  @override
  String shareProfileOf(String name) {
    return 'Check out $name\'s album diary on Vinilo';
  }

  @override
  String get welcomeIssue => 'No. 001';

  @override
  String get welcomeOverline => 'Record diary';

  @override
  String get welcomeHeadline => 'Your record diary starts here.';

  @override
  String get signInTitle => 'Sign\nin';

  @override
  String get signInIdentifierLabel => 'Email or username';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authShow => 'Show';

  @override
  String get authHide => 'Hide';

  @override
  String get signInSubmit => 'Sign in';

  @override
  String get authOr => 'or';

  @override
  String get authApple => 'Continue with Apple';

  @override
  String get authGoogle => 'Continue with Google';

  @override
  String get signInEmailOnly => 'For now, sign in with your email';

  @override
  String get authEmailMissing => 'Enter your email.';

  @override
  String get signUpTitle => 'Create\naccount';

  @override
  String get authNameLabel => 'Name';

  @override
  String get authNameMissing => 'Enter your name.';

  @override
  String get authUsernameLabel => 'Username';

  @override
  String get usernameStatusAvailable => 'Available';

  @override
  String get usernameStatusChecking => 'Checking…';

  @override
  String get usernameStatusTaken => 'Taken';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailPlaceholder => 'you@email.com';

  @override
  String authPasswordNewPlaceholder(int n) {
    return 'At least $n characters';
  }

  @override
  String authPasswordTooShort(int n) {
    return 'Your password needs at least $n characters.';
  }

  @override
  String get signUpTermsStart => 'By creating your account you accept the ';

  @override
  String get signUpTerms => 'Terms';

  @override
  String get signUpTermsMiddle => ' and the ';

  @override
  String get signUpPrivacy => 'Privacy Policy';

  @override
  String get signUpTermsEnd => '.';

  @override
  String get signUpSubmit => 'Create account';

  @override
  String get onboardingTitle => 'Finish your\nprofile';

  @override
  String get onboardingBody =>
      'Your account is ready. Add your name and a @username so your friends can find you.';

  @override
  String get usernameTitle => 'Pick your\n@username';

  @override
  String get linkTitle => 'Save your\naccount';

  @override
  String get homePopularWeek => 'Popular this week';

  @override
  String get seeAll => 'See all';

  @override
  String get seeAllPlural => 'See all';

  @override
  String get homeFriendsActivity => 'Your friends\' activity';

  @override
  String homeActivityNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n new',
      one: '1 new',
    );
    return '$_temp0';
  }

  @override
  String get feedLiked => 'You like it';

  @override
  String get feedLike => 'Like';

  @override
  String get feedComment => 'Comment';

  @override
  String feedReplies(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n replies',
      one: '1 reply',
    );
    return '$_temp0';
  }

  @override
  String get popularTitle => 'Popular this week';

  @override
  String get popularSubtitle => 'The most rated albums of the last 7 days';

  @override
  String get popularEmptyTitle => 'A quiet week';

  @override
  String get popularEmptyBody =>
      'No one has rated an album in the last 7 days.';

  @override
  String notificationsUnread(int n) {
    return '$n unread';
  }

  @override
  String get groupToday => 'Today';

  @override
  String get groupYesterday => 'Yesterday';

  @override
  String get groupThisWeek => 'This week';

  @override
  String get searchAllArtists => 'Artists';

  @override
  String get searchAllAlbums => 'Albums';

  @override
  String searchAllFor(String query) {
    return 'Results for “$query”';
  }

  @override
  String get searchClear => 'Clear search';
}
