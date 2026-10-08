import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Orçamento Base/orcamentos_cliente_page.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchTerm = '';

  static const Color _darkBrown = Color(0xFF5A3825);
  static const Color _brown = Color(0xFF79533B);
  static const Color _softBrown = Color(0xFFF4EEEA);
  static const Color _border = Color(0xFFE8E3DF);
  static const Color _softText = Color(0xFF77716D);

  // =====================================================
  //                       INIT
  // =====================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (!mounted) return;

    setState(() {
      _searchTerm = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();

    super.dispose();
  }

  // =====================================================
  //                     NEW CLIENT
  // =====================================================

  Future<void> _abrirDialogNovoCliente(
    BuildContext context,
  ) async {
    final nomeCtrl = TextEditingController();
    final telefoneCtrl = TextEditingController();
    final arquitetoCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Novo cliente',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller: nomeCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              cursorColor: _brown,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                color: Colors.black,
              ),
              decoration: _inputDecoration(
                label: 'Nome',
                hint: 'Nome do cliente',
                icon: Icons.person_outline_rounded,
              ),
              onSubmitted: (_) async {
                final nome = nomeCtrl.text.trim();

                if (nome.isEmpty) return;

                await _salvarCliente(
                  dialogContext,
                  nome: nome,
                  telefone: telefoneCtrl.text.trim(),
                  arquiteto: arquitetoCtrl.text.trim(),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                  color: _softText,
                ),
              ),
            ),
            FilledButton(
              onPressed: () async {
                final nome = nomeCtrl.text.trim();

                if (nome.isEmpty) return;

                await _salvarCliente(
                  dialogContext,
                  nome: nome,
                  telefone: telefoneCtrl.text.trim(),
                  arquiteto: arquitetoCtrl.text.trim(),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _darkBrown,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Salvar',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    nomeCtrl.dispose();
    telefoneCtrl.dispose();
    arquitetoCtrl.dispose();
  }

  Future<void> _salvarCliente(
    BuildContext dialogContext, {
    required String nome,
    required String telefone,
    required String arquiteto,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('clientes').add({
        'nome': nome,
        'telefone': telefone,
        'arquiteto': arquiteto,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cliente "$nome" adicionado.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao adicionar cliente: $e',
            ),
          ),
        );
      }
    }
  }

  // =====================================================
  //                       DELETE
  // =====================================================

  Future<bool> _confirmarRemocao(
    BuildContext context,
    String nome,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Remover cliente',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          content: Text(
            'Deseja remover o cliente "$nome"? Isso apagará todos os orçamentos dele.',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              height: 1.4,
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: _softText,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Remover',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _removerCliente(
    DocumentSnapshot cliente,
    String nome,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('clientes')
          .doc(cliente.id)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cliente "$nome" removido.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao remover cliente: $e',
          ),
        ),
      );
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
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          'Clientes',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ),

      // ===================================================
      //                         FAB
      // ===================================================

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _abrirDialogNovoCliente(context);
        },
        tooltip: 'Adicionar cliente',
        elevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: _darkBrown,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Icon(
          Icons.add_rounded,
          size: 28,
        ),
      ),

      // ===================================================
      //                         BODY
      // ===================================================

      body: Column(
        children: [
          // =================================================
          //                       SEARCH
          // =================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              20,
              24,
              8,
            ),
            child: TextField(
              controller: _searchController,
              cursorColor: _brown,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                hintStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: _softText,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _softText,
                  size: 21,
                ),
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: _searchController.clear,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _softText,
                          size: 19,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
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
              ),
            ),
          ),

          // =================================================
          //                    CLIENT LIST
          // =================================================

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('clientes')
                  .orderBy(
                    'createdAt',
                    descending: true,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                // -------------------------------------------
                // ERROR
                // -------------------------------------------

                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Erro ao carregar clientes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                }

                // -------------------------------------------
                // LOADING
                // -------------------------------------------

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _brown,
                    ),
                  );
                }

                final allDocs =
                    snapshot.data?.docs.toList() ?? [];

                // -------------------------------------------
                // FILTER
                // -------------------------------------------

                final filteredDocs = allDocs.where((doc) {
                  final data =
                      doc.data() as Map<String, dynamic>? ?? {};

                  final nome =
                      data['nome']?.toString().toLowerCase() ?? '';

                  if (_searchTerm.isEmpty) {
                    return true;
                  }

                  return nome.contains(_searchTerm);
                }).toList();

                // -------------------------------------------
                // EMPTY
                // -------------------------------------------

                if (filteredDocs.isEmpty) {
                  return _buildEmptyState();
                }

                // -------------------------------------------
                // LIST
                // -------------------------------------------

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    12,
                    24,
                    100,
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final cliente = filteredDocs[index];

                    final data =
                        cliente.data()
                            as Map<String, dynamic>? ??
                        {};

                    final nome =
                        data['nome']?.toString() ?? '';

                    final telefone =
                        data['telefone']?.toString() ?? '';

                    final arquiteto =
                        data['arquiteto']?.toString() ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: Dismissible(
                        key: ValueKey(cliente.id),
                        direction:
                            DismissDirection.endToStart,

                        // -----------------------------------
                        // DELETE BACKGROUND
                        // -----------------------------------

                        background: Container(
                          alignment: Alignment.centerRight,
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 22,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 23,
                          ),
                        ),

                        // -----------------------------------
                        // CONFIRM DELETE
                        // -----------------------------------

                        confirmDismiss: (_) {
                          return _confirmarRemocao(
                            context,
                            nome,
                          );
                        },

                        // -----------------------------------
                        // DELETE
                        // -----------------------------------

                        onDismissed: (_) async {
                          await _removerCliente(
                            cliente,
                            nome,
                          );
                        },

                        // -----------------------------------
                        // CLIENT CARD
                        // -----------------------------------

                        child: _buildClientCard(
                          context,
                          clienteId: cliente.id,
                          nome: nome,
                          telefone: telefone,
                          arquiteto: arquiteto,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  //                     CLIENT CARD
  // =====================================================

  Widget _buildClientCard(
    BuildContext context, {
    required String clienteId,
    required String nome,
    required String telefone,
    required String arquiteto,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor: _softBrown,
        highlightColor: _softBrown.withValues(alpha: 0.45),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrcamentosClientePage(
                clienteId: clienteId,
                clienteNome: nome,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _border,
            ),
          ),
          child: Row(
            children: [
              // ---------------------------------------------
              // ICON
              // ---------------------------------------------

              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _softBrown,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: _darkBrown,
                  size: 22,
                ),
              ),

              const SizedBox(width: 14),

              // ---------------------------------------------
              // INFORMATION
              // ---------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome.isEmpty
                          ? 'Cliente sem nome'
                          : nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),

                    if (arquiteto.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.architecture_outlined,
                            size: 15,
                            color: _softText,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Arquiteto: $arquiteto',
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12.5,
                                fontWeight:
                                    FontWeight.w500,
                                color: _softText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (telefone.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: _softText,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              telefone,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12.5,
                                fontWeight:
                                    FontWeight.w500,
                                color: _softText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ---------------------------------------------
              // ARROW
              // ---------------------------------------------

              const Icon(
                Icons.chevron_right_rounded,
                color: _softText,
                size: 23,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  //                       EMPTY
  // =====================================================

  Widget _buildEmptyState() {
    final searching = _searchTerm.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _softBrown,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                searching
                    ? Icons.search_off_rounded
                    : Icons.people_outline_rounded,
                color: _darkBrown,
                size: 29,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              searching
                  ? 'Nenhum cliente encontrado'
                  : 'Nenhum cliente cadastrado',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              searching
                  ? 'Tente buscar por outro nome.'
                  : 'Adicione seu primeiro cliente usando o botão +.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                height: 1.4,
                color: _softText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  //                    INPUT STYLE
  // =====================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        fontFamily: 'Nunito',
        color: _softText,
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Nunito',
        color: _softText,
      ),
      prefixIcon: Icon(
        icon,
        color: _softText,
        size: 21,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
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
    );
  }
}