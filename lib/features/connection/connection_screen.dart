import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/sse_service.dart';
import '../../core/config/app_config.dart';
import '../../shared/theme/app_theme.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _urlController       = TextEditingController(text: 'http://192.168.1.100:7000');
  final _tokenController     = TextEditingController();
  final _ownerNameController = TextEditingController();
  bool    _loading = false;
  bool    _obscure = true;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final ownerName = _ownerNameController.text.trim();
    final url       = _urlController.text.trim();
    final token     = _tokenController.text.trim();

    if (ownerName.isEmpty || url.isEmpty || token.isEmpty) {
      setState(() => _error = 'All fields are required');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await AppConfig.save(
        daemonUrl: url,
        token:     token,
        ownerName: ownerName,
      );
      await ApiClient.instance.getState();
      await SseService.instance.start();
      if (mounted) context.go('/home');
    } on DioException catch (e) {
      await AppConfig.clear();
      setState(() {
        _error = switch (e.response?.statusCode) {
          401  => 'Invalid token — check your HA long-lived access token',
          null => 'Cannot reach daemon — is it running at that address?',
          _    => 'Unexpected error (${e.response?.statusCode})',
        };
      });
    } catch (e) {
      await AppConfig.clear();
      setState(() => _error = 'Cannot reach daemon — $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: AppColors.blue.withOpacity(0.12),
                          border: Border.all(color: AppColors.blue.withOpacity(0.3)),
                        ),
                        child: const Center(child: Text('⚡', style: TextStyle(fontSize: 28))),
                      ),
                      const SizedBox(height: 16),
                      const Text('Elyon',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          )),
                      const SizedBox(height: 4),
                      const Text('Connect to your daemon',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Owner name
                  _FieldLabel('Your name'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ownerNameController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Acacia Gardens',
                      prefixIcon: Icon(Icons.person_outline_rounded,
                          size: 18, color: AppColors.textMuted),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Daemon URL
                  _FieldLabel('Daemon address'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'http://192.168.1.100:7000',
                      prefixIcon: Icon(Icons.router_rounded,
                          size: 18, color: AppColors.textMuted),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Token
                  _FieldLabel('Access token'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tokenController,
                    obscureText: _obscure,
                    autocorrect: false,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'HA long-lived access token',
                      prefixIcon: const Icon(Icons.key_rounded,
                          size: 18, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 15, color: AppColors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(color: AppColors.red, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  FilledButton(
                    onPressed: _loading ? null : _connect,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppColors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Connect',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Token is stored securely on this device.\nNever sent anywhere except your daemon.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      );
}