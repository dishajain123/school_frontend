import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/chat/message_model.dart';

class MessageInputBar extends StatefulWidget {
  const MessageInputBar({
    super.key,
    required this.onSendText,
    required this.onSendFile,
    this.isSending = false,
    this.isConnected = true,
    this.onRetryConnect,
  });

  final Future<bool> Function(String text) onSendText;
  final Future<bool> Function({
    required String filePath,
    required String fileName,
    required MessageType messageType,
  }) onSendFile;
  final bool isSending;
  final bool isConnected;
  final VoidCallback? onRetryConnect;

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!_hasText || widget.isSending) return;
    final text = _controller.text.trim();
    _controller.clear();
    setState(() => _hasText = false);
    await widget.onSendText(text);
  }

  Future<void> _handleAttach() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx'],
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    final path = picked.path;
    if (path == null) return;

    final ext = picked.extension?.toLowerCase() ?? '';
    final messageType = ['jpg', 'jpeg', 'png', 'gif'].contains(ext)
        ? MessageType.image
        : MessageType.file;

    await widget.onSendFile(
      filePath: path,
      fileName: picked.name,
      messageType: messageType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.surface100, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.isConnected)
              _DisconnectedBanner(onRetry: widget.onRetryConnect),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _AttachButton(
                  onTap: widget.isSending ? null : _handleAttach,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: AppColors.surface50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isFocused
                              ? AppColors.navyMedium.withValues(alpha: 0.5)
                              : AppColors.surface200,
                          width: _isFocused ? 1.5 : 1,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.grey800,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.isConnected
                              ? 'Type a message…'
                              : 'Reconnecting…',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.grey400,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        enabled: widget.isConnected && !widget.isSending,
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _SendButton(
                  hasText: _hasText,
                  isSending: widget.isSending,
                  isConnected: widget.isConnected,
                  onTap: _handleSend,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  const _AttachButton({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.attach_file_rounded,
          size: 20,
          color: onTap != null ? AppColors.grey600 : AppColors.grey400,
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.hasText,
    required this.isSending,
    required this.isConnected,
    required this.onTap,
  });

  final bool hasText;
  final bool isSending;
  final bool isConnected;
  final VoidCallback onTap;

  bool get _active => hasText && !isSending && isConnected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: _active
            ? const LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF0F2340)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: _active ? null : AppColors.surface100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _active
            ? [
                BoxShadow(
                  color: AppColors.navyDeep.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _active ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: isSending
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 2,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: _active ? AppColors.white : AppColors.grey400,
                  ),
          ),
        ),
      ),
    );
  }
}

class _DisconnectedBanner extends StatelessWidget {
  const _DisconnectedBanner({this.onRetry});
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.warningAmber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 13, color: AppColors.warningDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Connection lost',
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.warningDark, fontSize: 11),
            ),
          ),
          if (onRetry != null)
            GestureDetector(
              onTap: onRetry,
              child: Text(
                'Retry',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.navyMedium,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
