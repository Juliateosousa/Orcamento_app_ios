part of '../Orçamento Base/orcamento_page.dart';

/// Resumo financeiro de um móvel.
///
/// Os valores digitados são persistidos em:
/// moveis/{movelId}/rascunho/resumo
///
/// O subdocumento separado evita reconstruir os StreamBuilders
/// do móvel enquanto o usuário digita.
class ResumoMovel extends StatefulWidget {
  final String movelId;
  final double totalBruto;
  final ValueChanged<double>? onTotalChanged;
  final bool showTotalBruto;

  const ResumoMovel({
    super.key,
    required this.movelId,
    required this.totalBruto,
    this.onTotalChanged,
    this.showTotalBruto = true,
  });

  @override
  State<ResumoMovel> createState() => _ResumoMovelState();
}

class _ResumoMovelState extends State<ResumoMovel>
    with WidgetsBindingObserver {
  static const Color _darkBrown = Color(0xFF5A3825);
  static const Color _brown = Color(0xFF79533B);
  static const Color _softBrown = Color(0xFFF4EEEA);
  static const Color _border = Color(0xFFE8E3DF);
  static const Color _softText = Color(0xFF77716D);

  final _freteCtrl = TextEditingController();
  final _extraCtrl = TextEditingController();
  final _maoObraCtrl = TextEditingController();
  final _lucroCtrl = TextEditingController();

  bool _carregando = true;
  bool _usuarioJaDigitou = false;
  int _saveGeneration = 0;

  // ======================================================
  //                      FIRESTORE
  // ======================================================

  DocumentReference<Map<String, dynamic>> get _movelRef =>
      FirebaseFirestore.instance
          .collection('moveis')
          .doc(widget.movelId);

  DocumentReference<Map<String, dynamic>> get _rascunhoRef =>
      _movelRef.collection('rascunho').doc('resumo');

  // ======================================================
  //                       VALORES
  // ======================================================

  double _parse(String value) =>
      double.tryParse(
        value.trim().replaceAll(',', '.'),
      ) ??
      0;

  double get _frete => _parse(_freteCtrl.text);

  double get _extra => _parse(_extraCtrl.text);

  double get _maoObra => _parse(_maoObraCtrl.text);

  double get _lucro => _parse(_lucroCtrl.text);

  double get _totalGeral {
    final base =
        widget.totalBruto +
        _frete +
        _extra +
        _maoObra;

    return base * (1 + (_lucro / 100.0));
  }

  String _formatDecimal(
    num value, {
    int dec = 2,
  }) {
    return value.toStringAsFixed(dec);
  }

  // ======================================================
  //                     LIFECYCLE
  // ======================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _carregarValores();
  }

  @override
  void didUpdateWidget(
    covariant ResumoMovel oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    // Se os itens mudaram e consequentemente o total bruto
    // mudou, apenas recalculamos o total local.
    if (oldWidget.totalBruto != widget.totalBruto) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (!mounted) return;

          setState(() {});

          widget.onTotalChanged?.call(
            _totalGeral,
          );
        },
      );
    }

    // Segurança caso o mesmo State seja reutilizado
    // para outro móvel.
    if (oldWidget.movelId != widget.movelId) {
      _freteCtrl.clear();
      _extraCtrl.clear();
      _maoObraCtrl.clear();
      _lucroCtrl.clear();

      _usuarioJaDigitou = false;
      _carregando = true;

      _carregarValores();
    }
  }

  // ======================================================
  //                     CARREGAR
  // ======================================================

  Future<void> _carregarValores() async {
    try {
      // Compatibilidade com móveis antigos.
      final movelSnap = await _movelRef.get();

      final legado =
          movelSnap.data() ??
          <String, dynamic>{};

      // O rascunho novo tem prioridade.
      final rascunhoSnap =
          await _rascunhoRef.get();

      final salvo =
          rascunhoSnap.data() ??
          <String, dynamic>{};

      if (!mounted || _usuarioJaDigitou) {
        return;
      }

      String valor(
        String campoNovo,
        String campoLegado,
      ) {
        final value =
            salvo[campoNovo] ??
            legado[campoLegado];

        return value == null
            ? ''
            : value.toString();
      }

      _freteCtrl.text =
          valor('frete', 'frete');

      _extraCtrl.text =
          valor('extra', 'extra');

      _maoObraCtrl.text =
          valor('maoObra', 'maoObra');

      _lucroCtrl.text =
          valor(
            'lucroPercentual',
            'lucroPercentual',
          );

      setState(() {
        _carregando = false;
      });

      widget.onTotalChanged?.call(
        _totalGeral,
      );
    } catch (e) {
      debugPrint(
        'Erro ao carregar resumo do móvel '
        '${widget.movelId}: $e',
      );

      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // ======================================================
  //                       SALVAR
  // ======================================================

  Map<String, dynamic> _dadosAtuais() => {
    'frete': _frete,
    'extra': _extra,
    'maoObra': _maoObra,
    'lucroPercentual': _lucro,
    'updatedAt':
        FieldValue.serverTimestamp(),
  };

  void _onChanged(String _) {
    _usuarioJaDigitou = true;

    // Apenas este widget é reconstruído.
    setState(() {});

    widget.onTotalChanged?.call(
      _totalGeral,
    );

    _agendarAutosave();
  }

  void _agendarAutosave() {
    final generation =
        ++_saveGeneration;

    Future<void>.delayed(
      const Duration(milliseconds: 400),
      () async {
        if (!mounted ||
            generation !=
                _saveGeneration) {
          return;
        }

        await _saveNow();
      },
    );
  }

  Future<void> _saveNow() async {
    // Cancela autosaves anteriores.
    _saveGeneration++;

    try {
      await _rascunhoRef.set(
        _dadosAtuais(),
        SetOptions(
          merge: true,
        ),
      );
    } catch (e) {
      debugPrint(
        'Erro ao autosalvar resumo do móvel '
        '${widget.movelId}: $e',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state ==
            AppLifecycleState.inactive ||
        state ==
            AppLifecycleState.paused ||
        state ==
            AppLifecycleState.detached) {
      _saveNow();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this);

    if (_usuarioJaDigitou) {
      _saveNow();
    }

    _freteCtrl.dispose();
    _extraCtrl.dispose();
    _maoObraCtrl.dispose();
    _lucroCtrl.dispose();

    super.dispose();
  }

  // ======================================================
  //                    INPUT STYLE
  // ======================================================

  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(9),
        borderSide:
            const BorderSide(
          color: _border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(9),
        borderSide:
            const BorderSide(
          color: _brown,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(9),
        borderSide:
            const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(9),
        borderSide:
            const BorderSide(
          color: Colors.red,
          width: 1.4,
        ),
      ),
    );
  }

  // ======================================================
  //                   LINHA RESUMO
  // ======================================================

  Widget _linhaResumo({
    required String label,
    required TextEditingController controller,
    double width = 100,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
                color: _softText,
              ),
            ),
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: width,
            height: 36,
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType
                      .numberWithOptions(
                decimal: true,
              ),
              textAlign:
                  TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight:
                    FontWeight.w700,
                color: Colors.black,
              ),
              decoration:
                  _inputDecoration(),
              onChanged: _onChanged,
              onFieldSubmitted:
                  (_) => _saveNow(),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  //                        BUILD
  // ======================================================

  @override
  Widget build(BuildContext context) {
    final totalGeral =
        _totalGeral;

    return ConstrainedBox(
      constraints:
          const BoxConstraints(
        maxWidth: 340,
      ),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: _border,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            // =================================================
            //                   TOTAL BRUTO
            // =================================================

            if (widget.showTotalBruto) ...[
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total Bruto',
                      style: TextStyle(
                        fontFamily:
                            'Nunito',
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            _softText,
                      ),
                    ),
                  ),
                  Text(
                    'R\$ ${_formatDecimal(widget.totalBruto)}',
                    style:
                        const TextStyle(
                      fontFamily:
                          'Nunito',
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          Colors.black,
                    ),
                  ),
                ],
              ),

              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 11,
                ),
                child: Divider(
                  height: 1,
                  color: _border,
                ),
              ),
            ],

            // =================================================
            //                     CAMPOS
            // =================================================

            if (_carregando)
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 20,
                ),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color:
                          _darkBrown,
                    ),
                  ),
                ),
              )
            else ...[
              _linhaResumo(
                label: 'Frete (R\$)',
                controller:
                    _freteCtrl,
              ),
              _linhaResumo(
                label: 'Extra (R\$)',
                controller:
                    _extraCtrl,
              ),
              _linhaResumo(
                label:
                    'Mão de Obra (R\$)',
                controller:
                    _maoObraCtrl,
              ),
              _linhaResumo(
                label: 'Lucro (%)',
                controller:
                    _lucroCtrl,
                width: 80,
              ),
            ],

            const SizedBox(height: 5),

            // =================================================
            //                    TOTAL GERAL
            // =================================================

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: _softBrown,
                borderRadius:
                    BorderRadius.circular(
                  11,
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total Geral',
                      style: TextStyle(
                        fontFamily:
                            'Nunito',
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            _darkBrown,
                      ),
                    ),
                  ),
                  Text(
                    'R\$ ${_formatDecimal(totalGeral)}',
                    style:
                        const TextStyle(
                      fontFamily:
                          'Nunito',
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w900,
                      color:
                          _darkBrown,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
//                    PDF ITEM
// ======================================================

class _PdfLinhaItem {
  final String itemName;
  final String medida;
  final String quantidade;
  final String preco;
  final String total;

  _PdfLinhaItem({
    required this.itemName,
    required this.medida,
    required this.quantidade,
    required this.preco,
    required this.total,
  });
}