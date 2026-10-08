part of '../itens_page.dart';

// =====================================================
//                   MADEIRA MACIÇA
// =====================================================

class _ItensMadeiraMacicaView extends StatefulWidget {
  const _ItensMadeiraMacicaView();

  @override
  State<_ItensMadeiraMacicaView> createState() =>
      _ItensMadeiraMacicaViewState();
}

class _ItensMadeiraMacicaViewState
    extends State<_ItensMadeiraMacicaView> {
  final TextEditingController _searchController = TextEditingController();

  String _searchTerm = '';

  static const Color _brown = Color(0xFF79533B);
  static const Color _darkBrown = Color(0xFF5A3825);
  static const Color _border = Color(0xFFE8E3DF);
  static const Color _softText = Color(0xFF77716D);

  // =====================================================
  //                       HELPERS
  // =====================================================

  double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().replaceAll(',', '.'),
    );
  }

  String _formatPrecoM3(dynamic value) {
    final preco = _toDouble(value);

    if (preco == null) {
      return '-';
    }

    return 'R\$ ${preco.toStringAsFixed(2)}/m³';
  }

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
  //                       DELETE
  // =====================================================

  Future<bool> _confirmDelete(
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
            'Remover item',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          content: Text(
            'Deseja remover o item "$nome"?',
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
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
                Navigator.pop(dialogContext, true);
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

  // =====================================================
  //                       ADD
  // =====================================================

  Future<void> _showAddDialog(BuildContext context) async {
    final nameController = TextEditingController();

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
            'Novo item',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            cursorColor: _brown,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: Colors.black,
            ),
            decoration: InputDecoration(
              labelText: 'Nome do item',
              hintText: 'Ex: Madeira X',
              labelStyle: const TextStyle(
                fontFamily: 'Nunito',
                color: _softText,
              ),
              hintStyle: const TextStyle(
                fontFamily: 'Nunito',
                color: _softText,
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
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: _softText,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _darkBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final nome = nameController.text.trim();

                if (nome.isEmpty) {
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('items')
                      .add({
                    'name': nome,
                    'unitType': 'madeiraMacica',
                    'subcategory': null,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Item "$nome" adicionado com sucesso.',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Erro ao salvar item: $e',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Adicionar',
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

    nameController.dispose();
  }

  // =====================================================
  //                       EDIT
  // =====================================================

  Future<void> _showEditDialog(
    BuildContext context,
    DocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final nome = data['name']?.toString() ?? '(sem nome)';

    final precoController = TextEditingController(
      text: data['precoM3']?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            nome,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          content: TextField(
            controller: precoController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            cursorColor: _brown,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: Colors.black,
            ),
            decoration: InputDecoration(
              labelText: 'Preço por m³ (R\$)',
              hintText: 'Ex: 2500.00',
              labelStyle: const TextStyle(
                fontFamily: 'Nunito',
                color: _softText,
              ),
              hintStyle: const TextStyle(
                fontFamily: 'Nunito',
                color: _softText,
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
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: _softText,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _darkBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final preco = _toDouble(
                  precoController.text.trim(),
                );

                try {
                  await doc.reference.update({
                    'precoM3': preco,
                  });

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Preço atualizado para "$nome".',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Erro ao salvar dados do item: $e',
                        ),
                      ),
                    );
                  }
                }
              },
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

    precoController.dispose();
  }

  // =====================================================
  //                       BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('items')
        .where(
          'unitType',
          isEqualTo: 'madeiraMacica',
        );

    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          // ---------------- SEARCH ----------------

          Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              24,
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
                hintText: 'Buscar item...',
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
                        onPressed: () {
                          _searchController.clear();
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 19,
                          color: _softText,
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

          // ---------------- ITEMS ----------------

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar itens:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: Colors.red,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _brown,
                    ),
                  );
                }

                final docs = snapshot.data?.docs.toList() ?? [];

                docs.sort((a, b) {
                  final dataA =
                      a.data() as Map<String, dynamic>? ?? {};

                  final dataB =
                      b.data() as Map<String, dynamic>? ?? {};

                  final nomeA =
                      dataA['name']?.toString().toLowerCase() ?? '';

                  final nomeB =
                      dataB['name']?.toString().toLowerCase() ?? '';

                  return nomeA.compareTo(nomeB);
                });

                final filteredDocs = docs.where((doc) {
                  final data =
                      doc.data() as Map<String, dynamic>? ?? {};

                  final nome =
                      data['name']?.toString().toLowerCase() ?? '';

                  if (_searchTerm.isEmpty) {
                    return true;
                  }

                  return nome.contains(_searchTerm);
                }).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    16,
                    24,
                    40,
                  ),
                  children: [
                    // ---------------- HEADER ----------------

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Madeira Maciça',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _showAddDialog(context);
                          },
                          tooltip: 'Adicionar item',
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            color: _darkBrown,
                            size: 25,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ---------------- EMPTY ----------------

                    if (filteredDocs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 30,
                        ),
                        child: Center(
                          child: Text(
                            'Nenhum item encontrado.',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              color: _softText,
                            ),
                          ),
                        ),
                      ),

                    // ---------------- CARDS ----------------

                    for (final doc in filteredDocs)
                      _buildItemCard(
                        context,
                        doc,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  //                       ITEM CARD
  // =====================================================

  Widget _buildItemCard(
    BuildContext context,
    DocumentSnapshot doc,
  ) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final nome = data['name']?.toString() ?? '(sem nome)';

    final precoText = _formatPrecoM3(
      data['precoM3'],
    );

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Dismissible(
        key: ValueKey(doc.id),
        direction: DismissDirection.endToStart,

        // ---------------- DELETE BACKGROUND ----------------

        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
          ),
        ),

        // ---------------- CONFIRM DELETE ----------------

        confirmDismiss: (_) {
          return _confirmDelete(
            context,
            nome,
          );
        },

        // ---------------- DELETE ----------------

        onDismissed: (_) async {
          try {
            await doc.reference.delete();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Item "$nome" removido.',
                  ),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Erro ao remover item "$nome": $e',
                  ),
                ),
              );
            }
          }
        },

        // ---------------- CARD ----------------

        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              _showEditDialog(
                context,
                doc,
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _border,
                ),
              ),
              child: Row(
                children: [
                  // ICON

                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4EEEA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.forest_outlined,
                      color: _darkBrown,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // INFORMATION

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          precoText,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _softText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _softText,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}