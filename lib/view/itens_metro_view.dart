part of '../itens_page.dart';

// =====================================================
//                         METRO
// =====================================================

class _ItensMetroView extends StatefulWidget {
  const _ItensMetroView();

  @override
  State<_ItensMetroView> createState() => _ItensMetroViewState();
}

class _ItensMetroViewState extends State<_ItensMetroView> {
  final TextEditingController _searchController = TextEditingController();

  String _searchTerm = '';

  static const Color _brown = Color(0xFF79533B);
  static const Color _border = Color(0xFFE8E3DF);
  static const Color _softText = Color(0xFF77716D);

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

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              children: [
                _MetroCategoriaSection(
                  title: 'Fitas',
                  subcategoryKey: 'fita',
                  searchTerm: _searchTerm,
                ),
                _MetroCategoriaSection(
                  title: 'Outros',
                  subcategoryKey: 'outros',
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
//                    METRO CATEGORY
// =====================================================

class _MetroCategoriaSection extends StatelessWidget {
  final String title;
  final String subcategoryKey;
  final String searchTerm;

  const _MetroCategoriaSection({
    required this.title,
    required this.subcategoryKey,
    required this.searchTerm,
  });

  static const Color _brown = Color(0xFF79533B);
  static const Color _darkBrown = Color(0xFF5A3825);
  static const Color _border = Color(0xFFE8E3DF);
  static const Color _softText = Color(0xFF77716D);

  double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().replaceAll(',', '.'),
    );
  }

  String _formatPreco(dynamic value) {
    final preco = _toDouble(value);

    if (preco == null) {
      return '-';
    }

    return 'R\$ ${preco.toStringAsFixed(2)}';
  }

  String _formatMetragem(dynamic value) {
    final metragem = _toDouble(value);

    if (metragem == null) {
      return '-';
    }

    return '${metragem.toStringAsFixed(2)} m';
  }

  // =====================================================
  //                         ADD
  // =====================================================

  Future<void> _showAddItemDialog(
    BuildContext context,
  ) async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Novo item em $title',
            style: const TextStyle(
              fontFamily: 'Nunito',
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
              color: Colors.black,
            ),
            decoration: InputDecoration(
              labelText: 'Nome do item',
              hintText: 'Ex: Fita Tal',
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
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
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

    controller.dispose();

    if (name == null || name.isEmpty) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('items').add({
        'name': name,
        'unitType': 'metro',
        'subcategory': subcategoryKey,
        'precoMetro': null,
        'metragem': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Item "$name" adicionado em $title',
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
  }

  // =====================================================
  //                         EDIT
  // =====================================================

  Future<void> _showEditDialog(
    BuildContext context,
    DocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final nome = data['name']?.toString() ?? '(sem nome)';

    final precoController = TextEditingController(
      text: data['precoMetro']?.toString() ?? '',
    );

    final metragemController = TextEditingController(
      text: data['metragem']?.toString() ?? '',
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: precoController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                cursorColor: _brown,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: 'Preço (R\$)',
                  hintText: 'Ex: 5.90',
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
              const SizedBox(height: 12),
              TextField(
                controller: metragemController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                cursorColor: _brown,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: 'Metragem (m)',
                  hintText: 'Ex: 50',
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
            ],
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
                double? parse(String text) {
                  return double.tryParse(
                    text.replaceAll(',', '.'),
                  );
                }

                final preco = parse(
                  precoController.text.trim(),
                );

                final metragem = parse(
                  metragemController.text.trim(),
                );

                try {
                  await doc.reference.update({
                    'precoMetro': preco,
                    'metragem': metragem,
                  });

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Dados atualizados para "$nome".',
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
    metragemController.dispose();
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
  //                         BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('items')
        .where(
          'unitType',
          isEqualTo: 'metro',
        )
        .where(
          'subcategory',
          isEqualTo: subcategoryKey,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------- HEADER ----------------

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
            IconButton(
              onPressed: () {
                _showAddItemDialog(context);
              },
              tooltip: 'Adicionar item em $title',
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: _darkBrown,
                size: 25,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ---------------- FIRESTORE ----------------

        StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'Erro ao carregar itens: ${snapshot.error}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.red,
                ),
              );
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 20,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    color: _brown,
                  ),
                ),
              );
            }

            if (!snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 8,
                ),
                child: Text(
                  'Nenhum item cadastrado ainda.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: _softText,
                  ),
                ),
              );
            }

            final docs = snapshot.data!.docs.toList();

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

              if (searchTerm.isEmpty) {
                return true;
              }

              return nome.contains(searchTerm);
            }).toList();

            if (filteredDocs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 8,
                ),
                child: Text(
                  'Nenhum item encontrado.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: _softText,
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (final doc in filteredDocs)
                  _buildItemCard(
                    context,
                    doc,
                  ),
              ],
            );
          },
        ),

        const SizedBox(height: 20),
      ],
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

    final nome =
        data['name']?.toString() ?? '(sem nome)';

    final preco = _formatPreco(
      data['precoMetro'],
    );

    final metragem = _formatMetragem(
      data['metragem'],
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

        // ---------------- CONFIRM ----------------

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
                    'Erro ao remover item: $e',
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
                      Icons.straighten_rounded,
                      color: _darkBrown,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // INFO

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
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 14,
                          runSpacing: 4,
                          children: [
                            _info(
                              'Preço',
                              preco,
                            ),
                            _info(
                              'Metragem',
                              metragem,
                            ),
                          ],
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

  Widget _info(
    String label,
    String value,
  ) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: _softText,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}