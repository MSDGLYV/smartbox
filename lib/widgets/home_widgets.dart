part of '../app.dart';

class DeviceRegistrationPanel extends StatefulWidget {
  const DeviceRegistrationPanel({super.key, this.scale = 1});

  final double scale;

  @override
  State<DeviceRegistrationPanel> createState() =>
      _DeviceRegistrationPanelState();
}

class _DeviceRegistrationPanelState extends State<DeviceRegistrationPanel> {
  final TextEditingController _deviceIdController = TextEditingController();
  final TextEditingController _aliasController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _deviceIdController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final handler = SmartBoxScope.deviceRegistrationHandlerOf(context);
    final error = await Future.value(
      handler?.call(
        deviceId: _deviceIdController.text,
        alias: _aliasController.text,
      ),
    );

    if (!mounted) {
      return;
    }

    if (error == null) {
      _deviceIdController.clear();
      _aliasController.clear();
      showSnack(context, 'Device registered');
    }

    setState(() {
      _errorText = error;
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardScale = _clampDouble(widget.scale, 0.72, 1);
    return SmartCard(
      padding: EdgeInsets.all(16 * cardScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Register Device',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 18 * cardScale,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12 * cardScale),
          AppTextField(
            controller: _deviceIdController,
            hintText: 'Device authentication ID',
            icon: Icons.memory_rounded,
            textInputAction: TextInputAction.next,
            fontSize: 14 * cardScale,
            iconSize: 20 * cardScale,
            verticalPadding: 14 * cardScale,
          ),
          SizedBox(height: 10 * cardScale),
          AppTextField(
            controller: _aliasController,
            hintText: 'Alias',
            icon: Icons.label_outline_rounded,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            fontSize: 14 * cardScale,
            iconSize: 20 * cardScale,
            verticalPadding: 14 * cardScale,
          ),
          if (_errorText != null) ...[
            SizedBox(height: 8 * cardScale),
            Text(
              _errorText!,
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 12 * cardScale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          SizedBox(height: 12 * cardScale),
          PrimaryButton(
            label: _isSubmitting ? 'Registering...' : 'Register Device',
            icon: Icons.add_link_rounded,
            onPressed: _submit,
            height: 48 * cardScale,
            fontSize: 15 * cardScale,
            iconSize: 19 * cardScale,
          ),
        ],
      ),
    );
  }
}

class RegisteredDevicesPanel extends StatelessWidget {
  const RegisteredDevicesPanel({super.key, this.scale = 1});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final model = SmartBoxScope.of(context);
    final cardScale = _clampDouble(scale, 0.72, 1);

    if (model.isDeviceListLoading) {
      return SmartCard(
        padding: EdgeInsets.all(14 * cardScale),
        child: StatusLine(
          icon: Icons.hourglass_top_rounded,
          iconColor: AppColors.blue,
          label: 'Loading registered devices...',
        ),
      );
    }

    if (!model.hasRegisteredDevices) {
      return SmartCard(
        padding: EdgeInsets.all(14 * cardScale),
        child: StatusLine(
          icon: Icons.inventory_2_outlined,
          iconColor: AppColors.muted,
          label: 'No registered devices yet.',
        ),
      );
    }

    return SmartCard(
      padding: EdgeInsets.all(14 * cardScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Devices',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 17 * cardScale,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10 * cardScale),
          Wrap(
            spacing: 8 * cardScale,
            runSpacing: 8 * cardScale,
            children: [
              for (final device in model.registeredDevices)
                ChoiceChip(
                  label: Text(device.alias, overflow: TextOverflow.ellipsis),
                  selected: device.id == model.selectedDeviceId,
                  onSelected: (_) {
                    SmartBoxScope.deviceSelectionHandlerOf(
                      context,
                    )?.call(device.id);
                  },
                  labelStyle: TextStyle(
                    color: device.id == model.selectedDeviceId
                        ? Colors.white
                        : AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 13 * cardScale,
                  ),
                  selectedColor: AppColors.navy,
                  backgroundColor: const Color(0xFFF5FAFF),
                  side: const BorderSide(color: AppColors.border),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class DeviceHeroCard extends StatelessWidget {
  const DeviceHeroCard({super.key, this.scale = 1});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final model = SmartBoxScope.of(context);
    final cardScale = _clampDouble(scale, 0.72, 1);
    final paddingX = 18 * cardScale;
    final paddingY = 18 * cardScale;
    final illustrationSize = _clampDouble(178 * cardScale, 140, 198);
    final statusSize = 64 * cardScale;

    return Container(
      padding: EdgeInsets.fromLTRB(paddingX, paddingY, paddingX, paddingY),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAFF),
        borderRadius: BorderRadius.circular(18 * cardScale),
        border: Border.all(color: const Color(0xFFD8E6F5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 18 * cardScale,
            offset: Offset(0, 9 * cardScale),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 330;
          return Row(
            children: [
              Expanded(
                flex: compact ? 7 : 6,
                child: Center(
                  child: SizedBox(
                    width: illustrationSize,
                    height: illustrationSize,
                    child: Image.asset(
                      model.isLocked
                          ? 'assets/images/case-locked.png'
                          : 'assets/images/case-unlocked.png',
                      fit: BoxFit.contain,
                      semanticLabel: model.isLocked
                          ? 'Locked drop-off case'
                          : 'Unlocked drop-off case',
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12 * cardScale),
              Expanded(
                flex: compact ? 5 : 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: statusSize,
                      height: statusSize,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      clipBehavior: Clip.antiAlias,
                      child: model.isLocked
                          ? Transform.scale(
                              scale: 1.1,
                              child: Image.asset(
                                'assets/images/locked-icon.png',
                                fit: BoxFit.cover,
                                semanticLabel: 'Box locked',
                              ),
                            )
                          : Image.asset(
                              'assets/images/unlocked-icon.png',
                              fit: BoxFit.cover,
                              semanticLabel: 'Box unlocked',
                            ),
                    ),
                    SizedBox(height: 14 * cardScale),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        model.isLocked ? 'LOCKED' : 'OPEN',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 27 * cardScale,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(height: 4 * cardScale),
                    Text(
                      model.isLocked ? 'Box is secured' : 'Ready for delivery',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 16 * cardScale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DeviceStatusSummary extends StatelessWidget {
  const DeviceStatusSummary({super.key, this.scale = 1});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final model = SmartBoxScope.of(context);
    final cardScale = _clampDouble(scale, 0.72, 1);
    final label = model.isDeviceLoading
        ? 'Loading device data...'
        : (model.deviceError ??
              '${model.selectedDevice?.alias ?? 'Selected device'} - ${model.deviceStatus}');
    final icon = model.deviceError == null
        ? Icons.sensors_rounded
        : Icons.error_outline_rounded;
    final color = model.deviceError == null
        ? AppColors.green
        : AppColors.danger;

    return SmartCard(
      padding: EdgeInsets.symmetric(
        horizontal: 14 * cardScale,
        vertical: 12 * cardScale,
      ),
      child: StatusLine(icon: icon, iconColor: color, label: label),
    );
  }
}

class DeviceDetailsPanel extends StatelessWidget {
  const DeviceDetailsPanel({super.key, this.scale = 1});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final model = SmartBoxScope.of(context);
    final cardScale = _clampDouble(scale, 0.72, 1);

    if (!model.hasRegisteredDevices) {
      return const SizedBox.shrink();
    }

    if (model.isDeviceLoading) {
      return SmartCard(
        padding: EdgeInsets.all(14 * cardScale),
        child: StatusLine(
          icon: Icons.sync_rounded,
          iconColor: AppColors.blue,
          label: 'Loading selected device...',
        ),
      );
    }

    if (model.deviceError != null) {
      return SmartCard(
        padding: EdgeInsets.all(14 * cardScale),
        child: StatusLine(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.danger,
          label: model.deviceError!,
        ),
      );
    }

    return SmartCard(
      padding: EdgeInsets.all(14 * cardScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  model.selectedDevice?.alias ?? 'Selected Device',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 18 * cardScale,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Switch(
                value: model.securityMode,
                activeThumbColor: AppColors.green,
                onChanged: (enabled) async {
                  final handler = SmartBoxScope.securityModeHandlerOf(context);
                  final error = await Future.value(
                    handler?.call(enabled: enabled),
                  );
                  if (context.mounted && error != null) {
                    showSnack(context, error);
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 8 * cardScale),
          _DeviceDetailRow(
            icon: model.isOnline
                ? Icons.cloud_done_rounded
                : Icons.cloud_off_rounded,
            label: 'Connection',
            value: model.isOnline ? 'Online' : 'Offline',
            color: model.isOnline ? AppColors.green : AppColors.danger,
            scale: cardScale,
          ),
          _DeviceDetailRow(
            icon: Icons.schedule_rounded,
            label: 'Last seen',
            value: model.lastSeen.isEmpty ? 'Unknown' : model.lastSeen,
            scale: cardScale,
          ),
          _DeviceDetailRow(
            icon: model.lidLocked
                ? Icons.lock_rounded
                : Icons.lock_open_rounded,
            label: 'Lid',
            value:
                '${model.lidState} / ${model.lidLocked ? 'locked' : 'unlocked'}',
            color: model.lidLocked ? AppColors.green : AppColors.warning,
            scale: cardScale,
          ),
          _DeviceDetailRow(
            icon: Icons.shield_rounded,
            label: 'Security',
            value: model.securityMode ? 'Enabled' : 'Disabled',
            color: model.securityMode ? AppColors.green : AppColors.muted,
            scale: cardScale,
          ),
          _DeviceDetailRow(
            icon: model.alarmTriggered
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline_rounded,
            label: 'Alarm',
            value: model.alarmTriggered ? 'Triggered' : 'Clear',
            color: model.alarmTriggered ? AppColors.danger : AppColors.green,
            scale: cardScale,
          ),
          _DeviceDetailRow(
            icon: Icons.event_note_rounded,
            label: 'Events',
            value: '${model.deviceEvents.length}',
            scale: cardScale,
          ),
        ],
      ),
    );
  }
}

class DeviceEventsPanel extends StatelessWidget {
  const DeviceEventsPanel({super.key, this.scale = 1});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final model = SmartBoxScope.of(context);
    final cardScale = _clampDouble(scale, 0.72, 1);

    if (!model.hasRegisteredDevices ||
        model.isDeviceLoading ||
        model.deviceError != null) {
      return const SizedBox.shrink();
    }

    final latestEvents = model.deviceEvents.take(3).toList(growable: false);

    return SmartCard(
      padding: EdgeInsets.all(14 * cardScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${model.selectedDeviceId ?? 'device_id'}/event',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 18 * cardScale,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    openScreen(context, const SecurityAlertsScreen()),
                icon: Icon(Icons.open_in_new_rounded, size: 17 * cardScale),
                label: Text('View', style: TextStyle(fontSize: 13 * cardScale)),
              ),
            ],
          ),
          SizedBox(height: 8 * cardScale),
          if (latestEvents.isEmpty)
            StatusLine(
              icon: Icons.event_available_rounded,
              iconColor: AppColors.green,
              label: 'No device events yet.',
            )
          else
            ...latestEvents.map(
              (event) => Padding(
                padding: EdgeInsets.symmetric(vertical: 5 * cardScale),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _eventIcon(event.severity),
                      color: _eventColor(event.severity),
                      size: 20 * cardScale,
                    ),
                    SizedBox(width: 10 * cardScale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 13.5 * cardScale,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2 * cardScale),
                          Text(
                            event.time,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12.5 * cardScale,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _eventIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.warning_amber_rounded;
      case AlertSeverity.warning:
        return Icons.error_outline_rounded;
      case AlertSeverity.success:
        return Icons.check_circle_outline_rounded;
      case AlertSeverity.battery:
        return Icons.battery_alert_rounded;
    }
  }

  Color _eventColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return AppColors.danger;
      case AlertSeverity.warning:
        return AppColors.warning;
      case AlertSeverity.success:
        return AppColors.green;
      case AlertSeverity.battery:
        return AppColors.warning;
    }
  }
}

class DeviceImagePanel extends StatelessWidget {
  const DeviceImagePanel({super.key, this.scale = 1});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final model = SmartBoxScope.of(context);
    final cardScale = _clampDouble(scale, 0.72, 1);
    final imageSource = model.lastImageUrl.trim();
    final hasImage = imageSource.isNotEmpty;
    final status = model.imageStatus.toLowerCase();
    final busy =
        status == 'requested' || status == 'capturing' || status == 'uploading';

    if (!model.hasRegisteredDevices ||
        model.isDeviceLoading ||
        model.deviceError != null) {
      return const SizedBox.shrink();
    }

    return SmartCard(
      padding: EdgeInsets.all(14 * cardScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Image Request',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 18 * cardScale,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        final handler = SmartBoxScope.imageRequestHandlerOf(
                          context,
                        );
                        final error = await Future.value(handler?.call());
                        if (!context.mounted) {
                          return;
                        }
                        showSnack(context, error ?? 'Image request sent');
                      },
                icon: busy
                    ? SizedBox.square(
                        dimension: 15 * cardScale,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.photo_camera_rounded, size: 17 * cardScale),
                label: Text(
                  busy ? 'Working' : 'Capture',
                  style: TextStyle(fontSize: 13 * cardScale),
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * cardScale),
          _DeviceDetailRow(
            icon: _imageStatusIcon(status),
            label: 'Status',
            value: model.imageStatus.isEmpty ? 'idle' : model.imageStatus,
            color: _imageStatusColor(status),
            scale: cardScale,
          ),
          _DeviceDetailRow(
            icon: Icons.schedule_rounded,
            label: 'Captured',
            value: model.lastImageTime.isEmpty
                ? 'Not captured yet'
                : model.lastImageTime,
            scale: cardScale,
          ),
          if (hasImage)
            _DeviceDetailRow(
              icon: Icons.link_rounded,
              label: 'Image',
              value: model.lastImageUrl,
              color: AppColors.blue,
              scale: cardScale,
            ),
          if (hasImage && model.selectedDeviceId != null)
            _DeviceDetailRow(
              icon: Icons.folder_rounded,
              label: 'Storage path',
              value: '${model.selectedDeviceId}/$imageSource',
              color: AppColors.blue,
              scale: cardScale,
            ),
          SizedBox(height: 8 * cardScale),
          ClipRRect(
            borderRadius: BorderRadius.circular(8 * cardScale),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFFEFF4FA)),
                child: hasImage
                    ? _StorageImage(
                        source: imageSource,
                        deviceId: model.selectedDeviceId ?? '',
                        cardScale: cardScale,
                      )
                    : Center(
                        child: StatusLine(
                          icon: Icons.image_outlined,
                          iconColor: AppColors.muted,
                          label: 'Captured image will appear here.',
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _imageStatusIcon(String status) {
    switch (status) {
      case 'done':
        return Icons.check_circle_outline_rounded;
      case 'error':
        return Icons.error_outline_rounded;
      case 'requested':
      case 'capturing':
      case 'uploading':
        return Icons.sync_rounded;
      default:
        return Icons.image_outlined;
    }
  }

  Color _imageStatusColor(String status) {
    switch (status) {
      case 'done':
        return AppColors.green;
      case 'error':
        return AppColors.danger;
      case 'requested':
      case 'capturing':
      case 'uploading':
        return AppColors.blue;
      default:
        return AppColors.muted;
    }
  }
}

class _StorageImage extends StatefulWidget {
  const _StorageImage({
    required this.source,
    required this.deviceId,
    required this.cardScale,
  });

  final String source;
  final String deviceId;
  final double cardScale;

  @override
  State<_StorageImage> createState() => _StorageImageState();
}

class _StorageImageState extends State<_StorageImage> {
  late Future<_LoadedImage> _loadedImageFuture;

  @override
  void initState() {
    super.initState();
    _loadedImageFuture = _loadImage(widget.source, widget.deviceId);
  }

  @override
  void didUpdateWidget(covariant _StorageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.deviceId != widget.deviceId) {
      _loadedImageFuture = _loadImage(widget.source, widget.deviceId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LoadedImage>(
      future: _loadedImageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5 * widget.cardScale,
            ),
          );
        }

        final image = snapshot.data;
        if (snapshot.hasError || image == null) {
          return _ImageErrorBox(
            message: 'Image could not be opened.',
            detail: snapshot.error?.toString() ?? 'Empty image URL.',
            copyValue: _storagePathForSource(widget.source, widget.deviceId),
            cardScale: widget.cardScale,
          );
        }

        if (image.bytes != null) {
          return Image.memory(
            image.bytes!,
            key: ValueKey(image.copyValue),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              return _ImageErrorBox(
                message: 'Image bytes could not be decoded.',
                detail: error.toString(),
                copyValue: image.copyValue,
                cardScale: widget.cardScale,
              );
            },
          );
        }

        return Image.network(
          image.url!,
          key: ValueKey(image.url),
          fit: BoxFit.cover,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: (context, error, stackTrace) {
            return _ImageErrorBox(
              message: 'Image could not be loaded.',
              detail: error.toString(),
              copyValue: image.copyValue,
              cardScale: widget.cardScale,
            );
          },
        );
      },
    );
  }

  Future<_LoadedImage> _loadImage(String rawSource, String deviceId) async {
    final source = rawSource.trim();
    if (source.isEmpty) {
      throw StateError('Image source is empty.');
    }

    final uri = Uri.tryParse(source);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      final storagePath = _storagePathFromDownloadUrl(uri);
      if (storagePath != null) {
        return _loadStoragePath(storagePath);
      }
      return _LoadedImage.network(source);
    }

    if (uri != null && uri.scheme == 'gs') {
      return _loadStorageRef(FirebaseStorage.instance.refFromURL(source));
    }

    return _loadStoragePath(_storagePathForSource(source, deviceId));
  }

  Future<_LoadedImage> _loadStoragePath(String path) {
    return _loadStorageRef(FirebaseStorage.instance.ref(path));
  }

  Future<_LoadedImage> _loadStorageRef(Reference ref) async {
    final bytes = await _fetchStorageBytes(ref.fullPath);
    return _LoadedImage.bytes(bytes, ref.fullPath);
  }

  Future<Uint8List> _fetchStorageBytes(String path) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final response = await http
        .get(
          Uri.parse(_firebaseMediaUrl(path)),
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException(
            'Firebase Storage HTTP request timed out for $path',
          ),
        );

    if (response.statusCode != 200) {
      throw StateError(
        'Firebase Storage returned HTTP ${response.statusCode} for $path: '
        '${_bodyPreview(response.bodyBytes)}',
      );
    }

    final bytes = response.bodyBytes;
    if (bytes.length < 4) {
      throw StateError(
        'Firebase Storage returned only ${bytes.length} bytes for $path.',
      );
    }

    if (bytes[0] != 0xFF || bytes[1] != 0xD8) {
      throw StateError(
        'Downloaded ${bytes.length} bytes for $path, but it is not a JPEG. '
        'First bytes: ${_hexPreview(bytes)}. Body: ${_bodyPreview(bytes)}',
      );
    }

    return bytes;
  }

  static String _storagePathForSource(String source, String deviceId) {
    var path = source.trim();
    while (path.startsWith('/')) {
      path = path.substring(1);
    }

    final cleanDeviceId = deviceId.trim();
    final isPlainFileName = cleanDeviceId.isNotEmpty && !path.contains('/');
    if (isPlainFileName) {
      return '$cleanDeviceId/$path';
    }

    return path;
  }

  String? _storagePathFromDownloadUrl(Uri uri) {
    if (uri.host != 'firebasestorage.googleapis.com') {
      return null;
    }

    final segments = uri.pathSegments;
    final objectMarkerIndex = segments.indexOf('o');
    if (objectMarkerIndex == -1 || objectMarkerIndex + 1 >= segments.length) {
      return null;
    }

    return Uri.decodeComponent(
      segments.sublist(objectMarkerIndex + 1).join('/'),
    );
  }

  String _firebaseMediaUrl(String path) {
    final normalizedPath = path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .join('/');
    return 'https://firebasestorage.googleapis.com/v0/b/'
        '${FirebaseStorage.instance.bucket}/o/'
        '${Uri.encodeComponent(normalizedPath)}?alt=media';
  }

  String _hexPreview(Uint8List bytes) {
    return bytes
        .take(12)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(' ');
  }

  String _bodyPreview(Uint8List bytes) {
    return utf8.decode(bytes.take(160).toList(), allowMalformed: true).trim();
  }
}

class _LoadedImage {
  const _LoadedImage._({this.bytes, this.url, required this.copyValue});

  factory _LoadedImage.bytes(Uint8List bytes, String path) {
    return _LoadedImage._(bytes: bytes, copyValue: path);
  }

  factory _LoadedImage.network(String url) {
    return _LoadedImage._(url: url, copyValue: url);
  }

  final Uint8List? bytes;
  final String? url;
  final String copyValue;
}

class _ImageErrorBox extends StatelessWidget {
  const _ImageErrorBox({
    required this.message,
    required this.detail,
    required this.copyValue,
    required this.cardScale,
  });

  final String message;
  final String detail;
  final String copyValue;
  final double cardScale;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(12 * cardScale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusLine(
              icon: Icons.broken_image_outlined,
              iconColor: AppColors.danger,
              label: message,
            ),
            SizedBox(height: 8 * cardScale),
            Text(
              detail,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11.5 * cardScale,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8 * cardScale),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: copyValue));
                if (context.mounted) {
                  showSnack(context, 'Image URL copied');
                }
              },
              icon: Icon(Icons.copy_rounded, size: 16 * cardScale),
              label: Text(
                'Copy URL',
                style: TextStyle(fontSize: 12.5 * cardScale),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceDetailRow extends StatelessWidget {
  const _DeviceDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.scale,
    this.color = AppColors.navy,
  });

  final IconData icon;
  final String label;
  final String value;
  final double scale;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6 * scale),
      child: Row(
        children: [
          Icon(icon, color: color, size: 21 * scale),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13 * scale,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PackageStatusCard extends StatelessWidget {
  const PackageStatusCard({super.key, this.scale = 1});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final model = SmartBoxScope.of(context);
    final cardScale = _clampDouble(scale, 0.72, 1);
    final packageLabel = model.hasPackage
        ? 'Package\nInside'
        : 'No Package\nInside';
    final packageAsset = model.hasPackage
        ? 'assets/images/package-icon.png'
        : 'assets/images/package-unlocked-icon.png';

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 108 * cardScale),
      child: SmartCard(
        padding: EdgeInsets.symmetric(
          horizontal: 10 * cardScale,
          vertical: 16 * cardScale,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 58 * cardScale,
              height: 64 * cardScale,
              child: ClipRect(
                child: Transform.scale(
                  scale: model.hasPackage ? 1.85 : 1.0,
                  child: Transform.translate(
                    offset: Offset(model.hasPackage ? 4 * cardScale : 0, 0),
                    child: PackageIcon(
                      size: 64 * cardScale,
                      asset: packageAsset,
                      semanticLabel: packageLabel.replaceAll('\n', ' '),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10 * cardScale),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      packageLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 18 * cardScale,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 6 * cardScale),
                    Text(
                      model.lastSeen.isEmpty
                          ? 'Just now'
                          : 'Last seen: ${model.lastSeen}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14 * cardScale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BatteryStatusCard extends StatelessWidget {
  const BatteryStatusCard({super.key, this.scale = 1});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final model = SmartBoxScope.of(context);
    final cardScale = _clampDouble(scale, 0.72, 1);
    final batteryPercent = model.batteryPercent;
    final batteryColor = batteryLevelColor(batteryPercent);
    final batteryLabel = batteryLevelLabel(batteryPercent);

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 108 * cardScale),
      child: SmartCard(
        padding: EdgeInsets.symmetric(
          horizontal: 10 * cardScale,
          vertical: 16 * cardScale,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 62 * cardScale,
              child: Center(
                child: BatteryIcon(
                  percentage: batteryPercent,
                  width: 72 * cardScale,
                  height: 38 * cardScale,
                  quarterTurns: 3,
                ),
              ),
            ),
            SizedBox(width: 8 * cardScale),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Battery',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 18 * cardScale,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      '$batteryPercent%',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 28 * cardScale,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                    Text(
                      batteryLabel,
                      style: TextStyle(
                        color: batteryColor,
                        fontSize: 15 * cardScale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    this.icon,
    this.iconAsset,
    required this.label,
    required this.onTap,
    this.scale = 1,
  }) : assert(icon != null || iconAsset != null);

  final IconData? icon;
  final String? iconAsset;
  final String label;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 180.0;
        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 120.0;
        final widthScale = _clampDouble(maxWidth / 170, 0.68, 1);
        final heightScale = _clampDouble(maxHeight / 112, 0.68, 1);
        final tileScale = math.min(
          _clampDouble(scale, 0.72, 1),
          math.min(widthScale, heightScale),
        );
        final horizontalPadding = _clampDouble(14 * tileScale, 8, 14);
        final verticalPadding = _clampDouble(10 * tileScale, 6, 10);
        final innerWidth = math.max(0.0, maxWidth - horizontalPadding * 2);
        final innerHeight = math.max(0.0, maxHeight - verticalPadding * 2);
        final gap = _clampDouble(3 * tileScale, 2, 3);
        final labelLines = innerHeight < 74 ? 1 : 2;
        final labelFontSize = _clampDouble(17 * tileScale, 11, 17);
        final labelReserve = labelFontSize * 1.12 * labelLines;
        final iconSize = _clampDouble(
          math.min(
            72 * tileScale,
            math.min(innerWidth * 0.66, innerHeight - gap - labelReserve),
          ),
          24,
          72 * tileScale,
        );

        return SmartCard(
          onTap: onTap,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            verticalPadding,
            horizontalPadding,
            verticalPadding,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                flex: 5,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _buildIcon(iconSize),
                  ),
                ),
              ),
              SizedBox(height: gap),
              Flexible(
                flex: 3,
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: labelLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIcon(double size) {
    if (iconAsset != null) {
      return Image.asset(
        iconAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        semanticLabel: label,
      );
    }

    return Icon(icon, size: size, color: AppColors.navy, semanticLabel: label);
  }
}
