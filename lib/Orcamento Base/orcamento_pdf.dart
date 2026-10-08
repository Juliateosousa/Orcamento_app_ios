part of 'orcamento_page.dart';

extension _OrcamentoPdfExtension on _OrcamentoPageState {
Future<void> _gerarPdfOrcamento() async {
  try {
    final pdf = pw.Document();

    // 1) Busca todos os móveis deste orçamento
    final moveisQuery = await FirebaseFirestore.instance
        .collection('moveis')
        .where('numeroOrcamento', isEqualTo: widget.numeroOrcamento)
        .get();

    if (moveisQuery.docs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum móvel para gerar PDF.")),
      );
      return;
    }

    final moveisDocs = moveisQuery.docs.toList();
    moveisDocs.sort((a, b) {
    final da = (a.data() as Map<String, dynamic>? ?? {});
    final db = (b.data() as Map<String, dynamic>? ?? {});

    final na = (da['numeroMovel'] as num?)?.toInt() ?? 0;
    final nb = (db['numeroMovel'] as num?)?.toInt() ?? 0;

    return na.compareTo(nb);
  });

    for (final movelDoc in moveisDocs) {
      final movelData = movelDoc.data() as Map<String, dynamic>? ?? {};
      final nomeMovel = movelData['nome'] as String? ?? "(sem nome)";
      final int? numeroMovel = movelData['numeroMovel'] as int?;

      // 2) Itens do móvel
      final itensSnap = await movelDoc.reference
          .collection('itens')
          .orderBy('createdAt', descending: false)
          .get();
      final itensDocs = itensSnap.docs;

      // =====================================================
      // 2.1 – PRIMEIRA PASSAGEM: calcular valores dos itens
      // =====================================================
      final List<_PdfLinhaItem> linhasPdf = [];
      double totalBruto = 0.0;

      // Áreas auxiliares para verniz
      final double areaMadeiraPu =
          _calcularAreaM2VernizParaMovel(itensDocs, paraVernizPu: true);
      final double areaMadeiraComum =
          _calcularAreaM2VernizParaMovel(itensDocs, paraVernizPu: false);
      final double areaLaminas =
          _calcularAreaM2TotalLaminas(itensDocs);

      for (final itemDoc in itensDocs) {
        final itemData = itemDoc.data() as Map<String, dynamic>? ?? {};
        final itemName = itemData['itemName'] as String? ?? "(sem nome)";
        final unitType = itemData['unitType'];
        final subcategoryItem = itemData['subcategory'];
        final subLower =
            (subcategoryItem as String?)?.toLowerCase() ?? '';

        final bool isFolha = unitType == 'folha';
        final bool isColaBranca =
            unitType == 'litro' && itemName.toLowerCase() == 'cola branca';
        final bool isColaFormica =
            unitType == 'litro' && itemName.toLowerCase() == 'cola formica';
        final bool isUnidade = unitType == 'unidade';
        final bool isFita = subLower == 'fita' || subLower == 'fitas';
        final bool isOutros = subLower == 'outros' || subLower == 'outro';
        final bool isPintura =
            unitType == 'litro' && subLower == 'tintas';
        final bool isMadeiraMacica = unitType == 'madeiraMacica';
        final bool isVernizPu =
            unitType == 'litro' && itemName.toLowerCase() == 'verniz pu';
        final bool isVernizComum =
            unitType == 'litro' && itemName.toLowerCase() == 'verniz comum';
        final bool isValorTotal = isUnidade && (itemData['isValorTotal'] == true);


        final medidaUsada = _toDouble(itemData['medidaUsada']);
        final quantidadeUsada = _toDouble(itemData['quantidadeUsada']);
        final precoPorQuantidade = _toDouble(itemData['precoPorQuantidade']);
        final unidadeMedida = _unitSuffix(unitType as String?);

// --- FOLHA ---
final linhasFolha = (itemData['linhas'] as List?) ?? [];
final double? areaFolha = _toDouble(itemData['areaFolha']); // m² por folha
final double? precoFolha = _toDouble(itemData['precoFolha']);
final double taxaPerca = _toDouble(itemData['taxaPerca']) ?? 0;

double? tamanhoFolha;     // m² total
double? quantidadeFolha;  // nº de folhas
double? totalFolha;

if (isFolha) {
  double somaM2 = 0;
  double somaFolhas = 0;
  bool usouQtdFolhas = false;

  for (final raw in linhasFolha) {
    if (raw is! Map<String, dynamic>) continue;

    final qFolhas = _toDouble(raw['qtdFolhas']);

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

  // ✅ perda como fator de AUMENTO
  final fatorPerca = 1.0 + (taxaPerca / 100.0);

  if (somaFolhas > 0) {
    quantidadeFolha = usouQtdFolhas
        ? somaFolhas
        : somaFolhas * fatorPerca;
  } else if (tamanhoFolha != null && areaFolha != null && areaFolha > 0) {
    quantidadeFolha = (tamanhoFolha / areaFolha) * fatorPerca;
  }

  if (quantidadeFolha != null && precoFolha != null) {
    totalFolha = precoFolha * quantidadeFolha;
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

        // --- COLA BRANCA ---
        final litrosColaBranca = _toDouble(itemData['litros']);
        final precoLColaBranca = _toDouble(itemData['precoL']);
        double? totalColaBranca;
        if (isColaBranca &&
            litrosColaBranca != null &&
            precoLColaBranca != null) {
          totalColaBranca = litrosColaBranca * precoLColaBranca;
        }

        // --- FITA ---
        final metrosFitaItem = _toDouble(itemData['metrosFita']);
        final precoTotalFitaItem = _toDouble(itemData['precoMetro']);
        final metragemItem = _toDouble(itemData['metragem']);

        double? totalFita;
        double? precoPorMetroFitaLinha;
        double? quantidadeFitaItem;
        if ((isFita || isOutros) &&
            metrosFitaItem != null &&
            precoTotalFitaItem != null &&
            metragemItem != null &&
            metragemItem > 0) {
          precoPorMetroFitaLinha = precoTotalFitaItem / metragemItem;
          totalFita = metrosFitaItem * precoPorMetroFitaLinha;
          quantidadeFitaItem = metrosFitaItem / metragemItem;
        }

        // --- PINTURA ---
        final precoM2Pintura = _toDouble(itemData['precoM2']);
        double? pinturaM2;
        double? quantidadePintura;
        double? totalPintura;

        if (isPintura) {
          final linhasPintura = (itemData['linhasPintura'] as List?) ?? [];
          final bool arredondarQtde =
              itemData['arredondarQuantidade'] == true;

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

            quantidadePintura =
                arredondarQtde ? somaM2.ceilToDouble() : somaM2;

            if (precoM2Pintura != null) {
              totalPintura = arredondarQtde
                  ? quantidadePintura * precoM2Pintura * 1.20
                  : pinturaM2 * precoM2Pintura * 1.20;
            }
          }
        }

        // --- MADEIRA MACIÇA ---
        final volumeCm3 = _calcularVolumeM3Madeira(itemDoc); // cm³
        final precoM3 = _toDouble(itemData['precoM3']) ?? 0;

        final double quantidadeM3 = volumeCm3 / 1000000; // cm³ → m³
        final double totalMadeiraMacica = quantidadeM3 * precoM3;


        // --- VERNIZ PU / COMUM ---
        double? vernizPuM2;
        double? vernizPuLitros;
        double? totalVernizPu;

        double? vernizComumM2;
        double? vernizComumLitros;
        double? totalVernizComum;

        if (isVernizPu) {
          final double areaTotal = areaMadeiraPu + areaLaminas;
          if (areaTotal > 0) {
            vernizPuM2 = areaTotal;
            vernizPuLitros = areaTotal;
            final precoM2 = _toDouble(itemData['precoM2']);
            if (precoM2 != null) {
              totalVernizPu = precoM2 * areaTotal;
            }
          }
        }

        if (isVernizComum) {
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

        // --- COLA FORMICA ---
        double? colaLitrosTotal;
        double? colaPrecoL;

        if (isColaFormica) {
          final double lm2Mdf = _toDouble(itemData['lm2Mdf']) ?? 0;
          final double lm2Formica = _toDouble(itemData['lm2Formica']) ?? 0;
          colaPrecoL = _toDouble(itemData['precoL']);

          double somaLitros = 0;

          final listaItens = (itemData['colaFormicaItens'] as List?) ?? [];
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

              somaLitros += _calcularLitrosColaFormicaParaItem(
                alvo,
                lm2Mdf,
                lm2Formica,
              );

              final dataAlvo =
                  alvo.data() as Map<String, dynamic>? ?? {};
              final unitTypeAlvo =
                  (dataAlvo['unitType'] as String?)?.toLowerCase() ?? '';
              final subAlvo =
                  (dataAlvo['subcategory'] as String?)?.toLowerCase() ?? '';

              if (unitTypeAlvo != 'litro') {
                if (subAlvo.contains('fita')) {
                      0;
                } else {
                }
              }
            }
          }

          final extraLitros = _toDouble(itemData['extraLitros']) ?? 0;
          somaLitros += extraLitros;

          if (somaLitros > 0) colaLitrosTotal = somaLitros;
        }

        // =============== TOTAL DO ITEM (mesma lógica da tela) ===============
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
          totalItem = totalPintura;
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

        // ===================== Strings para o PDF =====================

        // MEDIDA
        String medidaTxt;
        if (isColaFormica || isColaBranca || isPintura || isVernizPu || isVernizComum) {
          medidaTxt = "L";
        } else if (isMadeiraMacica) {
          medidaTxt = "m³";
        } else if (isFita || isOutros) {
          medidaTxt = "m";
        } else if (isFolha) {
          medidaTxt = "m²";
        } else if (isUnidade) {
          medidaTxt = "Und";
        } else if (medidaUsada != null) {
          medidaTxt = "${_formatDecimal(medidaUsada)} $unidadeMedida";
        } else {
          medidaTxt = "-";
        }

        // QUANTIDADE
        String quantidadeTxt;
        if (isColaFormica) {
          if (colaLitrosTotal == null) {
            quantidadeTxt = "-";
          } else {
            quantidadeTxt = _formatDecimal(colaLitrosTotal);
          }
        } else if (isVernizPu) {
          if (vernizPuLitros == null || vernizPuLitros == 0) {
            quantidadeTxt = "-";
          } else {
            quantidadeTxt = _formatDecimal(vernizPuLitros);
          }
        } else if (isVernizComum) {
          if (vernizComumLitros == null || vernizComumLitros == 0) {
            quantidadeTxt = "-";
          } else {
            quantidadeTxt = _formatDecimal(vernizComumLitros);
          }

        } else if (isMadeiraMacica) {
          if (quantidadeM3 <= 0){
            quantidadeTxt = "-";
          } else {
            quantidadeTxt = _formatDecimal(quantidadeM3/1000000);
          }

        } else if (isColaBranca) {
          if (litrosColaBranca == null) {
            quantidadeTxt = "-";
          } else {
            quantidadeTxt = _formatDecimal(litrosColaBranca);
          }
        } else if (isFita || isOutros) {
          if (quantidadeFitaItem == null) {
            quantidadeTxt = "-";
          } else {
            quantidadeTxt = _formatDecimal(quantidadeFitaItem);
          }
        } else if (isFolha) {
          if (quantidadeFolha == null) {
            quantidadeTxt = "-";
          } else {
            quantidadeTxt = _formatDecimal(quantidadeFolha);
          }
        } else if (isUnidade) {
          if (quantidadeUnd == null) {
            quantidadeTxt = "-";
          } else {
            quantidadeTxt = _formatDecimal(quantidadeUnd);
          }
        } else if (isPintura) {
          if (quantidadePintura == null) {
            quantidadeTxt = "-";
          } else {
            quantidadeTxt =
                _formatDecimal(quantidadePintura * 1.20); // sem "m²"
          }
        } else {
          final q = quantidadeUsada;
          if (q == null) {
            quantidadeTxt = "-";
          } else {
            quantidadeTxt = _formatDecimal(q);
          }
        }

        // PREÇO (unitário)
        String precoTxt;
        if (isFolha && precoFolha != null) {
          precoTxt = "R\$ ${_formatDecimal(precoFolha, dec: 2)}";
        } else if (isUnidade) {
          // 🔹 Trata "Valor Total" usando precoUndMovel se existir
          double? precoBase;
          if (isValorTotal) {
            precoBase = precoUndMovel ?? precoUnidadeItem;
          } else {
            precoBase = precoUnidadeItem;
          }

          if (precoBase != null) {
            precoTxt = "R\$ ${_formatDecimal(precoBase, dec: 2)}";
          } else {
            precoTxt = "-";
          }
        } else if (isColaFormica && colaPrecoL != null) {
          precoTxt = "R\$ ${_formatDecimal(colaPrecoL, dec: 2)}";
        } else if (isColaBranca && precoLColaBranca != null) {
          precoTxt = "R\$ ${_formatDecimal(precoLColaBranca, dec: 2)}";
        } else if ((isFita || isOutros) && precoPorMetroFitaLinha != null) {
          precoTxt =
              "R\$ ${_formatDecimal(precoPorMetroFitaLinha, dec: 2)}";
        } else if (isPintura && precoM2Pintura != null) {
          precoTxt = "R\$ ${_formatDecimal(precoM2Pintura, dec: 2)}";
        } else if ((isVernizPu || isVernizComum) &&
            precoM2Pintura != null) {
          precoTxt = "R\$ ${_formatDecimal(precoM2Pintura, dec: 2)}";
        } else if (isMadeiraMacica && precoM3 > 0) {
          precoTxt = "R\$ ${_formatDecimal(precoM3, dec: 2)}/m³";
        } else if (precoPorQuantidade != null) {
          precoTxt =
              "R\$ ${_formatDecimal(precoPorQuantidade, dec: 2)}";
        } else {
          precoTxt = "-";
        }

        // TOTAL
        String totalTxt;
        if (totalItem <= 0) {
          totalTxt = "-";
        } else {
          totalTxt = "R\$ ${_formatDecimal(totalItem, dec: 2)}";
        }

        // Esconde verniz sem área
        if (isVernizPu && (vernizPuM2 == null || vernizPuM2 == 0)) {
          continue;
        }
        if (isVernizComum && (vernizComumM2 == null || vernizComumM2 == 0)) {
          continue;
        }

        linhasPdf.add(
          _PdfLinhaItem(
            itemName: itemName,
            medida: medidaTxt,
            quantidade: quantidadeTxt,
            preco: precoTxt,
            total: totalTxt,
          ),
        );
      }

      // =====================================================
      // 3) RESUMO (Frete / Extra / Mão de Obra / Lucro / Total Geral)
      // =====================================================
      final freteCtrl =
          _getOrCreateResumoController(_freteControllers, movelDoc.id);
      final almocoCtrl =
          _getOrCreateResumoController(_almocoControllers, movelDoc.id);
      final maoObraCtrl =
          _getOrCreateResumoController(_maoObraControllers, movelDoc.id);
      final lucroCtrl =
          _getOrCreateResumoController(_lucroControllers, movelDoc.id);

      double frete = _toDouble(freteCtrl.text) ?? 0;
      double almoco = _toDouble(almocoCtrl.text) ?? 0;
      double maoObra = _toDouble(maoObraCtrl.text) ?? 0;
      double lucro = _toDouble(lucroCtrl.text) ?? 0;

      final base = totalBruto + frete + almoco + maoObra;
      final totalGeral = base * (1 + (lucro / 100.0));
      final String obsMovel =
        (movelData['obs'] ?? '').toString().trim();

      // =====================================================
      // 4) Montar a página do PDF
      // =====================================================
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ===== CABEÇALHO =====
                pw.Text(
                  "Espart Moveis",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),

                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Endereço / telefone
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "Rua Adel Nogueira Maia, 300 - Messejana",
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                          pw.Text(
                            "Telefone: (085)3276-1956 / 3276-5621",
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    // PP na 1ª linha, Nº do móvel na 2ª linha (ambos à direita)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          "PP: ${ppController.text} / Emissão: ${formatarData(movelData['createdAt'])}",
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (numeroMovel != null)
                          pw.Text(
                            "Nº do Móvel: $numeroMovel",
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),

                // Cliente
                pw.Row(
                  children: [
                    pw.Text(
                      "Cliente: ",
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        widget.clienteNome,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),

                // Arquiteto
                pw.Row(
                  children: [
                    pw.Text(
                      "Arquiteto: ",
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        arquitetoController.text,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 16),

                // Nome do móvel
                pw.Text(
                  "Móvel: $nomeMovel",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),

                // Cabeçalho da tabela
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(4),
                    color: PdfColors.grey300,
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          "Item",
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          "Medida",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          "Quantidade",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          "Preço",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          "Total",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),

                if (linhasPdf.isEmpty)
                  pw.Text(
                    "Nenhum item cadastrado para este móvel.",
                    style: const pw.TextStyle(fontSize: 11),
                  )
                else
                  pw.Column(
                    children: linhasPdf.map((linha) {
                      return pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 4,
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 3,
                              child: pw.Text(
                                linha.itemName,
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                linha.medida,
                                textAlign: pw.TextAlign.center,
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                linha.quantidade,
                                textAlign: pw.TextAlign.center,
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                linha.preco,
                                textAlign: pw.TextAlign.center,
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                linha.total,
                                textAlign: pw.TextAlign.center,
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                // ===== RESUMO ABAIXO DA TABELA =====
                pw.SizedBox(height: 12),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "Total Bruto: R\$ ${_formatDecimal(totalBruto, dec: 2)}",
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Frete: R\$ ${_formatDecimal(frete, dec: 2)}",
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.Text(
                        "Extra: R\$ ${_formatDecimal(almoco, dec: 2)}",
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.Text(
                        "Mão de Obra Marceneiro: R\$ ${_formatDecimal(maoObra, dec: 2)}",
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.Text(
                        "(%): ${_formatDecimal(lucro, dec: 2)}%",
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        "Total Geral: R\$ ${_formatDecimal(totalGeral, dec: 2)}",
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      // 👇 ADD OBS RIGHT HERE (INSIDE THE SAME COLUMN)
                      if (obsMovel.isNotEmpty || obsMovel.isEmpty) ...[
                        pw.SizedBox(height: 10),
                        pw.Divider(),
                        pw.SizedBox(height: 6),

                        // 🔹 OBS aligned LEFT, text after label
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "Obs: ",
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                obsMovel,
                                style: const pw.TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    // 5) Exibe o preview / impressão
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erro ao gerar PDF: $e")),
    );
  }
}

// Atualiza total de um móvel e recalcula o total do orçamento


}
