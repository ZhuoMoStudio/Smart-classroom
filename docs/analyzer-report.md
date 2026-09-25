# CI 静态分析与测试报告

本文件由 CI 的 verify job 自动生成，请勿手工编辑。

- 生成时间：2026-09-25 12:06:33Z
- 触发：push @ main
- 提交：`1ee6d67de6baab55ac2dcf49cecb0e4b94e3bd73`
- Flutter：Flutter 3.44.9 • channel stable • https://github.com/flutter/flutter.git
- `flutter analyze` 退出码：1
- `flutter test` 退出码：1

## flutter analyze

```text
Resolving dependencies...
Downloading packages...
  archive 3.6.1 (4.3.0 available)
  clock 1.1.2 (1.1.3 available)
  code_assets 1.2.1 (2.1.0 available)
  cross_file 0.3.5+5 (0.4.0 available)
  dart_pubspec_licenses 3.0.12 (3.2.0 available)
  dbus 0.7.15 (0.8.0 available)
  equatable 2.1.0 (3.0.0 available)
  excel 3.0.0 (4.0.6 available)
  file_picker 10.3.8 (13.1.0 available)
  flutter_lints 3.0.2 (6.0.0 available)
  flutter_local_notifications 17.2.4 (22.3.1 available)
  flutter_local_notifications_linux 4.0.1 (8.0.1 available)
  flutter_local_notifications_platform_interface 7.2.0 (12.2.0 available)
  flutter_riverpod 2.6.1 (3.4.3 available)
  flutter_secure_storage 9.2.4 (11.2.0 available)
  flutter_secure_storage_linux 1.2.3 (3.0.3 available)
  flutter_secure_storage_macos 3.1.3 (4.0.0 available)
  flutter_secure_storage_platform_interface 1.1.2 (2.1.1 available)
  flutter_secure_storage_web 1.2.1 (2.1.1 available)
  flutter_secure_storage_windows 3.1.2 (4.2.2 available)
  hooks 2.0.2 (2.2.0 available)
  intl 0.20.2 (0.20.3 available)
  js 0.6.7 (0.7.2 available)
  lints 3.0.0 (6.1.0 available)
  matcher 0.12.19 (0.12.20 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  meta 1.18.0 (1.19.0 available)
  objective_c 9.5.0 (9.6.0 available)
  package_info_plus 8.3.1 (10.2.1 available)
  package_info_plus_platform_interface 3.2.1 (4.1.0 available)
  pdfrx 1.3.5 (2.6.5 available)
  record_use 0.6.0 (1.1.1 available)
  riverpod 2.6.1 (3.4.3 available)
  stack_trace 1.12.1 (1.12.2 available)
  test_api 0.7.11 (0.7.14 available)
  timezone 0.9.4 (0.11.1 available)
  vector_math 2.2.0 (2.4.3 available)
  win32 5.15.0 (6.4.0 available)
  xml 6.6.1 (7.0.1 available)
Got dependencies!
39 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Analyzing Smart-classroom...                                    

warning • Unused import: '../services/storage_service.dart'. Try removing the import directive • lib/providers/services_provider.dart:3:8 • unused_import
warning • Duplicate import. Try removing all but one import of the library • lib/providers/services_provider.dart:6:8 • duplicate_import
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/providers/timer_provider.dart:37:9 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/providers/timer_provider.dart:38:12 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/providers/timer_provider.dart:47:14 • curly_braces_in_flow_control_structures
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/dialogs/full_leaderboard_dialog.dart:241:48 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/dialogs/question_detail_dialog.dart:97:64 • deprecated_member_use
warning • Unused import: '../theme/design_tokens.dart'. Try removing the import directive • lib/screens/draw_panel.dart:7:8 • unused_import
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/draw_panel.dart:151:111 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/draw_panel.dart:165:142 • deprecated_member_use
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/screens/draw_panel.dart:199:9 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/screens/draw_panel.dart:199:28 • prefer_const_constructors
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/draw_panel.dart:259:63 • deprecated_member_use
warning • Unused import: '../theme/responsive.dart'. Try removing the import directive • lib/screens/home_screen.dart:18:8 • unused_import
warning • Unused import: '../widgets/workspace_picker_dialog.dart'. Try removing the import directive • lib/screens/home_screen.dart:25:8 • unused_import
warning • Unused import: '../models/class_model.dart'. Try removing the import directive • lib/screens/home_screen.dart:28:8 • unused_import
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:112:64 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:143:68 • deprecated_member_use
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/screens/home_screen.dart:148:42 • prefer_const_constructors
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:182:91 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:196:85 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:234:50 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:236:97 • deprecated_member_use
   info • Unnecessary braces in a string interpolation. Try removing the braces • lib/screens/home_screen.dart:352:104 • unnecessary_brace_in_string_interps
   info • Don't use 'BuildContext's across async gaps. Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check • lib/screens/home_screen.dart:382:43 • use_build_context_synchronously
   info • Don't use 'BuildContext's across async gaps. Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check • lib/screens/home_screen.dart:384:25 • use_build_context_synchronously
   info • Don't use 'BuildContext's across async gaps. Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check • lib/screens/home_screen.dart:385:37 • use_build_context_synchronously
   info • Don't use 'BuildContext's across async gaps. Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check • lib/screens/home_screen.dart:424:109 • use_build_context_synchronously
   info • Don't use 'BuildContext's across async gaps. Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check • lib/screens/home_screen.dart:425:41 • use_build_context_synchronously
   info • Don't use 'BuildContext's across async gaps. Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check • lib/screens/home_screen.dart:429:190 • use_build_context_synchronously
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:511:65 • deprecated_member_use
   info • 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:520:39 • deprecated_member_use
   info • 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:523:36 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:530:51 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:531:51 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:532:48 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:533:53 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:534:35 • deprecated_member_use
   info • 'groupValue' is deprecated and shouldn't be used. Use a RadioGroup ancestor to manage group value instead. This feature was deprecated after v3.32.0-0.0.pre. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:542:81 • deprecated_member_use
   info • 'onChanged' is deprecated and shouldn't be used. Use RadioGroup to handle value change instead. This feature was deprecated after v3.32.0-0.0.pre. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:542:111 • deprecated_member_use
   info • 'groupValue' is deprecated and shouldn't be used. Use a RadioGroup ancestor to manage group value instead. This feature was deprecated after v3.32.0-0.0.pre. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:543:77 • deprecated_member_use
   info • 'onChanged' is deprecated and shouldn't be used. Use RadioGroup to handle value change instead. This feature was deprecated after v3.32.0-0.0.pre. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:543:107 • deprecated_member_use
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/screens/home_screen.dart:575:22 • prefer_const_constructors
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/home_screen.dart:646:115 • deprecated_member_use
   info • Don't use 'BuildContext's across async gaps. Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check • lib/screens/home_screen.dart:657:41 • use_build_context_synchronously
   info • Don't use 'BuildContext's across async gaps. Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check • lib/screens/home_screen.dart:659:23 • use_build_context_synchronously
   info • Don't use 'BuildContext's across async gaps. Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check • lib/screens/home_screen.dart:660:35 • use_build_context_synchronously
   info • Don't use 'BuildContext's across async gaps. Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check • lib/screens/home_screen.dart:666:115 • use_build_context_synchronously
   info • Don't use 'BuildContext's across async gaps. Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check • lib/screens/home_screen.dart:667:35 • use_build_context_synchronously
warning • Unused import: '../models/score_history.dart'. Try removing the import directive • lib/screens/leaderboard_panel.dart:10:8 • unused_import
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/screens/leaderboard_panel.dart:43:22 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/screens/leaderboard_panel.dart:43:56 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/screens/leaderboard_panel.dart:85:20 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/screens/leaderboard_panel.dart:85:54 • curly_braces_in_flow_control_structures
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/leaderboard_panel.dart:145:41 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/leaderboard_panel.dart:162:93 • deprecated_member_use
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/screens/leaderboard_panel.dart:195:35 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/screens/leaderboard_panel.dart:195:82 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/screens/leaderboard_panel.dart:195:127 • curly_braces_in_flow_control_structures
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/leaderboard_panel.dart:196:101 • deprecated_member_use
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/screens/leaderboard_panel.dart:201:84 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/screens/leaderboard_panel.dart:201:114 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/screens/leaderboard_panel.dart:202:26 • curly_braces_in_flow_control_structures
   info • Don't use 'BuildContext's across async gaps. Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check • lib/screens/leaderboard_panel.dart:311:23 • use_build_context_synchronously
warning • The value of the local variable 'theme' isn't used. Try removing the variable or using it • lib/screens/onboarding_screen.dart:93:11 • unused_local_variable
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/onboarding_screen.dart:172:32 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/onboarding_screen.dart:173:51 • deprecated_member_use
  error • The method 'forPage' isn't defined for the type 'PdfAnnotationStore'. Try correcting the name to the name of an existing method, or defining a method named 'forPage' • lib/screens/pdf_reader_screen.dart:324:24 • undefined_method
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/pdf_reader_screen.dart:447:33 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/question_panel.dart:187:54 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/question_panel.dart:189:54 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/question_panel.dart:217:54 • deprecated_member_use
   info • Don't use 'BuildContext's across async gaps. Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check • lib/screens/question_panel.dart:289:11 • use_build_context_synchronously
   info • Don't use 'BuildContext's across async gaps. Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check • lib/screens/question_panel.dart:292:25 • use_build_context_synchronously
   info • Don't use 'BuildContext's across async gaps. Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check • lib/screens/timer_panel.dart:61:25 • use_build_context_synchronously
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/timer_panel.dart:108:58 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/screens/timer_panel.dart:130:39 • deprecated_member_use
   info • Unnecessary use of string interpolation. Try replacing the string literal with the variable name • lib/screens/timer_panel.dart:145:24 • unnecessary_string_interpolations
   info • Unnecessary use of string interpolation. Try replacing the string literal with the variable name • lib/screens/timer_panel.dart:155:24 • unnecessary_string_interpolations
warning • Unused import: '../theme/design_tokens.dart'. Try removing the import directive • lib/screens/usage_guide_screen.dart:2:8 • unused_import
warning • Unused import: 'cloud/cloud_storage_service.dart'. Try removing the import directive • lib/services/auto_sync_timer.dart:6:8 • unused_import
warning • Unused import: '../../providers/services_provider.dart'. Try removing the import directive • lib/services/cloud/cloud_storage_service.dart:3:8 • unused_import
warning • Unused import: 'dart:convert'. Try removing the import directive • lib/services/cloud/webdav_plus_sync.dart:1:8 • unused_import
warning • Unused import: '../storage_service.dart'. Try removing the import directive • lib/services/cloud/webdav_plus_sync.dart:6:8 • unused_import
warning • The receiver can't be null, so the null-aware operator '?.' is unnecessary. Try replacing the operator '?.' with '.' • lib/services/excel_service.dart:431:13 • invalid_null_aware_operator
   info • The private field _doc could be 'final'. Try making the field 'final' • lib/services/pdf_annotation_store.dart:129:17 • prefer_final_fields
warning • The value of the local variable 'file' isn't used. Try removing the variable or using it • lib/services/pdf_cache_manager.dart:98:15 • unused_local_variable
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/services/textbook_index_service.dart:44:48 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/services/textbook_index_service.dart:53:58 • curly_braces_in_flow_control_structures
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/services/update_service.dart:64:14 • prefer_const_constructors
warning • Unused import: 'package:flutter/foundation.dart'. Try removing the import directive • lib/services/workspace_service.dart:4:8 • unused_import
warning • The value of the local variable 'surface' isn't used. Try removing the variable or using it • lib/theme/app_theme.dart:9:11 • unused_local_variable
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/theme/app_theme.dart:40:37 • deprecated_member_use
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/theme/app_theme.dart:51:17 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/theme/app_theme.dart:71:16 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/theme/app_theme.dart:73:17 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/theme/app_theme.dart:73:44 • prefer_const_constructors
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/theme/app_theme.dart:89:48 • deprecated_member_use
warning • Unused import: 'dart:ui'. Try removing the import directive • lib/theme/design_tokens.dart:1:8 • unused_import
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/theme/design_tokens.dart:26:48 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/theme/design_tokens.dart:27:49 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/theme/design_tokens.dart:45:52 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/theme/design_tokens.dart:46:53 • deprecated_member_use
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/theme/design_tokens.dart:61:21 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/theme/design_tokens.dart:67:21 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/theme/design_tokens.dart:71:21 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/theme/design_tokens.dart:77:21 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/theme/design_tokens.dart:81:21 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/theme/design_tokens.dart:89:21 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/theme/design_tokens.dart:95:21 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/theme/design_tokens.dart:99:21 • prefer_const_constructors
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/widgets/glass_panel.dart:94:36 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/widgets/glass_panel.dart:99:33 • deprecated_member_use
warning • The value of the field '_previousScore' isn't used. Try removing the field, or using it • lib/widgets/rank_badge.dart:26:10 • unused_field
warning • The value of the local variable 'isAnimating' isn't used. Try removing the variable or using it • lib/widgets/rolling_display.dart:88:11 • unused_local_variable
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/widgets/rolling_display.dart:107:28 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/widgets/rolling_display.dart:113:28 • deprecated_member_use
warning • Unused import: '../theme/responsive.dart'. Try removing the import directive • lib/widgets/score_button.dart:3:8 • unused_import
warning • Unused import: 'dart:io'. Try removing the import directive • lib/widgets/textbook_panel.dart:1:8 • unused_import
warning • Unused import: '../theme/design_tokens.dart'. Try removing the import directive • lib/widgets/textbook_panel.dart:9:8 • unused_import
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/widgets/textbook_panel.dart:59:20 • curly_braces_in_flow_control_structures
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/widgets/textbook_panel.dart:324:58 • deprecated_member_use
   info • Statements in a while should be enclosed in a block. Try wrapping the statement in a block • lib/widgets/textbook_panel.dart:328:57 • curly_braces_in_flow_control_structures
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/widgets/textbook_panel.dart:337:59 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/widgets/textbook_panel.dart:407:49 • deprecated_member_use
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/widgets/textbook_panel.dart:476:15 • prefer_const_constructors
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/widgets/textbook_panel.dart:500:56 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/widgets/textbook_panel.dart:535:51 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/widgets/textbook_panel.dart:568:36 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/widgets/textbook_panel.dart:601:35 • deprecated_member_use
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/widgets/textbook_panel.dart:632:59 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/widgets/textbook_panel.dart:635:33 • curly_braces_in_flow_control_structures
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/widgets/toast_overlay.dart:50:35 • deprecated_member_use
warning • This default clause is covered by the previous cases. Try removing the default clause, or restructuring the preceding patterns • lib/widgets/toast_overlay.dart:99:7 • unreachable_switch_default
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/widgets/workspace_picker_dialog.dart:63:49 • deprecated_member_use
   info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. Try replacing the use of the deprecated member with the replacement • lib/widgets/workspace_picker_dialog.dart:93:41 • deprecated_member_use
   info • Don't use 'BuildContext's across async gaps. Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check • lib/widgets/workspace_picker_dialog.dart:163:27 • use_build_context_synchronously

137 issues found. (ran in 14.1s)
```

## flutter test

```text
Resolving dependencies...
Downloading packages...
  archive 3.6.1 (4.3.0 available)
  clock 1.1.2 (1.1.3 available)
  code_assets 1.2.1 (2.1.0 available)
  cross_file 0.3.5+5 (0.4.0 available)
  dart_pubspec_licenses 3.0.12 (3.2.0 available)
  dbus 0.7.15 (0.8.0 available)
  equatable 2.1.0 (3.0.0 available)
  excel 3.0.0 (4.0.6 available)
  file_picker 10.3.8 (13.1.0 available)
  flutter_lints 3.0.2 (6.0.0 available)
  flutter_local_notifications 17.2.4 (22.3.1 available)
  flutter_local_notifications_linux 4.0.1 (8.0.1 available)
  flutter_local_notifications_platform_interface 7.2.0 (12.2.0 available)
  flutter_riverpod 2.6.1 (3.4.3 available)
  flutter_secure_storage 9.2.4 (11.2.0 available)
  flutter_secure_storage_linux 1.2.3 (3.0.3 available)
  flutter_secure_storage_macos 3.1.3 (4.0.0 available)
  flutter_secure_storage_platform_interface 1.1.2 (2.1.1 available)
  flutter_secure_storage_web 1.2.1 (2.1.1 available)
  flutter_secure_storage_windows 3.1.2 (4.2.2 available)
  hooks 2.0.2 (2.2.0 available)
  intl 0.20.2 (0.20.3 available)
  js 0.6.7 (0.7.2 available)
  lints 3.0.0 (6.1.0 available)
  matcher 0.12.19 (0.12.20 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  meta 1.18.0 (1.19.0 available)
  objective_c 9.5.0 (9.6.0 available)
  package_info_plus 8.3.1 (10.2.1 available)
  package_info_plus_platform_interface 3.2.1 (4.1.0 available)
  pdfrx 1.3.5 (2.6.5 available)
  record_use 0.6.0 (1.1.1 available)
  riverpod 2.6.1 (3.4.3 available)
  stack_trace 1.12.1 (1.12.2 available)
  test_api 0.7.11 (0.7.14 available)
  timezone 0.9.4 (0.11.1 available)
  vector_math 2.2.0 (2.4.3 available)
  win32 5.15.0 (6.4.0 available)
  xml 6.6.1 (7.0.1 available)
Got dependencies!
39 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart
00:00 +0: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: RankSystem.getRank 0 分是倔强青铜 V
00:00 +1: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: RankSystem.getRank 每个大段位内部从 V 递增到 I（以倔强青铜为例）
00:00 +2: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: RankSystem.getRank 跨过 50 分进入秩序白银
00:00 +3: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: RankSystem.getRank 小数分向下取整，49.9 仍属倔强青铜 I
00:00 +4: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: RankSystem.getRank 负分被夹到 0，不产生越界段位
00:00 +5: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: RankSystem.getRank 290 分是至尊星耀 I，300 分起进入最强王者
00:00 +6: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: RankSystem.getRank 350 分及以上封顶荣耀王者，level 不再增长
00:00 +7: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: 模型派生值 Group.totalScore 是成员分数之和
00:00 +8: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: 模型派生值 Classroom.allMembers 展开全部小组
00:00 +9: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: 模型派生值 Member.copyWith 不改 uid，只改传入字段
lib/screens/pdf_reader_screen.dart:324:24: Error: The method 'forPage' isn't defined for the type 'PdfAnnotationStore'.
 - 'PdfAnnotationStore' is from 'package:smart_classroom/services/pdf_annotation_store.dart' ('lib/services/pdf_annotation_store.dart').
Try correcting the name to the name of an existing method, or defining a method named 'forPage'.
        strokes: store.forPage(pageNumber),
                       ^^^^^^^
00:04 +10 -1: loading /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart [E]
  Failed to load "/home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart":
  Compilation failed for testPath=/home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: lib/screens/pdf_reader_screen.dart:324:24: Error: The method 'forPage' isn't defined for the type 'PdfAnnotationStore'.
   - 'PdfAnnotationStore' is from 'package:smart_classroom/services/pdf_annotation_store.dart' ('lib/services/pdf_annotation_store.dart').
  Try correcting the name to the name of an existing method, or defining a method named 'forPage'.
          strokes: store.forPage(pageNumber),
                         ^^^^^^^
  .
00:04 +10 -1: Some tests failed.

Failing tests:
  /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: loading /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart
```
