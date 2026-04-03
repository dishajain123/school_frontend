import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
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

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
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
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'pdf',
        'doc',
        'docx',
      ],
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(
          top: BorderSide(color: AppColors.surface100, width: 1),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppDimensions.space8,
        right: AppDimensions.space8,
        top: AppDimensions.space8,
        bottom: AppDimensions.space8 + (bottomInset > 0 ? 0 : 0),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Disconnected banner
            if (!widget.isConnected)
              _DisconnectedBanner(onRetry: widget.onRetryConnect),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attach button
                _IconBtn(
                  icon: Icons.attach_file_rounded,
                  onTap: widget.isSending ? null : _handleAttach,
                  tooltip: 'Attach file',
                ),
                const SizedBox(width: AppDimensions.space4),
                // Text field
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: AppColors.surface50,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(
                        color: AppColors.surface200,
                        width: AppDimensions.borderMedium,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.grey800),
                      decoration: InputDecoration(
                        hintText: widget.isConnected
                            ? 'Type a message…'
                            : 'Reconnecting…',
                        hintStyle: AppTypography.bodyMedium
                            .copyWith(color: AppColors.grey400),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space12,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      enabled: widget.isConnected && !widget.isSending,
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.space4),
                // Send / loading button
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

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space8),
            child: Icon(
              icon,
              size: AppDimensions.iconMD,
              color: onTap != null ? AppColors.grey600 : AppColors.grey400,
            ),
          ),
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _active ? AppColors.navyDeep : AppColors.surface200,
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: _active ? onTap : null,
          customBorder: const CircleBorder(),
          child: Center(
            child: isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white),
                    ),
                  )
                : Icon(
                    Icons.send_rounded,
                    size: AppDimensions.iconSM,
                    color:
                        _active ? AppColors.white : AppColors.grey400,
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
      margin: const EdgeInsets.only(bottom: AppDimensions.space8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: AppDimensions.iconXS,
            color: AppColors.warningDark,
          ),
          const SizedBox(width: AppDimensions.space8),
          Expanded(
            child: Text(
              'Connection lost',
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.warningDark),
            ),
          ),
          if (onRetry != null)
            GestureDetector(
              onTap: onRetry,
              child: Text(
                'Retry',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.navyMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}