import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../itens_page.dart';
import '../clientes_page.dart';

class HomePage extends StatelessWidget {
  final User? user;

  const HomePage({
    super.key,
    required this.user,
  });

  static const Color _darkBrown = Color(0xFF5A3825);
  static const Color _brown = Color(0xFF79533B);
  static const Color _softBrown = Color(0xFFF4EEEA);
  static const Color _border = Color(0xFFE8E3DF);
  static const Color _softText = Color(0xFF77716D);

  // =====================================================
  //                       LOGOUT
  // =====================================================

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    // If your app uses AuthGate, FirebaseAuth will automatically
    // show the login page after signOut().
    //
    // If HomePage was opened with Navigator.push(),
    // this also safely closes the current page when possible.
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // =====================================================
  //                        BUILD
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
        titleSpacing: 24,
        title: const Text(
          'Espart Móveis',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () => _logout(context),
              tooltip: 'Sair',
              style: IconButton.styleFrom(
                backgroundColor: _softBrown,
                foregroundColor: _darkBrown,
              ),
              icon: const Icon(
                Icons.logout_rounded,
                size: 21,
              ),
            ),
          ),
        ],
      ),

      // ===================================================
      //                         BODY
      // ===================================================

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 650,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =========================================
                  //                    TITLE
                  // =========================================

                  const Text(
                    'Olá!',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'O que você deseja acessar?',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _softText,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // =========================================
                  //                  CLIENTES
                  // =========================================

                  _menuCard(
                    label: 'Clientes',
                    description:
                        'Visualize e gerencie seus clientes e orçamentos.',
                    icon: Icons.people_outline_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClientesPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // =========================================
                  //                    ITENS
                  // =========================================

                  _menuCard(
                    label: 'Itens',
                    description:
                        'Gerencie materiais, preços e informações dos itens.',
                    icon: Icons.inventory_2_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ItensPage(),
                        ),
                      );
                    },
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
  //                      MENU CARD
  // =====================================================

  Widget _menuCard({
    required String label,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: _softBrown,
        highlightColor: _softBrown.withValues(alpha: 0.45),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _border,
            ),
          ),
          child: Row(
            children: [
              // =============================================
              //                      ICON
              // =============================================

              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _softBrown,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: _darkBrown,
                  size: 27,
                ),
              ),

              const SizedBox(width: 18),

              // =============================================
              //                     TEXT
              // =============================================

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: _softText,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // =============================================
              //                    ARROW
              // =============================================

              const Icon(
                Icons.chevron_right_rounded,
                color: _brown,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}