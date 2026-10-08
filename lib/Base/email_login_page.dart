import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_page.dart';
import 'login_page.dart';

// =====================================================
//                    EMAIL ACCESS
// =====================================================

const String allowedDomain = '@espartmoveis.com';

bool isAllowedEmail(String? email) {
  if (email == null) return false;

  return email
      .trim()
      .toLowerCase()
      .endsWith(allowedDomain.toLowerCase());
}

// =====================================================
//                    EMAIL LOGIN PAGE
// =====================================================

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  String? errorMessage;

  static const Color _darkBrown = Color(0xFF5A3825);
  static const Color _brown = Color(0xFF79533B);
  static const Color _softBrown = Color(0xFFF4EEEA);
  static const Color _border = Color(0xFFE8E3DF);
  static const Color _softText = Color(0xFF77716D);

  // =====================================================
  //                       DISPOSE
  // =====================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // =====================================================
  //                         LOGIN
  // =====================================================

  Future<void> loginWithEmail() async {
    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final email = emailController.text.trim().toLowerCase();
      final password = passwordController.text;

      // ---------------------------------------------------
      // VALIDATION
      // ---------------------------------------------------

      if (email.isEmpty) {
        setState(() {
          errorMessage = 'Digite seu email.';
        });
        return;
      }

      if (!isAllowedEmail(email)) {
        setState(() {
          errorMessage =
              'Este email não é autorizado. Use um email que termine com $allowedDomain.';
        });
        return;
      }

      if (password.isEmpty) {
        setState(() {
          errorMessage = 'Digite sua senha.';
        });
        return;
      }

      // ---------------------------------------------------
      // FIREBASE LOGIN
      // ---------------------------------------------------

      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            user: user,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Não foi possível fazer login.';

      switch (e.code) {
        case 'user-not-found':
          message = 'Usuário não encontrado.';
          break;

        case 'wrong-password':
          message = 'Senha incorreta.';
          break;

        case 'invalid-credential':
          message = 'Email ou senha incorretos.';
          break;

        case 'invalid-email':
          message = 'O email informado é inválido.';
          break;

        case 'user-disabled':
          message = 'Este usuário foi desativado.';
          break;

        case 'too-many-requests':
          message =
              'Muitas tentativas de login. Aguarde um pouco e tente novamente.';
          break;

        case 'network-request-failed':
          message =
              'Não foi possível conectar. Verifique sua internet.';
          break;
      }

      if (mounted) {
        setState(() {
          errorMessage = message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Ocorreu um erro inesperado.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // =====================================================
  //                         BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ===================================================
      //                       APP BAR
      // ===================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const LoginPage(),
              ),
            );
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.black,
          ),
        ),
      ),

      // ===================================================
      //                         BODY
      // ===================================================

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // =========================================
                  //                     ICON
                  // =========================================

                  Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: _softBrown,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: _darkBrown,
                        size: 31,
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // =========================================
                  //                    TITLE
                  // =========================================

                  const Text(
                    'Login com email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Entre usando seu email da Espart Móveis.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: _softText,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // =========================================
                  //                    EMAIL
                  // =========================================

                  const Text(
                    'Email',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.email,
                    ],
                    cursorColor: _brown,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      color: Colors.black,
                    ),
                    decoration: _inputDecoration(
                      hintText: 'seuemail@espartmoveis.com',
                      icon: Icons.mail_outline_rounded,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =========================================
                  //                   PASSWORD
                  // =========================================

                  const Text(
                    'Senha',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [
                      AutofillHints.password,
                    ],
                    onSubmitted: (_) {
                      if (!loading) {
                        loginWithEmail();
                      }
                    },
                    cursorColor: _brown,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      color: Colors.black,
                    ),
                    decoration: _inputDecoration(
                      hintText: 'Digite sua senha',
                      icon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        tooltip: obscurePassword
                            ? 'Mostrar senha'
                            : 'Ocultar senha',
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: _softText,
                          size: 21,
                        ),
                      ),
                    ),
                  ),

                  // =========================================
                  //                    ERROR
                  // =========================================

                  if (errorMessage != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4F4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFD8D8),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red,
                            size: 19,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // =========================================
                  //                 LOGIN BUTTON
                  // =========================================

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: loading
                          ? null
                          : loginWithEmail,
                      style: FilledButton.styleFrom(
                        backgroundColor: _darkBrown,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            _darkBrown.withValues(alpha: 0.55),
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 21,
                              height: 21,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.3,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Entrar',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =========================================
                  //                    GOOGLE
                  // =========================================

                  TextButton(
                    onPressed: loading
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: _darkBrown,
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                    ),
                    child: const Text(
                      'Voltar para login com Google',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  //                   INPUT DECORATION
  // =====================================================

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 14,
        color: _softText,
      ),
      prefixIcon: Icon(
        icon,
        color: _softText,
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _brown,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }
}
