import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

const int _minimumSignUpPasswordLength = 6;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  StreamSubscription<AuthState>? _authStateSubscription;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isRoutingAfterAuth = false;

  @override
  void initState() {
    super.initState();

    if (AuthService.instance.isConfigured) {
      _authStateSubscription =
          Supabase.instance.client.auth.onAuthStateChange.listen(
        (authState) async {
          if (authState.session == null) {
            return;
          }

          switch (authState.event) {
            case AuthChangeEvent.initialSession:
            case AuthChangeEvent.signedIn:
            case AuthChangeEvent.tokenRefreshed:
              await _completeAuthenticatedFlow();
              break;
            default:
          }
        },
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resumeExistingSession();
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _resumeExistingSession() async {
    if (!mounted || !AuthService.instance.isConfigured) {
      return;
    }

    if (AuthService.instance.currentUser == null) {
      return;
    }

    await _completeAuthenticatedFlow();
  }

  Future<void> _completeAuthenticatedFlow() async {
    if (!mounted || _isRoutingAfterAuth) {
      return;
    }

    _isRoutingAfterAuth = true;

    try {
      await ProfileService.instance.hydrateCurrentSession();

      if (!mounted) {
        return;
      }

      Navigator.pushReplacementNamed(context, '/home');
    } finally {
      _isRoutingAfterAuth = false;
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(
        initialEmail: _emailController.text.trim(),
      ),
    );

    if (!mounted || email == null) {
      return;
    }

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Renseignez votre email.'),
        ),
      );
      return;
    }

    try {
      await AuthService.instance.resetPasswordForEmail(email);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Si un compte existe pour cet email, un message de reinitialisation a ete envoye.',
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
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Envoi impossible pour le moment.'),
        ),
      );
    }
  }

  Future<void> _showSignUpDialog() async {
    if (_isSubmitting) {
      return;
    }

    final draft = await showDialog<_SignUpDraft>(
      context: context,
      builder: (_) => _SignUpDialog(
        initialEmail: _emailController.text.trim(),
      ),
    );

    if (!mounted || draft == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await AuthService.instance.signUp(
        email: draft.email,
        password: draft.password,
        fullName: draft.fullName,
        associationName: draft.associationName,
      );

      if (response.session != null) {
        await _completeAuthenticatedFlow();
        return;
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Compte cree. Verifiez maintenant votre email avant de vous connecter.',
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
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscription impossible pour le moment.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_isSubmitting) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Renseignez votre email et votre mot de passe.'),
        ),
      );
      return;
    }

    if (!AuthService.instance.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Supabase n\'est pas encore configure. Ouverture en mode demo.',
          ),
        ),
      );
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthService.instance.signInWithPassword(
        email: email,
        password: password,
      );
      await _completeAuthenticatedFlow();
    } on AuthException catch (error) {
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
          content: Text('Connexion impossible pour le moment.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/logo.png',
                        height: 160,
                        width: 160,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Connexion',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          hintText: 'Email',
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: 'Mot de passe',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppTheme.textSecondaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Se connecter'),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _showForgotPasswordDialog,
                        child: const Text(
                          'Mot de passe oubli\u00E9 ?',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Pas encore de compte ?',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _showSignUpDialog,
                            child: const Text(
                              'S\'inscrire',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _SignUpDraft {
  const _SignUpDraft({
    required this.fullName,
    required this.associationName,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  final String fullName;
  final String associationName;
  final String email;
  final String password;
  final String confirmPassword;
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({
    required this.initialEmail,
  });

  final String initialEmail;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _close([String? result]) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mot de passe oublie'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Email',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _close(_emailController.text.trim()),
            child: const Text('Envoyer'),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _close,
              child: const Text('Annuler'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignUpDialog extends StatefulWidget {
  const _SignUpDialog({
    required this.initialEmail,
  });

  final String initialEmail;

  @override
  State<_SignUpDialog> createState() => _SignUpDialogState();
}

class _SignUpDialogState extends State<_SignUpDialog> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _associationController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  String? _fullNameError;
  String? _associationError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _associationController = TextEditingController();
    _emailController = TextEditingController(text: widget.initialEmail);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _associationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _cancel() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop();
  }

  OutlineInputBorder _errorBorder({double width = 1.5}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: AppTheme.dangerColor,
        width: width,
      ),
    );
  }

  bool _validateForm() {
    final fullName = _fullNameController.text.trim();
    final associationName = _associationController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final fullNameError =
        fullName.isEmpty ? 'Renseignez votre nom complet.' : null;
    final associationError =
        associationName.isEmpty ? 'Renseignez votre association.' : null;
    final emailError = email.isEmpty
        ? 'Renseignez votre email.'
        : (!email.contains('@') ? 'Renseignez un email valide.' : null);

    String? passwordError;
    if (password.isEmpty) {
      passwordError = 'Renseignez un mot de passe.';
    } else if (password.length < _minimumSignUpPasswordLength) {
      passwordError =
          'Le mot de passe doit contenir au moins $_minimumSignUpPasswordLength caracteres.';
    }

    String? confirmPasswordError;
    if (confirmPassword.isEmpty) {
      confirmPasswordError = 'Confirmez votre mot de passe.';
    } else if (passwordError == null && password != confirmPassword) {
      confirmPasswordError = 'Les mots de passe ne correspondent pas.';
    }

    setState(() {
      _fullNameError = fullNameError;
      _associationError = associationError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
    });

    return fullNameError == null &&
        associationError == null &&
        emailError == null &&
        passwordError == null &&
        confirmPasswordError == null;
  }

  void _revalidateIfNeeded() {
    if (_fullNameError == null &&
        _associationError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null) {
      return;
    }

    _validateForm();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    if (!_validateForm()) {
      return;
    }

    Navigator.of(context).pop(
      _SignUpDraft(
        fullName: _fullNameController.text.trim(),
        associationName: _associationController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('S\'inscrire'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _fullNameController,
              onChanged: (_) => _revalidateIfNeeded(),
              decoration: InputDecoration(
                hintText: 'Nom complet',
                errorText: _fullNameError,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _associationController,
              onChanged: (_) => _revalidateIfNeeded(),
              decoration: InputDecoration(
                hintText: 'Association',
                errorText: _associationError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => _revalidateIfNeeded(),
              decoration: InputDecoration(
                hintText: 'Email',
                errorText: _emailError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              onChanged: (_) => _revalidateIfNeeded(),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Mot de passe',
                errorText: _passwordError,
                errorMaxLines: 2,
                errorBorder: _errorBorder(),
                focusedErrorBorder: _errorBorder(width: 2),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              onChanged: (_) => _revalidateIfNeeded(),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Confirmer le mot de passe',
                errorText: _confirmPasswordError,
                errorMaxLines: 2,
                errorBorder: _errorBorder(),
                focusedErrorBorder: _errorBorder(width: 2),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Creer le compte'),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _cancel,
                child: const Text('Annuler'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
