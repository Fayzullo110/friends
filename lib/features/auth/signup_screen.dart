import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../models/app_user.dart';
import '../../theme/ios_icons.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback onSwitchToLogin;

  const SignUpScreen({super.key, required this.onSwitchToLogin});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = false;
  bool _checkingUsername = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _usernameStatus;
  Color? _usernameStatusColor;
  List<String> _usernameSuggestions = const [];
  DateTime? _birthDate;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      int computedAge = 0;
      if (_birthDate != null) {
        final now = DateTime.now();
        computedAge = now.year - _birthDate!.year;
        final hasHadBirthdayThisYear =
            now.month > _birthDate!.month ||
                (now.month == _birthDate!.month &&
                    now.day >= _birthDate!.day);
        if (!hasHadBirthdayThisYear) {
          computedAge -= 1;
        }
      }
      final AppUser user = await AuthService.instance.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: computedAge,
      );
      debugPrint('Signed up as: ${user.email}');
    } on Exception catch (e) {
      // Log the raw error for debugging.
      debugPrint('Sign up error: $e');
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateUsernameSuggestions() {
    final first = _firstNameController.text.trim().toLowerCase();
    final last = _lastNameController.text.trim().toLowerCase();
    if (first.isEmpty && last.isEmpty) {
      setState(() {
        _usernameSuggestions = const [];
      });
      return;
    }

    final base1 = [first, last].where((s) => s.isNotEmpty).join('.');
    final base2 = [first, last].where((s) => s.isNotEmpty).join('_');
    final base3 = '$first${last.isNotEmpty ? last[0] : ''}';

    final now = DateTime.now().millisecond; // simple varying suffix
    final suggestion1 = base1;
    final suggestion2 = '${base2}_${(now % 90) + 10}';
    final suggestion3 = '$base3${(now % 900) + 100}';

    setState(() {
      _usernameSuggestions = [
        suggestion1,
        suggestion2,
        suggestion3,
      ].where((s) => s.trim().isNotEmpty).toList();
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = _birthDate ?? DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 120),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: 'Select your date of birth',
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _ageController.text =
            '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}';
      });
    }
  }

  Future<void> _checkUsernameAvailability() async {
    final value = _usernameController.text.trim();
    if (value.isEmpty) {
      setState(() {
        _usernameStatus = 'Please enter a username to check.';
        _usernameStatusColor = Colors.red;
      });
      return;
    }

    setState(() {
      _checkingUsername = true;
      _usernameStatus = null;
    });

    final available =
        await AuthService.instance.isUsernameAvailable(value.trim());
    if (!mounted) return;

    setState(() {
      _checkingUsername = false;
      _usernameStatus = available
          ? 'Great, this username is available.'
          : 'This username is already taken.';
      _usernameStatusColor = available ? Colors.green : Colors.red;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050509), Color(0xFF101018)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 24 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Card(
                    color: theme.colorScheme.surface,
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Segmented toggle: Login / Register
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : widget.onSwitchToLogin,
                                    style: TextButton.styleFrom(
                                      foregroundColor: theme
                                          .colorScheme.onSurface
                                          .withOpacity(0.7),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                    ),
                                    child: const Text('Login'),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Register',
                                          style: theme
                                              .textTheme.labelLarge
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Create your account',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sign up to start sharing posts and chatting with friends.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Form(
                            key: _formKey,
                            child: Column(
                          children: [
                            TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                labelText: 'First name',
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.words,
                              onChanged: (_) => _updateUsernameSuggestions(),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your first name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(
                                labelText: 'Surname',
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.words,
                              onChanged: (_) => _updateUsernameSuggestions(),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) {
                                setState(() {
                                  _usernameStatus = null;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please choose a username';
                                }
                                if (value.length < 3) {
                                  return 'Username must be at least 3 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: _checkingUsername
                                      ? null
                                      : _checkUsernameAvailability,
                                  child: const Text('Check availability'),
                                ),
                                if (_checkingUsername)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                              ],
                            ),
                            if (_usernameStatus != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _usernameStatus!,
                                  style: TextStyle(
                                    color:
                                        _usernameStatusColor ?? Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (_usernameSuggestions.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: _usernameSuggestions.map((s) {
                                    return ActionChip(
                                      label: Text(s),
                                      onPressed: () {
                                        setState(() {
                                          _usernameController.text = s;
                                          _usernameStatus = null;
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _ageController,
                              readOnly: true,
                              onTap: _pickBirthDate,
                              decoration: const InputDecoration(
                                labelText: 'Date of birth',
                                hintText: 'Select your birth date',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(IOSIcons.calendar),
                              ),
                              validator: (value) {
                                if (_birthDate == null) {
                                  return 'Please select your birth date';
                                }

                                final now = DateTime.now();
                                var age = now.year - _birthDate!.year;
                                final hasHadBirthdayThisYear =
                                    now.month > _birthDate!.month ||
                                        (now.month == _birthDate!.month &&
                                            now.day >= _birthDate!.day);
                                if (!hasHadBirthdayThisYear) {
                                  age -= 1;
                                }

                                if (age < 13) {
                                  return 'You must be at least 13 years old';
                                }
                                if (age > 120) {
                                  return 'Please select a realistic date';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? IOSIcons.eyeSlash
                                        : IOSIcons.eye,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm password',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? IOSIcons.eyeSlash
                                        : IOSIcons.eye,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                            ),
                          ],
                        ),
                      ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _submit,
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Sign up'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Or sign up with',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                            setState(() => _isLoading = true);
                                            try {
                                              await AuthService.instance
                                                  .signInWithGoogle();
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Google sign-in failed: $e',
                                                  ),
                                                ),
                                              );
                                            } finally {
                                              if (mounted) {
                                                setState(
                                                    () => _isLoading = false);
                                              }
                                            }
                                          },
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                    ),
                                    icon: const Icon(IOSIcons.add), // Using add icon for Google G placeholder
                                    label: const Text('Google'),
                                  ),
                                ],
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
          ),
        ),
      ),
    );
  }
}
