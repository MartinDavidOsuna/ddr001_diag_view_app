import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../app_controller.dart';
import '../common/app_brand_logo.dart';
import '../common/app_version_label.dart';

final class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

final class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _displayName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  56,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppBrandLogo(
                          variant: AppBrandLogoVariant.symbol,
                          width: 68,
                          height: 68,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'DDR001',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'VERIFICADOR FUNCIONAL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.heading,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Acceso de técnico',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  key: const Key('login-display-name'),
                                  controller: _displayName,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: (value) =>
                                      (value ?? '').trim().isNotEmpty
                                      ? null
                                      : 'Ingresa tu nombre.',
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  key: const Key('login-email'),
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Correo',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  validator: (value) =>
                                      value != null &&
                                          RegExp(
                                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                          ).hasMatch(value.trim())
                                      ? null
                                      : 'Ingresa un correo válido.',
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  key: const Key('login-phone'),
                                  controller: _phone,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Teléfono',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                  validator: (value) =>
                                      (value ?? '')
                                              .replaceAll(RegExp(r'\D'), '')
                                              .length >=
                                          7
                                      ? null
                                      : 'Ingresa un teléfono válido.',
                                ),
                                if (state.errorMessage != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    state.errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 18),
                                FilledButton(
                                  key: const Key('login-submit'),
                                  onPressed: state.busy
                                      ? null
                                      : () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            ref
                                                .read(
                                                  appControllerProvider
                                                      .notifier,
                                                )
                                                .login(
                                                  _displayName.text,
                                                  _email.text,
                                                  _phone.text,
                                                );
                                          }
                                        },
                                  child: const Text('INGRESAR'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: AppVersionLabel(
                style: TextStyle(color: Color(0xFF31445D), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
