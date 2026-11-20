import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_constants.dart';
import '../../widgets/common/animated_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Auto-focus email field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emailFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, AppRoute.home);
      } else if (mounted && authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Center(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo/Title
                      Text(
                        AppStrings.appName,
                        style: theme.textTheme.displayLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        AppStrings.loginTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: 'admin@lubricentros.com',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.validationRequired;
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return AppStrings.validationInvalidEmail;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            tooltip: _obscurePassword ? 'Mostrar' : 'Ocultar',
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.validationRequired;
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleLogin(),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Login Button
                      AnimatedButton(
                        label: AppStrings.loginButton,
                        onPressed: _handleLogin,
                        isLoading: isLoading,
                        icon: Icons.login,
                      ),

                      // Inline error message (more visible than snackbar)
                      if (authProvider.error != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color:
                                theme.colorScheme.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            border: Border.all(
                              color: theme.colorScheme.error
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 18,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  authProvider.error!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.md),

                      // Register Link
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoute.register);
                        },
                        child: Text(
                          AppStrings.noAccount,
                          style: TextStyle(color: theme.colorScheme.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
