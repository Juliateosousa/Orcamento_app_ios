part of 'orcamento_page.dart';

extension _OrcamentoItemDialogsExtension on _OrcamentoPageState {
  static const Color _itemDialogDarkBrown = Color(0xFF5A3825);
  static const Color _itemDialogBrown = Color(0xFF79533B);
  static const Color _itemDialogSoftBrown = Color(0xFFF4EEEA);
  static const Color _itemDialogBorder = Color(0xFFE8E3DF);
  static const Color _itemDialogSoftText = Color(0xFF77716D);

  InputDecoration _itemDialogDecoration({
    required String label,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _itemDialogBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _itemDialogBrown, width: 1.5),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

    Future<void> _editMadeiraMacicaDialog(
    DocumentSnapshot movelDoc, // igual assinatura da folha, mesmo sem usar
    DocumentSnapshot itemDoc,
    String itemName,
  ) async {
    final data = itemDoc.data() as Map<String, dynamic>? ?? {};
    // usamos um campo separado pra madeira maciça
    final linhasData = (data['madeiraLinhas'] as List?) ?? [];
    bool vernizPU = data['vernizPU'] == true;
    bool vernizComum = data['vernizComum'] == true;


    final List<LinhaMadeira> linhas = [];

    if (linhasData.isNotEmpty) {
      for (final l in linhasData) {
        if (l is Map<String, dynamic>) {
          linhas.add(
            LinhaMadeira(
              qtd: l['quantidade']?.toString(),
              comp: l['comprimento']?.toString(),
              larg: l['largura']?.toString(),
              alt: l['altura']?.toString(),
              lados: l['lados']?.toString(),
            ),
          );
        }
      }
    }

    if (linhas.isEmpty) {
      linhas.add(LinhaMadeira());
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            Posicao? findPosicaoAtual() {
              final current = FocusManager.instance.primaryFocus;
              if (current == null) return null;

              for (var i = 0; i < linhas.length; i++) {
                final l = linhas[i];
                if (current == l.qtdFocus) return Posicao(i, 0);
                if (current == l.compFocus) return Posicao(i, 1);
                if (current == l.largFocus) return Posicao(i, 2);
                if (current == l.altFocus) return Posicao(i, 3);
              }
              return null;
            }

            void moveFocus({
              int deltaLinha = 0,
              int deltaColuna = 0,
              bool criarSeDownNoFinal = false,
            }) {
              final pos = findPosicaoAtual();
              if (pos == null) return;

              int linha = pos.linha;
              int coluna = pos.coluna;

              // mover coluna (0..3 → qtd, comp, larg, alt)
              if (deltaColuna != 0) {
                final newCol = coluna + deltaColuna;
                if (newCol < 0 || newCol > 3) {
                  return;
                }
                coluna = newCol;
              }

              // mover linha
              if (deltaLinha != 0) {
                final newLinha = linha + deltaLinha;
                if (newLinha < 0) return;

                if (newLinha >= linhas.length) {
                  // ↓ na última linha: cria nova
                  if (criarSeDownNoFinal && deltaLinha > 0) {
                    setStateDialog(() {
                      linhas.add(LinhaMadeira());
                    });
                    linha = linhas.length - 1;
                    coluna = 0; // começa em Quantidade
                  } else {
                    return;
                  }
                } else {
                  linha = newLinha;
                }
              }

              final l = linhas[linha];
              FocusNode node;
              if (coluna == 0) {
                node = l.qtdFocus;
              } else if (coluna == 1) {
                node = l.compFocus;
              } else if (coluna == 2) {
                node = l.largFocus;
              } else {
                node = l.altFocus;
              }

              Future.microtask(() {
                node.requestFocus();
              });
            }

            Future<void> salvar() async {
              final lista = <Map<String, dynamic>>[];

              for (final l in linhas) {
                final m = l.toMap();

                // pelo menos um campo preenchido
                final temAlgum = m.values.any(
                  (v) => v != null && v.toString().trim().isNotEmpty,
                );

                if (temAlgum) {
                  lista.add(m);
                }
              }

              try {
                await itemDoc.reference.update({
                  'madeiraLinhas': lista,
                  'vernizPU': vernizPU,
                  'vernizComum': vernizComum,
                });

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Medidas de Madeira Maciça salvas."),
                  ),
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Erro ao salvar medidas de Madeira Maciça: $e",
                    ),
                  ),
                );
              }
            }

            void addLinha() {
              setStateDialog(() {
                linhas.add(LinhaMadeira());
              });
            }

            return Shortcuts(
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.arrowLeft):
                    const MoveLeftIntent(),
                LogicalKeySet(LogicalKeyboardKey.arrowRight):
                    const MoveRightIntent(),
                LogicalKeySet(LogicalKeyboardKey.arrowUp):
                    const MoveUpIntent(),
                LogicalKeySet(LogicalKeyboardKey.arrowDown):
                    const MoveDownIntent(),
                LogicalKeySet(LogicalKeyboardKey.enter):
                    const SaveIntent(),
              },
              child: Actions(
                actions: <Type, Action<Intent>>{
                  MoveLeftIntent: CallbackAction<MoveLeftIntent>(
                    onInvoke: (intent) {
                      moveFocus(deltaColuna: -1);
                      return null;
                    },
                  ),
                  MoveRightIntent: CallbackAction<MoveRightIntent>(
                    onInvoke: (intent) {
                      moveFocus(deltaColuna: 1);
                      return null;
                    },
                  ),
                  MoveUpIntent: CallbackAction<MoveUpIntent>(
                    onInvoke: (intent) {
                      moveFocus(deltaLinha: -1);
                      return null;
                    },
                  ),
                  MoveDownIntent: CallbackAction<MoveDownIntent>(
                    onInvoke: (intent) {
                      moveFocus(
                        deltaLinha: 1,
                        criarSeDownNoFinal: true,
                      );
                      return null;
                    },
                  ),
                  SaveIntent: CallbackAction<SaveIntent>(
                    onInvoke: (intent) {
                      salvar();
                      return null;
                    },
                  ),
                },
                child: FocusScope(
                  autofocus: true,
                  child: AlertDialog(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    title: Text('Madeira Maciça - $itemName', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                    content: SizedBox(
                      width: 600,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Use as setas para navegar. ↓ na última linha adiciona nova linha. ENTER salva.",
                            style: TextStyle(
                              fontSize: 12,
                              color: _itemDialogSoftText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: CheckboxListTile(
                                  activeColor: _itemDialogDarkBrown,
                                  dense: true,
                                  title: const Text("Verniz PU"),
                                  value: vernizPU,
                                  onChanged: (v) {
                                    setStateDialog(() {
                                      vernizPU = v ?? false;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: CheckboxListTile(
                                  activeColor: _itemDialogDarkBrown,
                                  dense: true,
                                  title: const Text("Verniz Comum"),
                                  value: vernizComum,
                                  onChanged: (v) {
                                    setStateDialog(() {
                                      vernizComum = v ?? false;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 260,
                            child: ListView.builder(
                              itemCount: linhas.length,
                              itemBuilder: (context, index) {
                                final linha = linhas[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 6.0),
                                  child: Row(
                                    children: [
                                      // Qtd
                                      SizedBox(
                                        width: 70,
                                        height: 34,
                                        child: TextField(
                                          controller:
                                              linha.qtdController,
                                          focusNode: linha.qtdFocus,
                                          keyboardType:
                                              TextInputType.number,
                                          decoration:
                                              const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 6,
                                              horizontal: 8,
                                            ),
                                            border:
                                                OutlineInputBorder(),
                                            labelText: "Qtd",
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Comp
                                      SizedBox(
                                        width: 100,
                                        height: 34,
                                        child: TextField(
                                          controller:
                                              linha.compController,
                                          focusNode: linha.compFocus,
                                          keyboardType:
                                              const TextInputType
                                                      .numberWithOptions(
                                                  decimal: true),
                                          decoration:
                                              const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 6,
                                              horizontal: 8,
                                            ),
                                            border:
                                                OutlineInputBorder(),
                                            labelText: "Comp",
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Larg
                                      SizedBox(
                                        width: 100,
                                        height: 34,
                                        child: TextField(
                                          controller:
                                              linha.largController,
                                          focusNode: linha.largFocus,
                                          keyboardType:
                                              const TextInputType
                                                      .numberWithOptions(
                                                  decimal: true),
                                          decoration:
                                              const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 6,
                                              horizontal: 8,
                                            ),
                                            border:
                                                OutlineInputBorder(),
                                            labelText: "Larg",
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Alt
                                      SizedBox(
                                        width: 100,
                                        height: 34,
                                        child: TextField(
                                          controller:
                                              linha.altController,
                                          focusNode: linha.altFocus,
                                          keyboardType:
                                              const TextInputType
                                                      .numberWithOptions(
                                                  decimal: true),
                                          decoration:
                                              const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 6,
                                              horizontal: 8,
                                            ),
                                            border:
                                                OutlineInputBorder(),
                                            labelText: "Alt",
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Lados (Dropdown 3/4/5)
                                      SizedBox(
                                        width: 90,
                                        height: 34,
                                        child: DropdownButtonFormField<
                                            String>(
                                          initialValue: linha.lados,
                                          isDense: true,
                                          decoration:
                                              const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 6,
                                              horizontal: 8,
                                            ),
                                            border:
                                                OutlineInputBorder(),
                                            labelText: "Lados",
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: '3',
                                              child: Text('3'),
                                            ),
                                            DropdownMenuItem(
                                              value: '4',
                                              child: Text('4'),
                                            ),
                                            DropdownMenuItem(
                                              value: '5',
                                              child: Text('5'),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            setStateDialog(() {
                                              linha.lados =
                                                  value ?? '4';
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      if (linhas.length > 1)
                                        IconButton(
                                          onPressed: () {
                                            setStateDialog(() {
                                              linhas.removeAt(index);
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.close,
                                            size: 18,
                                          ),
                                          tooltip: "Remover linha",
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: addLinha,
                              icon: const Icon(Icons.add),
                              label: const Text("Adicionar linha"),
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(foregroundColor: _itemDialogSoftText),
                      child: const Text("Cancelar"),
                      ),
                      FilledButton.icon(
                      onPressed: salvar,
                      style: FilledButton.styleFrom(
                        backgroundColor: _itemDialogDarkBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        "Salvar",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

// ======================================================
//      EDITAR MEDIDAS DE ITEM DE FOLHA  (com Qtd Folhas)
//      Fórmula da área: qtdFolhas * qtd * (comp*larg/10000)
// ======================================================

Future<void> _editFolhaMedidasDialog(
  DocumentSnapshot movelDoc,
  DocumentSnapshot itemDoc,
  String itemName,
) async {
  final data = itemDoc.data() as Map<String, dynamic>? ?? {};
  final linhasData = (data['linhas'] as List?) ?? [];

  final List<LinhaFolha> linhas = [];

  // Carrega linhas salvas
  if (linhasData.isNotEmpty) {
    for (final l in linhasData) {
      if (l is Map<String, dynamic>) {
        linhas.add(
          LinhaFolha(
            folhas: l['qtdFolhas']?.toString(), // ✅ NOVO
            qtd: l['quantidade']?.toString(),
            comp: l['comprimento']?.toString(),
            larg: l['largura']?.toString(),
          ),
        );
      }
    }
  }

  if (linhas.isEmpty) {
    linhas.add(LinhaFolha());
  }

  await showDialog(
    context: context,
    builder: (ctx) {
      bool initializedFocus = false;

      return StatefulBuilder(
        builder: (ctx, setStateDialog) {
          // Foca na 1ª célula (Folhas)
          if (!initializedFocus && linhas.isNotEmpty) {
            initializedFocus = true;
            Future.microtask(() {
              linhas.first.qtdFocus.requestFocus(); // ✅ NOVO
            });
          }

          void addLinha() {
            setStateDialog(() {
              linhas.add(LinhaFolha());
            });
            Future.microtask(() {
              linhas.last.qtdFocus.requestFocus(); // ✅ NOVO
            });
          }

          Future<void> salvar() async {
            final lista = <Map<String, dynamic>>[];

            for (final l in linhas) {
              final map = l.toMap();

              final allEmpty =
                  (map['qtdFolhas'] as String).isEmpty && // ✅ NOVO
                  (map['quantidade'] as String).isEmpty &&
                  (map['comprimento'] as String).isEmpty &&
                  (map['largura'] as String).isEmpty;

              if (!allEmpty) {
                lista.add(map);
              }
            }

            try {
              // Capture UI helpers BEFORE awaiting (avoids context across async gap)
              final messenger = ScaffoldMessenger.of(context);

              await itemDoc.reference.update({
                'linhas': lista,
              });

              // Guard the BuildContext you are using
              if (!context.mounted) return;

              messenger.showSnackBar(
                SnackBar(
                  content: Text('Medidas salvas para "$itemName".'),
                ),
              );

              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            } catch (e) {
              if (!mounted) return;

              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                SnackBar(
                  content: Text("Erro ao salvar medidas: $e"),
                ),
              );
            }
          }

          Posicao? findPosicaoAtual() {
            final current = FocusManager.instance.primaryFocus;
            if (current == null) return null;

            for (var i = 0; i < linhas.length; i++) {
              final l = linhas[i];
              if (current == l.qtdFocus) return Posicao(i, colQtd);
              if (current == l.compFocus) return Posicao(i, colComp);
              if (current == l.largFocus) return Posicao(i, colLarg);
              if (current == l.folhasFocus) return Posicao(i, colFolhas);
            }
            return null;
          }


          void moveFocus({
            int deltaLinha = 0,
            int deltaColuna = 0,
            bool criarSeDownNoFinal = false,
          }) {
            final pos = findPosicaoAtual();
            if (pos == null) return;

            int linha = pos.linha;
            int coluna = pos.coluna;

            // mover coluna (0..3)
            if (deltaColuna != 0) {
              final newCol = coluna + deltaColuna;
              if (newCol < 0 || newCol > colMax) return;
              coluna = newCol;
            }

            // mover linha
            if (deltaLinha != 0) {
              final newLinha = linha + deltaLinha;
              if (newLinha < 0) return;

              if (newLinha >= linhas.length) {
                if (criarSeDownNoFinal && deltaLinha > 0) {
                  addLinha();
                  linha = linhas.length - 1;
                } else {
                  return;
                }
              } else {
                linha = newLinha;
              }

              // ✅ ALWAYS start in first column when moving lines
              coluna = 0; // 0 = qtdFocus in your mapping
            }

            final l = linhas[linha];
            late FocusNode node;

            if (coluna == colQtd) {
              node = l.qtdFocus;
            } else if (coluna == colComp) {
              node = l.compFocus;
            } else if (coluna == colLarg) {
              node = l.largFocus;
            } else {
              node = l.folhasFocus;
            }

            Future.microtask(() {
              node.requestFocus();
            });
          }

          return Shortcuts(
            shortcuts: <LogicalKeySet, Intent>{
              LogicalKeySet(LogicalKeyboardKey.arrowLeft):
                  const MoveLeftIntent(),
              LogicalKeySet(LogicalKeyboardKey.arrowRight):
                  const MoveRightIntent(),
              LogicalKeySet(LogicalKeyboardKey.arrowUp):
                  const MoveUpIntent(),
              LogicalKeySet(LogicalKeyboardKey.arrowDown):
                  const MoveDownIntent(),
              LogicalKeySet(LogicalKeyboardKey.enter):
                  const SaveIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                MoveLeftIntent: CallbackAction<MoveLeftIntent>(
                  onInvoke: (intent) {
                    moveFocus(deltaColuna: -1);
                    return null;
                  },
                ),
                MoveRightIntent: CallbackAction<MoveRightIntent>(
                  onInvoke: (intent) {
                    moveFocus(deltaColuna: 1);
                    return null;
                  },
                ),
                MoveUpIntent: CallbackAction<MoveUpIntent>(
                  onInvoke: (intent) {
                    moveFocus(deltaLinha: -1);
                    return null;
                  },
                ),
                MoveDownIntent: CallbackAction<MoveDownIntent>(
                  onInvoke: (intent) {
                    moveFocus(
                      deltaLinha: 1,
                      criarSeDownNoFinal: true,
                    );
                    return null;
                  },
                ),
                SaveIntent: CallbackAction<SaveIntent>(
                  onInvoke: (intent) {
                    salvar();
                    return null;
                  },
                ),
              },
              child: FocusScope(
                autofocus: true,
                child: AlertDialog(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  title: Text('Medidas - $itemName', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                  content: SizedBox(
                    width: 590,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Use as setas para navegar. ↓ na última linha adiciona nova linha. ENTER salva.",
                          style: TextStyle(
                            fontSize: 12,
                            color: _itemDialogSoftText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 260,
                          child: ListView.builder(
                            itemCount: linhas.length,
                            itemBuilder: (context, index) {
                              final linha = linhas[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  children: [

                                    // Qtd
                                    SizedBox(
                                      width: 80,
                                      height: 34,
                                      child: TextField(
                                        controller: linha.qtdController,
                                        focusNode: linha.qtdFocus,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 8,
                                          ),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                          labelText: "Qtd",
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Comp
                                    SizedBox(
                                      width: 120,
                                      height: 34,
                                      child: TextField(
                                        controller: linha.compController,
                                        focusNode: linha.compFocus,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 8,
                                          ),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                          labelText: "Comp",
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Larg
                                    SizedBox(
                                      width: 120,
                                      height: 34,
                                      child: TextField(
                                        controller: linha.largController,
                                        focusNode: linha.largFocus,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 8,
                                          ),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                          labelText: "Larg",
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),

                                    // ✅ NOVO: Qtd Folhas
                                    SizedBox(
                                      width: 90,
                                      height: 34,
                                      child: TextField(
                                        controller: linha.folhasController,
                                        focusNode: linha.folhasFocus,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 8,
                                          ),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                          labelText: "Folhas",
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    if (linhas.length > 1)
                                      IconButton(
                                        onPressed: () {
                                          setStateDialog(() {
                                            linhas.removeAt(index);
                                          });
                                        },
                                        icon: const Icon(Icons.close, size: 18),
                                        tooltip: "Remover linha",
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: addLinha,
                            icon: const Icon(Icons.add_rounded, color: _itemDialogBrown),
                            label: const Text("Adicionar linha", style: TextStyle(color: _itemDialogBrown, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(foregroundColor: _itemDialogSoftText),
                      child: const Text("Cancelar"),
                    ),
                    FilledButton.icon(
                      onPressed: salvar,
                      style: FilledButton.styleFrom(
                        backgroundColor: _itemDialogDarkBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        "Salvar",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  // ======================================================
  //      EDITAR LITROS DE COLA BRANCA (APENAS 1 VALOR L)
  // ======================================================

  Future<void> _editColaBrancaDialog(
    DocumentSnapshot itemDoc,
    String itemName,
  ) async {
    final data = itemDoc.data() as Map<String, dynamic>? ?? {};
    final litrosExistente = data['litros'] as num?;

    final controller = TextEditingController(
      text: litrosExistente != null ? litrosExistente.toString() : "",
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
        title: Text('Litros - $itemName', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Quantidade em Litros (L)",
              hintText: "Ex: 2.5",
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: _itemDialogSoftText),
                      child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              final txt = controller.text.trim();
              final valor = double.tryParse(txt.replaceAll(',', '.'));

              try {
                await itemDoc.reference.update({
                  'litros': valor,
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Litros de "$itemName" atualizados para ${valor ?? "-"} L'),
                    ),
                  );
                }
                // ignore: use_build_context_synchronously
                Navigator.pop(ctx);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erro ao salvar litros: $e"),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: _itemDialogDarkBrown),
            child: const Text(
              "Salvar",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }


Future<void> _editFitaMetrosDialog(
  DocumentSnapshot itemDoc,
  String itemName,
) async {
  final data = itemDoc.data() as Map<String, dynamic>? ?? {};
  // campo que usamos no orçamento para quantidade de fita em metros
  final double? metrosFitaAtual = _toDouble(data['metrosFita']);

  final controller = TextEditingController(
    text: metrosFitaAtual?.toString() ?? "",
  );

  await showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
        title: Text(itemName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Metros de fita usados (m)",
            hintText: "Ex: 5.5",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: _itemDialogSoftText),
                      child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              double? parse(String t) =>
                  double.tryParse(t.replaceAll(',', '.'));

              final novoValor = parse(controller.text.trim());

              try {
                await itemDoc.reference.update({
                  'metrosFita': novoValor,
                });

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Metros de fita atualizados para "$itemName".',
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Erro ao salvar metros de fita: $e",
                    ),
                  ),
                );
              }

              // fecha o diálogo
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: _itemDialogDarkBrown),
            child: const Text(
              "Salvar",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      );
    },
  );
}

Future<void> _editPinturaDialog(
  DocumentSnapshot movelDoc,
  DocumentSnapshot itemDoc,
  String itemName,
) async {
  final data = itemDoc.data() as Map<String, dynamic>? ?? {};

  // ⬇️ usamos uma lista separada só para pintura
  final linhasData = (data['linhasPintura'] as List?) ?? [];

  // ⬇️ flag para arredondar a quantidade
  bool arredondarQuantidade = data['arredondarQuantidade'] as bool? ?? false;

  final List<LinhaFolha> linhas = [];

  if (linhasData.isNotEmpty) {
    for (final l in linhasData) {
      if (l is Map<String, dynamic>) {
        linhas.add(
          LinhaFolha(
            qtd: l['quantidade']?.toString(),
            comp: l['comprimento']?.toString(),
            larg: l['largura']?.toString(),
          ),
        );
      }
    }
  }

  if (linhas.isEmpty) {
    linhas.add(LinhaFolha());
  }

  await showDialog(
    context: context,
    builder: (ctx) {
      bool initializedFocus = false;

      return StatefulBuilder(
        builder: (ctx, setStateDialog) {
          if (!initializedFocus && linhas.isNotEmpty) {
            initializedFocus = true;
            Future.microtask(() {
              linhas.first.qtdFocus.requestFocus();
            });
          }

          void addLinha() {
            setStateDialog(() {
              linhas.add(LinhaFolha());
            });
            Future.microtask(() {
              linhas.last.qtdFocus.requestFocus();
            });
          }

          Future<void> salvar() async {
            final lista = <Map<String, dynamic>>[];

            for (final l in linhas) {
              final map = l.toMap();
              final allEmpty = (map['quantidade'] as String).isEmpty &&
                  (map['comprimento'] as String).isEmpty &&
                  (map['largura'] as String).isEmpty;
              if (!allEmpty) {
                lista.add(map);
              }
            }

            try {
              await itemDoc.reference.update({
                // ⬇️ salva as linhas da PINTURA
                'linhasPintura': lista,
                // ⬇️ salva se deve arredondar ou não
                'arredondarQuantidade': arredondarQuantidade,
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Medidas de pintura salvas para "$itemName".'),
                  ),
                );
              }
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Erro ao salvar medidas de pintura: $e"),
                  ),
                );
              }
            }
          }

          Posicao? findPosicaoAtual() {
            final current = FocusManager.instance.primaryFocus;
            if (current == null) return null;

            for (var i = 0; i < linhas.length; i++) {
              final l = linhas[i];
              if (current == l.qtdFocus) return Posicao(i, 0);
              if (current == l.compFocus) return Posicao(i, 1);
              if (current == l.largFocus) return Posicao(i, 2);
            }
            return null;
          }

          void moveFocus({
            int deltaLinha = 0,
            int deltaColuna = 0,
            bool criarSeDownNoFinal = false,
          }) {
            final pos = findPosicaoAtual();
            if (pos == null) return;

            int linha = pos.linha;
            int coluna = pos.coluna;

            // mover coluna
            if (deltaColuna != 0) {
              final newCol = coluna + deltaColuna;
              if (newCol < 0 || newCol > 2) {
                return;
              }
              coluna = newCol;
            }

            // mover linha
            if (deltaLinha != 0) {
              final newLinha = linha + deltaLinha;
              if (newLinha < 0) return;

              if (newLinha >= linhas.length) {
                // seta pra baixo na última linha -> cria nova e vai pra Qtd
                if (criarSeDownNoFinal && deltaLinha > 0) {
                  addLinha();
                  linha = linhas.length - 1;
                  coluna = 0; // sempre começa em Quantidade
                } else {
                  return;
                }
              } else {
                linha = newLinha;
              }
            }

            final l = linhas[linha];
            FocusNode node;
            if (coluna == 0) {
              node = l.qtdFocus;
            } else if (coluna == 1) {
              node = l.compFocus;
            } else {
              node = l.largFocus;
            }

            Future.microtask(() {
              node.requestFocus();
            });
          }

          return Shortcuts(
            shortcuts: <LogicalKeySet, Intent>{
              LogicalKeySet(LogicalKeyboardKey.arrowLeft):
                  const MoveLeftIntent(),
              LogicalKeySet(LogicalKeyboardKey.arrowRight):
                  const MoveRightIntent(),
              LogicalKeySet(LogicalKeyboardKey.arrowUp):
                  const MoveUpIntent(),
              LogicalKeySet(LogicalKeyboardKey.arrowDown):
                  const MoveDownIntent(),
              LogicalKeySet(LogicalKeyboardKey.enter):
                  const SaveIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                MoveLeftIntent: CallbackAction<MoveLeftIntent>(
                  onInvoke: (intent) {
                    moveFocus(deltaColuna: -1);
                    return null;
                  },
                ),
                MoveRightIntent: CallbackAction<MoveRightIntent>(
                  onInvoke: (intent) {
                    moveFocus(deltaColuna: 1);
                    return null;
                  },
                ),
                MoveUpIntent: CallbackAction<MoveUpIntent>(
                  onInvoke: (intent) {
                    moveFocus(deltaLinha: -1);
                    return null;
                  },
                ),
                MoveDownIntent: CallbackAction<MoveDownIntent>(
                  onInvoke: (intent) {
                    moveFocus(
                      deltaLinha: 1,
                      criarSeDownNoFinal: true,
                    );
                    return null;
                  },
                ),
                SaveIntent: CallbackAction<SaveIntent>(
                  onInvoke: (intent) {
                    salvar();
                    return null;
                  },
                ),
              },
              child: FocusScope(
                autofocus: true,
                child: AlertDialog(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  title: Text('Medidas Pintura - $itemName', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                  content: SizedBox(
                    width: 500,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Use as setas para navegar. ↓ na última linha adiciona nova linha. ENTER salva.",
                          style: TextStyle(
                            fontSize: 12,
                            color: _itemDialogSoftText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 260,
                          child: ListView.builder(
                            itemCount: linhas.length,
                            itemBuilder: (context, index) {
                              final linha = linhas[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      height: 34,
                                      child: TextField(
                                        controller:
                                            linha.qtdController,
                                        focusNode: linha.qtdFocus,
                                        keyboardType:
                                            TextInputType.number,
                                        decoration:
                                            const InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 8,
                                          ),
                                          border:
                                              OutlineInputBorder(),
                                          labelText: "Qtd",
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 120,
                                      height: 34,
                                      child: TextField(
                                        controller:
                                            linha.compController,
                                        focusNode: linha.compFocus,
                                        keyboardType:
                                            const TextInputType
                                                    .numberWithOptions(
                                                decimal: true),
                                        decoration:
                                            const InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 8,
                                          ),
                                          border:
                                              OutlineInputBorder(),
                                          labelText: "Comp",
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 120,
                                      height: 34,
                                      child: TextField(
                                        controller:
                                            linha.largController,
                                        focusNode: linha.largFocus,
                                        keyboardType:
                                            const TextInputType
                                                    .numberWithOptions(
                                                decimal: true),
                                        decoration:
                                            const InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 8),
                                          border:
                                              OutlineInputBorder(),
                                          labelText: "Larg",
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    if (linhas.length > 1)
                                      IconButton(
                                        onPressed: () {
                                          setStateDialog(() {
                                            linhas.removeAt(index);
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.close,
                                          size: 18,
                                        ),
                                        tooltip: "Remover linha",
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: addLinha,
                            icon: const Icon(Icons.add_rounded, color: _itemDialogBrown),
                            label: const Text("Adicionar linha", style: TextStyle(color: _itemDialogBrown, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // ⬇️ Checkbox "Arredondar quantidade"
                        CheckboxListTile(
                                  activeColor: _itemDialogDarkBrown,
                          value: arredondarQuantidade,
                          onChanged: (v) {
                            setStateDialog(() {
                              arredondarQuantidade = v ?? false;
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title:
                              const Text("Arredondar quantidade"),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(foregroundColor: _itemDialogSoftText),
                      child: const Text("Cancelar"),
                    ),
                    FilledButton.icon(
                      onPressed: salvar,
                      style: FilledButton.styleFrom(
                        backgroundColor: _itemDialogDarkBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        "Salvar",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  // ======================================================
  //      EDITAR CONFIGURAÇÃO DE COLA FORMICA POR MÓVEL
  // ======================================================

Future<void> _editColaFormicaDialog(
  DocumentSnapshot movelDoc,
  DocumentSnapshot itemDoc,
  String itemName,
) async {
  // 1) Buscar todos os itens desse móvel
  final itensSnapshot =
      await movelDoc.reference.collection('itens').get();

  final todosItensMovel = itensSnapshot.docs;

  // Itens elegíveis: MDF, Fitas, Formica, Lâmina, Manta
  const allowedSubcats = [
    'mdf',
    'fita',
    'formica',
    'lamina',
    'manta',
  ];

  final elegiveis = todosItensMovel.where((d) {
    final data = d.data() as Map<String, dynamic>? ?? {};
    final unitType = data['unitType'];
    final subcat = (data['subcategory'] as String?)?.toLowerCase();

    if (unitType == 'litro') return false; // ignora tintas/colas etc.

    if (subcat != null && allowedSubcats.contains(subcat)) {
      return true;
    }
    return false;
  }).toList();

  // 2) Carregar dados já salvos nesse item (cola formica)
  final data = itemDoc.data() as Map<String, dynamic>? ?? {};
  final linhasData = (data['colaFormicaItens'] as List?) ?? [];
  final extraLitrosExistente = (data['extraLitros'] as num?)?.toDouble();
  final double lm2Mdf = _toDouble(data['lm2Mdf']) ?? 0;
  final double lm2Formica = _toDouble(data['lm2Formica']) ?? 0;

  // Lista de IDs de itens do móvel selecionados em cada linha
  final List<String?> selectedIds = [];

  if (elegiveis.isNotEmpty) {
    // Só tenta reconstruir linhas se existirem itens elegíveis
    for (final l in linhasData) {
      if (l is Map<String, dynamic>) {
        final id = l['itemMovelId'] as String?;
        selectedIds.add(id);
      }
    }

    if (selectedIds.isEmpty) {
      selectedIds.add(null); // pelo menos 1 linha vazia
    }
  }

  final extraLitrosController = TextEditingController(
    text: extraLitrosExistente != null ? extraLitrosExistente.toString() : "",
  );

  DocumentSnapshot? findById(
      List<QueryDocumentSnapshot> list, String id) {
    for (final d in list) {
      if (d.id == id) return d;
    }
    return null;
  }

  if (!mounted) return;

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
            title: Text('Cola Formica - $itemName', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (elegiveis.isEmpty) ...[
                    const Text(
                      "Não há itens elegíveis (MDF, Fitas, Formica, Lâminas ou Mantas) "
                      "cadastrados neste móvel.\n\n"
                      "Você ainda pode informar apenas os litros extras de Cola Formica.",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    const Text(
                      "Selecione os itens deste móvel que utilizam Cola Formica.\n"
                      "Cada linha representa um item que usa a cola. À direita aparece os L calculados.",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    // Lista de linhas (dropdowns + L calculado)
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        itemCount: selectedIds.length,
                        itemBuilder: (context, index) {
                          final currentId = selectedIds[index];

                          // cálculo dos litros desse item específico
                          double? litrosCalculado;
                          if (currentId != null) {
                            final docSel = findById(elegiveis, currentId);
                            if (docSel != null) {
                              litrosCalculado =
                                  _calcularLitrosColaFormicaParaItem(
                                docSel,
                                lm2Mdf,
                                lm2Formica,
                              );
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    isExpanded: true,
                                    initialValue: currentId,
                                    decoration: const InputDecoration(
                                      labelText: "Item do móvel",
                                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                      isDense: true,
                                    ),
                                    // 🔥 Itens filtrados para NÃO repetir seleções
                                    items: () {
                                      // IDs já usados em outras linhas (diferentes da atual)
                                      final usedIds = selectedIds
                                          .where((id) =>
                                              id != null && id != currentId)
                                          .toSet();

                                      return <DropdownMenuItem<String?>>[
                                        const DropdownMenuItem<String?>(
                                          value: null,
                                          child: Text("- selecione -"),
                                        ),
                                        ...elegiveis
                                            .where((d) => !usedIds.contains(d.id))
                                            .map((d) {
                                          final dd = d.data()
                                                  as Map<String, dynamic>? ??
                                              {};
                                          final nomeItem =
                                              dd['itemName'] as String? ??
                                                  "(sem nome)";
                                          return DropdownMenuItem<String?>(
                                            value: d.id,
                                            child: Text(
                                              nomeItem,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }),
                                      ];
                                    }(),
                                    onChanged: (value) {
                                      setStateDialog(() {
                                        selectedIds[index] = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    (litrosCalculado == null ||
                                            litrosCalculado == 0)
                                        ? "-"
                                        : "${_formatDecimal(litrosCalculado, dec: 2)} L",
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (selectedIds.length > 1)
                                  IconButton(
                                    onPressed: () {
                                      setStateDialog(() {
                                        selectedIds.removeAt(index);
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.close,
                                      size: 18,
                                    ),
                                    tooltip: "Remover linha",
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setStateDialog(() {
                            selectedIds.add(null);
                          });
                        },
                        icon: const Icon(Icons.add_rounded, color: _itemDialogBrown),
                        label: const Text("Adicionar linha", style: TextStyle(color: _itemDialogBrown, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Litros extras de Cola Formica (opcional)",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: extraLitrosController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        hintText: "Ex: 0.5",
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(foregroundColor: _itemDialogSoftText),
                      child: const Text("Cancelar"),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: _itemDialogDarkBrown,
                ),
                onPressed: () async {
                  // Montar lista final de itens selecionados
                  final List<Map<String, dynamic>> itensSelecionados = [];

                  if (elegiveis.isNotEmpty) {
                    for (final id in selectedIds) {
                      if (id == null) continue;
                      final docSel = findById(elegiveis, id);
                      if (docSel == null) continue;

                      final dData =
                          docSel.data() as Map<String, dynamic>? ?? {};
                      final nomeItem =
                          dData['itemName'] as String? ?? "(sem nome)";

                      itensSelecionados.add({
                        'itemMovelId': docSel.id,
                        'itemName': nomeItem,
                      });
                    }
                  }

                  double? extra;
                  final txt = extraLitrosController.text.trim();
                  if (txt.isNotEmpty) {
                    extra = double.tryParse(
                        txt.replaceAll(',', '.'));
                  }

                  try {
                    await itemDoc.reference.update({
                      'colaFormicaItens': itensSelecionados,
                      'extraLitros': extra,
                    });

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Configuração de Cola Formica salva."),
                        ),
                      );
                    }
                    // ignore: use_build_context_synchronously
                    Navigator.pop(ctx);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text("Erro ao salvar Cola Formica: $e"),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  "Salvar",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            ]
          );
        },
      );
    },
  );
}

  Future<void> _editUnidadeQuantidadeDialog(
    DocumentSnapshot itemDoc,
    String itemName,
  ) async {
    final data = itemDoc.data() as Map<String, dynamic>? ?? {};
    final quantidadeExistente = data['quantidadeUnd'] as num?;

    final controller = TextEditingController(
      text: quantidadeExistente != null ? quantidadeExistente.toString() : "",
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
        title: Text('Quantidade - $itemName', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Quantidade de itens",
              hintText: "Ex: 4",
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: _itemDialogSoftText),
                      child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              final txt = controller.text.trim();
              final valor = double.tryParse(txt.replaceAll(',', '.'));

              try {
                await itemDoc.reference.update({
                  'quantidadeUnd': valor,
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Quantidade de "$itemName" atualizada para ${valor ?? "-"} Und',
                      ),
                    ),
                  );
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erro ao salvar quantidade: $e"),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: _itemDialogDarkBrown),
            child: const Text(
              "Salvar",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

}
