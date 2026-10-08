part of '../itens_page.dart';

// =====================================================
//                       FOLHA
// =====================================================

class _ItensFolhaView extends StatefulWidget {
  const _ItensFolhaView();

  @override
  State<_ItensFolhaView> createState() => _ItensFolhaViewState();
}

class _ItensFolhaViewState extends State<_ItensFolhaView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = "";

  static const Color _brown = Color(0xFF79533B);
  static const Color _border = Color(0xFFE8E3DF);
  static const Color _softText = Color(0xFF77716D);

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          // =====================================================
          // SEARCH
          // =====================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
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
                hintText: 'Buscar folha...',
                hintStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _softText,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _softText,
                  size: 21,
                ),

                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                        onPressed: _searchController.clear,
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
                    width: 1,
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

          // =====================================================
          // CONTENT
          // =====================================================

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              children: [
                _FolhaCategoriaSection(
                  title: 'Compensado',
                  subcategoryKey: 'compensado',
                  searchTerm: _searchTerm,
                ),

                _FolhaCategoriaSection(
                  title: 'Formica',
                  subcategoryKey: 'formica',
                  searchTerm: _searchTerm,
                ),

                _FolhaCategoriaSection(
                  title: 'MDF',
                  subcategoryKey: 'mdf',
                  searchTerm: _searchTerm,
                ),

                _FolhaCategoriaSection(
                  title: 'Lâmina',
                  subcategoryKey: 'lamina',
                  searchTerm: _searchTerm,
                ),

                _FolhaCategoriaSection(
                  title: 'Manta',
                  subcategoryKey: 'manta',
                  searchTerm: _searchTerm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
//                  CATEGORIA FOLHA
// =====================================================

class _FolhaCategoriaSection extends StatelessWidget {
  final String title;
  final String subcategoryKey;
  final String searchTerm;

  const _FolhaCategoriaSection({
    required this.title,
    required this.subcategoryKey,
    required this.searchTerm,
  });

  static const Color _brown = Color(0xFF79533B);
  static const Color _darkBrown = Color(0xFF5A3825);
  static const Color _border = Color(0xFFE8E3DF);
  static const Color _softText = Color(0xFF77716D);

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String _formatPreco(dynamic v) {
    final d = _toDouble(v);

    if (d == null) {
      return '-';
    }

    return 'R\$ ${d.toStringAsFixed(2)}';
  }

  String _formatArea(dynamic v) {
    final d = _toDouble(v);

    if (d == null) {
      return '-';
    }

    return '${d.toStringAsFixed(2)} m²';
  }

  String _formatPerda(dynamic v) {
    final d = _toDouble(v);

    if (d == null) {
      return '-';
    }

    return '${d.toStringAsFixed(1)}%';
  }

  // =====================================================
  // ADD ITEM
  // =====================================================

  Future<void> _showAddItemDialog(BuildContext context) async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          titlePadding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            8,
          ),

          contentPadding: const EdgeInsets.fromLTRB(
            24,
            12,
            24,
            8,
          ),

          actionsPadding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16,
          ),

          title: Text(
            'Novo item em $title',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),

          content: TextField(
            controller: controller,
            autofocus: true,
            cursorColor: _brown,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: 'Nome do item',
              hintText: 'Ex: MDF 18mm 2 Faces Ultra',

              labelStyle: const TextStyle(
                fontFamily: 'Nunito',
                color: _softText,
              ),

              filled: true,
              fillColor: Colors.white,

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _border,
                ),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _brown,
                  width: 1.5,
                ),
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: _softText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            FilledButton(
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
              onPressed: () {
                Navigator.pop(
                  ctx,
                  controller.text.trim(),
                );
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

    if (name == null || name.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('items').add({
        'name': name,
        'unitType': 'folha',
        'subcategory': subcategoryKey,
        'precoFolha': null,
        'areaFolha': null,
        'taxaPerca': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Item "$name" adicionado em $title',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao salvar item: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // EDIT ITEM
  // =====================================================

  Future<void> _showEditDialog(
    BuildContext context,
    DocumentSnapshot doc,
  ) async {
    final data =
        doc.data() as Map<String, dynamic>? ?? {};

    final precoController = TextEditingController(
      text: data['precoFolha']?.toString() ?? '',
    );

    final areaController = TextEditingController(
      text: data['areaFolha']?.toString() ?? '',
    );

    final perdaController = TextEditingController(
      text: data['taxaPerca']?.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          titlePadding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            8,
          ),

          contentPadding: const EdgeInsets.fromLTRB(
            24,
            12,
            24,
            8,
          ),

          actionsPadding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16,
          ),

          title: Text(
            data['name'] ?? 'Item',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),

          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(
                    controller: precoController,
                    label: 'Preço da folha (R\$)',
                    hint: 'Ex: 350.00',
                  ),

                  const SizedBox(height: 14),

                  _dialogField(
                    controller: areaController,
                    label: 'Área da folha (m²)',
                    hint: 'Ex: 2.80',
                  ),

                  const SizedBox(height: 14),

                  _dialogField(
                    controller: perdaController,
                    label: 'Taxa de perda (%)',
                    hint: 'Ex: 10',
                  ),
                ],
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: _softText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _darkBrown,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              onPressed: () async {
                double? parse(String text) {
                  return double.tryParse(
                    text.replaceAll(',', '.'),
                  );
                }

                final preco =
                    parse(precoController.text);

                final area =
                    parse(areaController.text);

                final perda =
                    parse(perdaController.text);

                try {
                  await doc.reference.update({
                    'precoFolha': preco,
                    'areaFolha': area,
                    'taxaPerca': perda,
                  });

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                } catch (e) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erro ao salvar: $e',
                      ),
                    ),
                  );
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
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      cursorColor: _brown,

      style: const TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w500,
      ),

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        labelStyle: const TextStyle(
          fontFamily: 'Nunito',
          color: _softText,
        ),

        filled: true,
        fillColor: Colors.white,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: _border,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: _brown,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // =====================================================
  // DELETE
  // =====================================================

  Future<bool> _confirmDelete(
    BuildContext context,
    String nome,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) {
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
                ),
              ),

              content: Text(
                'Deseja remover o item "$nome"?',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(ctx, false),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: _softText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                TextButton(
                  onPressed: () =>
                      Navigator.pop(ctx, true),
                  child: const Text(
                    'Remover',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Color(0xFFB3261E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // =====================================================
  // BUILD CATEGORY
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('items')
        .where(
          'unitType',
          isEqualTo: 'folha',
        )
        .where(
          'subcategory',
          isEqualTo: subcategoryKey,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =====================================================
          // CATEGORY HEADER
          // =====================================================

          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      _showAddItemDialog(context),

                  borderRadius:
                      BorderRadius.circular(10),

                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),

                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(10),

                      border: Border.all(
                        color: _border,
                      ),
                    ),

                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: _darkBrown,
                        ),

                        SizedBox(width: 5),

                        Text(
                          'Adicionar',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w700,
                            color: _darkBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // =====================================================
          // ITEMS
          // =====================================================

          StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  child: Text(
                    'Erro ao carregar: ${snapshot.error}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Color(0xFFB3261E),
                    ),
                  ),
                );
              }

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _brown,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Carregando...',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: _softText,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 10,
                  ),
                  child: Text(
                    'Nenhum item cadastrado ainda.',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      color: _softText,
                    ),
                  ),
                );
              }

              final docs =
                  snapshot.data!.docs.toList()
                    ..sort((a, b) {
                      final da =
                          a.data()
                                  as Map<String, dynamic>? ??
                              {};

                      final db =
                          b.data()
                                  as Map<String, dynamic>? ??
                              {};

                      final na =
                          (da['name'] ?? '') as String;

                      final nb =
                          (db['name'] ?? '') as String;

                      return na
                          .toLowerCase()
                          .compareTo(
                            nb.toLowerCase(),
                          );
                    });

              final filteredDocs =
                  docs.where((doc) {
                final data =
                    doc.data()
                            as Map<String, dynamic>? ??
                        {};

                final nome =
                    (data['name'] ?? '') as String;

                if (searchTerm.isEmpty) {
                  return true;
                }

                return nome
                    .toLowerCase()
                    .contains(searchTerm);
              }).toList();

              if (filteredDocs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 10,
                  ),
                  child: Text(
                    'Nenhum resultado encontrado.',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      color: _softText,
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  for (final doc
                      in filteredDocs) ...[
                    Builder(
                      builder: (ctx) {
                        final data =
                            doc.data()
                                    as Map<String,
                                        dynamic>? ??
                                {};

                        final nome =
                            data['name']
                                    as String? ??
                                '(sem nome)';

                        final preco =
                            _formatPreco(
                          data['precoFolha'],
                        );

                        final area =
                            _formatArea(
                          data['areaFolha'],
                        );

                        final perda =
                            _formatPerda(
                          data['taxaPerca'],
                        );

                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 9,
                          ),

                          child: Dismissible(
                            key: ValueKey(doc.id),

                            direction:
                                DismissDirection
                                    .endToStart,

                            background: Container(
                              alignment:
                                  Alignment.centerRight,

                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 22,
                              ),

                              decoration:
                                  BoxDecoration(
                                color: const Color(
                                  0xFFB3261E,
                                ),

                                borderRadius:
                                    BorderRadius
                                        .circular(14),
                              ),

                              child: const Icon(
                                Icons
                                    .delete_outline_rounded,
                                color: Colors.white,
                              ),
                            ),

                            confirmDismiss:
                                (direction) =>
                                    _confirmDelete(
                              context,
                              nome,
                            ),

                            onDismissed:
                                (direction) async {
                              try {
                                await doc.reference
                                    .delete();

                                if (!context.mounted) {
                                  return;
                                }

                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Item "$nome" removido de $title.',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) {
                                  return;
                                }

                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Erro ao remover item: $e',
                                    ),
                                  ),
                                );
                              }
                            },

                            child:
                                _FolhaItemRowCard(
                              nome: nome,
                              precoText: preco,
                              areaText: area,
                              perdaText: perda,
                              onTap: () =>
                                  _showEditDialog(
                                context,
                                doc,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
