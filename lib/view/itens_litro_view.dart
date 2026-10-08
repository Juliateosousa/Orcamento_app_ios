part of '../itens_page.dart';

// =====================================================
//                       LITRO
// =====================================================

class _ItensLitroView extends StatefulWidget {
  const _ItensLitroView();

  @override
  State<_ItensLitroView> createState() => _ItensLitroViewState();
}

class _ItensLitroViewState extends State<_ItensLitroView> {
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
                  borderSide: const BorderSide(color: _border),
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
                _TintasSection(searchTerm: _searchTerm),
                _VernizSection(searchTerm: _searchTerm),
                _ColasSection(searchTerm: _searchTerm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------ TINTAS ------------

class _TintasSection extends StatelessWidget {
  final String searchTerm;

  const _TintasSection({required this.searchTerm});

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String _formatPrecoM2(dynamic v) {
    final d = _toDouble(v);
    if (d == null) return "-";
    return "R\$ ${d.toStringAsFixed(2)} / m²";
  }

  Future<void> _showAddItemDialog(BuildContext context) async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text("Nova Tinta"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Nome da tinta",
            hintText: "Ex: Pintura a Laca",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text(
              "Salvar",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('items').add({
        'name': name,
        'unitType': 'litro',
        'subcategory': 'tintas',
        'precoM2': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tinta "$name" adicionada.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar tinta: $e')),
      );
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    DocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final nome = data['name'] as String? ?? "(sem nome)";
    final controller = TextEditingController(
      text: data['precoM2']?.toString() ?? "",
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(nome),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Preço por m² (R\$)",
            hintText: "Ex: 150.00",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              double? parse(String t) =>
                  double.tryParse(t.replaceAll(',', '.'));

              final preco = parse(controller.text.trim());

              try {
                await doc.reference.update({'precoM2': preco});
                // ignore: use_build_context_synchronously
                Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Preço atualizado para "$nome".'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text("Erro ao salvar preço da tinta: $e"),
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Salvar",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String nome) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
            title: const Text("Remover tinta"),
            content: Text('Deseja remover a tinta "$nome"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Remover",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('items')
        .where('unitType', isEqualTo: 'litro')
        .where('subcategory', isEqualTo: 'tintas');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Tintas",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showAddItemDialog(context),
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF5A3825)),
              tooltip: "Adicionar tinta",
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                "Erro ao carregar tintas: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                "Carregando tintas...",
                style: TextStyle(color: Colors.grey),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text(
                "Nenhuma tinta cadastrada ainda.",
                style: TextStyle(color: Colors.grey),
              );
            }

            final docs = snapshot.data!.docs.toList()
              ..sort((a, b) {
                final da = (a.data() as Map<String, dynamic>? ?? {});
                final db = (b.data() as Map<String, dynamic>? ?? {});
                final na = (da['name'] ?? '') as String;
                final nb = (db['name'] ?? '') as String;
                return na.toLowerCase().compareTo(nb.toLowerCase());
              });

            final filteredDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final nome = (data['name'] ?? '') as String;
              if (searchTerm.isEmpty) return true;
              return nome.toLowerCase().contains(searchTerm);
            }).toList();

            return Column(
              children: [
                for (final doc in filteredDocs) ...[
                  Builder(
                    builder: (ctx) {
                      final data =
                          doc.data() as Map<String, dynamic>? ?? {};
                      final nome = data['name'] as String? ?? "(sem nome)";
                      final preco = _formatPrecoM2(data['precoM2']);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Dismissible(
                          key: ValueKey(doc.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            color: Colors.red.withValues(alpha: 0.8),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) =>
                              _confirmDelete(context, nome),
                          onDismissed: (direction) async {
                            try {
                              await doc.reference.delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Tinta "$nome" removida.'),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text("Erro ao remover tinta: $e"),
                                ),
                              );
                            }
                          },
                          child: _LitroItemRowCard(
                            nome: nome,
                            label: "Preço por m²",
                            value: preco,
                            onTap: () => _showEditDialog(context, doc),
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
        const SizedBox(height: 16),
      ],
    );
  }
}

// ------------ VERNIZ ------------

class _VernizSection extends StatelessWidget {
  final String searchTerm;

  const _VernizSection({required this.searchTerm});

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String _formatPrecoM2(dynamic v) {
    final d = _toDouble(v);
    if (d == null) return "-";
    return "R\$ ${d.toStringAsFixed(2)} / m²";
  }

  Future<void> _showAddItemDialog(BuildContext context) async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text("Novo Verniz"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Nome do verniz",
            hintText: "Ex: Verniz PU",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text(
              "Salvar",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('items').add({
        'name': name,
        'unitType': 'litro',
        'subcategory': 'verniz',
        'precoM2': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verniz "$name" adicionada.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar verniz: $e')),
      );
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    DocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final nome = data['name'] as String? ?? "(sem nome)";
    final controller = TextEditingController(
      text: data['precoM2']?.toString() ?? "",
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(nome),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Preço por m² (R\$)",
            hintText: "Ex: 150.00",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              double? parse(String t) =>
                  double.tryParse(t.replaceAll(',', '.'));

              final preco = parse(controller.text.trim());

              try {
                await doc.reference.update({'precoM2': preco});
                // ignore: use_build_context_synchronously
                Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Preço atualizado para "$nome".'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text("Erro ao salvar preço do verniz: $e"),
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Salvar",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String nome) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
            title: const Text("Remover verniz"),
            content: Text('Deseja remover o verniz "$nome"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Remover",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('items')
        .where('unitType', isEqualTo: 'litro')
        .where('subcategory', isEqualTo: 'verniz');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Verniz",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showAddItemDialog(context),
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF5A3825)),
              tooltip: "Adicionar verniz",
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                "Erro ao carregar vernizes: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                "Carregando vernizes...",
                style: TextStyle(color: Colors.grey),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text(
                "Nenhum verniz cadastrado ainda.",
                style: TextStyle(color: Colors.grey),
              );
            }

            final docs = snapshot.data!.docs.toList()
              ..sort((a, b) {
                final da = (a.data() as Map<String, dynamic>? ?? {});
                final db = (b.data() as Map<String, dynamic>? ?? {});
                final na = (da['name'] ?? '') as String;
                final nb = (db['name'] ?? '') as String;
                return na.toLowerCase().compareTo(nb.toLowerCase());
              });

            final filteredDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final nome = (data['name'] ?? '') as String;
              if (searchTerm.isEmpty) return true;
              return nome.toLowerCase().contains(searchTerm);
            }).toList();

            return Column(
              children: [
                for (final doc in filteredDocs) ...[
                  Builder(
                    builder: (ctx) {
                      final data =
                          doc.data() as Map<String, dynamic>? ?? {};
                      final nome = data['name'] as String? ?? "(sem nome)";
                      final preco = _formatPrecoM2(data['precoM2']);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Dismissible(
                          key: ValueKey(doc.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            color: Colors.red.withValues(alpha: 0.8),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) =>
                              _confirmDelete(context, nome),
                          onDismissed: (direction) async {
                            try {
                              await doc.reference.delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Verniz "$nome" removido.'),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text("Erro ao remover verniz: $e"),
                                ),
                              );
                            }
                          },
                          child: _LitroItemRowCard(
                            nome: nome,
                            label: "Preço por m²",
                            value: preco,
                            onTap: () => _showEditDialog(context, doc),
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
        const SizedBox(height: 16),
      ],
    );
  }
}

// ------------ COLAS (COM CHECKBOXES) ------------

class _ColasSection extends StatelessWidget {
  final String searchTerm;

  const _ColasSection({required this.searchTerm});

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String _formatPrecoL(dynamic v) {
    final d = _toDouble(v);
    if (d == null) return "-";
    return "R\$ ${d.toStringAsFixed(2)} / L";
  }

  String _formatLm2(dynamic v) {
    final d = _toDouble(v);
    if (d == null) return "-";
    return "${d.toStringAsPrecision(3)} L/m²";
  }

  Future<void> _showAddColaDialog(BuildContext context) async {
    final nameController = TextEditingController();
    bool hasPrecoL = true;
    bool hasLm2 = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
              title: const Text("Nova Cola"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Nome da cola",
                      hintText: "Ex: Cola Branca, Cola Formica...",
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: hasPrecoL,
                    onChanged: (v) {
                      setState(() {
                        hasPrecoL = v ?? false;
                      });
                    },
                    title: const Text("Usar Preço por L"),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: hasLm2,
                    onChanged: (v) {
                      setState(() {
                        hasLm2 = v ?? false;
                      });
                    },
                    title: const Text("Usar L/m²"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty || (!hasPrecoL && !hasLm2)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Informe um nome e marque pelo menos uma opção.",
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx, {
                      'name': name,
                      'hasPrecoL': hasPrecoL,
                      'hasLm2': hasLm2,
                    });
                  },
                  child: const Text(
                    "Salvar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final String name = result['name'] as String;
    final bool selectedPrecoL = result['hasPrecoL'] as bool;
    final bool selectedLm2 = result['hasLm2'] as bool;

    try {
      await FirebaseFirestore.instance.collection('items').add({
        'name': name,
        'unitType': 'litro',
        'subcategory': 'colas',
        'hasPrecoL': selectedPrecoL,
        'hasLm2': selectedLm2,
        'precoL': null,
        'lm2': null,
        'usaLm2Separado': false, // 👈 NOVO
        'lm2Mdf': null, // 👈 NOVO
        'lm2Formica': null, // 👈 NOVO
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cola "$name" adicionada.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar cola: $e')),
      );
    }
  }

  Future<void> _showEditColaDialog(
    BuildContext context,
    DocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = data['name'] as String? ?? "(sem nome)";

    final bool hasPrecoL = (data['hasPrecoL'] as bool?) ?? false;
    final bool hasLm2 = (data['hasLm2'] as bool?) ?? false;

    final isColaFormica = name.toLowerCase() == 'cola formica';

    final precoLController = TextEditingController(
      text: data['precoL']?.toString() ?? "",
    );
    final lm2Controller = TextEditingController(
      text: data['lm2']?.toString() ?? "",
    );

    bool usaLm2Separado = (data['usaLm2Separado'] as bool?) ?? false;
    final lm2MdfController = TextEditingController(
      text: data['lm2Mdf']?.toString() ?? "",
    );
    final lm2FormicaController = TextEditingController(
      text: data['lm2Formica']?.toString() ?? "",
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
              title: Text(name),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasPrecoL) ...[
                      TextField(
                        controller: precoLController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: "Preço por L (R\$)",
                          hintText: "Ex: 45.90",
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (hasLm2) ...[
                      if (isColaFormica) ...[
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: usaLm2Separado,
                          onChanged: (v) {
                            setState(() {
                              usaLm2Separado = v ?? false;
                            });
                          },
                          title: const Text(
                            "Usar L/m² separado para MDF e Formica",
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (usaLm2Separado) ...[
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  "L/m² (MDF):",
                                  textAlign: TextAlign.right,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 90,
                                child: TextField(
                                  controller: lm2MdfController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 8,
                                    ),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  "L/m² (Formica):",
                                  textAlign: TextAlign.right,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 90,
                                child: TextField(
                                  controller: lm2FormicaController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 8,
                                    ),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          TextField(
                            controller: lm2Controller,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: const InputDecoration(
                              labelText: "L/m²",
                              hintText:
                                  "Ex: 0.7 (por exemplo 3.5L / 5.03m² ≈ 0.696)",
                            ),
                          ),
                        ],
                      ] else ...[
                        TextField(
                          controller: lm2Controller,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: const InputDecoration(
                            labelText: "L/m²",
                            hintText:
                                "Ex: 0.7 (por exemplo 3.5L / 5.03m² ≈ 0.696)",
                          ),
                        ),
                      ],
                    ],
                    if (!hasPrecoL && !hasLm2) ...[
                      const SizedBox(height: 8),
                      const Text(
                        "Este item não foi configurado com Preço/L nem L/m².",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () async {
                    double? parse(String text) =>
                        double.tryParse(text.replaceAll(',', '.'));

                    final precoL = hasPrecoL
                        ? parse(precoLController.text.trim())
                        : null;

                    double? lm2;
                    double? lm2Mdf;
                    double? lm2Formica;

                    bool finalUsaLm2Separado = false;

                    if (hasLm2) {
                      if (isColaFormica && usaLm2Separado) {
                        lm2Mdf = parse(lm2MdfController.text.trim());
                        lm2Formica =
                            parse(lm2FormicaController.text.trim());
                        lm2 = null;
                        finalUsaLm2Separado = true;
                      } else {
                        lm2 = parse(lm2Controller.text.trim());
                        lm2Mdf = null;
                        lm2Formica = null;
                        finalUsaLm2Separado = false;
                      }
                    }

                    try {
                      await doc.reference.update({
                        'precoL': precoL,
                        'lm2': lm2,
                        'usaLm2Separado': finalUsaLm2Separado,
                        'lm2Mdf': lm2Mdf,
                        'lm2Formica': lm2Formica,
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Dados atualizados para "$name".'),
                          ),
                        );
                      }
                      // ignore: use_build_context_synchronously
                      Navigator.pop(ctx);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Erro ao salvar dados da cola: $e"),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    "Salvar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String nome) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
            title: const Text("Remover cola"),
            content: Text('Deseja remover a cola "$nome"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Remover",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('items')
        .where('unitType', isEqualTo: 'litro')
        .where('subcategory', isEqualTo: 'colas');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Colas",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showAddColaDialog(context),
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF5A3825)),
              tooltip: "Adicionar cola",
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                "Erro ao carregar colas: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                "Carregando colas...",
                style: TextStyle(color: Colors.grey),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text(
                "Nenhuma cola cadastrada ainda.",
                style: TextStyle(color: Colors.grey),
              );
            }

            final docs = snapshot.data!.docs.toList()
              ..sort((a, b) {
                final da = (a.data() as Map<String, dynamic>? ?? {});
                final db = (b.data() as Map<String, dynamic>? ?? {});
                final na = (da['name'] ?? '') as String;
                final nb = (db['name'] ?? '') as String;
                return na.toLowerCase().compareTo(nb.toLowerCase());
              });

            final filteredDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final nome = (data['name'] ?? '') as String;
              if (searchTerm.isEmpty) return true;
              return nome.toLowerCase().contains(searchTerm);
            }).toList();

            return Column(
              children: [
                for (final doc in filteredDocs) ...[
                  Builder(
                    builder: (ctx) {
                      final data =
                          doc.data() as Map<String, dynamic>? ?? {};
                      final nome = data['name'] as String? ?? "(sem nome)";
                      final hasPrecoL =
                          (data['hasPrecoL'] as bool?) ?? false;
                      final hasLm2 =
                          (data['hasLm2'] as bool?) ?? false;

                      final precoLText =
                          hasPrecoL ? _formatPrecoL(data['precoL']) : "-";

                      String lm2Text = "-";
                      if (hasLm2) {
                        final nomeLower = nome.toLowerCase();
                        if (nomeLower == 'cola formica') {
                          final lm2Mdf = _toDouble(data['lm2Mdf']);
                          final lm2Formica =
                              _toDouble(data['lm2Formica']);
                          final usaSeparado =
                              data['usaLm2Separado'] == true;

                          if (usaSeparado &&
                              (lm2Mdf != null || lm2Formica != null)) {
                            final mdfStr = lm2Mdf != null
                                ? "${lm2Mdf.toStringAsPrecision(3)} MDF"
                                : "";
                            final formStr = lm2Formica != null
                                ? "${lm2Formica.toStringAsPrecision(3)} Formica"
                                : "";
                            lm2Text = [mdfStr, formStr]
                                .where((s) => s.isNotEmpty)
                                .join(" / ");
                          } else {
                            lm2Text = _formatLm2(data['lm2']);
                          }
                        } else {
                          lm2Text = _formatLm2(data['lm2']);
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Dismissible(
                          key: ValueKey(doc.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            color: Colors.red.withValues(alpha: 0.8),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) =>
                              _confirmDelete(context, nome),
                          onDismissed: (direction) async {
                            try {
                              await doc.reference.delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Cola "$nome" removida.'),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text("Erro ao remover cola: $e"),
                                ),
                              );
                            }
                          },
                          child: _ColaItemRowCard(
                            nome: nome,
                            hasPrecoL: hasPrecoL,
                            hasLm2: hasLm2,
                            precoLText: precoLText,
                            lm2Text: lm2Text,
                            onTap: () => _showEditColaDialog(
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
        const SizedBox(height: 16),
      ],
    );
  }
}
