part of '../Orçamento Base/orcamento_page.dart';

// ======================================================
//          ITENS, CÁLCULOS E RESUMO DO MÓVEL
// ======================================================

// Estado leve do autosave do resumo.
// O rascunho fica em uma subcoleção separada para NÃO disparar o stream
// do documento principal do móvel a cada tecla digitada.
final Set<String> _resumoRascunhoCarregando = <String>{};
final Set<String> _resumoRascunhoCarregado = <String>{};
final Set<String> _resumoRascunhoAlteradoLocalmente = <String>{};

extension _MovelItensExtension on _OrcamentoPageState {
  DocumentReference<Map<String, dynamic>> _resumoRascunhoRef(
    DocumentReference movelRef,
  ) {
    return movelRef.collection('rascunho').doc('resumo');
  }

  void _carregarResumoRascunhoUmaVez({
    required String movelId,
    required DocumentReference movelRef,
    required TextEditingController freteCtrl,
    required TextEditingController extraCtrl,
    required TextEditingController maoObraCtrl,
    required TextEditingController lucroCtrl,
    required VoidCallback atualizarResumo,
  }) {
    if (_resumoRascunhoCarregado.contains(movelId) ||
        _resumoRascunhoCarregando.contains(movelId)) {
      return;
    }

    _resumoRascunhoCarregando.add(movelId);

    () async {
      try {
        final snap = await _resumoRascunhoRef(movelRef).get();
        final data = snap.data();

        // Se a pessoa começou a digitar antes do GET terminar, nunca
        // sobrescrevemos o que ela acabou de escrever.
        if (data != null &&
            !_resumoRascunhoAlteradoLocalmente.contains(movelId)) {
          freteCtrl.text = data['frete']?.toString() ?? freteCtrl.text;
          extraCtrl.text = data['extra']?.toString() ?? extraCtrl.text;
          maoObraCtrl.text = data['maoObra']?.toString() ?? maoObraCtrl.text;
          lucroCtrl.text =
              data['lucroPercentual']?.toString() ?? lucroCtrl.text;

          atualizarResumo();
        }
      } catch (e) {
        debugPrint('Erro ao carregar rascunho do resumo ($movelId): $e');
      } finally {
        _resumoRascunhoCarregando.remove(movelId);
        _resumoRascunhoCarregado.add(movelId);
      }
    }();
  }

  void _agendarAutosaveResumo({
    required String movelId,
    required DocumentReference movelRef,
    required TextEditingController freteCtrl,
    required TextEditingController extraCtrl,
    required TextEditingController maoObraCtrl,
    required TextEditingController lucroCtrl,
  }) {
    _resumoRascunhoAlteradoLocalmente.add(movelId);

    // Grava a cada alteração, mas em um documento separado.
    // Assim o Firestore persiste imediatamente sem provocar rebuild do
    // StreamBuilder que observa o documento principal do móvel.
    () async {
      try {
        await _resumoRascunhoRef(movelRef).set({
          'frete': _parseResumoDouble(freteCtrl.text),
          'extra': _parseResumoDouble(extraCtrl.text),
          'maoObra': _parseResumoDouble(maoObraCtrl.text),
          'lucroPercentual': _parseResumoDouble(lucroCtrl.text),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Erro no autosave do resumo ($movelId): $e');
      }
    }();
  }

  Future<void> _salvarResumoAgora({
    required String movelId,
    required DocumentReference movelRef,
    required TextEditingController freteCtrl,
    required TextEditingController extraCtrl,
    required TextEditingController maoObraCtrl,
    required TextEditingController lucroCtrl,
  }) async {
    _resumoRascunhoAlteradoLocalmente.add(movelId);

    try {
      await _resumoRascunhoRef(movelRef).set({
        'frete': _parseResumoDouble(freteCtrl.text),
        'extra': _parseResumoDouble(extraCtrl.text),
        'maoObra': _parseResumoDouble(maoObraCtrl.text),
        'lucroPercentual': _parseResumoDouble(lucroCtrl.text),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erro ao salvar resumo imediatamente ($movelId): $e');
    }
  }

  Widget _buildItensEResumo(
    BuildContext context,
    DocumentSnapshot doc,
    String nomeMovel,
    Query itensQuery,
  ) {
    return StreamBuilder<QuerySnapshot>(
  stream: itensQuery.snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return Text(
        "Erro ao carregar itens: ${snapshot.error}",
        style: const TextStyle(color: Colors.red),
      );
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Text(
        "Carregando itens...",
        style: TextStyle(color: Colors.grey),
      );
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Text(
        "Nenhum item adicionado ainda.",
        style: TextStyle(color: Colors.grey),
      );
    }

    final itensDocs = snapshot.data!.docs.toList();
    // tentar garantir que Verniz PU exista se tiver lâmina
    _ensureVernizPuForLaminas(doc, itensDocs);
    _ensureVernizesParaMadeiraMacica(doc, itensDocs);

    // ========= 1ª PASSAGEM: calcular TOTAL BRUTO =========
    double totalBruto = 0;

    for (final itemDoc in itensDocs) {
      final itemData =
          itemDoc.data() as Map<String, dynamic>? ?? {};
      final itemName =
          itemData['itemName'] as String? ?? "(sem nome)";
      final unitType = itemData['unitType'];
      final subcategoryItem = itemData['subcategory'];
      final subLower =
          (subcategoryItem as String?)?.toLowerCase() ?? '';

      final bool isFolha = unitType == 'folha';
      final bool isColaBranca =
          unitType == 'litro' &&
          itemName.toLowerCase() == 'cola branca';
      final bool isColaFormica =
          unitType == 'litro' &&
          itemName.toLowerCase() == 'cola formica';
      final bool isUnidade = unitType == 'unidade';
      final bool isFita = subLower == 'fita' || subLower == 'fitas';
      final bool isOutros = subLower == 'outros' || subLower == 'outro';
      final bool isPintura =
          unitType == 'litro' && subLower == 'tintas';
      final bool isMadeiraMacica = unitType == 'madeiraMacica';
      // genérico
      final quantidadeUsada =
          _toDouble(itemData['quantidadeUsada']);
      final precoPorQuantidade =
          _toDouble(itemData['precoPorQuantidade']);
      final bool isVernizPu = unitType == 'litro' &&
          itemName.toLowerCase() == 'verniz pu';
      final bool isVernizComum = unitType == 'litro' &&
          itemName.toLowerCase() == 'verniz comum';
      final bool isValorTotal = isUnidade && (itemData['isValorTotal'] == true);
          

// --- FOLHA ---
final linhasFolha = (itemData['linhas'] as List?) ?? [];
final double? areaFolha = _toDouble(itemData['areaFolha']);
final double? precoFolha = _toDouble(itemData['precoFolha']);
final double taxaPerca = _toDouble(itemData['taxaPerca']) ?? 0;

double? tamanhoFolha;
double? quantidadeFolha;
double? totalFolha;

if (isFolha) {
  double somaM2Medidas = 0;
  double somaFolhasManuais = 0;

  for (final raw in linhasFolha) {
    if (raw is! Map<String, dynamic>) continue;

    // Folhas digitadas diretamente
    final qFolhas = _toDouble(raw['qtdFolhas']);

    if (qFolhas != null && qFolhas > 0) {
      somaFolhasManuais += qFolhas;
    }

    // Medidas digitadas
    final q = _toDouble(raw['quantidade']);
    final c = _toDouble(raw['comprimento']);
    final g = _toDouble(raw['largura']);

    if (q != null && c != null && g != null) {
      somaM2Medidas += q * (c * g / 10000.0);
    }
  }

  // Área usada pelas medidas
  if (somaM2Medidas > 0) {
    tamanhoFolha = somaM2Medidas;
  }

  double folhasCalculadas = 0;

  // Calcula folhas provenientes das medidas
  if (areaFolha != null && areaFolha > 0 && somaM2Medidas > 0) {
    folhasCalculadas = somaM2Medidas / areaFolha;

    // perda somente sobre o material calculado pelas medidas
    folhasCalculadas *= (1 + taxaPerca / 100);
  }

  // SOMA medidas + folhas digitadas
  final totalQuantidadeFolhas =
      folhasCalculadas + somaFolhasManuais;

  if (totalQuantidadeFolhas > 0) {
    quantidadeFolha = totalQuantidadeFolhas;
  }

  if (quantidadeFolha != null && precoFolha != null) {
    totalFolha = quantidadeFolha * precoFolha;
  }
}

      // ====== UNIDADE ======
final double? quantidadeUnd = _toDouble(itemData['quantidadeUnd']);
final double? precoUnidadeItem = _toDouble(itemData['precoUnidade']); // preço da tabela
final double? precoUndMovel    = _toDouble(itemData['precoUnd']);     // preço customizado do "Valor Total"

// usa o mesmo itemName que você já tem lá em cima

double? totalUnidade;

if (isUnidade && quantidadeUnd != null) {
  if (isValorTotal) {
    // ⭐ Valor Total: usa o precoUnd (se existir) senão cai pro precoUnidade da tabela
    final double? precoBase = precoUndMovel ?? precoUnidadeItem;
    if (precoBase != null) {
      totalUnidade = quantidadeUnd * precoBase;
    }
  } else {
    // Unidade normal
    if (precoUnidadeItem != null) {
      totalUnidade = quantidadeUnd * precoUnidadeItem;
    }
  }
}
// ====== VERNIZ PU / VERNIZ COMUM (1ª PASSAGEM) ======
double? totalVernizPu;

double? totalVernizComum;

// Área total da madeira que usa Verniz PU
final double areaMadeiraPu =
    _calcularAreaM2VernizParaMovel(itensDocs, paraVernizPu: true);

// Área total da madeira que usa Verniz Comum
final double areaMadeiraComum =
    _calcularAreaM2VernizParaMovel(itensDocs, paraVernizPu: false);

// Área das LÂMINAS (entra só na conta do Verniz PU)
final double areaLaminas =
    _calcularAreaM2TotalLaminas(itensDocs);

// ------- VERNIZ PU -------
if (isVernizPu) {
  final double areaTotal = areaMadeiraPu + areaLaminas;

  if (areaTotal > 0) {

    final precoM2 = _toDouble(itemData['precoM2']);
    if (precoM2 != null && precoM2 > 0) {
      totalVernizPu = precoM2 * areaTotal;
    }
  } else {
    // 🔥 força sumir da tabela
    totalVernizPu = null;
  }
}

// ------- VERNIZ COMUM -------
if (isVernizComum) {
  final double areaTotal = areaMadeiraComum;

  if (areaTotal > 0) {

    final precoM2 = _toDouble(itemData['precoM2']);
    if (precoM2 != null && precoM2 > 0) {
      totalVernizComum = precoM2 * areaTotal;
    }
  } else {
    // 🔥 força sumir da tabela
    totalVernizComum = null;
  }
}

// ====== COLA FORMICA ======
double? colaLitrosTotal;
double? colaPrecoL;

if (isColaFormica) {
  final double lm2Mdf = _toDouble(itemData['lm2Mdf']) ?? 0;
  final double lm2Formica = _toDouble(itemData['lm2Formica']) ?? 0;
  colaPrecoL = _toDouble(itemData['precoL']);

  double somaLitros = 0;

  final listaItens =
      (itemData['colaFormicaItens'] as List?) ?? [];
  for (final cfg in listaItens) {
    if (cfg is Map<String, dynamic>) {
      final id = cfg['itemMovelId'] as String?;
      if (id == null) continue;

      DocumentSnapshot? alvo;
      for (final d in itensDocs) {
        if (d.id == id) {
          alvo = d;
          break;
        }
      }
      if (alvo == null) continue;

      // LITROS (quantidade em L)
      somaLitros += _calcularLitrosColaFormicaParaItem(
        alvo,
        lm2Mdf,
        lm2Formica,
      );

    }
  }

  final extraLitros = _toDouble(itemData['extraLitros']) ?? 0;
  somaLitros += extraLitros;

  if (somaLitros > 0) colaLitrosTotal = somaLitros;
}

      // ====== COLA BRANCA (L) ======
      final litrosColaBranca = _toDouble(itemData['litros']);
      final precoLColaBranca = _toDouble(itemData['precoL']);
      double? totalColaBranca;
      if (isColaBranca &&
          litrosColaBranca != null &&
          precoLColaBranca != null) {
        totalColaBranca = litrosColaBranca * precoLColaBranca;
      }

      // ====== FITA (m) ======
      final metrosFita =
          _toDouble(itemData['metrosFita']); // digitado na página do orçamento
      final precoTotalFita =
          _toDouble(itemData['precoMetro']); // preço TOTAL do item
      final metragemItem =
          _toDouble(itemData['metragem']); // metragem cadastrada no item

      double? precoPorMetroFita;
      double? totalFita;

      if ((isFita || isOutros)&&
          metrosFita != null &&
          precoTotalFita != null &&
          metragemItem != null &&
          metragemItem > 0) {
        precoPorMetroFita = precoTotalFita / metragemItem; // R$/m
        totalFita = metrosFita * precoPorMetroFita;
      }

// --- PINTURA ---
final precoM2Pintura = _toDouble(itemData['precoM2']);
double? pinturaM2;
double? quantidadePintura;
double? totalPintura;

if (isPintura) {
  final linhasPintura = (itemData['linhasPintura'] as List?) ?? [];
  final bool arredondarQtde = itemData['arredondarQuantidade'] == true;

  double somaM2 = 0;

  for (final l in linhasPintura) {
    if (l is Map<String, dynamic>) {
      final q = _toDouble(l['quantidade']);
      final c = _toDouble(l['comprimento']);
      final g = _toDouble(l['largura']);

      if (q != null && c != null && g != null) {
        somaM2 += q * (c * g / 10000.0); // cm² → m²
      }
    }
  }

  if (somaM2 > 0) {
    pinturaM2 = somaM2;

    // QUANTIDADE usada na tabela
    quantidadePintura =
        arredondarQtde ? somaM2.ceilToDouble() : somaM2;

    // TOTAL deve usar QUANTIDADE se arredondado
    if (precoM2Pintura != null) {
      totalPintura = arredondarQtde
          ? quantidadePintura * precoM2Pintura
          : pinturaM2 * precoM2Pintura;
    }
  }
}

      // MADEIRA MACIÇA
      final volume = _calcularVolumeM3Madeira(itemDoc);
      final precoM3 = _toDouble(itemData['precoM3']) ?? 0;
      final totalMadeiraMacica = (volume/1000000) * precoM3;

      // ====== SOMA NO TOTAL BRUTO ======
      double totalItem = 0;

      if (isFolha && totalFolha != null) {
        totalItem = totalFolha;
      } else if (isUnidade && totalUnidade != null) {
        totalItem = totalUnidade;
      } else if (isColaFormica &&
          colaLitrosTotal != null &&
          colaPrecoL != null) {
        totalItem = colaLitrosTotal * colaPrecoL;
      } else if (isColaBranca && totalColaBranca != null) {
        totalItem = totalColaBranca;
      } else if ((isFita || isOutros) && totalFita != null) {
        totalItem = totalFita;
      } else if (isPintura && totalPintura != null) {
        totalItem = totalPintura * 1.20;
      } else if (isVernizPu && totalVernizPu != null) {
        totalItem = totalVernizPu;
      } else if (isVernizComum && totalVernizComum != null) {
        totalItem = totalVernizComum;
      } else if (isMadeiraMacica) {
        totalItem = totalMadeiraMacica;
      } else if (!isFolha &&
          !isUnidade &&
          !isColaFormica &&
          !isColaBranca &&
          !isFita &&
          !isOutros &&
          !isPintura) {
        final q = quantidadeUsada;
        final p = precoPorQuantidade;
        if (q != null && p != null) {
          totalItem = q * p;
        }
      }

      totalBruto += totalItem;
    }

    // ========= 2ª PASSAGEM: desenhar linhas dos itens + Total Bruto =========
    return Column(
      children: [
        // Tabela de itens
        // This is intentionally a shrink-wrapped ListView. This is the
        // layout used by the older working version of this screen.
        // IMPORTANT:
        // The orçamento page already owns the vertical scrolling.
        // Build every item as a normal child so this widget reports its
        // complete height to the móvel card instead of creating a nested
        // viewport. This makes the card grow with all of its item rows.
        Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(itensDocs.length, (index) {
            final itemDoc = itensDocs[index];
            final itemData =
                itemDoc.data() as Map<String, dynamic>? ?? {};
            final itemName =
                itemData['itemName'] as String? ?? "(sem nome)";
            final unitType = itemData['unitType'];
            final subcategoryItem = itemData['subcategory'];
            final subLower =
                (subcategoryItem as String?)?.toLowerCase() ?? '';
            

            final bool isFolha = unitType == 'folha';
            final bool isColaBranca =
                unitType == 'litro' &&
                itemName.toLowerCase() == 'cola branca';
            final bool isColaFormica =
                unitType == 'litro' &&
                itemName.toLowerCase() == 'cola formica';
            final bool isUnidade = unitType == 'unidade';
            final bool isFita =
                subLower == 'fita' || subLower == 'fitas';
            final bool isOutros =
                subLower == 'outros' || subLower == 'outro';
            final bool isPintura =
                unitType == 'litro' && subLower == 'tintas';
            final bool isMadeiraMacica = unitType == 'madeiraMacica';
            final bool isVernizPu = unitType == 'litro' &&
                itemName.toLowerCase() == 'verniz pu';
            final bool isVernizComum = unitType == 'litro' &&
                itemName.toLowerCase() == 'verniz comum';
            final bool isValorTotal = isUnidade && (itemData['isValorTotal'] == true);
          

            // valores genéricos (para outros tipos)
            final medidaUsada = _toDouble(itemData['medidaUsada']);
            final quantidadeUsada =
                _toDouble(itemData['quantidadeUsada']);
            final precoPorQuantidade =
                _toDouble(itemData['precoPorQuantidade']);

            final unidadeMedida =
                _unitSuffix(unitType as String?);

// --- FOLHA ---
final linhasFolha = (itemData['linhas'] as List?) ?? [];
final double? areaFolha = _toDouble(itemData['areaFolha']);
final double? precoFolha = _toDouble(itemData['precoFolha']);
final double taxaPerca = _toDouble(itemData['taxaPerca']) ?? 0;

double? tamanhoFolha;
double? quantidadeFolha;
double? totalFolha;

if (isFolha) {
  double somaM2Medidas = 0;
  double somaFolhasManuais = 0;

  for (final raw in linhasFolha) {
    if (raw is! Map<String, dynamic>) continue;

    // Folhas digitadas diretamente
    final qFolhas = _toDouble(raw['qtdFolhas']);

    if (qFolhas != null && qFolhas > 0) {
      somaFolhasManuais += qFolhas;
    }

    // Medidas digitadas
    final q = _toDouble(raw['quantidade']);
    final c = _toDouble(raw['comprimento']);
    final g = _toDouble(raw['largura']);

    if (q != null && c != null && g != null) {
      somaM2Medidas += q * (c * g / 10000.0);
    }
  }

  // Área usada pelas medidas
  if (somaM2Medidas > 0) {
    tamanhoFolha = somaM2Medidas;
  }

  double folhasCalculadas = 0;

  // Calcula folhas provenientes das medidas
  if (areaFolha != null && areaFolha > 0 && somaM2Medidas > 0) {
    folhasCalculadas = somaM2Medidas / areaFolha;

    // perda somente sobre o material calculado pelas medidas
    folhasCalculadas *= (1 + taxaPerca / 100);
  }

  // SOMA medidas + folhas digitadas
  final totalQuantidadeFolhas =
      folhasCalculadas + somaFolhasManuais;

  if (totalQuantidadeFolhas > 0) {
    quantidadeFolha = totalQuantidadeFolhas;
  }

  if (quantidadeFolha != null && precoFolha != null) {
    totalFolha = quantidadeFolha * precoFolha;
  }
}

// --- PINTURA ---
final precoM2Pintura = _toDouble(itemData['precoM2']);
double? pinturaM2;
double? quantidadePintura;
double? totalPintura;

if (isPintura) {
  final linhasPintura = (itemData['linhasPintura'] as List?) ?? [];
  final bool arredondarQtde = itemData['arredondarQuantidade'] == true;

  double somaM2 = 0;

  for (final l in linhasPintura) {
    if (l is Map<String, dynamic>) {
      final q = _toDouble(l['quantidade']);
      final c = _toDouble(l['comprimento']);
      final g = _toDouble(l['largura']);

      if (q != null && c != null && g != null) {
        somaM2 += q * (c * g / 10000.0); // cm² → m²
      }
    }
  }

  if (somaM2 > 0) {
    pinturaM2 = somaM2;

    // QUANTIDADE usada na tabela
    quantidadePintura =
        arredondarQtde ? somaM2.ceilToDouble() : somaM2;

    // TOTAL deve usar QUANTIDADE se arredondado
    if (precoM2Pintura != null) {
      totalPintura = arredondarQtde
          ? quantidadePintura * precoM2Pintura
          : pinturaM2 * precoM2Pintura;
    }
  }
}

            // ====== UNIDADE ======
final double? quantidadeUnd = _toDouble(itemData['quantidadeUnd']);

// usa o mesmo itemName que você já tem lá em cima


// ====== VERNIZ PU / VERNIZ COMUM (1ª PASSAGEM) ======
double? vernizPuM2;
double? vernizPuLitros;
double? totalVernizPu;

double? vernizComumM2;
double? vernizComumLitros;
double? totalVernizComum;

// Área total da madeira que usa Verniz PU
final double areaMadeiraPu =
    _calcularAreaM2VernizParaMovel(itensDocs, paraVernizPu: true);

// Área total da madeira que usa Verniz Comum
final double areaMadeiraComum =
    _calcularAreaM2VernizParaMovel(itensDocs, paraVernizPu: false);

// Área das LÂMINAS (entra só na conta do Verniz PU)
final double areaLaminas = _calcularAreaM2TotalLaminas(itensDocs);

// ------- VERNIZ PU -------
if (isVernizPu) {
  final double areaTotal = areaMadeiraPu + areaLaminas;

  if (areaTotal > 0) {
    vernizPuM2 = areaTotal;
    vernizPuLitros = areaTotal; // 1 L para 1 m²
    final precoM2 = _toDouble(itemData['precoM2']);
    if (precoM2 != null) {
      totalVernizPu = precoM2 * areaTotal;
    }
  }
}

// ------- VERNIZ COMUM -------
if (isVernizComum) { // se seu bool chama isVernizNormal, troque aqui
  final double areaTotal = areaMadeiraComum;

  if (areaTotal > 0) {
    vernizComumM2 = areaTotal;
    vernizComumLitros = areaTotal;
    final precoM2 = _toDouble(itemData['precoM2']);
    if (precoM2 != null) {
      totalVernizComum = precoM2 * areaTotal;
    }
  }
}

// ====== COLA FORMICA ======
double? colaLitrosTotal;
double? colaPrecoL;
double? colaMetrosTotal;
double? colaM2Total;

if (isColaFormica) {
  final double lm2Mdf = _toDouble(itemData['lm2Mdf']) ?? 0;
  final double lm2Formica = _toDouble(itemData['lm2Formica']) ?? 0;
  colaPrecoL = _toDouble(itemData['precoL']);

  double somaLitros = 0;
  double somaMetros = 0;
  double somaM2 = 0;

  final listaItens =
      (itemData['colaFormicaItens'] as List?) ?? [];
  for (final cfg in listaItens) {
    if (cfg is Map<String, dynamic>) {
      final id = cfg['itemMovelId'] as String?;
      if (id == null) continue;

      DocumentSnapshot? alvo;
      for (final d in itensDocs) {
        if (d.id == id) {
          alvo = d;
          break;
        }
      }
      if (alvo == null) continue;

      // LITROS (quantidade em L)
      somaLitros += _calcularLitrosColaFormicaParaItem(
        alvo,
        lm2Mdf,
        lm2Formica,
      );

      // TAMANHO (m / m²) só pra exibir
      final dataAlvo =
          alvo.data() as Map<String, dynamic>? ?? {};
      final unitTypeAlvo =
          (dataAlvo['unitType'] as String?)?.toLowerCase() ?? '';
      final subAlvo =
          (dataAlvo['subcategory'] as String?)?.toLowerCase() ?? '';

      if (unitTypeAlvo != 'litro') {
        if (subAlvo.contains('fita')) {
          final metrosFita = _toDouble(dataAlvo['metrosFita']);
          final quantidadeUsadaSel =
              _toDouble(dataAlvo['quantidadeUsada']);
          final metragemItemSel =
              _toDouble(dataAlvo['metragem']);
          final metros =
              metrosFita ?? quantidadeUsadaSel ?? metragemItemSel ?? 0;
          if (metros > 0) somaMetros += metros;
        } else {
          final area = _calcularAreaM2DeFolha(alvo);
          if (area > 0) somaM2 += area;
        }
      }
    }
  }

  final extraLitros = _toDouble(itemData['extraLitros']) ?? 0;
  somaLitros += extraLitros;

  if (somaLitros > 0) colaLitrosTotal = somaLitros;
  if (somaMetros > 0) colaMetrosTotal = somaMetros;
  if (somaM2 > 0) colaM2Total = somaM2;
}

            // ====== COLA BRANCA ======
            final litrosColaBranca =
                _toDouble(itemData['litros']);
            final precoLColaBranca = _toDouble(itemData['precoL']);
            double? totalColaBranca;
            if (isColaBranca &&
                litrosColaBranca != null &&
                precoLColaBranca != null) {
              totalColaBranca =
                  litrosColaBranca * precoLColaBranca;
            }

            // ====== FITA ======
            final metrosFitaItem =
                _toDouble(itemData['metrosFita']);
            final precoTotalFitaItem =
                _toDouble(itemData['precoMetro']);
            final metragemItem =
                _toDouble(itemData['metragem']);

            double? totalFita;
            double? precoPorMetroFitaLinha;
            double? quantidadefitaitem;
            if ((isFita || isOutros) &&
                metrosFitaItem != null &&
                precoTotalFitaItem != null &&
                metragemItem != null &&
                metragemItem > 0) {
              precoPorMetroFitaLinha =
                  precoTotalFitaItem / metragemItem;
              totalFita = metrosFitaItem * precoPorMetroFitaLinha;
              quantidadefitaitem = metrosFitaItem / metragemItem;
            }

            // ✅ AQUI ENTRA ESSE IF DE ESCONDER:
            if (isVernizPu && (vernizPuM2 == null || vernizPuM2 == 0)) {
              return const SizedBox.shrink();
            }

            if (isVernizComum && (vernizComumM2 == null || vernizComumM2 == 0)) {
              return const SizedBox.shrink();
            }

            return Dismissible(
              key: ValueKey(itemDoc.id),
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
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Remover item"),
                        content: Text(
                            'Deseja remover o item "$itemName" deste móvel?'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(ctx, false),
                            child: const Text("Cancelar"),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(ctx, true),
                            child: const Text(
                              "Remover",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ) ??
                    false;
              },
              onDismissed: (direction) async {
                try {
                  await itemDoc.reference.delete();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Item "$itemName" removido de "$nomeMovel".'),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text("Erro ao remover item: $e"),
                    ),
                  );
                }
              },
              child: InkWell(
                hoverColor: const Color(0xFFF4EEEA),
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  if (isFolha) {
                    _editFolhaMedidasDialog(
                        doc, itemDoc, itemName);
                  } else if (isColaBranca) {
                    _editColaBrancaDialog(
                        itemDoc, itemName);
                  } else if (isColaFormica) {
                    _editColaFormicaDialog(
                        doc, itemDoc, itemName);
                  } else if (isPintura) {
                    _editPinturaDialog(
                        doc, itemDoc, itemName);
                  } else if (isUnidade) {
                      if (isValorTotal) {
                        // 👉 comportamento especial pro item "Valor Total"
                        _editValorTotalDialog(itemDoc, itemName);
                      } else {
                        // 👉 todos os outros unidade continuam iguais
                        _editUnidadeQuantidadeDialog(itemDoc, itemName);
                      }
                  } else if (isFita || isOutros){
                    _editFitaMetrosDialog(
                        itemDoc,  itemName);
                  } else if (isMadeiraMacica){
                    _editMadeiraMacicaDialog(
                      doc, itemDoc, itemName);
                  }else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Edição detalhada ainda não configurada para esse tipo de item."),
                      ),
                    );
                  }
                },
                child: Container(
                  margin:
                      const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                      vertical: 4, horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      // ITEM
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 6,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                itemName,
                                style: const TextStyle(
                                    fontSize: 13),
                                overflow:
                                    TextOverflow.ellipsis,
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // MEDIDA
                      Expanded(
                        flex: 2,
                        child: Builder(
                          builder: (context) {
                            if (isColaFormica ||
                                isColaBranca) {
                              return const Text(
                                "L",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13),
                              );
                            }

                            if (isPintura || isVernizPu || isVernizComum) {
                              return const Text(
                                "L",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13),
                              );
                            }
                            if (isMadeiraMacica){
                              return const Text(
                                "m³",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13),
                              );
                            }
                            if (isFita || isOutros) {
                              return const Text(
                                "m",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13),
                              );
                            }

                            if (isFolha) {
                              return const Text(
                                "m²",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13),
                              );
                            }
                            if (isUnidade) {
                              if (isValorTotal) {
                                final medidaVT =
                                    (itemData['medidaValorTotal'] as String?) ?? "Und";

                                return Text(
                                  medidaVT,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13),
                                );
                              }

                              // unidade normal
                              return const Text(
                                "Und",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13),
                              );
                            }

                            final medida = medidaUsada;
                            if (medida == null) {
                              return const Text(
                                "-",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13),
                              );
                            }
                            return Text(
                              "${_formatDecimal(medida)} $unidadeMedida",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13),
                            );
                          },
                        ),
                      ),

                      // TAMANHO
                      Expanded(
                        flex: 2,
                        child: Builder(
                          builder: (context) {
                            if (isColaBranca) {
                              return const Text(
                                "-",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13),
                              );
                            }

                            if (isColaFormica) {
                              final hasMetros = (colaMetrosTotal ?? 0) > 0;
                              final hasM2 = (colaM2Total ?? 0) > 0;

                              if (!hasMetros && !hasM2) {
                                return const Text(
                                  "-",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13),
                                );
                              }

                              String texto;
                              if (hasMetros && hasM2) {
                                texto =
                                    "${_formatDecimal(colaMetrosTotal!)} m / ${_formatDecimal(colaM2Total!)} m²";
                              } else if (hasMetros) {
                                texto =
                                    "${_formatDecimal(colaMetrosTotal!)} m";
                              } else {
                                texto =
                                    "${_formatDecimal(colaM2Total!)} m²";
                              }

                              return Text(
                                texto,
                                textAlign:
                                    TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13),
                              );
                            }

                            if (isFita || isOutros) {
                              if (metrosFitaItem ==
                                  null) {
                                return const Text(
                                  "-",
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13),
                                );
                              }
                              return Text(
                                "${_formatDecimal(metrosFitaItem)} m",
                                textAlign:
                                    TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13),
                              );
                            }

                              // dentro do Builder da coluna TAMANHO
                              if (isVernizPu) {
                                if (vernizPuM2 == null || vernizPuM2 == 0) {
                                  return const Text(
                                    "-",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13),
                                  );
                                }
                                return Text(
                                  "${_formatDecimal(vernizPuM2)} m²",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13),
                                );
                              }

                              if (isVernizComum) { // ou isVernizNormal
                                if (vernizComumM2 == null || vernizComumM2 == 0) {
                                  return const Text(
                                    "-",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13),
                                  );
                                }
                                return Text(
                                  "${_formatDecimal(vernizComumM2)} m²",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13),
                                );
                              }

                            else if (isMadeiraMacica) {
                              final tamanhoM3 = _calcularVolumeM3Madeira(itemDoc);

                              if (tamanhoM3 <= 0) {
                                return const Text(
                                  "-",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                );
                              }

                              return Text(
                                "${_formatDecimal(tamanhoM3/1000000)} m³",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              );
                            }

                            if (isFolha) {
                              if (tamanhoFolha ==
                                  null) {
                                return const Text(
                                  "-",
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13),
                                );
                              }
                              return Text(
                                "${_formatDecimal(tamanhoFolha)} m²",
                                textAlign:
                                    TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13),
                              );
                            }

                            if (isPintura) {
                              if (pinturaM2 == null) {
                                return const Text(
                                  "-",
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13),
                                );
                              }
                              return Text(
                                "${_formatDecimal(pinturaM2)} m²",
                                textAlign:
                                    TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13),
                              );
                            }

                            if (isUnidade) {
                              return const Text(
                                "-",
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13),
                              );
                            }

                            final tamanhoValue =
                                itemData['tamanho'];
                            final tamanhoStr =
                                tamanhoValue == null
                                    ? '-'
                                    : tamanhoValue
                                        .toString();
                            return Text(
                              tamanhoStr,
                              textAlign:
                                  TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13),
                            );
                          },
                        ),
                      ),

                      // QUANTIDADE
                      Expanded(
                        flex: 2,
                        child: Builder(
                          builder: (context) {
                            if (isColaFormica) {
                              if (colaLitrosTotal == null) {
                                return const Text(
                                  "-",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                );
                              }
                              return Text(
                                _formatDecimal(colaLitrosTotal),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              );
                            }

                            if (isVernizPu) {
                              if (vernizPuLitros == null || vernizPuLitros == 0) {
                                return const Text(
                                  "-",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                );
                              }
                              return Text(
                                _formatDecimal(vernizPuLitros),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              );
                            }

                            if (isVernizComum) {
                              if (vernizComumLitros == null || vernizComumLitros == 0) {
                                return const Text(
                                  "-",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                );
                              }
                              return Text(
                                _formatDecimal(vernizComumLitros),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              );
                            }

                            if (isPintura) {
                              if (quantidadePintura == null) {
                                return const Text(
                                  "-",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                );
                              } else {
                                return Text(
                                  _formatDecimal(quantidadePintura * 1.20), // 👈 sem unidade
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13),
                                );
                              }
                            }
                            if (isMadeiraMacica) {
                              final tamanhoM3 = _calcularVolumeM3Madeira(itemDoc);

                              if (tamanhoM3 <= 0) {
                                return const Text(
                                  "-",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                );
                              }

                              return Text(
                                _formatDecimal(tamanhoM3/1000000),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              );
                            }

                            if (isColaBranca) {
                              if (litrosColaBranca ==
                                  null) {
                                return const Text(
                                  "-",
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13),
                                );
                              }
                              return Text(
                                _formatDecimal(
                                    litrosColaBranca),
                                textAlign:
                                    TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13),
                              );
                            }
                            if (isFita || isOutros) {
                              if (quantidadefitaitem ==
                                  null) {
                                return const Text(
                                  "-",
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13),
                                );
                              }
                              return Text(
                                _formatDecimal(
                                    quantidadefitaitem),
                                textAlign:
                                    TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13),
                              );
                            }

                            if (isFolha) {
                              if (quantidadeFolha ==
                                  null) {
                                return const Text(
                                  "-",
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13),
                                );
                              }
                              return Text(
                                _formatDecimal(
                                    quantidadeFolha),
                                textAlign:
                                    TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13),
                              );
                            }

                            if (isUnidade) {
                              if (quantidadeUnd ==
                                  null) {
                                return const Text(
                                  "-",
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13),
                                );
                              }
                              return Text(
                                _formatDecimal(
                                    quantidadeUnd),
                                textAlign:
                                    TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13),
                              );
                            }

                            final q = quantidadeUsada;
                            if (q == null) {
                              return const Text(
                                "-",
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13),
                              );
                            }
                            return Text(
                              _formatDecimal(q),
                              textAlign:
                                  TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13),
                            );
                          },
                        ),
                      ),

                      // PREÇO
                      Expanded(
                        flex: 2,
                        child: _buildPrecoCell(
                          itemData,
                          isFolha: isFolha,
                          isColaFormica: isColaFormica,
                          isColaBranca: isColaBranca,
                          isUnidade: isUnidade,
                          isFita: isFita,
                          isOutros: isOutros,
                          isPintura: isPintura,
                          isMadeiraMacica: isMadeiraMacica,
                          isVernizPu: isVernizPu,
                          isVernizComum: isVernizComum,
                        ),
                      ),

                      // TOTAL
                      Expanded(
                        flex: 2,
                        child: Builder(
                          builder: (context) {
                            // 👇 Pega o nome do item pra detectar "Valor Total"

                            if (isColaFormica) {
                              if (colaLitrosTotal == null || colaPrecoL == null) {
                                return const Text(
                                  "-",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                );
                              }
                              final total = colaLitrosTotal * colaPrecoL;
                              return Text(
                                "R\$ ${_formatDecimal(total, dec: 2)}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }

                            if (isPintura) {
                              if (totalPintura == null) {
                                return const Text(
                                  "-",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                );
                              }
                              return Text(
                                "R\$ ${_formatDecimal(totalPintura * 1.20, dec: 2)}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }

                            if (isMadeiraMacica) {
                              final volume = _calcularVolumeM3Madeira(itemDoc);
                              final precoM3 = _toDouble(itemData['precoM3']) ?? 0;

                              if (volume <= 0 || precoM3 <= 0) {
                                return const Text(
                                  "-",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                );
                              }

                              final total = (volume / 1000000) * precoM3;

                              return Text(
                                "R\$ ${_formatDecimal(total, dec: 2)}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }

                            if (isColaBranca) {
                              if (totalColaBranca == null) {
                                return const Text(
                                  "-",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                );
                              }
                              return Text(
                                "R\$ ${_formatDecimal(totalColaBranca, dec: 2)}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }

                            if (isFita || isOutros) {
                              if (totalFita == null) {
                                return const Text(
                                  "-",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                );
                              }
                              return Text(
                                "R\$ ${_formatDecimal(totalFita, dec: 2)}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }

                            if (isFolha) {
                              if (totalFolha == null) {
                                return const Text(
                                  "-",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                );
                              }
                              return Text(
                                "R\$ ${_formatDecimal(totalFolha, dec: 2)}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }

                            if (isVernizPu) {
                              if (totalVernizPu == null) {
                                return const Text(
                                  "-",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                );
                              }
                              return Text(
                                "R\$ ${_formatDecimal(totalVernizPu, dec: 2)}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }

                            if (isVernizComum) {
                              if (totalVernizComum == null) {
                                return const Text(
                                  "-",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                );
                              }
                              return Text(
                                "R\$ ${_formatDecimal(totalVernizComum, dec: 2)}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }

                            if (isUnidade) {
                              final qtd = _toDouble(itemData['quantidadeUnd']);
                              if (qtd == null) {
                                return const Text(
                                  "-",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                );
                              }

                              final bool isValorTotal = isUnidade && (itemData['isValorTotal'] == true);

                              final precoTabela = _toDouble(itemData['precoUnidade']);
                              final precoCustom = _toDouble(itemData['precoUnd']);

                              final precoBase = isValorTotal
                                  ? (precoCustom ?? precoTabela)
                                  : precoTabela;

                              if (precoBase == null) {
                                return const Text(
                                  "-",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                );
                              }

                              final total = qtd * precoBase;

                              return Text(
                                "R\$ ${_formatDecimal(total, dec: 2)}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }

                            final qtd = quantidadeUsada;
                            final preco = precoPorQuantidade;
                            if (qtd == null || preco == null) {
                              return const Text(
                                "-",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13),
                              );
                            }
                            final total = qtd * preco;
                            return Text(
                              "R\$ ${_formatDecimal(total, dec: 2)}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),

          const SizedBox(height: 8),

                  // Linha de TOTAL BRUTO (lado direito do móvel)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Total Bruto: R\$ ${_formatDecimal(totalBruto, dec: 2)}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 🔹 Resumo (Frete / Extra / Mão de Obra / Lucro / Total Geral)
                  Align(
                    alignment: Alignment.centerRight,
                    child: StatefulBuilder(
                      builder: (context, setResumoState) {
                        final movelData =
                            doc.data() as Map<String, dynamic>? ?? {};

                        // ---------- valores iniciais ----------
                        final freteCtrl = _getOrCreateResumoController(
                          _freteControllers,
                          doc.id,
                          initialText: movelData['frete']?.toString() ?? '',
                        );
                        final extraCtrl = _getOrCreateResumoController(
                          _almocoControllers,
                          doc.id,
                          initialText: movelData['extra']?.toString() ?? '',
                        );
                        final maoObraCtrl = _getOrCreateResumoController(
                          _maoObraControllers,
                          doc.id,
                          initialText: movelData['maoObra']?.toString() ?? '',
                        );
                        final lucroCtrl = _getOrCreateResumoController(
                          _lucroControllers,
                          doc.id,
                          initialText: movelData['lucroPercentual']?.toString() ?? '',
                        );

                        final obsCtrl = _getOrCreateObsController(
                          doc.id,
                          initial: movelData['obs']?.toString() ?? '',
                        );

                        final frete = _parseResumoDouble(freteCtrl.text);
                        final extra = _parseResumoDouble(extraCtrl.text);
                        final maoObra = _parseResumoDouble(maoObraCtrl.text);
                        final lucro = _parseResumoDouble(lucroCtrl.text);

                        final base = totalBruto + frete + extra + maoObra;
                        final totalGeral = base * (1 + (lucro / 100));

                        final movelRef = doc.reference;

                        _carregarResumoRascunhoUmaVez(
                          movelId: doc.id,
                          movelRef: movelRef,
                          freteCtrl: freteCtrl,
                          extraCtrl: extraCtrl,
                          maoObraCtrl: maoObraCtrl,
                          lucroCtrl: lucroCtrl,
                          atualizarResumo: () {
                            // Rebuild único ao abrir o móvel, depois que o
                            // rascunho salvo foi carregado. Não acontece ao digitar.
                            if (context.mounted) {
                              setResumoState(() {});
                            }
                          },
                        );

                        void autosaveResumo() {
                          setResumoState(() {}); // recalcula apenas o resumo local
                          _agendarAutosaveResumo(
                            movelId: doc.id,
                            movelRef: movelRef,
                            freteCtrl: freteCtrl,
                            extraCtrl: extraCtrl,
                            maoObraCtrl: maoObraCtrl,
                            lucroCtrl: lucroCtrl,
                          );
                        }

                        Future<void> salvarResumoAgora() {
                          return _salvarResumoAgora(
                            movelId: doc.id,
                            movelRef: movelRef,
                            freteCtrl: freteCtrl,
                            extraCtrl: extraCtrl,
                            maoObraCtrl: maoObraCtrl,
                            lucroCtrl: lucroCtrl,
                          );
                        }

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                        // ===================== OBS (LEFT) =====================
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              await _editObsDialog(doc);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black26),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Obs:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Altura natural: a observação e o cartão do móvel crescem
                                  // conforme o conteúdo, sem uma área interna de scroll fixa.
                                  Text(
                                        obsCtrl.text.trim().isEmpty
                                            ? "Clique para escrever..."
                                            : obsCtrl.text.trim(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: obsCtrl.text.trim().isEmpty
                                              ? Colors.grey
                                              : Colors.black87,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                              // ===================== RESUMO (RIGHT) =====================
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 320),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _linhaResumo(
                                      label: "Frete (R\$)",
                                      controller: freteCtrl,
                                      onChange: autosaveResumo,
                                      onSave: salvarResumoAgora,
                                    ),
                                    _linhaResumo(
                                      label: "Extra (R\$)",
                                      controller: extraCtrl,
                                      onChange: autosaveResumo,
                                      onSave: salvarResumoAgora,
                                    ),
                                    _linhaResumo(
                                      label: "Mão de Obra (R\$)",
                                      controller: maoObraCtrl,
                                      onChange: autosaveResumo,
                                      onSave: salvarResumoAgora,
                                    ),
                                    _linhaResumo(
                                      label: "(%)",
                                      controller: lucroCtrl,
                                      width: 70,
                                      onChange: autosaveResumo,
                                      onSave: salvarResumoAgora,
                                    ),

                                    // 🔥 TOTAL GERAL (HERE 👇)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const Text(
                                          "Total Geral:",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "R\$ ${_formatDecimal(totalGeral, dec: 2)}",
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ]
              );
            }
          );
  }
}
