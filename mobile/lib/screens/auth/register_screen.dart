import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_constants.dart';
import '../../widgets/common/animated_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.validationRequired;
    if (value.length < 8)
      return AppStrings.validationMinChars.replaceFirst('%d', '8');
    if (!RegExp(r'[A-Z]').hasMatch(value))
      return AppStrings.validationUppercase;
    if (!RegExp(r'[a-z]').hasMatch(value))
      return AppStrings.validationLowercase;
    if (!RegExp(r'[0-9]').hasMatch(value)) return AppStrings.validationNumber;
    return null;
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Volver',
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppStrings.registerTitle,
                      style: theme.textTheme.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppStrings.registerSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return AppStrings.validationRequired;
                        if (value.length < 2)
                          return AppStrings.validationMinChars
                              .replaceFirst('%d', '2');
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

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
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return AppStrings.validationRequired;
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return AppStrings.validationInvalidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Phone Field (Optional)
                    TextFormField(
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: const InputDecoration(
                        labelText: 'Teléfono (opcional)',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
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
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocus,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                          tooltip:
                              _obscureConfirmPassword ? 'Mostrar' : 'Ocultar',
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text)
                          return AppStrings.validationPasswordsMatch;
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleRegister(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Register Button
                    AnimatedButton(
                      label: AppStrings.registerButton,
                      onPressed: _handleRegister,
                      isLoading: isLoading,
                      icon: Icons.person_add,
                    ),

                    // Inline error message
                    if (authProvider.error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          border: Border.all(
                            color:
                                theme.colorScheme.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                size: 18, color: theme.colorScheme.error),
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

                    // Login Link
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        AppStrings.hasAccount,
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
    );
  }
}
