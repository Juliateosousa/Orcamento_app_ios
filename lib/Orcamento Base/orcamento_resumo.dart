part of 'orcamento_page.dart';

extension _OrcamentoResumoExtension on _OrcamentoPageState {
  // =====================================================
  //                       COLORS
  // =====================================================

  static const Color _resumoDarkBrown = Color(0xFF5A3825);
  static const Color _resumoBrown = Color(0xFF79533B);
  static const Color _resumoSoftBrown = Color(0xFFF4EEEA);
  static const Color _resumoBorder = Color(0xFFE8E3DF);
  static const Color _resumoSoftText = Color(0xFF77716D);

  // =====================================================
  //                   ORÇAMENTO REF
  // =====================================================

  DocumentReference get _orcamentoRef {
    return FirebaseFirestore.instance
        .collection('clientes')
        .doc(widget.clienteId)
        .collection('orcamentos')
        .doc(widget.orcamentoId);
  }

  // =====================================================
  //                  INPUT DECORATION
  // =====================================================

  InputDecoration _resumoInputDecoration({
    String? label,
    String? hint,
    Widget? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      labelStyle: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 13,
        color: _resumoSoftText,
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 13,
        color: _resumoSoftText,
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: _resumoBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: _resumoBrown,
          width: 1.5,
        ),
      ),
    );
  }

  // =====================================================
  //                    LINHA RESUMO
  // =====================================================

  Widget _linhaResumo({
    required String label,
    required TextEditingController controller,
    required VoidCallback onSave,
    required VoidCallback onChange,
    double width = 90,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow =
              constraints.maxWidth < 330;

          final field = SizedBox(
            width: isNarrow
                ? double.infinity
                : width,
            height: 40,
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              cursorColor: _resumoBrown,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              decoration: _resumoInputDecoration(),
              onChanged: (_) {
                onChange();
              },
              onEditingComplete: onSave,
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _resumoSoftText,
                  ),
                ),
                const SizedBox(height: 5),
                field,
              ],
            );
          }

          return Row(
            mainAxisAlignment:
                MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 160,
                child: Text(
                  '$label:',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _resumoSoftText,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              field,
            ],
          );
        },
      ),
    );
  }

  // =====================================================
  //                RESUMO CONTROLLERS
  // =====================================================

  TextEditingController _getOrCreateResumoController(
    Map<String, TextEditingController> map,
    String movelId, {
    String? initialText,
  }) {
    if (map.containsKey(movelId)) {
      return map[movelId]!;
    }

    final controller = TextEditingController(
      text: initialText ?? '',
    );

    map[movelId] = controller;

    return controller;
  }

  // =====================================================
  //                   OBS CONTROLLER
  // =====================================================

  TextEditingController _getOrCreateObsController(
    String movelId, {
    String? initial,
  }) {
    if (_obsControllers.containsKey(movelId)) {
      return _obsControllers[movelId]!;
    }

    final controller = TextEditingController(
      text: initial ?? '',
    );

    _obsControllers[movelId] = controller;

    return controller;
  }

  // =====================================================
  //                    PARSE DOUBLE
  // =====================================================

  double _parseResumoDouble(
    String? value,
  ) {
    if (value == null) return 0;

    final text = value
        .replaceAll(',', '.')
        .trim();

    if (text.isEmpty) return 0;

    return double.tryParse(text) ?? 0;
  }

  // =====================================================
  //             SALVAR RESUMO DE TODOS MÓVEIS
  // =====================================================

  Future<void> _salvarResumoTodosMoveis() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('moveis')
          .where(
            'numeroOrcamento',
            isEqualTo: widget.numeroOrcamento,
          )
          .get();

      for (final doc in snap.docs) {
        final movelId = doc.id;

        final freteCtrl =
            _freteControllers[movelId];

        final extraCtrl =
            _almocoControllers[movelId];

        final maoObraCtrl =
            _maoObraControllers[movelId];

        final lucroCtrl =
            _lucroControllers[movelId];

        // Só salva os controllers que já existem
        // para este móvel.
        if (freteCtrl == null &&
            extraCtrl == null &&
            maoObraCtrl == null &&
            lucroCtrl == null) {
          continue;
        }

        await doc.reference.update({
          'frete': freteCtrl == null
              ? FieldValue.delete()
              : _parseResumoDouble(
                  freteCtrl.text,
                ),
          'extra': extraCtrl == null
              ? FieldValue.delete()
              : _parseResumoDouble(
                  extraCtrl.text,
                ),
          'maoObra': maoObraCtrl == null
              ? FieldValue.delete()
              : _parseResumoDouble(
                  maoObraCtrl.text,
                ),
          'lucroPercentual': lucroCtrl == null
              ? FieldValue.delete()
              : _parseResumoDouble(
                  lucroCtrl.text,
                ),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Resumo salvo com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao salvar resumo: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  //                 EDITAR VALOR TOTAL
  // =====================================================

  Future<void> _editValorTotalDialog(
    DocumentSnapshot itemDoc,
    String itemName,
  ) async {
    final data =
        itemDoc.data() as Map<String, dynamic>? ?? {};

    final nomeAtual =
        (data['itemName'] ??
                data['name'] ??
                itemName)
            .toString();

    final precoAtual =
        data['precoUnd'];

    final qtdAtual =
        data['quantidadeUnd'];

    final String medidaAtual =
        (data['medidaValorTotal'] as String?) ??
            'Und';

    final nomeController =
        TextEditingController(
      text: nomeAtual,
    );

    final precoController =
        TextEditingController(
      text: precoAtual == null
          ? ''
          : precoAtual.toString(),
    );

    final qtdController =
        TextEditingController(
      text: qtdAtual == null
          ? ''
          : qtdAtual.toString(),
    );

    double? parse(String text) {
      return double.tryParse(
        text.replaceAll(',', '.'),
      );
    }

    const medidaOptions = [
      'Und',
      'm³',
      'm²',
      'm',
      'L',
    ];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        String medidaSelecionada =
            medidaOptions.contains(medidaAtual)
                ? medidaAtual
                : medidaOptions.first;

        return StatefulBuilder(
          builder: (
            dialogContext,
            setStateDialog,
          ) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor:
                  Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(18),
              ),
              titlePadding:
                  const EdgeInsets.fromLTRB(
                24,
                22,
                24,
                0,
              ),
              contentPadding:
                  const EdgeInsets.fromLTRB(
                24,
                18,
                24,
                8,
              ),
              actionsPadding:
                  const EdgeInsets.fromLTRB(
                16,
                4,
                16,
                14,
              ),

              // -------------------------------------------
              // TITLE
              // -------------------------------------------

              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _resumoSoftBrown,
                      borderRadius:
                          BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons
                          .request_quote_outlined,
                      color: _resumoDarkBrown,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valor Total',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 19,
                            fontWeight:
                                FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Editar valor deste móvel',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w500,
                            color:
                                _resumoSoftText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // -------------------------------------------
              // CONTENT
              // -------------------------------------------

              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      // -----------------------------------
                      // NAME
                      // -----------------------------------

                      TextField(
                        controller:
                            nomeController,
                        textCapitalization:
                            TextCapitalization
                                .sentences,
                        cursorColor:
                            _resumoBrown,
                        style:
                            const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        decoration:
                            _resumoInputDecoration(
                          label: 'Nome',
                          hint:
                              'Ex: Total marcenaria',
                        ),
                      ),

                      const SizedBox(height: 14),

                      // -----------------------------------
                      // UNIT
                      // -----------------------------------

                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            medidaSelecionada,
                        dropdownColor:
                            Colors.white,
                        style:
                            const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        icon: const Icon(
                          Icons
                              .keyboard_arrow_down_rounded,
                          color:
                              _resumoDarkBrown,
                        ),
                        items: medidaOptions
                            .map(
                              (medida) =>
                                  DropdownMenuItem<
                                      String>(
                                value: medida,
                                child: Text(
                                  medida,
                                  style:
                                      const TextStyle(
                                    fontFamily:
                                        'Nunito',
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            medidaSelecionada =
                                value ?? 'Und';
                          });
                        },
                        decoration:
                            _resumoInputDecoration(
                          label: 'Medida',
                        ),
                      ),

                      const SizedBox(height: 14),

                      // -----------------------------------
                      // PRICE
                      // -----------------------------------

                      TextField(
                        controller:
                            precoController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .allow(
                            RegExp(
                              r'[0-9.,]',
                            ),
                          ),
                        ],
                        cursorColor:
                            _resumoBrown,
                        style:
                            const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        decoration:
                            _resumoInputDecoration(
                          label: 'Preço (R\$)',
                          hint: 'Ex: 1500.00',
                        ),
                      ),

                      const SizedBox(height: 14),

                      // -----------------------------------
                      // QUANTITY
                      // -----------------------------------

                      TextField(
                        controller:
                            qtdController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .allow(
                            RegExp(
                              r'[0-9.,]',
                            ),
                          ),
                        ],
                        cursorColor:
                            _resumoBrown,
                        style:
                            const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        decoration:
                            _resumoInputDecoration(
                          label: 'Quantidade',
                          hint: 'Ex: 1',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // -------------------------------------------
              // ACTIONS
              // -------------------------------------------

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight:
                          FontWeight.w600,
                      color:
                          _resumoSoftText,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    final novoNome =
                        nomeController.text
                            .trim();

                    final preco = parse(
                      precoController.text
                          .trim(),
                    );

                    final qtd = parse(
                      qtdController.text
                          .trim(),
                    );

                    try {
                      await itemDoc.reference
                          .update({
                        'itemName':
                            novoNome.isEmpty
                                ? nomeAtual
                                : novoNome,
                        'precoUnd': preco,
                        'quantidadeUnd': qtd,
                        'medidaValorTotal':
                            medidaSelecionada,
                      });

                      if (!dialogContext
                          .mounted) {
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                      );

                      if (!mounted) return;

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Valor total atualizado para "${novoNome.isEmpty ? nomeAtual : novoNome}".',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erro ao salvar Valor Total: $e',
                          ),
                        ),
                      );
                    }
                  },
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        _resumoDarkBrown,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        11,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Salvar',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nomeController.dispose();
    precoController.dispose();
    qtdController.dispose();
  }

  // =====================================================
  //                     EDITAR OBS
  // =====================================================

  Future<void> _editObsDialog(
    DocumentSnapshot movelDoc,
  ) async {
    final movelData =
        movelDoc.data()
                as Map<String, dynamic>? ??
            {};

    final String obsAtual =
        (movelData['obs'] ?? '').toString();

    final controller =
        _getOrCreateObsController(
      movelDoc.id,
      initial: obsAtual,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor:
              Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
          titlePadding:
              const EdgeInsets.fromLTRB(
            24,
            22,
            24,
            0,
          ),
          contentPadding:
              const EdgeInsets.fromLTRB(
            24,
            18,
            24,
            8,
          ),
          actionsPadding:
              const EdgeInsets.fromLTRB(
            16,
            4,
            16,
            14,
          ),

          // ---------------------------------------------
          // TITLE
          // ---------------------------------------------

          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _resumoSoftBrown,
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.notes_rounded,
                  color: _resumoDarkBrown,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Observações',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 19,
                        fontWeight:
                            FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Observações específicas deste móvel',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w500,
                        color:
                            _resumoSoftText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ---------------------------------------------
          // CONTENT
          // ---------------------------------------------

          content: SizedBox(
            width: 420,
            child: TextField(
              controller: controller,
              maxLines: 6,
              minLines: 4,
              textCapitalization:
                  TextCapitalization.sentences,
              cursorColor: _resumoBrown,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                height: 1.4,
                color: Colors.black,
              ),
              decoration:
                  _resumoInputDecoration(
                hint:
                    'Escreva qualquer observação deste móvel...',
              ),
            ),
          ),

          // ---------------------------------------------
          // ACTIONS
          // ---------------------------------------------

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight:
                      FontWeight.w600,
                  color:
                      _resumoSoftText,
                ),
              ),
            ),
            FilledButton(
              onPressed: () async {
                final texto =
                    controller.text.trim();

                try {
                  await movelDoc.reference
                      .update({
                    'obs': texto,
                    'obsUpdatedAt':
                        FieldValue
                            .serverTimestamp(),
                  });

                  if (dialogContext.mounted) {
                    Navigator.pop(
                      dialogContext,
                    );
                  }

                  if (!mounted) return;

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Obs salva.',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erro ao salvar Obs: $e',
                      ),
                    ),
                  );
                }
              },
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    _resumoDarkBrown,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
              ),
              child: const Text(
                'Salvar',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  //          CARREGAR / SALVAR ORÇAMENTO (HEADER)
  // =====================================================
}