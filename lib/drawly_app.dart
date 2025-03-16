import 'package:drawly_core/drawly_core.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrawlyApp extends StatefulWidget {
  const DrawlyApp({required this.home, super.key});

  final Widget home;

  @override
  State<DrawlyApp> createState() => _DrawlyAppState();
}

class _DrawlyAppState extends State<DrawlyApp> {
  final rxError = ValueNotifier<ErrorDTO?>(null);

  late final void Function(dynamic) _onErrorEvent;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  @override
  void dispose() {
    SocketManager.instance.offEvent('error', _onErrorEvent);
    super.dispose();
  }

  String? userAvatar;

  Future<void> getLocalStorageUserAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    userAvatar = prefs.getString('user_avatar_path');
  }

  Future<void> _initializeSocket() async {
    _onErrorEvent = (data) {
      rxError.value = ErrorDTO.fromJson(data as Map<String, dynamic>);
    };
    SocketManager.instance.onEvent('error', _onErrorEvent);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Drawly',
      theme: lightTheme,
      home: widget.home,
      builder: (_, child) {
        return ValueListenableBuilder<ErrorDTO?>(
          valueListenable: rxError,
          builder: (_, value, __) {
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                if (value?.message.isNotEmpty ?? false)
                  GestureDetector(
                    onTap: () {
                      rxError.value = null;
                    },
                    child: DrawlyBackFilter(
                      child: GestureDetector(
                        onTap: () {},
                        child: Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Error',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(color: Colors.red),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  value!.message,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        rxError.value = null;
                                      },
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
