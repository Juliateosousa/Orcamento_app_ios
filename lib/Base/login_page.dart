import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'home_page.dart';
import 'email_login_page.dart';

// ======================================================
// ACCESS SETTINGS
// ======================================================

const String allowedDomain = "espartmoveis.com";

const List<String> allowedEmails = [
  String.fromEnvironment("ALLOWED_EMAIL_1"),
  String.fromEnvironment("ALLOWED_EMAIL_2"),
  String.fromEnvironment("ALLOWED_EMAIL_3"),
];

bool isAllowedEmail(String? email) {
  if (email == null) return false;

  final e = email.toLowerCase().trim();

  final allowedList =
      allowedEmails.map((x) => x.toLowerCase().trim()).toList();

  return allowedList.contains(e) || e.endsWith("@$allowedDomain");
}

// ======================================================
// LOGIN PAGE
// ======================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool loading = false;
  String? errorMessage;

  // Desktop Client ID used by macOS.
  static const String macosDesktopClientId =
      String.fromEnvironment("GOOGLE_MACOS_CLIENT_ID");

  // ======================================================
  // GOOGLE LOGIN
  // ======================================================

  Future<void> signInWithGoogle() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      debugPrint('1. Starting Google Sign-In');

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            !kIsWeb && Platform.isMacOS ? macosDesktopClientId : null,
      );

      final GoogleSignInAccount? googleUser =
          await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('2. Google Sign-In cancelled');
        return;
      }

      debugPrint(
        '2. Google user selected',
      );

      // Check whether the account is allowed.
      if (!isAllowedEmail(googleUser.email)) {
        await googleSignIn.signOut();

        throw Exception(
          'Email não autorizado',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint('3. Google authentication received');

      debugPrint(
        'Access token exists: ${googleAuth.accessToken != null}',
      );

      debugPrint(
        'ID token exists: ${googleAuth.idToken != null}',
      );

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final user = userCredential.user;

      if (user == null) {
        throw Exception(
          "Firebase não retornou o usuário.",
        );
      }

      debugPrint(
        '4. Firebase user authenticated',
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomePage(
            user: user,
          ),
        ),
      );

      debugPrint('5. Navigation executed');
    }

    // ====================================================
    // FIREBASE ERROR
    // ====================================================

    on FirebaseAuthException catch (e, stackTrace) {
      debugPrint(
        'FirebaseAuthException: ${e.code}',
      );

      debugPrint(
        'Message: ${e.message}',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        errorMessage =
            e.message ?? 'Erro ao entrar com Google.';
      });
    }

    // ====================================================
    // OTHER ERRORS
    // ====================================================

    catch (e, stackTrace) {
      debugPrint(
        'Google Sign-In error: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        errorMessage =
            'Erro ao entrar com Google: $e';
      });
    }

    // ====================================================
    // FINISH
    // ====================================================

    finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ======================================================
  // SMALL FEATURE ITEM
  // ======================================================

  Widget _loginFeature(
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.black54,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ======================================================
  // FEATURE DIVIDER
  // ======================================================

  Widget _featureDivider() {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      color: Colors.black.withValues(
        alpha: 0.10,
      ),
    );
  }

  // ======================================================
  // PAGE
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        children: [
          // =================================================
          // DECORATIVE BACKGROUND ICONS
          // =================================================

          Positioned(
            top: 70,
            left: 55,
            child: Icon(
              Icons.chair_outlined,
              size: 70,
              color: Colors.black.withValues(
                alpha: 0.025,
              ),
            ),
          ),

          Positioned(
            top: 110,
            right: 70,
            child: Icon(
              Icons.straighten_outlined,
              size: 60,
              color: Colors.black.withValues(
                alpha: 0.025,
              ),
            ),
          ),

          Positioned(
            bottom: 70,
            left: 90,
            child: Icon(
              Icons.calculate_outlined,
              size: 65,
              color: Colors.black.withValues(
                alpha: 0.025,
              ),
            ),
          ),

          Positioned(
            bottom: 100,
            right: 70,
            child: Icon(
              Icons.inventory_2_outlined,
              size: 70,
              color: Colors.black.withValues(
                alpha: 0.025,
              ),
            ),
          ),

          // =================================================
          // MAIN CONTENT
          // =================================================

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),

                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 460,
                  ),

                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [
                      // =====================================
                      // APP ICON
                      // =====================================

                      Container(
                        width: 108,
                        height: 108,
                        padding: const EdgeInsets.all(8),

                        decoration: BoxDecoration(
                          color: Colors.white,

                          borderRadius:
                              BorderRadius.circular(26),

                          border: Border.all(
                            color: Colors.black
                                .withValues(
                              alpha: 0.07,
                            ),
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(
                                alpha: 0.07,
                              ),
                              blurRadius: 25,
                              offset:
                                  const Offset(0, 10),
                            ),
                          ],
                        ),

                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // =====================================
                      // APP NAME
                      // =====================================

                      const Text(
                        'Espart Móveis',
                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 32,
                          fontWeight:
                              FontWeight.w700,
                          letterSpacing: -0.8,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Text(
                        'Sistema de Orçamentos',
                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black
                              .withValues(
                            alpha: 0.48,
                          ),
                        ),
                      ),

                      const SizedBox(height: 34),

                      // =====================================
                      // LOGIN CARD
                      // =====================================

                      Container(
                        width: double.infinity,

                        padding:
                            const EdgeInsets.all(28),

                        decoration: BoxDecoration(
                          color: Colors.white,

                          borderRadius:
                              BorderRadius.circular(20),

                          border: Border.all(
                            color: Colors.black
                                .withValues(
                              alpha: 0.10,
                            ),
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(
                                alpha: 0.045,
                              ),
                              blurRadius: 25,
                              offset:
                                  const Offset(0, 8),
                            ),
                          ],
                        ),

                        child: Column(
                          children: [
                            // ===============================
                            // LOCK ICON
                            // ===============================

                            Container(
                              width: 44,
                              height: 44,

                              decoration:
                                  BoxDecoration(
                                color: Colors.black
                                    .withValues(
                                  alpha: 0.045,
                                ),
                                shape:
                                    BoxShape.circle,
                              ),

                              child: const Icon(
                                Icons
                                    .lock_outline_rounded,
                                size: 21,
                              ),
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            // ===============================
                            // WELCOME
                            // ===============================

                            const Text(
                              'Bem-vindo',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              'Entre na sua conta para continuar',
                              textAlign:
                                  TextAlign.center,

                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black
                                    .withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 26,
                            ),

                            // ===============================
                            // ERROR
                            // ===============================

                            if (errorMessage !=
                                null) ...[
                              Container(
                                width:
                                    double.infinity,

                                padding:
                                    const EdgeInsets
                                        .all(14),

                                decoration:
                                    BoxDecoration(
                                  color: Colors.red
                                      .withValues(
                                    alpha: 0.035,
                                  ),

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    10,
                                  ),

                                  border:
                                      Border.all(
                                    color: Colors.red
                                        .withValues(
                                      alpha: 0.18,
                                    ),
                                  ),
                                ),

                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [
                                    const Icon(
                                      Icons
                                          .error_outline_rounded,
                                      size: 19,
                                      color:
                                          Colors.red,
                                    ),

                                    const SizedBox(
                                      width: 10,
                                    ),

                                    Expanded(
                                      child: Text(
                                        errorMessage!,
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.red,
                                          fontSize:
                                              12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(
                                height: 18,
                              ),
                            ],

                            // ===============================
                            // GOOGLE LOGIN
                            // ===============================

                            SizedBox(
                              width:
                                  double.infinity,
                              height: 54,

                              child: ElevatedButton(
                                onPressed: loading
                                    ? null
                                    : signInWithGoogle,

                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  elevation: 0,

                                  backgroundColor:
                                      Colors.black,

                                  foregroundColor:
                                      Colors.white,

                                  disabledBackgroundColor:
                                      Colors.black54,

                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      12,
                                    ),
                                  ),
                                ),

                                child: loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,

                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2,
                                          color: Colors
                                              .white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .center,

                                        children: [
                                          Icon(
                                            Icons
                                                .login_rounded,
                                            size: 20,
                                          ),

                                          SizedBox(
                                            width: 10,
                                          ),

                                          Text(
                                            'Entrar com Google',
                                            style:
                                                TextStyle(
                                              fontSize:
                                                  15,
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(
                              height: 21,
                            ),

                            // ===============================
                            // OR DIVIDER
                            // ===============================

                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors
                                        .black
                                        .withValues(
                                      alpha: 0.10,
                                    ),
                                  ),
                                ),

                                Padding(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 14,
                                  ),

                                  child: Text(
                                    'ou',
                                    style:
                                        TextStyle(
                                      fontSize: 12,
                                      color: Colors
                                          .black
                                          .withValues(
                                        alpha:
                                            0.35,
                                      ),
                                    ),
                                  ),
                                ),

                                Expanded(
                                  child: Divider(
                                    color: Colors
                                        .black
                                        .withValues(
                                      alpha: 0.10,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 21,
                            ),

                            // ===============================
                            // EMAIL LOGIN
                            // ===============================

                            SizedBox(
                              width:
                                  double.infinity,
                              height: 54,

                              child: OutlinedButton(
                                onPressed: loading
                                    ? null
                                    : () {
                                        Navigator
                                            .push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    const EmailLoginPage(),
                                          ),
                                        );
                                      },

                                style:
                                    OutlinedButton
                                        .styleFrom(
                                  foregroundColor:
                                      Colors.black87,

                                  side: BorderSide(
                                    color: Colors
                                        .black
                                        .withValues(
                                      alpha: 0.18,
                                    ),
                                  ),

                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      12,
                                    ),
                                  ),
                                ),

                                child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,

                                  children: [
                                    Icon(
                                      Icons
                                          .mail_outline_rounded,
                                      size: 20,
                                    ),

                                    SizedBox(
                                      width: 10,
                                    ),

                                    Text(
                                      'Entrar com Email',
                                      style:
                                          TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight
                                                .w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // =====================================
                      // APP FEATURES
                      // =====================================

                      Wrap(
                        alignment:
                            WrapAlignment.center,
                        crossAxisAlignment:
                            WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 12,

                        children: [
                          _loginFeature(
                            Icons
                                .request_quote_outlined,
                            'Orçamentos',
                          ),

                          _featureDivider(),

                          _loginFeature(
                            Icons.chair_outlined,
                            'Móveis',
                          ),

                          _featureDivider(),

                          _loginFeature(
                            Icons
                                .people_outline_rounded,
                            'Clientes',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // =====================================
                      // SECURITY TEXT
                      // =====================================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: Colors.black
                                .withValues(
                              alpha: 0.32,
                            ),
                          ),

                          const SizedBox(width: 6),

                          Text(
                            'Acesso exclusivo Espart Móveis',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black
                                  .withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}