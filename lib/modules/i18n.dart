// lib/modules/i18n.dart
// Multi-language support for JA_PyToCy (English / Tiếng Việt)
// Uses InheritedNotifier for context-based access from anywhere in the tree

import 'package:flutter/material.dart';
import 'app_config.dart';

enum AppLanguage { en, vi }

extension AppLanguageExt on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.en: return 'en';
      case AppLanguage.vi: return 'vi';
    }
  }

  String get shortLabel {
    switch (this) {
      case AppLanguage.en: return 'EN';
      case AppLanguage.vi: return 'VN';
    }
  }

  String get fullLabel {
    switch (this) {
      case AppLanguage.en: return 'English';
      case AppLanguage.vi: return 'Tiếng Việt';
    }
  }

  static AppLanguage fromCode(String code) {
    switch (code) {
      case 'vi': return AppLanguage.vi;
      default:   return AppLanguage.en;
    }
  }

  AppLanguage get next {
    final values = AppLanguage.values;
    return values[(index + 1) % values.length];
  }
}

class AppStrings {
  final AppLanguage lang;
  const AppStrings(this.lang);

  String _s(String en, String vi) => lang == AppLanguage.vi ? vi : en;

  // Sidebar Titles & Actions
  String get appTitle => _s('Python To Cython Converter', 'Chuyển Đổi Python Sang Cython');
  String get sectionSettings => _s('Settings', 'Cài Đặt');
  String get sectionActions => _s('Actions', 'Thao Tác');
  String get btnSelectFiles => _s('Select Files', 'Chọn Tệp Tin');
  String get btnSelectDir => _s('Select Folder', 'Chọn Thư Mục');
  String get btnClearQueue => _s('Clear Queue', 'Xóa Hàng Đợi');
  String get btnCompileAll => _s('Compile All', 'Biên Dịch Tất Cả');
  String get btnCompiling => _s('Compiling...', 'Đang Biên Dịch...');
  String get btnInstallCython => _s('Install Cython', 'Cài Đặt Cython');

  // Config options
  String get optDeleteSource => _s('Delete Source Files (.py)', 'Xóa tệp nguồn (.py) sau biên dịch');
  String get optKeepSource => _s('Keep Source Files (.py)', 'Giữ lại tệp nguồn (.py)');
  String get optDeleteC => _s('Delete Intermediate .c Files', 'Xóa tệp .c trung gian');
  String get optKeepC => _s('Keep Intermediate .c Files', 'Giữ lại tệp .c trung gian');
  String get labelLangLevel => _s('Python Language Level', 'Phiên bản ngôn ngữ Python');
  String get sectionDirectives => _s('Cython Directives (Optimization)', 'Chỉ thị Cython (Tối ưu hóa)');
  String get optBoundsCheck => _s('Bounds Check (boundscheck)', 'Kiểm tra biên mảng (boundscheck)');
  String get optWrapAround => _s('Wrap Around (wraparound)', 'Hỗ trợ chỉ số âm (wraparound)');
  String get optInitializedCheck => _s('Initialized Check', 'Kiểm tra khởi tạo con trỏ');
  String get optNoneCheck => _s('None Check', 'Kiểm tra giá trị None');

  // Directives tooltips
  String get tipBoundsCheck => _s('Setting to False removes bounds checking for array indexing, improving speed but risking crash if index out of range.', 'Đặt thành False sẽ bỏ qua kiểm tra biên mảng, giúp tăng tốc độ nhưng có nguy cơ lỗi nếu chỉ số ngoài phạm vi.');
  String get tipWrapAround => _s('Setting to False disables negative indexing support, increasing execution speed.', 'Đặt thành False sẽ tắt hỗ trợ chỉ số âm, giúp tăng tốc độ thực thi.');
  String get tipInitializedCheck => _s('Setting to False disables checking if memoryview/objects are initialized.', 'Đặt thành False sẽ bỏ qua kiểm tra bộ nhớ/đối tượng đã khởi tạo hay chưa.');
  String get tipNoneCheck => _s('Setting to False disables checks for None access on extension types.', 'Đặt thành False sẽ bỏ qua kiểm tra truy cập thuộc tính None.');

  // Table Headers
  String get colNum => '#';
  String get colFileName => _s('FILE NAME', 'TÊN TỆP');
  String get colPath => _s('FOLDER PATH', 'ĐƯỜNG DẪN THƯ MỤC');
  String get colSize => _s('SIZE', 'KÍCH THƯỚC');
  String get colStatus => _s('STATUS', 'TRẠNG THÁI');
  String get colResult => _s('RESULT / DETAILS', 'KẾT QUẢ / CHI TIẾT');

  // File States
  String get statusPending => _s('Pending', 'Chờ xử lý');
  String get statusCompiling => _s('Compiling', 'Đang biên dịch');
  String get statusSuccess => _s('Success', 'Thành công');
  String get statusFailed => _s('Failed', 'Thất bại');

  // Logs and Console
  String get labelLogs => _s('COMPILATION TERMINAL LOGS', 'NHẬT KÝ BIÊN DỊCH REAL-TIME');
  String get terminalEmpty => _s('Terminal idle. Start compiling to view compiler output here...', 'Màn hình biên dịch rảnh. Hãy bắt đầu biên dịch để xem kết quả tại đây...');

  // Health and Environment Check
  String get envChecking => _s('Checking environment...', 'Đang kiểm tra môi trường...');
  String get envPythonFound => _s('Python: Found', 'Python: Đã tìm thấy');
  String get envPythonMissing => _s('Python: Not Found', 'Python: Chưa cài đặt');
  String get envCythonFound => _s('Cython: Found', 'Cython: Đã tìm thấy');
  String get envCythonMissing => _s('Cython: Not Found', 'Cython: Chưa cài đặt');
  String get envCompilerFound => _s('Compiler: Found', 'Trình biên dịch C: Đã tìm thấy');
  String get envCompilerMissing => _s('Compiler: Not Found (Requires MSVC/GCC)', 'Trình biên dịch C: Chưa tìm thấy (Cần MSVC/GCC)');

  // Alerts and Dialogs
  String get dlgHelpTitle => _s('Environment Support Guide', 'Hướng dẫn Cài đặt Môi trường');
  String get dlgHelpCompilerDesc => _s(
    'Cython compiles Python modules to C extensions. Therefore, you must have a C/C++ compiler installed:\n\n'
    '• Windows: Install Microsoft Visual Studio or Visual Studio Build Tools (check "C++ Build Tools").\n'
    '• macOS: Run `xcode-select --install` in terminal.\n'
    '• Linux: Run `sudo apt install build-essential` or equivalent package.',
    'Cython biên dịch các module Python sang ngôn ngữ C mở rộng. Do đó, hệ thống bắt buộc phải cài đặt trình biên dịch C/C++:\n\n'
    '• Windows: Cài đặt Microsoft Visual Studio hoặc Visual Studio Build Tools (chọn "C++ Build Tools").\n'
    '• macOS: Chạy lệnh `xcode-select --install` trong Terminal.\n'
    '• Linux: Chạy lệnh `sudo apt install build-essential` hoặc tương đương.'
  );
  String get dlgHelpCythonDesc => _s(
    'Cython library is missing in your Python environment. You can install it by clicking the "Install Cython" button on the sidebar or running:\n\n'
    'pip install cython',
    'Thư viện Cython chưa được cài đặt trong môi trường Python của bạn. Bạn có thể cài đặt bằng cách nhấn nút "Cài Đặt Cython" hoặc chạy lệnh:\n\n'
    'pip install cython'
  );

  String get msgCythonInstalled => _s('Cython library installed successfully!', 'Đã cài đặt thư viện Cython thành công!');
  String get msgCythonInstallFail => _s('Failed to install Cython. Please install it manually.', 'Cài đặt Cython thất bại. Vui lòng cài đặt thủ công.');
  String get msgSelectPython => _s('No python files selected', 'Chưa chọn tệp Python nào');
  String get msgEmptyQueue => _s('Queue is empty. Select files first.', 'Hàng đợi trống. Hãy chọn tệp trước.');
  String get msgCompilerError => _s('Compilation failed. Check terminal logs for detailed errors.', 'Biên dịch thất bại. Hãy xem nhật ký màn hình để biết chi tiết lỗi.');
  String get btnClose => _s('Close', 'Đóng');

  // Info
  String get tooltipRefresh => _s('Refresh environment check', 'Làm mới kiểm tra môi trường');
  String get tooltipLanguage => _s('Change Language', 'Thay đổi ngôn ngữ');
  String get tooltipTheme => _s('Toggle Theme (Dark/Light/Auto)', 'Thay đổi giao diện (Tối/Sáng/Tự động)');

  String tooltipThemeState(String mode) => _s('Theme: $mode', 'Giao diện: $mode');
}

class LanguageNotifier extends ChangeNotifier {
  AppLanguage _current;

  LanguageNotifier(this._current);

  AppLanguage get language => _current;
  AppStrings get strings => AppStrings(_current);

  void setLanguage(AppLanguage lang) {
    if (_current == lang) return;
    _current = lang;
    AppConfig.set('language', lang.code);
    notifyListeners();
  }

  void toggle() {
    setLanguage(_current.next);
  }
}

class LanguageProvider extends InheritedNotifier<LanguageNotifier> {
  const LanguageProvider({
    super.key,
    required super.notifier,
    required super.child,
  });

  static LanguageNotifier of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<LanguageProvider>();
    return provider!.notifier!;
  }
}

extension BuildContextI18n on BuildContext {
  AppStrings get strings => LanguageProvider.of(this).strings;
  LanguageNotifier get languageNotifier => LanguageProvider.of(this);
}
