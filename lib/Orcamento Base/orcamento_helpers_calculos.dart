part of 'orcamento_page.dart';

extension _OrcamentoHelpersCalculosExtension on _OrcamentoPageState {
  String _formatDecimal(num? value, {int dec = 2}) {
    if (value == null) return "-";
    return value.toStringAsFixed(dec);
  }

  String _unitSuffix(String? unitType) {
    switch (unitType) {
      case 'folha':
        return 'm²';
      case 'litro':
        return 'L';
      case 'metro':
        return 'm';
      case 'unidade':
        return 'Und';
      default:
        return '';
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      return double.tryParse(v.replaceAll(',', '.'));
    }
    return null;
  }

Widget _buildPrecoCell(
  Map<String, dynamic> itemData, {
  required bool isFolha,
  required bool isColaFormica,
  required bool isColaBranca,
  required bool isUnidade,
  required bool isFita,
  required bool isOutros,
  required bool isPintura,
  required bool isMadeiraMacica,
  required bool isVernizPu,
  required bool isVernizComum,
}) {
  // 👇 Name do item (pode vir de itemName ou name)

  // 👇 Só é "Valor Total" se for unidade + nome "valor total"
  final bool isValorTotal = isUnidade && (itemData['isValorTotal'] == true);

  // FOLHA
  if (isFolha) {
    final precoFolha = _toDouble(itemData['precoFolha']);
    if (precoFolha == null) {
      return const Text(
        "-",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13),
      );
    }
    return Text(
      "R\$ ${_formatDecimal(precoFolha, dec: 2)}",
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13),
    );
  }

  // COLA FORMICA → preço por L
  if (isColaFormica) {
    final precoL = _toDouble(itemData['precoL']);
    if (precoL == null) {
      return const Text(
        "-",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13),
      );
    }
    return Text(
      "R\$ ${_formatDecimal(precoL, dec: 2)}",
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13),
    );
  }

  // COLA BRANCA → preço por L
  if (isColaBranca) {
    final precoL = _toDouble(itemData['precoL']);
    if (precoL == null) {
      return const Text(
        "-",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13),
      );
    }
    return Text(
      "R\$ ${_formatDecimal(precoL, dec: 2)}",
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13),
    );
  }

  // FITA → preço por metro
  if (isFita || isOutros) {
    final precoMetro = _toDouble(itemData['precoMetro']);
    if (precoMetro == null) {
      return const Text(
        "-",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13),
      );
    }
    return Text(
      "R\$ ${_formatDecimal(precoMetro, dec: 2)}",
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13),
    );
  }

  // 🔥 PINTURA + VERNIZ PU / COMUM → preço por m²
  if (isPintura || isVernizPu || isVernizComum) {
    final precoM2 = _toDouble(itemData['precoM2']);
    if (precoM2 == null) {
      return const Text(
        "-",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13),
      );
    }
    return Text(
      "R\$ ${_formatDecimal(precoM2, dec: 2)}",
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13),
    );
  }

  // MADEIRA MACIÇA → preço por m³
  if (isMadeiraMacica) {
    final precoM3 = _toDouble(itemData['precoM3']);
    if (precoM3 == null) {
      return const Text(
        "-",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13),
      );
    }
    return Text(
      "R\$ ${_formatDecimal(precoM3, dec: 2)}",
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13),
    );
  }

  // ⭐ CASO ESPECIAL: "Valor Total" (unidade) → usa precoUnd salvo no móvel
  if (isValorTotal) {
    final precoUnd = _toDouble(itemData['precoUnd']);
    if (precoUnd == null) {
      return const Text(
        "-",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13),
      );
    }
    return Text(
      "R\$ ${_formatDecimal(precoUnd, dec: 2)}",
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13),
    );
  }

  // fallback para outros (unidade normal etc.)
  final precoUnidade =
      _toDouble(itemData['precoUnidade'] ?? itemData['precoUnd']);
  if (precoUnidade == null) {
    return const Text(
      "-",
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 13),
    );
  }

  return Text(
    "R\$ ${_formatDecimal(precoUnidade, dec: 2)}",
    textAlign: TextAlign.center,
    style: const TextStyle(fontSize: 13),
  );
}


double _calcularVolumeM3Madeira(DocumentSnapshot itemDoc) {
  final data = itemDoc.data() as Map<String, dynamic>? ?? {};
  final linhas = (data['madeiraLinhas'] as List?) ?? [];

  double total = 0;

  for (final l in linhas) {
    if (l is! Map<String, dynamic>) continue;

    final qtd   = _toDouble(l['quantidade']) ?? 0;
    final comp  = _toDouble(l['comprimento']) ?? 0;
    final larg  = _toDouble(l['largura']) ?? 0;
    final alt   = _toDouble(l['altura']) ?? 0;

    if (qtd <= 0 || comp <= 0 || larg <= 0 || alt <= 0) continue;

    // assumindo tudo em metros → volume em m³
    final volume = qtd * comp * larg * alt;
    total += volume;
  }

  return total;
}

double _calcularAreaM2VernizParaMovel(
  List<DocumentSnapshot> itensDocs, {
  required bool paraVernizPu,
}) {
  double soma = 0;

  for (final doc in itensDocs) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final unitType = data['unitType'] as String? ?? '';

    // Só madeira maciça entra aqui
    if (unitType != 'madeiraMacica') continue;

    // Flags salvas no edit dialog
    final bool usaPu = data['vernizPU'] == true;
    final bool usaComum = data['vernizComum'] == true;

    // Se estamos calculando para PU, só conta quem marcou PU
    if (paraVernizPu && !usaPu) continue;

    // Se estamos calculando para Comum, só conta quem marcou Comum
    if (!paraVernizPu && !usaComum) continue;

    final linhas = (data['madeiraLinhas'] as List?) ?? [];

    for (final l in linhas) {
      if (l is! Map<String, dynamic>) continue;

      final double? qtd = _toDouble(l['quantidade']);
      final double? comp = _toDouble(l['comprimento']);
      final double? larg = _toDouble(l['largura']);
      final double? alt = _toDouble(l['altura']);
      final String ladosStr = (l['lados']?.toString() ?? '4').trim();

      if (qtd == null || comp == null || larg == null || alt == null) {
        continue;
      }

      double areaCm2 = 0;

      if (ladosStr == '3') {
        // 3 lados: ((((2 * alt) + larg) * comp) * quantidade)
        areaCm2 = (((2 * alt) + larg) * comp) * qtd;
      } else if (ladosStr == '4') {
        // 4 lados: ((2 * larg + 2 * alt) * comp) * quantidade
        areaCm2 = ((2 * larg + 2 * alt) * comp) * qtd;
      } else if (ladosStr == '5') {
        // 5 lados: (((larg * alt) * 2) + (comp * larg) + ((comp * alt) * 2)) * quantidade
        areaCm2 =
            (((larg * alt) * 2) + (comp * larg) + ((comp * alt) * 2)) * qtd;
      } else {
        // se por algum motivo vier outro valor, ignora
        continue;
      }

      // cm² → m²  (se suas medidas já forem em m, tira o / 10000)
      final areaM2 = areaCm2 / 10000.0;
      if (areaM2 > 0) {
        soma += areaM2;
      }
    }
  }

  return soma;
}

double _calcularLitrosColaFormicaParaItem(
  DocumentSnapshot itemMovelDoc,
  double lm2Mdf,
  double lm2Formica,
) {
  final data = itemMovelDoc.data() as Map<String, dynamic>? ?? {};

  // tudo minúsculo pra não dar erro por maiúscula
  final unitType = (data['unitType'] as String?)?.toLowerCase() ?? '';
  final sub = (data['subcategory'] as String?)?.toLowerCase() ?? '';

  // não confiar demais no unitType, só evitar "litro"
  final bool isLitro = unitType == 'litro';

  // identificadores por subcategoria, aceitando coisas como "mdf branco"
  final bool isMdf     = sub.contains('mdf');
  final bool isFormica = sub.contains('formica');
  final bool isLamina  = sub.contains('lamina');
  final bool isManta   = sub.contains('manta');
  final bool isFita    = unitType == 'metro' && sub.contains('fita');
  final bool isOutros  = unitType == 'metro' && sub.contains('outros');

  const double litrosPorMetroFita = 1.0;

  // =============== FOLHAS (MDF / FORMICA / LÂMINA / MANTA) ===============
  // qualquer coisa que não seja "litro" nem "metro", vamos tentar tratar como folha com área
  final bool usaArea = !isLitro && !isFita || !isOutros && (isMdf || isFormica || isLamina || isManta);

  if (usaArea) {
    final double areaM2 = _calcularAreaM2DeFolha(itemMovelDoc);
    if (areaM2 <= 0) return 0;

    // Lâmina ou Manta → 1L por m²
    if (isLamina || isManta) {
      return areaM2;
    }

    // MDF → usa lm2Mdf
    if (isMdf) {
      if (lm2Mdf <= 0) return 0;
      return areaM2 * lm2Mdf;
    }

    // Formica → usa lm2Formica
    if (isFormica) {
      if (lm2Formica <= 0) return 0;
      return areaM2 * lm2Formica;
    }

    return 0;
  }

  // =============== FITA (metro) ===============
  if (isFita || isOutros) {
    final metrosFita = _toDouble(data['metrosFita']);
    final quantidadeUsada = _toDouble(data['quantidadeUsada']);
    final metragemItem = _toDouble(data['metragem']);

    final metros = metrosFita ?? quantidadeUsada ?? metragemItem ?? 0;

    if (metros <= 0) return 0;

    return metros * litrosPorMetroFita * 0.05; // 1 m -> 1 L
  }

  // outros tipos não entram na cola
  return 0;
}

double _calcularAreaM2TotalLaminas(List<DocumentSnapshot> itensDocs) {
  double soma = 0;

  for (final doc in itensDocs) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final unitType = data['unitType'] as String? ?? '';
    final sub = (data['subcategory'] as String?)?.toLowerCase() ?? '';

    // Folha de LÂMINA
    if (unitType == 'folha' && sub.contains('lamina')) {
      final area = _calcularAreaM2DeFolha(doc);
      if (area > 0) {
        soma += area;
      }
    }
  }

  return soma;
}

double _calcularAreaM2DeFolha(DocumentSnapshot doc) {
  final data =
      doc.data() as Map<String, dynamic>? ?? {};

  final linhas = (data['linhas'] as List?) ?? [];

  final double areaFolha =
      _toDouble(data['areaFolha']) ?? 0;

  double somaM2 = 0;

  for (final raw in linhas) {
    if (raw is! Map<String, dynamic>) continue;

    // ===================================================
    // 1. FOLHAS INFORMADAS MANUALMENTE
    // ===================================================

    final qFolhas = _toDouble(
      raw['qtdFolhas'],
    );

    if (qFolhas != null &&
        qFolhas > 0 &&
        areaFolha > 0) {
      somaM2 += qFolhas * areaFolha;
    }

    // ===================================================
    // 2. ÁREA INFORMADA POR DIMENSÕES
    // ===================================================

    final q = _toDouble(
      raw['quantidade'],
    );

    final c = _toDouble(
      raw['comprimento'],
    );

    final g = _toDouble(
      raw['largura'],
    );

    if (q != null &&
        q > 0 &&
        c != null &&
        c > 0 &&
        g != null &&
        g > 0) {
      somaM2 += q * (c * g / 10000.0);
    }
  }

  return somaM2;
}

Future<void> _ensureVernizesParaMadeiraMacica(
  DocumentSnapshot movelDoc,
  List<QueryDocumentSnapshot> itensDocs,
) async {
  bool precisaPu = false;
  bool precisaNormal = false;

  // 1) Ler as MADEIRAS MACIÇAS deste móvel
  for (final d in itensDocs) {
    final data = d.data() as Map<String, dynamic>? ?? {};
    final unitType = (data['unitType'] as String?)?.toLowerCase() ?? '';

    if (unitType == 'madeiramacica') {
      // ⚠️ Usa exatamente os campos que você salva no diálogo:
      if (data['vernizPU'] == true) {
        precisaPu = true;
      }
      if (data['vernizComum'] == true) {
        precisaNormal = true;
      }
    }
  }

  // Se nenhuma madeira maciça pede verniz, não faz nada
  if (!precisaPu && !precisaNormal) return;

  // 2) Garantir Verniz PU
  if (precisaPu && !_criandoVernizPu) {
    _criandoVernizPu = true;
    try {
      // Ver se já existe Verniz PU neste móvel
      final existingPu = await movelDoc.reference
          .collection('itens')
          .where('unitType', isEqualTo: 'litro')
          .where('itemName', isEqualTo: 'Verniz PU')
          .limit(1)
          .get();

      if (existingPu.docs.isEmpty) {
        // Buscar o item global "Verniz PU" em items
        final queryPu = await FirebaseFirestore.instance
            .collection('items')
            .where('unitType', isEqualTo: 'litro')
            .where('name', isEqualTo: 'Verniz PU')
            .limit(1)
            .get();

        if (queryPu.docs.isNotEmpty) {
          final itemVernizPu = queryPu.docs.first;
          final dataItem = itemVernizPu.data() as Map<String, dynamic>? ?? {};

          await movelDoc.reference.collection('itens').add({
            'itemId': itemVernizPu.id,
            'itemName': dataItem['name'] ?? 'Verniz PU',
            'unitType': dataItem['unitType'] ?? 'litro',
            'subcategory': dataItem['subcategory'],
            'precoM2': dataItem['precoM2'],
            'hasPrecoM2': dataItem['hasPrecoM2'],
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } finally {
      _criandoVernizPu = false;
    }
  }

  // 3) Garantir VERNIZ COMUM
  if (precisaNormal && !_criandoVernizComum) {
    _criandoVernizComum = true;
    try {
      // Ver se já existe Verniz Comum neste móvel
      final existingNormal = await movelDoc.reference
          .collection('itens')
          .where('unitType', isEqualTo: 'litro')
          .where('itemName', isEqualTo: 'Verniz Comum')
          .limit(1)
          .get();

      if (existingNormal.docs.isEmpty) {
        // Buscar item global "Verniz Comum" em items
        final queryNormal = await FirebaseFirestore.instance
            .collection('items')
            .where('unitType', isEqualTo: 'litro')
            .where('name', isEqualTo: 'Verniz Comum')
            .limit(1)
            .get();

        if (queryNormal.docs.isNotEmpty) {
          final itemVernizComum = queryNormal.docs.first;
          final dataItem =
              itemVernizComum.data() as Map<String, dynamic>? ?? {};

          await movelDoc.reference.collection('itens').add({
            'itemId': itemVernizComum.id,
            'itemName': dataItem['name'] ?? 'Verniz Comum',
            'unitType': dataItem['unitType'] ?? 'litro',
            'subcategory': dataItem['subcategory'],
            'precoM2': dataItem['precoM2'],
            'hasPrecoM2': dataItem['hasPrecoM2'],
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } finally {
      _criandoVernizComum = false;
    }
  }
}

//
// FAZER VERNIZ PU APARECER QUANDO LAMINA
//
Future<void> _ensureVernizPuForLaminas(
  DocumentSnapshot movelDoc,
  List<QueryDocumentSnapshot> itensDocs,
) async {
  // 🔒 Se já tem uma criação de Verniz PU em andamento, não faz nada
  if (_criandoVernizPu) return;

  bool temLamina = false;

  // 1) Ver se existe alguma LÂMINA neste móvel (pelo snapshot atual)
  for (final d in itensDocs) {
    final data = d.data() as Map<String, dynamic>? ?? {};
    final unitType = (data['unitType'] as String?)?.toLowerCase() ?? '';
    final sub = (data['subcategory'] as String?)?.toLowerCase() ?? '';

    if (unitType == 'folha' && sub.contains('lamina')) {
      temLamina = true;
      break;
    }
  }

  // Se não tem lâmina, não faz nada
  if (!temLamina) return;

  _criandoVernizPu = true; // 🔒 liga o cadeado
  try {
    // 2) GARANTIA NO FIRESTORE: existe Verniz PU já?
    final existing = await movelDoc.reference
        .collection('itens')
        .where('unitType', isEqualTo: 'litro')
        .where('itemName', isEqualTo: 'Verniz PU')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // Já existe pelo menos um Verniz PU neste móvel → não cria outro
      return;
    }

    // 3) Buscar o item global "Verniz PU" na coleção items
    final query = await FirebaseFirestore.instance
        .collection('items')
        .where('unitType', isEqualTo: 'litro')
        .where('name', isEqualTo: 'Verniz PU')
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      // não existe item "Verniz PU" cadastrado em items
      return;
    }

    final itemVerniz = query.docs.first;
    final dataItem = itemVerniz.data() as Map<String, dynamic>? ?? {};

    // 4) Copiar campos importantes para dentro do móvel
    await movelDoc.reference.collection('itens').add({
      'itemId': itemVerniz.id,
      'itemName': dataItem['name'] ?? 'Verniz PU',
      'unitType': dataItem['unitType'] ?? 'litro',
      'subcategory': dataItem['subcategory'],
      'precoM2': dataItem['precoM2'],
      'hasPrecoM2': dataItem['hasPrecoM2'],
      'createdAt': FieldValue.serverTimestamp(),
    });
  } finally {
    // libera o cadeado mesmo se der erro
    _criandoVernizPu = false;
  }
}

// ======================================================
//      EDITAR METROS DE FITA (APENAS 1 VALOR EM m)
// ======================================================


}
