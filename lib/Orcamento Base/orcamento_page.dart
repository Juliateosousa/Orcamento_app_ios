import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/services.dart';

import 'package:printing/printing.dart';

import 'package:pdf/widgets.dart' as pw;

import 'package:pdf/pdf.dart';

import 'package:flutter/foundation.dart';



import '../aux_and_helpers.dart';



import 'dart:async';

import 'package:intl/intl.dart';



part '../Móvel/orcamento_moveis.dart';

part '../Móvel/orcamento_movel_card.dart';

part '../Móvel/orcamento_movel_itens.dart';

part 'orcamento_header.dart';

part '../Móvel/resumo_movel.dart';

part 'orcamento_resumo.dart';

part 'orcamento_dados.dart';

part 'orcamento_pdf.dart';

part '../Móvel/orcamento_movel_actions.dart';

part 'orcamento_helpers_calculos.dart';

part 'orcamento_item_dialogs.dart';



// ======================================================

//                    TABLE COLUMNS

// ======================================================



const int colQtd = 0;

const int colComp = 1;

const int colLarg = 2;

const int colFolhas = 3;

const int colMax = colFolhas;



// ======================================================

//                    DATE FORMAT

// ======================================================



String formatarData(dynamic createdAt) {

  if (createdAt == null) return '-';



  final DateTime date =

      (createdAt as Timestamp).toDate();



  return DateFormat('dd/MM/yy').format(date);

}



// ======================================================

//                   FIRESTORE INIT

// ======================================================



Future<void> initFirestore() async {

  if (kIsWeb) {

    FirebaseFirestore.instance.settings =

        const Settings(

      persistenceEnabled: false,

    );

  }

}



// ======================================================

//                   PÁGINA DE ORÇAMENTO

// ======================================================



class OrcamentoPage extends StatefulWidget {

  final String clienteId;

  final String clienteNome;

  final String orcamentoId;

  final int numeroOrcamento;



  const OrcamentoPage({

    super.key,

    required this.clienteId,

    required this.orcamentoId,

    required this.numeroOrcamento,

    required this.clienteNome,

  });



  @override

  State<OrcamentoPage> createState() =>

      _OrcamentoPageState();

}



// ======================================================

//                     PAGE STATE

// ======================================================



class _OrcamentoPageState extends State<OrcamentoPage> {

  // ====================================================

  //                       COLORS

  // ====================================================



  static const Color _darkBrown =

      Color(0xFF5A3825);



  static const Color _brown =

      Color(0xFF79533B);



  static const Color _softBrown =

      Color(0xFFF4EEEA);



  static const Color _border =

      Color(0xFFE8E3DF);



  static const Color _softText =

      Color(0xFF77716D);



  // ====================================================

  //                    GENERAL STATE

  // ====================================================



  Timer? _saveTimer;
  String _movelSearch = '';



  bool _moveisDescending = false;



  final ScrollController _scrollCtrl =

      ScrollController();



  final PageStorageKey<String>

      _orcamentoScrollKey =

      const PageStorageKey<String>(

    'orcamentoScroll',

  );



  late final Stream<QuerySnapshot> _moveisStream;



  // ====================================================

  //                    CONTROLLERS

  // ====================================================



  final TextEditingController ppController =

      TextEditingController();



  final TextEditingController clienteController =

      TextEditingController();



  final TextEditingController

      telefoneClienteController =

      TextEditingController();



  final TextEditingController arquitetoController =

      TextEditingController();



  final TextEditingController freteController =

      TextEditingController();



  final TextEditingController extraController =

      TextEditingController();



  final TextEditingController maoDeObraController =

      TextEditingController();



  final TextEditingController percentualController =

      TextEditingController();



  // ====================================================

  //                   VERNIZ LOCKS

  // ====================================================



  bool _criandoVernizPu = false;



  bool _criandoVernizComum = false;



  // ====================================================

  //                 TOTALS PER MÓVEL

  // ====================================================



  final Set<String> _moveisJaInicializados = {};



  final Map<String, double>

      _totaisGeraisPorMovel = {};



  final ValueNotifier<double>

      _totalOrcamentoNotifier =

      ValueNotifier<double>(0.0);



  // ====================================================

  //                    OBS PER MÓVEL

  // ====================================================



  final Map<String, TextEditingController>

      _obsControllers = {};



  // ====================================================

  //                SELECTED CLIENT

  // ====================================================



  String? clienteSelecionadoId;



  // ====================================================

  //             RESUMO CONTROLLERS PER MÓVEL

  // ====================================================



  final Map<String, TextEditingController>

      _freteControllers = {};



  final Map<String, TextEditingController>

      _almocoControllers = {};



  final Map<String, TextEditingController>

      _maoObraControllers = {};



  final Map<String, TextEditingController>

      _lucroControllers = {};



  // ====================================================

  //                       WIDTHS

  // ====================================================



  double larguraCliente = 350;



  double larguraArquiteto = 350;



  double larguraTelefone = 180;



  // ====================================================

  //                     SAVE STATE

  // ====================================================



  bool salvandoCliente = false;



  bool salvandoMovel = false;



  bool salvandoOrcamento = false;



  // ====================================================

  //                       INIT

  // ====================================================



  @override

  void initState() {

    super.initState();



    clienteController.text =

        widget.clienteNome;



    _carregarOrcamento();



    _totaisGeraisPorMovel.clear();



    _moveisJaInicializados.clear();



    _totalOrcamentoNotifier.value = 0.0;



    _carregarCabecalhoOrcamento();



    _moveisStream = FirebaseFirestore.instance

        .collection('moveis')

        .where(

          'numeroOrcamento',

          isEqualTo: widget.numeroOrcamento,

        )

        .orderBy('numeroMovel')

        .snapshots();

  }



  // ====================================================

  //                       DISPOSE

  // ====================================================



  @override

  void dispose() {

    freteController.dispose();

    extraController.dispose();

    maoDeObraController.dispose();

    percentualController.dispose();



    ppController.dispose();

    clienteController.dispose();

    telefoneClienteController.dispose();

    arquitetoController.dispose();



    _saveTimer?.cancel();



    for (final controller

        in _freteControllers.values) {

      controller.dispose();

    }



    for (final controller

        in _almocoControllers.values) {

      controller.dispose();

    }



    for (final controller

        in _maoObraControllers.values) {

      controller.dispose();

    }



    for (final controller

        in _lucroControllers.values) {

      controller.dispose();

    }



    for (final controller

        in _obsControllers.values) {

      controller.dispose();

    }



    _scrollCtrl.dispose();



    _totalOrcamentoNotifier.dispose();



    super.dispose();

  }



  // ====================================================

  //                  MÓVEL SEARCH BAR

  // ====================================================



  Widget _buildMovelSearchBar(

    BuildContext context,

  ) {

    return Row(

      children: [

        // ------------------------------------------------

        // SEARCH

        // ------------------------------------------------



        Expanded(

          child: TextField(

            cursorColor: _brown,

            style: const TextStyle(

              fontFamily: 'Nunito',

              fontSize: 14,

              fontWeight: FontWeight.w500,

              color: Colors.black,

            ),

            decoration: InputDecoration(

              hintText: 'Buscar móvel...',

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

              filled: true,

              fillColor: Colors.white,

              isDense: true,

              contentPadding:

                  const EdgeInsets.symmetric(

                horizontal: 16,

                vertical: 15,

              ),

              enabledBorder: OutlineInputBorder(

                borderRadius:

                    BorderRadius.circular(14),

                borderSide: const BorderSide(

                  color: _border,

                ),

              ),

              focusedBorder: OutlineInputBorder(

                borderRadius:

                    BorderRadius.circular(14),

                borderSide: const BorderSide(

                  color: _brown,

                  width: 1.5,

                ),

              ),

            ),

            onChanged: (value) {

              setState(() {

                _movelSearch =

                    value.trim().toLowerCase();

              });

            },

          ),

        ),



        const SizedBox(width: 10),



        // ------------------------------------------------

        // SORT BUTTON

        // ------------------------------------------------



        Tooltip(

          message: _moveisDescending

              ? 'Mostrar primeiros móveis primeiro'

              : 'Mostrar últimos móveis primeiro',

          child: Material(

            color: _softBrown,

            borderRadius:

                BorderRadius.circular(13),

            child: InkWell(

              borderRadius:

                  BorderRadius.circular(13),

              onTap: () {

                setState(() {

                  _moveisDescending =

                      !_moveisDescending;

                });

              },

              child: SizedBox(

                width: 48,

                height: 48,

                child: Icon(

                  _moveisDescending

                      ? Icons

                          .arrow_downward_rounded

                      : Icons

                          .arrow_upward_rounded,

                  color: _darkBrown,

                  size: 21,

                ),

              ),

            ),

          ),

        ),

      ],

    );

  }



  // ====================================================

  //                   APP BAR BUTTON

  // ====================================================



  Widget _buildAppBarButton({

    required String tooltip,

    required IconData icon,

    required VoidCallback onPressed,

  }) {

    return Padding(

      padding: const EdgeInsets.symmetric(

        vertical: 7,

      ),

      child: Tooltip(

        message: tooltip,

        child: Material(

          color: _softBrown,

          borderRadius:

              BorderRadius.circular(11),

          child: InkWell(

            onTap: onPressed,

            borderRadius:

                BorderRadius.circular(11),

            child: SizedBox(

              width: 40,

              height: 40,

              child: Icon(

                icon,

                size: 20,

                color: _darkBrown,

              ),

            ),

          ),

        ),

      ),

    );

  }



  // ====================================================

  //                        BUILD

  // ====================================================



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,



      // =================================================

      //                      APP BAR

      // =================================================



      appBar: AppBar(

        backgroundColor: Colors.white,

        surfaceTintColor: Colors.transparent,

        elevation: 0,

        scrolledUnderElevation: 0,

        leading: IconButton(
        tooltip: 'Voltar',
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: Colors.black,
        ),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),

      iconTheme: const IconThemeData(

          color: Colors.black,

        ),

        title: Column(

          crossAxisAlignment:

              CrossAxisAlignment.start,

          children: [

            const Text(

              'Orçamento',

              style: TextStyle(

                fontFamily: 'Nunito',

                fontSize: 22,

                fontWeight: FontWeight.w800,

                color: Colors.black,

              ),

            ),

            Text(

              'Nº ${widget.numeroOrcamento}',

              style: const TextStyle(

                fontFamily: 'Nunito',

                fontSize: 11,

                fontWeight: FontWeight.w600,

                color: _softText,

              ),

            ),

          ],

        ),

        actions: [

          // ----------------------------------------------

          // SAVE

          // ----------------------------------------------



          _buildAppBarButton(

            tooltip: 'Salvar resumo',

            icon: Icons.save_outlined,

            onPressed: _salvarResumoTodosMoveis,

          ),



          const SizedBox(width: 8),



          // ----------------------------------------------

          // PDF

          // ----------------------------------------------



          _buildAppBarButton(

            tooltip: 'Gerar PDF',

            icon: Icons.picture_as_pdf_outlined,

            onPressed: _gerarPdfOrcamento,

          ),



          const SizedBox(width: 16),

        ],

      ),



      // =================================================

      //                       BODY

      // =================================================



      body: SafeArea(

        child: ListView(

          controller: _scrollCtrl,

          key: _orcamentoScrollKey,

          padding: const EdgeInsets.fromLTRB(

            20,

            12,

            20,

            110,

          ),

          children: [

            // --------------------------------------------

            // HEADER

            // --------------------------------------------



            _buildHeader(context),



            const SizedBox(height: 24),



            // --------------------------------------------

            // MÓVEIS TITLE

            // --------------------------------------------



            const Text(

              'Móveis',

              style: TextStyle(

                fontFamily: 'Nunito',

                fontSize: 20,

                fontWeight: FontWeight.w800,

                color: Colors.black,

              ),

            ),



            const SizedBox(height: 4),



            const Text(

              'Gerencie os móveis deste orçamento.',

              style: TextStyle(

                fontFamily: 'Nunito',

                fontSize: 13,

                fontWeight: FontWeight.w500,

                color: _softText,

              ),

            ),



            const SizedBox(height: 14),



            // --------------------------------------------

            // SEARCH + SORT

            // --------------------------------------------



            _buildMovelSearchBar(context),



            const SizedBox(height: 16),



            // --------------------------------------------

            // MÓVEIS

            // --------------------------------------------



            _buildMoveisSection(context),



            const SizedBox(height: 24),

          ],

        ),

      ),



      // =================================================

      //                  ADD MÓVEL BUTTON

      // =================================================
    floatingActionButton: FloatingActionButton(
      onPressed: () async {
        await _showAddMovelDialog(context);
      },
      tooltip: 'Adicionar móvel',
      elevation: 1,
      hoverElevation: 3,
      highlightElevation: 0,
      backgroundColor: _darkBrown,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.add_rounded,
        size: 28,
      ),
    ),

    floatingActionButtonLocation:
        FloatingActionButtonLocation.startFloat,

    );

  }

}