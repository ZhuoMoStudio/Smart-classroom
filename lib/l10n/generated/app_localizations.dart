import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Classroom'**
  String get appTitle;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Classroom Interactive Tool'**
  String get appDescription;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Smart Classroom'**
  String get welcome;

  /// No description provided for @onboarding.
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get onboarding;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @startUsing.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get startUsing;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @load.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get load;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @lock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lock;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @deselect.
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get deselect;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @tip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tip;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete? This action cannot be undone.'**
  String get confirmDeleteMessage;

  /// No description provided for @classroom.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classroom;

  /// No description provided for @classrooms.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get classrooms;

  /// No description provided for @selectClass.
  ///
  /// In en, this message translates to:
  /// **'Select Class'**
  String get selectClass;

  /// No description provided for @addClass.
  ///
  /// In en, this message translates to:
  /// **'Add Class'**
  String get addClass;

  /// No description provided for @className.
  ///
  /// In en, this message translates to:
  /// **'Class Name'**
  String get className;

  /// No description provided for @deleteClass.
  ///
  /// In en, this message translates to:
  /// **'Delete Class'**
  String get deleteClass;

  /// No description provided for @deleteClassConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete class \"{name}\"? All groups and members will be removed.'**
  String deleteClassConfirm(Object name);

  /// No description provided for @noClassSelected.
  ///
  /// In en, this message translates to:
  /// **'Please select a class first'**
  String get noClassSelected;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @addGroup.
  ///
  /// In en, this message translates to:
  /// **'Add Group'**
  String get addGroup;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @deleteGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete group \"{name}\"?'**
  String deleteGroupConfirm(Object name);

  /// No description provided for @lockGroup.
  ///
  /// In en, this message translates to:
  /// **'Lock Group'**
  String get lockGroup;

  /// No description provided for @unlockGroup.
  ///
  /// In en, this message translates to:
  /// **'Unlock Group'**
  String get unlockGroup;

  /// No description provided for @groupLocked.
  ///
  /// In en, this message translates to:
  /// **'Group Locked'**
  String get groupLocked;

  /// No description provided for @groupLockTip.
  ///
  /// In en, this message translates to:
  /// **'Draw a group first before locking'**
  String get groupLockTip;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMember;

  /// No description provided for @memberName.
  ///
  /// In en, this message translates to:
  /// **'Member Name'**
  String get memberName;

  /// No description provided for @deleteMember.
  ///
  /// In en, this message translates to:
  /// **'Delete Member'**
  String get deleteMember;

  /// No description provided for @deleteMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete member \"{name}\"?'**
  String deleteMemberConfirm(Object name);

  /// No description provided for @noMembers.
  ///
  /// In en, this message translates to:
  /// **'No member data'**
  String get noMembers;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @scores.
  ///
  /// In en, this message translates to:
  /// **'Scores'**
  String get scores;

  /// No description provided for @resetAllScores.
  ///
  /// In en, this message translates to:
  /// **'Reset All Scores'**
  String get resetAllScores;

  /// No description provided for @resetScoresConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all scores? This cannot be undone.'**
  String get resetScoresConfirm;

  /// No description provided for @scoresReset.
  ///
  /// In en, this message translates to:
  /// **'All scores have been reset'**
  String get scoresReset;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @drawPanel.
  ///
  /// In en, this message translates to:
  /// **'Draw Panel'**
  String get drawPanel;

  /// No description provided for @drawMember.
  ///
  /// In en, this message translates to:
  /// **'Draw Member'**
  String get drawMember;

  /// No description provided for @drawGroup.
  ///
  /// In en, this message translates to:
  /// **'Draw Group'**
  String get drawGroup;

  /// No description provided for @candidatePool.
  ///
  /// In en, this message translates to:
  /// **'Candidate Pool'**
  String get candidatePool;

  /// No description provided for @drawPeople.
  ///
  /// In en, this message translates to:
  /// **'{count} people'**
  String drawPeople(Object count);

  /// No description provided for @drawGroups.
  ///
  /// In en, this message translates to:
  /// **'{count} groups'**
  String drawGroups(Object count);

  /// No description provided for @drawButton.
  ///
  /// In en, this message translates to:
  /// **'Draw!'**
  String get drawButton;

  /// No description provided for @noMembersToDraw.
  ///
  /// In en, this message translates to:
  /// **'No members to draw. Add members first.'**
  String get noMembersToDraw;

  /// No description provided for @noGroupsToDraw.
  ///
  /// In en, this message translates to:
  /// **'No groups to draw. Add groups first.'**
  String get noGroupsToDraw;

  /// No description provided for @currentScore.
  ///
  /// In en, this message translates to:
  /// **'Current Score: {score}'**
  String currentScore(Object score);

  /// No description provided for @questionBank.
  ///
  /// In en, this message translates to:
  /// **'Question Bank'**
  String get questionBank;

  /// No description provided for @questionBanks.
  ///
  /// In en, this message translates to:
  /// **'Question Banks'**
  String get questionBanks;

  /// No description provided for @questionPanel.
  ///
  /// In en, this message translates to:
  /// **'Question Panel'**
  String get questionPanel;

  /// No description provided for @noQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions available'**
  String get noQuestions;

  /// No description provided for @noQuestionsHint.
  ///
  /// In en, this message translates to:
  /// **'Click import button to add questions'**
  String get noQuestionsHint;

  /// No description provided for @mixMode.
  ///
  /// In en, this message translates to:
  /// **'Mix Mode'**
  String get mixMode;

  /// No description provided for @importCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get importCsv;

  /// No description provided for @importExcel.
  ///
  /// In en, this message translates to:
  /// **'Import Excel'**
  String get importExcel;

  /// No description provided for @riskQuestion.
  ///
  /// In en, this message translates to:
  /// **'Risk Question'**
  String get riskQuestion;

  /// No description provided for @riskQuestions.
  ///
  /// In en, this message translates to:
  /// **'Risk Questions'**
  String get riskQuestions;

  /// No description provided for @answered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get answered;

  /// No description provided for @resetAnswered.
  ///
  /// In en, this message translates to:
  /// **'Reset Answered'**
  String get resetAnswered;

  /// No description provided for @viewAnswer.
  ///
  /// In en, this message translates to:
  /// **'View Answer'**
  String get viewAnswer;

  /// No description provided for @closeAndMark.
  ///
  /// In en, this message translates to:
  /// **'Close (Mark as Answered)'**
  String get closeAndMark;

  /// No description provided for @randomPick.
  ///
  /// In en, this message translates to:
  /// **'Random Pick'**
  String get randomPick;

  /// No description provided for @noAvailableQuestion.
  ///
  /// In en, this message translates to:
  /// **'No available questions'**
  String get noAvailableQuestion;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import successful: {name} ({count} questions)'**
  String importSuccess(Object count, Object name);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(Object error);

  /// No description provided for @deleteBank.
  ///
  /// In en, this message translates to:
  /// **'Delete Bank'**
  String get deleteBank;

  /// No description provided for @deleteBankConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete bank \"{name}\"?'**
  String deleteBankConfirm(Object name);

  /// No description provided for @bankDeleted.
  ///
  /// In en, this message translates to:
  /// **'Bank deleted: {name}'**
  String bankDeleted(Object name);

  /// No description provided for @resetBank.
  ///
  /// In en, this message translates to:
  /// **'Bank reset: {name}'**
  String resetBank(Object name);

  /// No description provided for @selectBankFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a bank first'**
  String get selectBankFirst;

  /// No description provided for @timer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timer;

  /// No description provided for @timerPanel.
  ///
  /// In en, this message translates to:
  /// **'Clock & Timer'**
  String get timerPanel;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutes;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @resetTimer.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetTimer;

  /// No description provided for @countdown.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get countdown;

  /// No description provided for @setTimer.
  ///
  /// In en, this message translates to:
  /// **'Set Timer'**
  String get setTimer;

  /// No description provided for @customMinutes.
  ///
  /// In en, this message translates to:
  /// **'Custom minutes'**
  String get customMinutes;

  /// No description provided for @doubleClickSync.
  ///
  /// In en, this message translates to:
  /// **'Double-click to sync network time'**
  String get doubleClickSync;

  /// No description provided for @timeSynced.
  ///
  /// In en, this message translates to:
  /// **'Time synced'**
  String get timeSynced;

  /// No description provided for @timeSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Network time sync failed'**
  String get timeSyncFailed;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @leaderboardPanel.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardPanel;

  /// No description provided for @memberBoard.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get memberBoard;

  /// No description provided for @groupBoard.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupBoard;

  /// No description provided for @fullLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Full Leaderboard'**
  String get fullLeaderboard;

  /// No description provided for @memberManagement.
  ///
  /// In en, this message translates to:
  /// **'Member Management'**
  String get memberManagement;

  /// No description provided for @groupManagement.
  ///
  /// In en, this message translates to:
  /// **'Group Management'**
  String get groupManagement;

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rank;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @operation.
  ///
  /// In en, this message translates to:
  /// **'Operation'**
  String get operation;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @saveJson.
  ///
  /// In en, this message translates to:
  /// **'Save JSON'**
  String get saveJson;

  /// No description provided for @loadJson.
  ///
  /// In en, this message translates to:
  /// **'Load JSON'**
  String get loadJson;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Save successful'**
  String get saveSuccess;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(Object error);

  /// No description provided for @loadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Load successful'**
  String get loadSuccess;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed: {error}'**
  String loadFailed(Object error);

  /// No description provided for @autoSave.
  ///
  /// In en, this message translates to:
  /// **'Auto Save'**
  String get autoSave;

  /// No description provided for @autoSaveInterval.
  ///
  /// In en, this message translates to:
  /// **'Auto Save Interval'**
  String get autoSaveInterval;

  /// No description provided for @dirty.
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get dirty;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @savingDot.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingDot;

  /// No description provided for @selectFolder.
  ///
  /// In en, this message translates to:
  /// **'Select Folder'**
  String get selectFolder;

  /// No description provided for @folderSelected.
  ///
  /// In en, this message translates to:
  /// **'Folder selected'**
  String get folderSelected;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get syncTitle;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syncing;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Sync Complete'**
  String get syncComplete;

  /// No description provided for @syncingMessage.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncingMessage;

  /// No description provided for @syncingUpload.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get syncingUpload;

  /// No description provided for @syncingDownload.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get syncingDownload;

  /// No description provided for @syncingClean.
  ///
  /// In en, this message translates to:
  /// **'Cleaning up...'**
  String get syncingClean;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not Connected'**
  String get notConnected;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Sync Error'**
  String get syncError;

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last Sync'**
  String get lastSync;

  /// No description provided for @cloudConfig.
  ///
  /// In en, this message translates to:
  /// **'Cloud Settings'**
  String get cloudConfig;

  /// No description provided for @cloudService.
  ///
  /// In en, this message translates to:
  /// **'Cloud Service'**
  String get cloudService;

  /// No description provided for @webdavUrl.
  ///
  /// In en, this message translates to:
  /// **'WebDAV URL'**
  String get webdavUrl;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @remoteFolder.
  ///
  /// In en, this message translates to:
  /// **'Remote Folder Path'**
  String get remoteFolder;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// No description provided for @testingConnection.
  ///
  /// In en, this message translates to:
  /// **'Testing connection...'**
  String get testingConnection;

  /// No description provided for @connectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful ✓'**
  String get connectionSuccess;

  /// No description provided for @autoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto Sync'**
  String get autoSync;

  /// No description provided for @autoSyncInterval.
  ///
  /// In en, this message translates to:
  /// **'Auto Sync Interval'**
  String get autoSyncInterval;

  /// No description provided for @syncStrategy.
  ///
  /// In en, this message translates to:
  /// **'Sync Strategy'**
  String get syncStrategy;

  /// No description provided for @uploadOnly.
  ///
  /// In en, this message translates to:
  /// **'Upload Only'**
  String get uploadOnly;

  /// No description provided for @downloadOnly.
  ///
  /// In en, this message translates to:
  /// **'Download Only'**
  String get downloadOnly;

  /// No description provided for @bidirectional.
  ///
  /// In en, this message translates to:
  /// **'Bidirectional'**
  String get bidirectional;

  /// No description provided for @conflictStrategy.
  ///
  /// In en, this message translates to:
  /// **'Conflict Handling'**
  String get conflictStrategy;

  /// No description provided for @remoteFirst.
  ///
  /// In en, this message translates to:
  /// **'Cloud First'**
  String get remoteFirst;

  /// No description provided for @localFirst.
  ///
  /// In en, this message translates to:
  /// **'Local First'**
  String get localFirst;

  /// No description provided for @manualSelect.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manualSelect;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @none_.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none_;

  /// No description provided for @localImage.
  ///
  /// In en, this message translates to:
  /// **'Local Image'**
  String get localImage;

  /// No description provided for @bingDaily.
  ///
  /// In en, this message translates to:
  /// **'Bing Daily'**
  String get bingDaily;

  /// No description provided for @unsplash.
  ///
  /// In en, this message translates to:
  /// **'Unsplash'**
  String get unsplash;

  /// No description provided for @customUrl.
  ///
  /// In en, this message translates to:
  /// **'Custom URL'**
  String get customUrl;

  /// No description provided for @themeSettings.
  ///
  /// In en, this message translates to:
  /// **'Theme Settings'**
  String get themeSettings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get soundEffects;

  /// No description provided for @sounds.
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get sounds;

  /// No description provided for @wallpaper.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper'**
  String get wallpaper;

  /// No description provided for @wallpaperSource.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper Source'**
  String get wallpaperSource;

  /// No description provided for @wallpaperInterval.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper Change Interval'**
  String get wallpaperInterval;

  /// No description provided for @layout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get layout;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @landscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get landscape;

  /// No description provided for @portrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get portrait;

  /// No description provided for @hours24.
  ///
  /// In en, this message translates to:
  /// **'24-Hour Clock'**
  String get hours24;

  /// No description provided for @timerPresets.
  ///
  /// In en, this message translates to:
  /// **'Timer Presets (comma-separated)'**
  String get timerPresets;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get update;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @currentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current Version'**
  String get currentVersion;

  /// No description provided for @latestVersion.
  ///
  /// In en, this message translates to:
  /// **'Latest Version'**
  String get latestVersion;

  /// No description provided for @goDownload.
  ///
  /// In en, this message translates to:
  /// **'Go to download page?'**
  String get goDownload;

  /// No description provided for @goDownloadPage.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get goDownloadPage;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'Already up to date'**
  String get upToDate;

  /// No description provided for @exportTemplate.
  ///
  /// In en, this message translates to:
  /// **'Export Template'**
  String get exportTemplate;

  /// No description provided for @exportMemberTemplate.
  ///
  /// In en, this message translates to:
  /// **'Export Student List Template'**
  String get exportMemberTemplate;

  /// No description provided for @exportQuestionTemplate.
  ///
  /// In en, this message translates to:
  /// **'Export Question Bank Template'**
  String get exportQuestionTemplate;

  /// No description provided for @importScores.
  ///
  /// In en, this message translates to:
  /// **'Import Scores'**
  String get importScores;

  /// No description provided for @exportScores.
  ///
  /// In en, this message translates to:
  /// **'Export Scores'**
  String get exportScores;

  /// No description provided for @scoreImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Scores imported successfully'**
  String get scoreImportSuccess;

  /// No description provided for @scoreImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Score import failed: {error}'**
  String scoreImportFailed(Object error);

  /// No description provided for @scoreExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Scores exported successfully'**
  String get scoreExportSuccess;

  /// No description provided for @scoreExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Score export failed: {error}'**
  String scoreExportFailed(Object error);

  /// No description provided for @usbDetected.
  ///
  /// In en, this message translates to:
  /// **'USB drive detected'**
  String get usbDetected;

  /// No description provided for @usbDataFolder.
  ///
  /// In en, this message translates to:
  /// **'USB data folder'**
  String get usbDataFolder;

  /// No description provided for @autoLoadFromUsb.
  ///
  /// In en, this message translates to:
  /// **'Auto-loading data from USB'**
  String get autoLoadFromUsb;

  /// No description provided for @usbNotFound.
  ///
  /// In en, this message translates to:
  /// **'USB data folder not found'**
  String get usbNotFound;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Smart Classroom'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Desc.
  ///
  /// In en, this message translates to:
  /// **'A classroom interaction tool designed for teachers\n\nEfficiently manage classes, groups and members\nRandom draws, score management and data sync'**
  String get onboardingPage1Desc;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Create Classes & Groups'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Desc.
  ///
  /// In en, this message translates to:
  /// **'Create your classes from the central console\nAdd groups under each class\nAdd members to groups and start teaching\n\nImport Excel rosters for quick setup'**
  String get onboardingPage2Desc;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Random Draw & Scores'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Desc.
  ///
  /// In en, this message translates to:
  /// **'Random roll-call for individuals and groups\nLock specific groups, set no-repeat mode\nOne-tap score adjustments for drawn students\nAuto-generated rank badges for fun'**
  String get onboardingPage3Desc;

  /// No description provided for @onboardingPage4Title.
  ///
  /// In en, this message translates to:
  /// **'Quiz Bank & Timer'**
  String get onboardingPage4Title;

  /// No description provided for @onboardingPage4Desc.
  ///
  /// In en, this message translates to:
  /// **'Import Excel question banks with risk tagging\nRandom non-answered questions, multi-bank mix\nBuilt-in countdown timer with presets\nDouble-click clock to sync network time'**
  String get onboardingPage4Desc;

  /// No description provided for @onboardingPage5Title.
  ///
  /// In en, this message translates to:
  /// **'Data Sync & Backup'**
  String get onboardingPage5Title;

  /// No description provided for @onboardingPage5Desc.
  ///
  /// In en, this message translates to:
  /// **'Auto-save data to USB drive\nExcel score import/export\nWebDAV cloud sync (e.g. Nutstore)\nSeamless cross-device teaching continuity'**
  String get onboardingPage5Desc;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get chinese;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
