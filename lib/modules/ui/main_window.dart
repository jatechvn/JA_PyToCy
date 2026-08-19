// lib/modules/ui/main_window.dart
// Main application window with Python file queue, settings, and compiler output logs

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../logic.dart';
import '../constants.dart';
import '../i18n.dart';
import '../app_config.dart';
import 'styles.dart';
import 'dialogs.dart';

class MainWindow extends StatefulWidget {
  final CompilerLogic logic;
  final ThemeNotifier themeNotifier;
  final LanguageNotifier languageNotifier;

  const MainWindow({
    super.key,
    required this.logic,
    required this.themeNotifier,
    required this.languageNotifier,
  });

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  AppColors get _c => widget.themeNotifier.colors;
  AppStrings get _s => widget.languageNotifier.strings;

  final GlobalKey _themeButtonKey = GlobalKey();
  final ScrollController _terminalScrollController = ScrollController();
  final List<String> _terminalLogs = [];

  // Config States
  bool _cleanCFiles = true;
  bool _deleteSource = false;
  String _languageLevel = '3';
  
  bool _boundsCheck = false;
  bool _wrapAround = false;
  bool _initializedCheck = false;
  bool _noneCheck = false;

  bool _isCheckingEnv = false;

  @override
  void initState() {
    super.initState();
    _loadConfigValues();
    _checkEnv();
    
    // Listen to compiler logs
    widget.logic.logStream.listen((log) {
      if (mounted) {
        setState(() {
          _terminalLogs.add(log);
        });
        _scrollToBottom();
      }
    });

    // Listen to queue / status changes
    widget.logic.statusStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _loadConfigValues() {
    setState(() {
      _cleanCFiles = AppConfig.getBool(keyCleanCFiles, defaultValue: true);
      _deleteSource = AppConfig.getBool(keyDeleteSource, defaultValue: false);
      _languageLevel = AppConfig.get(keyLanguageLevel, defaultValue: '3');
      
      _boundsCheck = AppConfig.getBool(keyDirectiveBoundsCheck, defaultValue: false);
      _wrapAround = AppConfig.getBool(keyDirectiveWrapAround, defaultValue: false);
      _initializedCheck = AppConfig.getBool(keyDirectiveInitializedCheck, defaultValue: false);
      _noneCheck = AppConfig.getBool(keyDirectiveNoneCheck, defaultValue: false);
    });
  }

  Future<void> _checkEnv() async {
    if (_isCheckingEnv) return;
    setState(() => _isCheckingEnv = true);
    await widget.logic.checkEnvironment();
    if (mounted) {
      setState(() => _isCheckingEnv = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_terminalScrollController.hasClients) {
        _terminalScrollController.animateTo(
          _terminalScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['py'],
        allowMultiple: true,
        dialogTitle: 'Select Python Files',
      );

      if (result != null && result.paths.isNotEmpty) {
        for (final path in result.paths) {
          if (path != null) {
            widget.logic.addFile(path);
          }
        }
      }
    } catch (e) {
      _showSnackbar('Error picking files: $e', isError: true);
    }
  }

  Future<void> _pickDirectory() async {
    try {
      final path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Python Project Folder',
      );

      if (path != null) {
        await widget.logic.addDirectory(path);
      }
    } catch (e) {
      _showSnackbar('Error picking directory: $e', isError: true);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? _c.statusRemoved : _c.bgCard,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeQueue = widget.logic.queue;
    final isCompiling = widget.logic.isCompiling;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: _c.bgPrimary,
          borderRadius: Platform.isWindows ? BorderRadius.zero : const BorderRadius.all(Radius.circular(8)),
        ),
        child: Row(
          children: [
            // LEFT SIDEBAR: Settings & Actions
            _buildSidebar(isCompiling),

            // RIGHT CONTENT AREA: File Queue Table & Terminal Logs
            Expanded(
              child: Column(
                children: [
                  // Queue Table
                  Expanded(
                    flex: 6,
                    child: _buildQueueTable(activeQueue),
                  ),
                  
                  // Divider
                  Container(
                    height: 1,
                    color: _c.borderDefault,
                  ),

                  // Terminal logs
                  Expanded(
                    flex: 4,
                    child: _buildTerminal(),
                  ),

                  // Bottom status bar
                  _buildStatusBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(bool isCompiling) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: _c.bgSecondary,
        border: Border(right: BorderSide(color: _c.borderDefault)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Title
          Row(
            children: [
              Icon(Icons.terminal, color: _c.linkAccent, size: 28),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _c.textPrimary,
                    ),
                  ),
                  Text(
                    'v$appVersion',
                    style: TextStyle(
                      fontSize: 11,
                      color: _c.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Environment Health Indicator Card
          _buildEnvCard(),
          const SizedBox(height: 18),

          // Selection Actions
          StyledWidgets.sectionHeader(_s.sectionActions, _c, icon: Icons.bolt),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isCompiling ? null : _pickFiles,
                  icon: const Icon(Icons.note_add_outlined, size: 16),
                  label: Text(_s.btnSelectFiles, style: const TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isCompiling ? null : _pickDirectory,
                  icon: const Icon(Icons.folder_open_outlined, size: 16),
                  label: Text(_s.btnSelectDir, style: const TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Settings Section
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StyledWidgets.sectionHeader(_s.sectionSettings, _c, icon: Icons.settings),
                  
                  // Keep / Delete Source Files Checkbox
                  CheckboxListTile(
                    value: _deleteSource,
                    onChanged: isCompiling ? null : (val) async {
                      if (val != null) {
                        setState(() => _deleteSource = val);
                        await AppConfig.set(keyDeleteSource, val.toString());
                      }
                    },
                    title: Text(_s.optDeleteSource, style: TextStyle(fontSize: 12, color: _c.textPrimary, fontWeight: FontWeight.w500)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Keep / Delete Intermediate C Files Checkbox
                  CheckboxListTile(
                    value: _cleanCFiles,
                    onChanged: isCompiling ? null : (val) async {
                      if (val != null) {
                        setState(() => _cleanCFiles = val);
                        await AppConfig.set(keyCleanCFiles, val.toString());
                      }
                    },
                    title: Text(_s.optDeleteC, style: TextStyle(fontSize: 12, color: _c.textPrimary, fontWeight: FontWeight.w500)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),

                  // Python Language Level Segmented Control
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _s.labelLangLevel,
                        style: TextStyle(fontSize: 12, color: _c.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: _c.bgTertiary,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _c.borderDefault),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildLangLevelSegment('3', 'Python 3', isCompiling),
                            ),
                            Expanded(
                              child: _buildLangLevelSegment('2', 'Python 2', isCompiling),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Collapsible Cython Directives
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Icon(Icons.tune, size: 16, color: _c.targetAccent),
                          const SizedBox(width: 8),
                          Text(
                            _s.sectionDirectives,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      iconColor: _c.linkAccent,
                      collapsedIconColor: _c.textMuted,
                      children: [
                        _buildDirectiveCheckbox(
                          title: 'boundscheck',
                          subtitle: _s.optBoundsCheck,
                          value: _boundsCheck,
                          tooltip: _s.tipBoundsCheck,
                          onChanged: isCompiling ? null : (v) async {
                            setState(() => _boundsCheck = v ?? false);
                            await AppConfig.set(keyDirectiveBoundsCheck, (_boundsCheck).toString());
                          },
                        ),
                        _buildDirectiveCheckbox(
                          title: 'wraparound',
                          subtitle: _s.optWrapAround,
                          value: _wrapAround,
                          tooltip: _s.tipWrapAround,
                          onChanged: isCompiling ? null : (v) async {
                            setState(() => _wrapAround = v ?? false);
                            await AppConfig.set(keyDirectiveWrapAround, (_wrapAround).toString());
                          },
                        ),
                        _buildDirectiveCheckbox(
                          title: 'initializedcheck',
                          subtitle: _s.optInitializedCheck,
                          value: _initializedCheck,
                          tooltip: _s.tipInitializedCheck,
                          onChanged: isCompiling ? null : (v) async {
                            setState(() => _initializedCheck = v ?? false);
                            await AppConfig.set(keyDirectiveInitializedCheck, (_initializedCheck).toString());
                          },
                        ),
                        _buildDirectiveCheckbox(
                          title: 'nonecheck',
                          subtitle: _s.optNoneCheck,
                          value: _noneCheck,
                          tooltip: _s.tipNoneCheck,
                          onChanged: isCompiling ? null : (v) async {
                            setState(() => _noneCheck = v ?? false);
                            await AppConfig.set(keyDirectiveNoneCheck, (_noneCheck).toString());
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          // Compile Button & Clear Queue
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isCompiling || widget.logic.queue.isEmpty ? null : _startCompilation,
                  icon: isCompiling 
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.play_arrow, size: 16),
                  label: Text(isCompiling ? _s.btnCompiling : _s.btnCompileAll),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _c.linkAccent,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isCompiling || widget.logic.queue.isEmpty ? null : _clearQueue,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: Text(_s.btnClearQueue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnvCard() {
    final py = widget.logic.env.pythonAvailable;
    final cy = widget.logic.env.cythonAvailable;
    final cc = widget.logic.env.compilerAvailable;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _c.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _c.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Environment Health',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _c.textPrimary),
              ),
              IconButton(
                onPressed: _isCheckingEnv ? null : _checkEnv,
                icon: Icon(Icons.sync, size: 14, color: _c.linkAccent),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: _s.tooltipRefresh,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildEnvRow(_s.envPythonFound.split(':')[0], py, py ? widget.logic.env.pythonVersion : _s.envPythonMissing),
          const SizedBox(height: 6),
          _buildEnvRow(_s.envCythonFound.split(':')[0], cy, cy ? 'v${widget.logic.env.cythonVersion}' : _s.envCythonMissing),
          const SizedBox(height: 6),
          _buildEnvRow(_s.envCompilerFound.split(':')[0], cc, cc ? widget.logic.env.compilerInfo : _s.envCompilerMissing),
          
          if (!cy && py) ...[
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: widget.logic.isCompiling ? null : _installCython,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                backgroundColor: _c.targetAccent,
              ),
              child: Center(
                child: Text(
                  _s.btnInstallCython,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ),
          ],
          if (!cc || !cy || !py) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => const HelpEnvironmentDialog(),
                );
              },
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 12, color: _c.linkAccent),
                  const SizedBox(width: 4),
                  Text(
                    'Setup Help Guide',
                    style: TextStyle(fontSize: 11, color: _c.linkAccent, decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnvRow(String name, bool success, String version) {
    return Row(
      children: [
        Icon(
          success ? Icons.check_circle_outline : Icons.error_outline,
          color: success ? _c.statusActive : _c.statusRemoved,
          size: 14,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(fontSize: 11, color: _c.textSecondary, fontWeight: FontWeight.bold),
              ),
              Text(
                version,
                style: TextStyle(fontSize: 10, color: _c.textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLangLevelSegment(String level, String label, bool isCompiling) {
    final isSelected = _languageLevel == level;
    final activeBg = _c.linkAccent;
    final textCol = isSelected
        ? (_c.brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white)
        : _c.textSecondary;

    return GestureDetector(
      onTap: isCompiling ? null : () async {
        setState(() => _languageLevel = level);
        await AppConfig.set(keyLanguageLevel, level);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: textCol,
          ),
        ),
      ),
    );
  }

  Widget _buildDirectiveCheckbox({
    required String title,
    required String subtitle,
    required bool value,
    required String tooltip,
    required void Function(bool?)? onChanged,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _c.textPrimary)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 10, color: _c.textSecondary)),
      dense: true,
      contentPadding: EdgeInsets.zero,
      secondary: Tooltip(
        message: tooltip,
        child: Icon(Icons.help_outline, size: 14, color: _c.textMuted),
      ),
    );
  }

  Widget _buildQueueTable(List<ConversionEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue, size: 48, color: _c.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'Queue is empty',
              style: TextStyle(color: _c.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Add Python files or select a folder to get started',
              style: TextStyle(color: _c.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: _c.bgSecondary,
            border: Border(bottom: BorderSide(color: _c.borderDefault)),
          ),
          child: Row(
            children: [
              SizedBox(width: 30, child: Text(_s.colNum, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _c.textSecondary))),
              Expanded(flex: 3, child: Text(_s.colFileName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _c.textSecondary))),
              Expanded(flex: 4, child: Text(_s.colPath, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _c.textSecondary))),
              Expanded(flex: 1, child: Text(_s.colSize, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _c.textSecondary))),
              Expanded(flex: 2, child: Text(_s.colStatus, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _c.textSecondary))),
              Expanded(flex: 4, child: Text(_s.colResult, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _c.textSecondary))),
            ],
          ),
        ),

        // Scrollable Rows
        Expanded(
          child: ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: _c.borderDefault),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: entry.status == 'compiling' ? _c.bgHover : Colors.transparent,
                child: Row(
                  children: [
                    SizedBox(width: 30, child: Text('${index + 1}', style: TextStyle(fontSize: 12, color: _c.textSecondary))),
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.fileName,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _c.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Tooltip(
                        message: entry.filePath,
                        child: Text(
                          entry.directoryPath,
                          style: TextStyle(fontSize: 11, color: _c.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        entry.sizeStr,
                        style: TextStyle(fontSize: 11, color: _c.textSecondary),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          _buildStatusBadge(entry.status),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        entry.details,
                        style: TextStyle(fontSize: 11, color: entry.status == 'failed' ? _c.statusRemoved : _c.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    String label;
    switch (status) {
      case 'compiling':
        label = _s.statusCompiling;
        break;
      case 'success':
        label = _s.statusSuccess;
        break;
      case 'failed':
        label = _s.statusFailed;
        break;
      default:
        label = _s.statusPending;
    }
    return StyledWidgets.statusBadge(label, _c);
  }

  Widget _buildTerminal() {
    final terminalBg = _c.brightness == Brightness.dark ? const Color(0xFF070A13) : _c.bgTertiary;
    final innerBg = _c.brightness == Brightness.dark ? const Color(0xFF030509) : _c.bgCard;
    final defaultTxtColor = _c.brightness == Brightness.dark ? const Color(0xFFE2E8F0) : _c.textPrimary;

    return Container(
      color: terminalBg,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Terminal bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.wysiwyg, color: _c.borderHighlight, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    _s.labelLogs,
                    style: TextStyle(
                      color: _c.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (_terminalLogs.isNotEmpty)
                IconButton(
                  onPressed: () => setState(() => _terminalLogs.clear()),
                  icon: Icon(Icons.delete_outline, size: 14, color: _c.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Scrollable terminal content
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: innerBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _c.borderDefault),
              ),
              child: _terminalLogs.isEmpty
                  ? Center(
                      child: Text(
                        _s.terminalEmpty,
                        style: TextStyle(color: _c.textMuted.withValues(alpha: 0.5), fontSize: 11, fontFamily: 'Cascadia Code'),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : SelectionArea(
                      child: ListView.builder(
                        controller: _terminalScrollController,
                        itemCount: _terminalLogs.length,
                        itemBuilder: (context, index) {
                          final text = _terminalLogs[index];
                          // Simple error coloration
                          Color txtColor = defaultTxtColor;
                          if (text.toLowerCase().contains('error') || text.toLowerCase().contains('failed')) {
                            txtColor = _c.statusRemoved;
                          } else if (text.toLowerCase().contains('success') || text.toLowerCase().contains('compiled')) {
                            txtColor = _c.statusActive;
                          }
                          
                          return Text(
                            text,
                            style: TextStyle(
                              color: txtColor,
                              fontSize: 11,
                              fontFamily: 'Cascadia Code',
                              height: 1.3,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final statusColor = widget.logic.env.pythonAvailable && widget.logic.env.cythonAvailable && widget.logic.env.compilerAvailable
        ? _c.statusActive
        : _c.statusRemoved;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: _c.bgSecondary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Ready check
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.logic.env.pythonAvailable && widget.logic.env.cythonAvailable && widget.logic.env.compilerAvailable
                    ? 'Ready'
                    : 'Setup issue detected',
                style: TextStyle(fontSize: 10, color: _c.textSecondary),
              ),
            ],
          ),
          
          // Right: Actions
          Row(
            children: [
              // Language Switch
              InkWell(
                onTap: () {
                  widget.languageNotifier.toggle();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.language, size: 14, color: _c.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        widget.languageNotifier.language.shortLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Theme Toggle
              InkWell(
                key: _themeButtonKey,
                onTap: () {
                  final revealState = context.findAncestorStateOfType<ThemeRevealState>();
                  if (revealState != null) {
                    revealState.triggerReveal(
                      buttonKey: _themeButtonKey,
                      onToggle: () {
                        final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
                        widget.themeNotifier.toggle(platformBrightness);
                      },
                    );
                  } else {
                    final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
                    widget.themeNotifier.toggle(platformBrightness);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Row(
                    children: [
                      Icon(widget.themeNotifier.modeIcon, size: 14, color: _c.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        widget.themeNotifier.modeLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _clearQueue() {
    setState(() {
      widget.logic.clearQueue();
    });
  }

  Future<void> _startCompilation() async {
    if (!widget.logic.env.pythonAvailable || !widget.logic.env.cythonAvailable || !widget.logic.env.compilerAvailable) {
      showDialog(
        context: context,
        builder: (_) => const HelpEnvironmentDialog(),
      );
      return;
    }
    
    await widget.logic.compileAll();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _installCython() async {
    final success = await widget.logic.installCython();
    if (mounted) {
      if (success) {
        _showSnackbar(_s.msgCythonInstalled);
      } else {
        _showSnackbar(_s.msgCythonInstallFail, isError: true);
      }
    }
  }
}
