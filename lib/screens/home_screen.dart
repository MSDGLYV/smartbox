part of '../app.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onSignOut, this.onSendLidCommand});

  final VoidCallback onSignOut;
  final LidCommandHandler? onSendLidCommand;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final model = SmartBoxScope.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawerScrimColor: const Color(0x99000000),
        drawer: SmartDrawer(onSignOut: widget.onSignOut),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = _clampDouble(
                constraints.maxWidth * 0.075,
                26,
                32,
              );
              final verticalPadding = _clampDouble(
                constraints.maxHeight * 0.014,
                8,
                16,
              );
              final contentWidth = _responsiveContentWidth(
                math.max(0.0, constraints.maxWidth - horizontalPadding * 2),
              );
              final widthScale = _clampDouble(
                constraints.maxWidth / 390,
                0.82,
                1.06,
              );
              final heightScale = _clampDouble(
                constraints.maxHeight / 820,
                0.72,
                1,
              );
              final scale = math.min(widthScale, heightScale);
              final gridGap = _clampDouble(14 * scale, 12, 16);
              final gridColumns = contentWidth >= 620 ? 3 : 2;
              final tileWidth = math.max(
                0.0,
                (contentWidth - gridGap * (gridColumns - 1)) / gridColumns,
              );
              final gridAspectRatio = _clampDouble(
                tileWidth / (gridColumns == 4 ? 118 : 108),
                1.18,
                1.55,
              );

              final content = SizedBox(
                width: contentWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                          icon: const Icon(Icons.menu_rounded),
                          color: AppColors.navy,
                          iconSize: 34 * scale,
                          tooltip: 'Menu',
                        ),
                        NotificationBell(
                          alertCount: model.alerts
                              .where(
                                (alert) =>
                                    alert.severity != AlertSeverity.success,
                              )
                              .length,
                          showBadge: false,
                          onTap: () =>
                              openScreen(context, const SecurityAlertsScreen()),
                        ),
                      ],
                    ),
                    SizedBox(height: 20 * scale),
                    Text(
                      'Hello, ${model.userName}',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontSize: 38 * scale, letterSpacing: 0),
                    ),
                    SizedBox(height: 6 * scale),
                    Text(
                      'Welcome back!',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 21 * scale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 22 * scale),
                    DeviceRegistrationPanel(scale: scale),
                    SizedBox(height: 14 * scale),
                    RegisteredDevicesPanel(scale: scale),
                    SizedBox(height: 14 * scale),
                    DeviceHeroCard(scale: scale),
                    if (model.isDeviceLoading ||
                        model.deviceError != null ||
                        model.lastSeen.isNotEmpty ||
                        model.hasRegisteredDevices) ...[
                      SizedBox(height: 12 * scale),
                      DeviceStatusSummary(scale: scale),
                    ],
                    SizedBox(height: 12 * scale),
                    DeviceDetailsPanel(scale: scale),
                    SizedBox(height: 12 * scale),
                    DeviceEventsPanel(scale: scale),
                    SizedBox(height: 12 * scale),
                    DeviceImagePanel(scale: scale),
                    SizedBox(height: 20 * scale),
                    SectionLabel('QUICK ACTIONS', scale: scale),
                    SizedBox(height: 12 * scale),
                    GridView(
                      padding: EdgeInsets.zero,
                      primary: false,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridColumns,
                        crossAxisSpacing: gridGap,
                        mainAxisSpacing: gridGap,
                        childAspectRatio: gridAspectRatio,
                      ),
                      children: [
                        QuickActionTile(
                          iconAsset: 'assets/images/unlock-icon.png',
                          label: 'Unlock',
                          scale: scale,
                          onTap: () => showQuickActionLockCommand(
                            context,
                            model,
                            unlock: true,
                            onSendLidCommand: widget.onSendLidCommand,
                          ),
                        ),
                        QuickActionTile(
                          iconAsset: 'assets/images/lock-icon.png',
                          label: 'Lock',
                          scale: scale,
                          onTap: () => showQuickActionLockCommand(
                            context,
                            model,
                            unlock: false,
                            onSendLidCommand: widget.onSendLidCommand,
                          ),
                        ),
                        QuickActionTile(
                          icon: model.securityMode
                              ? Icons.shield_rounded
                              : Icons.shield_outlined,
                          label: model.securityMode
                              ? 'Security On'
                              : 'Security Off',
                          scale: scale,
                          onTap: () async {
                            final handler = SmartBoxScope.securityModeHandlerOf(
                              context,
                            );
                            final error = await Future.value(
                              handler?.call(enabled: !model.securityMode),
                            );
                            if (!context.mounted) {
                              return;
                            }
                            showSnack(
                              context,
                              error ??
                                  (model.securityMode
                                      ? 'Security mode disabled'
                                      : 'Security mode enabled'),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: math.max(
                            0.0,
                            constraints.maxHeight - verticalPadding * 2,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: content,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
