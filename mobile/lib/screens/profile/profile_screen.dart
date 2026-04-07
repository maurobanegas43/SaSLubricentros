import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Colores del tema
  static const Color _errorColor = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Avatar y nombre
            _buildProfileHeader(
                context, user?.name ?? 'Usuario', user?.email ?? ''),
            const SizedBox(height: AppSpacing.xl),

            // Información de la cuenta
            _buildSection(
              context,
              title: 'Información de la Cuenta',
              children: [
                _buildInfoTile(
                  context,
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: user?.email ?? 'No disponible',
                ),
                _buildInfoTile(
                  context,
                  icon: Icons.person_outline,
                  label: 'Nombre',
                  value: user?.name ?? 'No disponible',
                ),
                _buildInfoTile(
                  context,
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: user?.phone ?? 'No configurado',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Configuración
            _buildSection(
              context,
              title: 'Configuración',
              children: [
                _buildSettingTile(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notificaciones',
                  subtitle: 'Gestionar alertas y recordatorios',
                  onTap: () => _showComingSoon(context),
                ),
                _buildSettingTile(
                  context,
                  icon: Icons.lock_outline,
                  title: 'Seguridad',
                  subtitle: 'Cambiar contraseña',
                  onTap: () => _showComingSoon(context),
                ),
                _buildSettingTile(
                  context,
                  icon: Icons.language,
                  title: 'Idioma',
                  subtitle: 'Español',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Datos del vehículo
            _buildSection(
              context,
              title: 'Datos del Vehículo',
              children: [
                _buildSettingTile(
                  context,
                  icon: Icons.directions_car_outlined,
                  title: 'Mi Vehículo',
                  subtitle: 'Toyota Corolla (2022)',
                  onTap: () => _showComingSoon(context),
                ),
                _buildSettingTile(
                  context,
                  icon: Icons.build_outlined,
                  title: 'Historial de Servicios',
                  subtitle: 'Ver servicios realizados',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Botón de cerrar sesión
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context, authProvider),
                icon: Icon(Icons.logout, color: _errorColor),
                label: Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: _errorColor),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _errorColor),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Versión de la app
            Text(
              'Versión 1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, String email) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          email,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidadcoming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que querés cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.logout();
            },
            child: Text(
              'Cerrar Sesión',
              style: TextStyle(color: _errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
