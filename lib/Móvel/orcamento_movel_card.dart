part of '../Orçamento Base/orcamento_page.dart';

extension _MovelCardExtension on _OrcamentoPageState {
  static const Color _cardDarkBrown = Color(0xFF5A3825);
  static const Color _cardBrown = Color(0xFF79533B);
  static const Color _cardSoftBrown = Color(0xFFF4EEEA);
  static const Color _cardBorder = Color(0xFFE8E3DF);
  static const Color _cardSoftText = Color(0xFF77716D);

Widget _buildMovelCard(
  BuildContext context,
  DocumentSnapshot doc,
) {
  
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final nomeMovel = data['nome'] as String? ?? "(sem nome)";

    final itensQuery = doc.reference
        .collection('itens')
        .orderBy('createdAt', descending: false);

    return Container(
      key: ValueKey(doc.id),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho do móvel
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
            child: Row(
              children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _cardSoftBrown,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "#${data['numeroMovel']}",
                  style: const TextStyle(
                    color: _cardDarkBrown,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nomeMovel,
                  style: const TextStyle(
                    color: Color(0xFF1C1B1A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: _cardSoftBrown,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => _showAddItemMovelDialog(context, doc),
                  icon: const Icon(Icons.add_rounded, color: _cardDarkBrown),
                  tooltip: "Adicionar item",
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => _mostrarOpcoesMovel(context, doc, nomeMovel),
                icon: const Icon(Icons.more_horiz_rounded, color: _cardBrown),
                tooltip: "Opções do móvel",
              ),
            ],
          ),
          ),
          const Divider(height: 1, thickness: 1, color: _cardBorder),

          // Cabeçalho da "tabela"
          Container(
            key: ValueKey(doc.id),
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
            decoration: const BoxDecoration(
              color: _cardSoftBrown,
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    "Item",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Medida",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Tamanho",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Quantidade",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Preço",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Total",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ITENS + RESUMO
StreamBuilder<QuerySnapshot>(
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
final double? areaFolha = _toDouble(itemData['areaFolha']); // m² por folha
final double? precoFolha = _toDouble(itemData['precoFolha']);
final double taxaPerca = _toDouble(itemData['taxaPerca']) ?? 0;

double? tamanhoFolha;     // m² total
double? quantidadeFolha;  // nº de folhas (quando digitado)
double? totalFolha;

if (isFolha) {
  double somaM2 = 0;
  double somaFolhas = 0;
  bool usouQtdFolhas = false;

  for (final raw in linhasFolha) {
    if (raw is! Map<String, dynamic>) continue;

    final qFolhas = _toDouble(raw['qtdFolhas']); // <-- ajuste a key se necessário

    if (qFolhas != null && qFolhas > 0 && areaFolha != null && areaFolha > 0) {
      usouQtdFolhas = true;
      somaFolhas += qFolhas;
      somaM2 += qFolhas * areaFolha;
      continue;
    }

    final q = _toDouble(raw['quantidade']);
    final c = _toDouble(raw['comprimento']);
    final g = _toDouble(raw['largura']);
    if (q != null && c != null && g != null) {
      somaM2 += q * (c * g / 10000.0);
    }
  }

  if (somaM2 > 0) tamanhoFolha = somaM2;

  if (somaFolhas > 0) {
    quantidadeFolha = somaFolhas; // digitado
  } else if (tamanhoFolha != null && areaFolha != null && areaFolha > 0) {
    quantidadeFolha = tamanhoFolha / areaFolha; // calculado
  }

  if (quantidadeFolha != null && precoFolha != null) {
    // ✅ taxaPerca SÓ quando NÃO usou qtdFolhas
    final fatorPerca = usouQtdFolhas ? 1.0 : (1 + (taxaPerca / 100.0));
    totalFolha = precoFolha * quantidadeFolha * fatorPerca;
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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itensDocs.length,
          itemBuilder: (context, index) {
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
final double? areaFolha = _toDouble(itemData['areaFolha']); // m² por folha
final double? precoFolha = _toDouble(itemData['precoFolha']);
final double taxaPerca = _toDouble(itemData['taxaPerca']) ?? 0;

double? tamanhoFolha;     // m² total
double? quantidadeFolha;  // nº de folhas (quando digitado)
double? totalFolha;

if (isFolha) {
  double somaM2 = 0;
  double somaFolhas = 0;

  for (final raw in linhasFolha) {
    if (raw is! Map<String, dynamic>) continue;

    final qFolhas = _toDouble(raw['qtdFolhas']); // <-- ajuste a key se necessário

    if (qFolhas != null && qFolhas > 0 && areaFolha != null && areaFolha > 0) {
      somaFolhas += qFolhas;
      somaM2 += qFolhas * areaFolha;
      continue;
    }

    final q = _toDouble(raw['quantidade']);
    final c = _toDouble(raw['comprimento']);
    final g = _toDouble(raw['largura']);
    if (q != null && c != null && g != null) {
      somaM2 += q * (c * g / 10000.0);
    }
  }

  if (somaM2 > 0) tamanhoFolha = somaM2;

  final quantidadeperca = 1 + (taxaPerca/100);

  if (somaFolhas > 0) {
    quantidadeFolha = somaFolhas; // digitado
  } else if (tamanhoFolha != null && areaFolha != null && areaFolha > 0) {
    quantidadeFolha = (tamanhoFolha / areaFolha) * quantidadeperca; // calculado
  }

  if (quantidadeFolha != null && precoFolha != null) {
    // ✅ taxaPerca SÓ quando NÃO usou qtdFolhas
    totalFolha = precoFolha * quantidadeFolha;
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
                key: ValueKey(doc.id),
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
                  key: ValueKey(doc.id),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 4),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF0ECE9)),
                    ),
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
          },
        ),

          const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _cardSoftBrown,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Total Bruto  •  R\$ ${_formatDecimal(totalBruto, dec: 2)}",
                          style: const TextStyle(
                            color: _cardDarkBrown,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

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

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        // ===================== OBS (LEFT) =====================
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              await _editObsDialog(doc);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                border: Border.all(color: _cardBorder),
                                borderRadius: BorderRadius.circular(14),
                                color: const Color(0xFFFCFBFA),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.notes_rounded, size: 17, color: _cardBrown),
                                      SizedBox(width: 7),
                                      Text(
                                        "Observações",
                                        style: TextStyle(
                                          color: _cardDarkBrown,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // 👇 FIXED HEIGHT + SCROLL
                                  SizedBox(
                                    height: 140, // 🔥 control OBS height here
                                    child: SingleChildScrollView(
                                      child: Text(
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
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                              const SizedBox(width: 16),

                              // ===================== RESUMO (RIGHT) =====================
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 320),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _linhaResumo(
                                      label: "Frete (R\$)",
                                      controller: freteCtrl,
                                      onChange: () => setResumoState(() {}),
                                      onSave: () async {
                                        await movelRef.update({
                                          'frete': _parseResumoDouble(freteCtrl.text),
                                        });
                                      },
                                    ),
                                    _linhaResumo(
                                      label: "Extra (R\$)",
                                      controller: extraCtrl,
                                      onChange: () => setResumoState(() {}),
                                      onSave: () async {
                                        await movelRef.update({
                                          'extra': _parseResumoDouble(extraCtrl.text),
                                        });
                                      },
                                    ),
                                    _linhaResumo(
                                      label: "Mão de Obra (R\$)",
                                      controller: maoObraCtrl,
                                      onChange: () => setResumoState(() {}),
                                      onSave: () async {
                                        await movelRef.update({
                                          'maoObra': _parseResumoDouble(maoObraCtrl.text),
                                        });
                                      },
                                    ),
                                    _linhaResumo(
                                      label: "(%)",
                                      controller: lucroCtrl,
                                      width: 70,
                                      onChange: () => setResumoState(() {}),
                                      onSave: () async {
                                        await movelRef.update({
                                          'lucroPercentual': _parseResumoDouble(lucroCtrl.text),
                                        });
                                      },
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
          )
        ]
      )
    );
  }
}
