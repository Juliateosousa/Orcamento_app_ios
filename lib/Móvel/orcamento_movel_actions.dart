part of '../Orçamento Base/orcamento_page.dart';

extension _OrcamentoMovelActionsExtension on _OrcamentoPageState {
  static const Color _dialogDarkBrown = Color(0xFF5A3825);
  static const Color _dialogBrown = Color(0xFF79533B);
  static const Color _dialogSoftBrown = Color(0xFFF4EEEA);
  static const Color _dialogSoftText = Color(0xFF77716D);


Future<void> adicionarMovelArmazenadoEmOrcamento({

  required BuildContext context,

  required String clienteId,

  required DocumentSnapshot modeloDoc,

  required int numeroOrcamentoDestino,

}) async {

  final db = FirebaseFirestore.instance;

  final data = modeloDoc.data() as Map<String, dynamic>? ?? {};

  final nomeMovel = data['nome'] as String? ?? "(sem nome)";

  // 1) Criar um novo móvel na coleção principal "moveis"

  final moveisRef = db.collection('moveis');

  final novoMovelRef = moveisRef.doc();

  final novoData = Map<String, dynamic>.from(data);

  // garante que esse móvel agora pertence ao orçamento de destino

  novoData['numeroOrcamento'] = numeroOrcamentoDestino;

  novoData['createdAt'] = FieldValue.serverTimestamp();

  // campos que só faziam sentido no armazenamento

  novoData.remove('numeroOrcamentoOriginal');

  novoData.remove('armazenadoEm');

  await novoMovelRef.set(novoData);

  // 2) Copiar subcoleção "itens" do modelo para o novo móvel

  final itensSnap = await modeloDoc.reference.collection('itens').get();

  for (final item in itensSnap.docs) {

    await novoMovelRef.collection('itens').add(item.data());

  }

  // 3) Remover o modelo da coleção "moveis_armazenados"

  await modeloDoc.reference.delete();

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(

    SnackBar(

      content: Text(

        'Móvel "$nomeMovel" adicionado ao orçamento Nº $numeroOrcamentoDestino e removido dos móveis armazenados.',

      ),

    ),

  );

}

  Future<void> _guardarMovelComoModelo(

  BuildContext context,

  String clienteId,

  DocumentSnapshot movelDoc,

) async {

  final db = FirebaseFirestore.instance;

  final data = movelDoc.data() as Map<String, dynamic>? ?? {};

  final numeroOrcamentoOriginal = data['numeroOrcamento'];

  final nomeMovel = data['nome'] as String? ?? "(sem nome)";

  // coleção onde vamos guardar os móveis "modelo" desse cliente

  final modelosRef = db

      .collection('clientes')

      .doc(clienteId)

      .collection('moveis_armazenados');

  // novo documento de modelo

  final modeloRef = modelosRef.doc();

  final novoData = Map<String, dynamic>.from(data);

  novoData['numeroOrcamentoOriginal'] = numeroOrcamentoOriginal;

  novoData['armazenadoEm'] = FieldValue.serverTimestamp();

  await modeloRef.set(novoData);

  // copiar subcoleção itens

  final itensSnap = await movelDoc.reference.collection('itens').get();

  for (final item in itensSnap.docs) {

    await modeloRef.collection('itens').add(item.data());

  }

  // agora apaga o móvel original (com itens)

  await _apagarMovelComItens(movelDoc);

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(

    SnackBar(

      content: Text('Móvel "$nomeMovel" foi guardado e removido do orçamento.'),

    ),

  );

}

Future<void> _duplicarMovel(

  BuildContext context,

  DocumentSnapshot movelDoc,

) async {

  final movelData = movelDoc.data() as Map<String, dynamic>? ?? {};

  final nomeAtual = (movelData['nome'] ?? '').toString();

  final nameCtrl = TextEditingController(text: "$nomeAtual (cópia)");

  final String? novoNome = await showDialog<String>(

    context: context,

    builder: (ctx) => AlertDialog(

      title: const Text("Duplicar móvel"),

      content: TextField(

        controller: nameCtrl,

        decoration: const InputDecoration(

          labelText: "Nome do novo móvel",

          border: OutlineInputBorder(),

        ),

      ),

      actions: [

        TextButton(

          onPressed: () => Navigator.pop(ctx),

          child: const Text("Cancelar"),

        ),

        TextButton(

          onPressed: () {

            final t = nameCtrl.text.trim();

            Navigator.pop(ctx, t.isEmpty ? null : t);

          },

          child: const Text(

            "Duplicar",

            style: TextStyle(fontWeight: FontWeight.bold),

          ),

        ),

      ],

    ),

  );

  if (novoNome == null) return;

  try {

    // ✅ SEM INDEX: usa o contador global

    final int novoNumeroMovel = await _gerarProximoNumeroMovelGlobal();

    // cria novo movel

    final newMovelRef = FirebaseFirestore.instance.collection('moveis').doc();

    final newMovelData = Map<String, dynamic>.from(movelData);

    newMovelData['nome'] = novoNome;

    newMovelData['numeroMovel'] = novoNumeroMovel;

    newMovelData['createdAt'] = FieldValue.serverTimestamp();

    // (opcional) se você NÃO quiser copiar o id do orçamento ou outros campos, remova aqui

    // newMovelData.remove('algumCampo');

    await newMovelRef.set(newMovelData);

    // copia itens

    final itensSnap = await movelDoc.reference.collection('itens').get();

    const int chunkSize = 400;

    var batch = FirebaseFirestore.instance.batch();

    int opCount = 0;

    for (final item in itensSnap.docs) {

      final itemData = item.data() as Map<String, dynamic>? ?? {};

      final newItemRef = newMovelRef.collection('itens').doc();

      final newItemData = Map<String, dynamic>.from(itemData);

      newItemData['createdAt'] = FieldValue.serverTimestamp();

      batch.set(newItemRef, newItemData);

      opCount++;

      if (opCount >= chunkSize) {

        await batch.commit();

        batch = FirebaseFirestore.instance.batch();

        opCount = 0;

      }

    }

    if (opCount > 0) {

      await batch.commit();

    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(content: Text('Móvel duplicado: "$novoNome"')),

    );

  } catch (e) {

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(content: Text("Erro ao duplicar móvel: $e")),

    );

  }

}

Future<void> _apagarMovelComItens(DocumentSnapshot movelDoc) async {

  // apaga todos os itens primeiro

  final itensSnap = await movelDoc.reference.collection('itens').get();

  for (final item in itensSnap.docs) {

    await item.reference.delete();

  }

  // depois apaga o móvel

  await movelDoc.reference.delete();

}

Future<void> _mostrarOpcoesMovel(

  BuildContext context,

  DocumentSnapshot movelDoc,

  String nomeMovel,

) async {

  // capture messenger early (so we don't call of(context) after awaits)

  final messenger = ScaffoldMessenger.of(context);

  final escolha = await showDialog<_AcaoMovel>(

    context: context,

    builder: (ctx) {

      return AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _dialogSoftBrown,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.chair_alt_rounded, color: _dialogDarkBrown),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Opções do móvel",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    nomeMovel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _dialogSoftText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 470,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MovelActionTile(
                icon: Icons.copy_rounded,
                title: "Duplicar",
                subtitle: "Cria uma cópia deste móvel e de todos os itens.",
                onTap: () => Navigator.pop(ctx, _AcaoMovel.duplicar),
              ),
              const SizedBox(height: 8),
              _MovelActionTile(
                icon: Icons.inventory_2_outlined,
                title: "Guardar e remover",
                subtitle: "Salva como modelo e remove deste orçamento.",
                onTap: () => Navigator.pop(ctx, _AcaoMovel.guardar),
              ),
              const SizedBox(height: 8),
              _MovelActionTile(
                icon: Icons.delete_outline_rounded,
                title: "Excluir definitivamente",
                subtitle: "Remove o móvel e todos os itens vinculados.",
                destructive: true,
                onTap: () => Navigator.pop(ctx, _AcaoMovel.excluir),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: _dialogSoftText),
            child: const Text("Cancelar"),
          ),
        ],
      );

    },

  );

  // ✅ after await showDialog, context might be unmounted

  if (!context.mounted) return;

  if (escolha == null) return;

  if (escolha == _AcaoMovel.duplicar) {

    await _duplicarMovel(context, movelDoc);

    if (!context.mounted) return;

  } else if (escolha == _AcaoMovel.guardar) {

    await _guardarMovelComoModelo(context, widget.clienteId, movelDoc);

    if (!context.mounted) return;

  } else if (escolha == _AcaoMovel.excluir) {

    await _apagarMovelComItens(movelDoc);

    if (!context.mounted) return;

    messenger.showSnackBar(

      SnackBar(content: Text('Móvel "$nomeMovel" excluído definitivamente.')),

    );

  }

}

Future<void> _showAddMovelDialog(BuildContext context) async {

  final TextEditingController controller = TextEditingController();

  final String? nomeMovel = await showDialog<String>(

    context: context,

    builder: (ctx) {

      return AlertDialog(

        title: const Text("Novo Móvel"),

        content: SizedBox(

          width: 320,

          child: TextField(

            controller: controller,

            decoration: const InputDecoration(

              labelText: "Nome do móvel",

              border: OutlineInputBorder(),

            ),

          ),

        ),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(ctx),

            child: const Text("Cancelar"),

          ),

          TextButton(

            onPressed: () {

              final txt = controller.text.trim();

              if (txt.isEmpty) {

                Navigator.pop(ctx, null);

              } else {

                Navigator.pop(ctx, txt);

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

  if (nomeMovel == null || nomeMovel.isEmpty) return;

  try {

    // 👉 aqui usamos o contador GLOBAL

    final int numeroMovel = await _gerarProximoNumeroMovelGlobal();

    await FirebaseFirestore.instance.collection('moveis').add({

      'clienteId': widget.clienteId,

      'orcamentoId': widget.orcamentoId,

      'nome': nomeMovel,

      'numeroOrcamento': widget.numeroOrcamento, // se ainda usa pra filtrar

      'numeroMovel': numeroMovel,                // AGORA É GLOBAL

      'createdAt': FieldValue.serverTimestamp(),

    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text('Móvel #$numeroMovel "$nomeMovel" adicionado.'),

      ),

    );

  } catch (e) {

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(content: Text('Erro ao salvar móvel: $e')),

    );

  }

}

  // ======================================================

  //       ADICIONAR ITEM (VINDO DA COLEÇÃO items) A UM MÓVEL

  // ======================================================

  Future<void> _showAddItemMovelDialog(

  BuildContext context,

  DocumentSnapshot movelDoc,

) async {

  final nomeMovel =

      (movelDoc.data() as Map<String, dynamic>?)?['nome'] ?? '';

  String filtro = "";

  final DocumentSnapshot? itemEscolhido =

      await showDialog<DocumentSnapshot>(

    context: context,

    builder: (ctx) {

      return StatefulBuilder(

        builder: (ctx, setStateDialog) {

          final itemsQuery =

              FirebaseFirestore.instance.collection('items');

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            title: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _dialogSoftBrown,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.add_rounded, color: _dialogDarkBrown),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Adicionar item",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        nomeMovel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _dialogSoftText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 540,

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  TextField(

                    decoration: InputDecoration(
                      hintText: "Buscar item...",
                      prefixIcon: const Icon(Icons.search_rounded, color: _dialogBrown),
                      filled: true,
                      fillColor: const Color(0xFFFCFBFA),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE8E3DF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _dialogBrown, width: 1.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    onChanged: (value) {

                      setStateDialog(() {

                        filtro = value.trim().toLowerCase();

                      });

                    },

                  ),

                  const SizedBox(height: 12),

                  SizedBox(

                    height: 330,

                    child: StreamBuilder<QuerySnapshot>(

                      stream: itemsQuery.snapshots(),

                      builder: (context, snapshot) {

                        if (snapshot.hasError) {

                          return Text(

                            "Erro ao carregar itens: ${snapshot.error}",

                            style: const TextStyle(color: Colors.red),

                          );

                        }

                        if (snapshot.connectionState ==

                            ConnectionState.waiting) {

                          return const Center(

                            child: CircularProgressIndicator(),

                          );

                        }

                        if (!snapshot.hasData ||

                            snapshot.data!.docs.isEmpty) {

                          return const Center(

                            child: Text(

                              "Nenhum item cadastrado ainda.",

                              style: TextStyle(color: Colors.grey),

                            ),

                          );

                        }

                        final todos = snapshot.data!.docs;

                        final filtrados = todos.where((doc) {

                          final data =

                              doc.data() as Map<String, dynamic>?;

                          final nome =

                              (data?['name'] ?? '') as String;

                          if (filtro.isEmpty) return true;

                          return nome.toLowerCase().contains(filtro);

                        }).toList()

                          ..sort((a, b) {

                            final da =

                                (a.data() as Map<String, dynamic>? ?? {});

                            final db =

                                (b.data() as Map<String, dynamic>? ?? {});

                            final na = (da['name'] ?? '') as String;

                            final nb = (db['name'] ?? '') as String;

                            return na

                                .toLowerCase()

                                .compareTo(nb.toLowerCase());

                          });

                        if (filtrados.isEmpty) {

                          return const Center(

                            child: Text(

                              "Nenhum item encontrado.",

                              style: TextStyle(color: Colors.grey),

                            ),

                          );

                        }

                        return ListView.builder(

                          itemCount: filtrados.length,

                          itemBuilder: (context, index) {

                            final doc = filtrados[index];

                            final data =

                                doc.data() as Map<String, dynamic>? ?? {};

                            final nome = data['name'] as String? ??

                                "(sem nome)";

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Material(
                                color: const Color(0xFFFCFBFA),
                                borderRadius: BorderRadius.circular(12),
                                child: ListTile(
                                  dense: true,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Color(0xFFE8E3DF)),
                                  ),
                                  title: Text(
                                    nome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: _dialogBrown,
                                    size: 20,
                                  ),
                                  onTap: () {
                                    Navigator.pop(ctx, doc);
                                  },
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

            ),

            actions: [

              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(foregroundColor: _dialogSoftText),
                child: const Text("Cancelar"),
              ),

            ],

          );

        },

      );

    },

  );

  if (itemEscolhido == null) return;

  try {

    final dataItem =

        itemEscolhido.data() as Map<String, dynamic>? ?? {};

    final itemName = dataItem['name'] as String? ?? "(sem nome)";

    final unitType = dataItem['unitType']; // 'folha', 'litro', etc

    final subcategory = dataItem['subcategory']; // ex: 'tintas', 'colas'

    // copiando informações importantes do item "original" para o item do móvel

    final precoFolha = dataItem['precoFolha'];

    final areaFolha = dataItem['areaFolha'];

    final taxaPerca = dataItem['taxaPerca'];

    final precoUnidade = dataItem['precoUnidade'];

    final metragem = dataItem['metragem'];

    final precoMetro = dataItem['precoMetro'];

    // 🔹 Cola: preço/L e L/m² (se existirem no item original)

    final precoM2 = dataItem['precoM2'];

    final precoL = dataItem['precoL'];

    final lm2Mdf = dataItem['lm2Mdf'];

    final lm2Formica = dataItem['lm2Formica'];

    final hasPrecoL = dataItem['hasPrecoL'];

    final hasLm2 = dataItem['hasLm2'];

    final usaLm2Separado = dataItem['usaLm2Separado'];

    final precoM3 = dataItem['precoM3'];

final bool isValorTotalItem =

    unitType == 'unidade' &&

    itemName.trim().toLowerCase() == 'valor total';

await movelDoc.reference.collection('itens').add({

  'itemId': itemEscolhido.id,

  'itemName': itemName,

  'unitType': unitType,

  'subcategory': subcategory,

  // ✅ ONLY "Valor Total" gets the flag

  'isValorTotal': isValorTotalItem,

  'linhas': [],

  'precoFolha': precoFolha,

  'areaFolha': areaFolha,

  'taxaPerca': taxaPerca,

  'precoUnidade': precoUnidade,

  'precoL': precoL,

  'lm2Mdf': lm2Mdf,

  'lm2Formica': lm2Formica,

  'usaLm2Separado': usaLm2Separado,

  'hasPrecoL': hasPrecoL,

  'hasLm2': hasLm2,

  'precoM2': precoM2,

  'metragem': metragem,

  'precoMetro': precoMetro,

  'precoM3': precoM3,

  'createdAt': FieldValue.serverTimestamp(),

  // (optional defaults for Valor Total)

  if (isValorTotalItem) ...{

    'quantidadeUnd': 1,

    'precoUnd': 0,

    'medidaValorTotal': 'Und',

  },

});

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text('Item "$itemName" adicionado em "$nomeMovel".'),

      ),

    );

  } catch (e) {

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(content: Text("Erro ao salvar item: $e")),

    );

  }

}

  // ======================================================

  //  EDITAR MEDIDAS MADEIRA

  // ======================================================

}

class _MovelActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const _MovelActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF79533B);
    const softBrown = Color(0xFFF4EEEA);
    const border = Color(0xFFE8E3DF);
    const softText = Color(0xFF77716D);
    final foreground = destructive ? Colors.red.shade700 : brown;
    final background = destructive ? Colors.red.withValues(alpha: 0.06) : softBrown;
    final outline = destructive ? Colors.red.withValues(alpha: 0.18) : border;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: outline),
          ),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(
                      color: foreground, fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(
                      color: softText, fontSize: 12, height: 1.25)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: foreground, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

