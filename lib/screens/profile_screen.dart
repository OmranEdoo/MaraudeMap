import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/current_session.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/app_help_button.dart';
import '../widgets/navigation_menu_panel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey _menuHelpKey = GlobalKey();
  final GlobalKey _cardHelpKey = GlobalKey();
  final GlobalKey _logoutHelpKey = GlobalKey();
  bool _isSavingProfile = false;

  Future<void> _showEditProfileDialog() async {
    if (_isSavingProfile) {
      return;
    }

    final draft = await showDialog<_ProfileDraft>(
      context: context,
      builder: (_) => _EditProfileDialog(
        initialFullName: CurrentSession.displayName,
        initialEmail: CurrentSession.email,
        initialAssociationName: CurrentSession.associationName,
      ),
    );

    if (!mounted || draft == null) {
      return;
    }

    if (draft.fullName.isEmpty ||
        draft.email.isEmpty ||
        draft.associationName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Renseignez tous les champs du profil.'),
        ),
      );
      return;
    }

    final normalizedEmail = draft.email.trim();
    if (!normalizedEmail.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Renseignez un email valide.'),
        ),
      );
      return;
    }

    setState(() {
      _isSavingProfile = true;
    });

    final previousEmail = CurrentSession.email;

    try {
      await ProfileService.instance.updateCurrentProfile(
        email: normalizedEmail,
        fullName: draft.fullName,
        associationName: draft.associationName,
      );

      if (!mounted) {
        return;
      }

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            normalizedEmail == previousEmail
                ? 'Profil mis a jour.'
                : 'Profil mis a jour. Verifiez votre email si une confirmation vous est demandee.',
          ),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mise a jour impossible pour le moment.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final helpTargets = [
      AppHelpTarget(
        targetKey: _menuHelpKey,
        title: 'Menu',
        description:
            'Utilisez ce bouton pour revenir rapidement vers la carte, la liste ou l historique.',
        onTargetTap: () => showNavigationMenuPanel(
          context,
          currentRoute: '/profile',
        ),
        closeAfterTap: true,
      ),
      AppHelpTarget(
        targetKey: _cardHelpKey,
        title: 'Profil',
        description:
            'Cette fiche resume les informations du membre actuellement connecte.',
      ),
      AppHelpTarget(
        targetKey: _logoutHelpKey,
        title: 'Deconnexion',
        description:
            'Deconnectez-vous ici pour revenir a l ecran de connexion.',
        placement: AppHelpPlacement.above,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          key: _menuHelpKey,
          icon: const Icon(Icons.menu),
          onPressed: () => showNavigationMenuPanel(
            context,
            currentRoute: '/profile',
          ),
        ),
        title: const Text('Profil'),
        centerTitle: true,
        actions: [
          AppHelpButton(targets: helpTargets),
        ],
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    key: _cardHelpKey,
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 32,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                      Row(
                                        children: [
                                          const Expanded(
                                            child: Text(
                                              'Profil utilisateur',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                                color: AppTheme.textPrimaryColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          OutlinedButton.icon(
                                            onPressed:
                                                _isSavingProfile ? null : _showEditProfileDialog,
                                            icon: _isSavingProfile
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Icon(Icons.edit_outlined),
                                            label: Text(
                                              _isSavingProfile
                                                  ? 'Enregistrement'
                                                  : 'Modifier',
                                            ),
                                          ),
                                        ],
                                      ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Membre connecte de l association ${CurrentSession.associationName}',
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildInfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Nom',
                          value: CurrentSession.displayName,
                        ),
                        const SizedBox(height: 18),
                        _buildInfoRow(
                          icon: Icons.mail_outline,
                          label: 'Email',
                          value: CurrentSession.email,
                        ),
                        const SizedBox(height: 18),
                        _buildInfoRow(
                          icon: Icons.groups_outlined,
                          label: 'Association',
                          value: CurrentSession.associationName,
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton.icon(
                          key: _logoutHelpKey,
                          onPressed: () async {
                            await AuthService.instance.signOut();
                            CurrentSession.resetToDemo();
                            if (!context.mounted) {
                              return;
                            }

                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/authenticate',
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Deconnexion'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileDraft {
  const _ProfileDraft({
    required this.fullName,
    required this.email,
    required this.associationName,
  });

  final String fullName;
  final String email;
  final String associationName;
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.initialFullName,
    required this.initialEmail,
    required this.initialAssociationName,
  });

  final String initialFullName;
  final String initialEmail;
  final String initialAssociationName;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _associationController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.initialFullName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _associationController = TextEditingController(
      text: widget.initialAssociationName,
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _associationController.dispose();
    super.dispose();
  }

  void _close([_ProfileDraft? draft]) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le profil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                hintText: 'Nom complet',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Email',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _associationController,
              decoration: const InputDecoration(
                hintText: 'Association',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _close,
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => _close(
            _ProfileDraft(
              fullName: _fullNameController.text.trim(),
              email: _emailController.text.trim(),
              associationName: _associationController.text.trim(),
            ),
          ),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
