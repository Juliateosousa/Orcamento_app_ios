import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'orcamento_page.dart';

// ======================================================
//                         COLORS
// ======================================================

const Color _darkBrown = Color(0xFF5A3825);
const Color _brown = Color(0xFF79533B);
const Color _softBrown = Color(0xFFF4EEEA);
const Color _border = Color(0xFFE8E3DF);
const Color _softText = Color(0xFF77716D);

// ======================================================
//              CONTADOR GLOBAL DE ORÇAMENTOS
// ======================================================

Future<int> gerarProximoNumeroOrcamentoGlobal() async {
  final ref = FirebaseFirestore.instance
      .collection('config')
      .doc('contador_orcamentos');

  return FirebaseFirestore.instance.runTransaction<int>(
    (transaction) async {
      final snapshot = await transaction.get(ref);

      int atual = 0;

      if (snapshot.exists) {
        final data =
            snapshot.data() ?? {};

        final ultimo = data['ultimoNumero'];

        if (ultimo is int) {
          atual = ultimo;
        } else if (ultimo is num) {
          atual = ultimo.toInt();
        }
      }

      final proximo = atual + 1;

      transaction.set(
        ref,
        {
          'ultimoNumero': proximo,
        },
        SetOptions(
          merge: true,
        ),
      );

      return proximo;
    },
  );
}

// ======================================================
//              PÁGINA DE ORÇAMENTOS DO CLIENTE
// ======================================================

class OrcamentosClientePage extends StatefulWidget {
  final String clienteId;
  final String clienteNome;

  const OrcamentosClientePage({
    super.key,
    required this.clienteId,
    required this.clienteNome,
  });

  @override
  State<OrcamentosClientePage> createState() =>
      _OrcamentosClientePageState();
}

class _OrcamentosClientePageState
    extends State<OrcamentosClientePage> {
  bool _isFabHovered = false;

  // ====================================================
  //                  CRIAR ORÇAMENTO
  // ====================================================

  Future<void> _criarNovoOrcamento() async {
    try {
      final nextNumero =
          await gerarProximoNumeroOrcamentoGlobal();

      final novoDoc = await FirebaseFirestore.instance
          .collection('clientes')
          .doc(widget.clienteId)
          .collection('orcamentos')
          .add({
        'numeroOrcamento': nextNumero,
        'createdAt': FieldValue.serverTimestamp(),
        'clienteId': widget.clienteId,
        'clienteNome': widget.clienteNome,
        'pp': null,
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrcamentoPage(
            clienteId: widget.clienteId,
            clienteNome: widget.clienteNome,
            orcamentoId: novoDoc.id,
            numeroOrcamento: nextNumero,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao criar novo orçamento: $e',
          ),
        ),
      );
    }
  }

  // ====================================================
  //               DELETE CONFIRMATION
  // ====================================================

  Future<bool> _confirmarRemocao(
    String tituloOrcamento,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Remover orçamento',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Deseja remover o orçamento $tituloOrcamento do cliente "${widget.clienteNome}"?',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: _softText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                      color: _softText,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: const Text(
                    'Remover',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // ====================================================
  //                       BUILD
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
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Orçamentos',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            Text(
              widget.clienteNome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _softText,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 16,
            ),
            child: Tooltip(
              message: 'Móveis armazenados',
              child: Material(
                color: _softBrown,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MoveisArmazenadosPage(
                          clienteId: widget.clienteId,
                          clienteNome: widget.clienteNome,
                        ),
                      ),
                    );
                  },
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: _darkBrown,
                      size: 21,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // =================================================
      //                       BODY
      // =================================================

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clientes')
            .doc(widget.clienteId)
            .collection('orcamentos')
            .orderBy(
              'numeroOrcamento',
              descending: false,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _PageMessage(
              icon: Icons.error_outline_rounded,
              title: 'Erro ao carregar orçamentos',
              message:
                  'Não foi possível carregar os orçamentos deste cliente.',
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _brown,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const _PageMessage(
              icon: Icons.request_quote_outlined,
              title: 'Nenhum orçamento',
              message:
                  'Adicione o primeiro orçamento deste cliente.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              20,
              14,
              20,
              100,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];

              final data =
                  doc.data() as Map<String, dynamic>? ?? {};

              final numeroRaw =
                  data['numeroOrcamento'];

              final int numeroOrcamento =
                  numeroRaw is num
                      ? numeroRaw.toInt()
                      : int.tryParse(
                            numeroRaw?.toString() ?? '',
                          ) ??
                          0;

              // ------------------------------------------
              // DATE
              // ------------------------------------------

              final createdAt = data['createdAt'];

              String dataStr = '';

              if (createdAt is Timestamp) {
                final dt = createdAt.toDate();

                dataStr =
                    '${dt.day.toString().padLeft(2, '0')}/'
                    '${dt.month.toString().padLeft(2, '0')}/'
                    '${dt.year}';
              }

              // ------------------------------------------
              // PP
              // ------------------------------------------

              final String pp =
                  (data['pp'] ?? '')
                      .toString()
                      .trim();

              final String tituloOrcamento =
                  pp.isNotEmpty
                      ? 'PP $pp'
                      : 'Orçamento Nº $numeroOrcamento';

              // ------------------------------------------
              // CARD
              // ------------------------------------------

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Dismissible(
                  key: ValueKey(doc.id),
                  direction:
                      DismissDirection.endToStart,

                  // --------------------------------------
                  // DELETE BACKGROUND
                  // --------------------------------------

                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  confirmDismiss: (_) {
                    return _confirmarRemocao(
                      tituloOrcamento,
                    );
                  },

                  onDismissed: (_) async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('clientes')
                          .doc(widget.clienteId)
                          .collection('orcamentos')
                          .doc(doc.id)
                          .delete();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Orçamento $tituloOrcamento removido de "${widget.clienteNome}".',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erro ao remover orçamento: $e',
                          ),
                        ),
                      );
                    }
                  },

                  // --------------------------------------
                  // CONTENT
                  // --------------------------------------

                  child: Material(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(16),
                      splashColor:
                          _softBrown.withValues(
                        alpha: 0.7,
                      ),
                      highlightColor:
                          _softBrown.withValues(
                        alpha: 0.35,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                OrcamentoPage(
                              clienteId:
                                  widget.clienteId,
                              clienteNome:
                                  widget.clienteNome,
                              orcamentoId: doc.id,
                              numeroOrcamento:
                                  numeroOrcamento,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                            color: _border,
                          ),
                        ),
                        child: Row(
                          children: [
                            // --------------------------------
                            // ICON
                            // --------------------------------

                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: _softBrown,
                                borderRadius:
                                    BorderRadius.circular(
                                  13,
                                ),
                              ),
                              child: const Icon(
                                Icons
                                    .request_quote_outlined,
                                color: _darkBrown,
                                size: 23,
                              ),
                            ),

                            const SizedBox(width: 14),

                            // --------------------------------
                            // INFO
                            // --------------------------------

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    tituloOrcamento,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                    style:
                                        const TextStyle(
                                      fontFamily:
                                          'Nunito',
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.w800,
                                      color:
                                          Colors.black,
                                    ),
                                  ),
                                  if (dataStr
                                      .isNotEmpty) ...[
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons
                                              .calendar_today_outlined,
                                          size: 13,
                                          color:
                                              _softText,
                                        ),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          dataStr,
                                          style:
                                              const TextStyle(
                                            fontFamily:
                                                'Nunito',
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight
                                                    .w500,
                                            color:
                                                _softText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            // --------------------------------
                            // NUMBER OF MÓVEIS
                            // --------------------------------

                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore
                                  .instance
                                  .collection('moveis')
                                  .where(
                                    'clienteId',
                                    isEqualTo:
                                        widget.clienteId,
                                  )
                                  .where(
                                    'numeroOrcamento',
                                    isEqualTo:
                                        numeroOrcamento,
                                  )
                                  .snapshots(),
                              builder: (
                                context,
                                moveisSnapshot,
                              ) {
                                if (!moveisSnapshot
                                    .hasData) {
                                  return const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _brown,
                                    ),
                                  );
                                }

                                final quantidade =
                                    moveisSnapshot
                                        .data!
                                        .docs
                                        .length;

                                return Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        _softBrown,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      10,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons
                                            .chair_outlined,
                                        size: 17,
                                        color:
                                            _darkBrown,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                        '$quantidade',
                                        style:
                                            const TextStyle(
                                          fontFamily:
                                              'Nunito',
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight
                                                  .w800,
                                          color:
                                              _darkBrown,
                                        ),
                                      ),
                                      if (MediaQuery
                                              .sizeOf(
                                                context,
                                              )
                                              .width >
                                          500) ...[
                                        const SizedBox(
                                          width: 4,
                                        ),
                                        Text(
                                          quantidade == 1
                                              ? 'móvel'
                                              : 'móveis',
                                          style:
                                              const TextStyle(
                                            fontFamily:
                                                'Nunito',
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                            color:
                                                _darkBrown,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),

                            const SizedBox(width: 8),

                            const Icon(
                              Icons.chevron_right_rounded,
                              color: _brown,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      // =================================================
      //                 ADD ORÇAMENTO FAB
      // =================================================

      floatingActionButton: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() {
            _isFabHovered = true;
          });
        },
        onExit: (_) {
          setState(() {
            _isFabHovered = false;
          });
        },
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 150),
          width: _isFabHovered ? 62 : 58,
          height: _isFabHovered ? 62 : 58,
          child: FloatingActionButton(
            onPressed: _criarNovoOrcamento,
            tooltip: 'Novo orçamento',
            elevation: _isFabHovered ? 3 : 0,
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
        ),
      ),
    );
  }
}

// ======================================================
//              PÁGINA DE MÓVEIS ARMAZENADOS
// ======================================================

class MoveisArmazenadosPage extends StatelessWidget {
  final String clienteId;
  final String clienteNome;

  const MoveisArmazenadosPage({
    super.key,
    required this.clienteId,
    required this.clienteNome,
  });

  @override
  Widget build(BuildContext context) {
    final modelosRef = FirebaseFirestore.instance
        .collection('clientes')
        .doc(clienteId)
        .collection('moveis_armazenados');

    return Scaffold(
      backgroundColor: Colors.white,

      // =================================================
      //                     APP BAR
      // =================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Móveis armazenados',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            Text(
              clienteNome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _softText,
              ),
            ),
          ],
        ),
      ),

      // =================================================
      //                       BODY
      // =================================================

      body: StreamBuilder<QuerySnapshot>(
        stream: modelosRef
            .orderBy(
              'nome',
              descending: false,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _PageMessage(
              icon: Icons.error_outline_rounded,
              title: 'Erro ao carregar móveis',
              message:
                  'Não foi possível carregar os móveis armazenados.',
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _brown,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const _PageMessage(
              icon: Icons.inventory_2_outlined,
              title: 'Nenhum móvel armazenado',
              message:
                  'Os móveis armazenados deste cliente aparecerão aqui.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              20,
              14,
              20,
              30,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];

              final data =
                  doc.data() as Map<String, dynamic>? ?? {};

              final nome =
                  data['nome'] as String? ??
                      '(sem nome)';

              final numOrig =
                  data['numeroOrcamentoOriginal'];

              final numeroOrigStr =
                  numOrig == null
                      ? '-'
                      : numOrig.toString();

              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(16),
                    border: Border.all(
                      color: _border,
                    ),
                  ),
                  child: Row(
                    children: [
                      // ----------------------------------
                      // ICON
                      // ----------------------------------

                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _softBrown,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.chair_outlined,
                          color: _darkBrown,
                          size: 22,
                        ),
                      ),

                      const SizedBox(width: 13),

                      // ----------------------------------
                      // INFO
                      // ----------------------------------

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Orig. Orçamento Nº $numeroOrigStr',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w500,
                                color: _softText,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ----------------------------------
                      // ADD
                      // ----------------------------------

                      Tooltip(
                        message:
                            'Adicionar em um orçamento',
                        child: Material(
                          color: _softBrown,
                          borderRadius:
                              BorderRadius.circular(11),
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(
                              11,
                            ),
                            onTap: () {
                              _showAdicionarMovelEmOrcamentoDialog(
                                context,
                                clienteId,
                                doc,
                              );
                            },
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.add_rounded,
                                color: _darkBrown,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ====================================================
  //              SELECT ORÇAMENTO DIALOG
  // ====================================================

  void _showAdicionarMovelEmOrcamentoDialog(
    BuildContext context,
    String clienteId,
    DocumentSnapshot movelModeloDoc,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return _AdicionarMovelDialog(
          clienteId: clienteId,
          movelModeloDoc: movelModeloDoc,
          parentContext: context,
        );
      },
    );
  }
}

// ======================================================
//          DIALOG: ESCOLHER ORÇAMENTO DO MÓVEL
// ======================================================

class _AdicionarMovelDialog extends StatefulWidget {
  final String clienteId;
  final DocumentSnapshot movelModeloDoc;
  final BuildContext parentContext;

  const _AdicionarMovelDialog({
    required this.clienteId,
    required this.movelModeloDoc,
    required this.parentContext,
  });

  @override
  State<_AdicionarMovelDialog> createState() =>
      _AdicionarMovelDialogState();
}

class _AdicionarMovelDialogState
    extends State<_AdicionarMovelDialog> {
  String? _orcamentoSelecionadoId;

  DocumentSnapshot?
      _orcamentoSelecionadoDoc;

  @override
  Widget build(BuildContext context) {
    final orcamentosRef =
        FirebaseFirestore.instance
            .collection('clientes')
            .doc(widget.clienteId)
            .collection('orcamentos')
            .orderBy(
              'numeroOrcamento',
              descending: false,
            );

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
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
        16,
        16,
        16,
        8,
      ),
      actionsPadding:
          const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        14,
      ),

      // =================================================
      //                      TITLE
      // =================================================

      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _softBrown,
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.move_to_inbox_outlined,
              color: _darkBrown,
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
                  'Adicionar móvel',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Escolha o orçamento de destino',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _softText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // =================================================
      //                     CONTENT
      // =================================================

      content: SizedBox(
        width: 400,
        height: 300,
        child: FutureBuilder<QuerySnapshot>(
          future: orcamentosRef.get(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const _PageMessage(
                icon: Icons.error_outline_rounded,
                title: 'Erro',
                message:
                    'Não foi possível carregar os orçamentos.',
              );
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(
                  color: _brown,
                ),
              );
            }

            final docs =
                snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const _PageMessage(
                icon:
                    Icons.request_quote_outlined,
                title: 'Nenhum orçamento',
                message:
                    'Nenhum orçamento encontrado para este cliente.',
              );
            }

            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final doc = docs[index];

                final data =
                    doc.data()
                            as Map<String, dynamic>? ??
                        {};

                final numero =
                    data['numeroOrcamento'] ?? 0;

                final pp =
                    (data['pp'] ?? '')
                        .toString()
                        .trim();

                final createdAt =
                    data['createdAt'];

                String dataStr = '';

                if (createdAt is Timestamp) {
                  final dt =
                      createdAt.toDate();

                  dataStr =
                      '${dt.day.toString().padLeft(2, '0')}/'
                      '${dt.month.toString().padLeft(2, '0')}/'
                      '${dt.year}';
                }

                final titulo =
                    pp.isNotEmpty
                        ? 'PP $pp'
                        : 'Orçamento Nº $numero';

                final selected =
                    _orcamentoSelecionadoId ==
                        doc.id;

                return Material(
                  color: selected
                      ? _softBrown
                      : Colors.white,
                  borderRadius:
                      BorderRadius.circular(13),
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(13),
                    onTap: () {
                      setState(() {
                        _orcamentoSelecionadoId =
                            doc.id;

                        _orcamentoSelecionadoDoc =
                            doc;
                      });
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                        border: Border.all(
                          color: selected
                              ? _brown
                              : _border,
                          width:
                              selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // ------------------------------
                          // RADIO
                          // ------------------------------

                          SizedBox(
                            width: 28,
                            height: 28,
                            child: Radio<String>(
                              value: doc.id,
                              groupValue:
                                  _orcamentoSelecionadoId,
                              activeColor:
                                  _darkBrown,
                              onChanged: (value) {
                                setState(() {
                                  _orcamentoSelecionadoId =
                                      value;

                                  _orcamentoSelecionadoDoc =
                                      doc;
                                });
                              },
                            ),
                          ),

                          const SizedBox(width: 9),

                          // ------------------------------
                          // INFO
                          // ------------------------------

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  titulo,
                                  style:
                                      const TextStyle(
                                    fontFamily:
                                        'Nunito',
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                    color:
                                        Colors.black,
                                  ),
                                ),
                                if (dataStr
                                    .isNotEmpty) ...[
                                  const SizedBox(
                                    height: 3,
                                  ),
                                  Text(
                                    dataStr,
                                    style:
                                        const TextStyle(
                                      fontFamily:
                                          'Nunito',
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight
                                              .w500,
                                      color:
                                          _softText,
                                    ),
                                  ),
                                ],
                              ],
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
        ),
      ),

      // =================================================
      //                     ACTIONS
      // =================================================

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Cancelar',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
              color: _softText,
            ),
          ),
        ),
        FilledButton(
          onPressed:
              _orcamentoSelecionadoDoc ==
                      null
                  ? null
                  : () async {
                      final orcamentoDocSelecionado =
                          _orcamentoSelecionadoDoc!;

                      Navigator.of(context)
                          .pop();

                      try {
                        await moverModeloParaOrcamento(
                          widget.parentContext,
                          widget.clienteId,
                          widget.movelModeloDoc,
                          orcamentoDocSelecionado,
                        );

                        if (!widget
                            .parentContext
                            .mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(
                          widget.parentContext,
                        ).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Móvel adicionado ao orçamento com sucesso.',
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!widget
                            .parentContext
                            .mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(
                          widget.parentContext,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Erro ao adicionar móvel: $e',
                            ),
                          ),
                        );
                      }
                    },
          style: FilledButton.styleFrom(
            backgroundColor: _darkBrown,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                _border,
            disabledForegroundColor:
                _softText,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(11),
            ),
          ),
          child: const Text(
            'Adicionar',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ======================================================
//        COPIAR MÓVEL ARMAZENADO PARA ORÇAMENTO
// ======================================================

Future<void> moverModeloParaOrcamento(
  BuildContext context,
  String clienteId,
  DocumentSnapshot movelModeloDoc,
  DocumentSnapshot orcamentoDoc,
) async {
  final db = FirebaseFirestore.instance;

  final movelData =
      movelModeloDoc.data()
              as Map<String, dynamic>? ??
          {};

  final nomeMovel =
      movelData['nome'] as String? ??
          '(sem nome)';

  final orcData =
      orcamentoDoc.data()
              as Map<String, dynamic>? ??
          {};

  final numeroOrcamento =
      orcData['numeroOrcamento'] ?? 0;

  final moveisRef =
      db.collection('moveis');

  final novoMovelRef =
      moveisRef.doc();

  final novoData =
      Map<String, dynamic>.from(
    movelData,
  );

  novoData['numeroOrcamento'] =
      numeroOrcamento;

  novoData['clienteId'] =
      clienteId;

  novoData['createdAt'] =
      FieldValue.serverTimestamp();

  novoData.remove(
    'numeroOrcamentoOriginal',
  );

  novoData.remove(
    'armazenadoEm',
  );

  // ====================================================
  //                 CREATE NEW MÓVEL
  // ====================================================

  await novoMovelRef.set(
    novoData,
  );

  // ====================================================
  //                   COPY ITEMS
  // ====================================================

  final itensSnap =
      await movelModeloDoc.reference
          .collection('itens')
          .get();

  for (final item in itensSnap.docs) {
    await novoMovelRef
        .collection('itens')
        .add(
          item.data(),
        );
  }

  // ====================================================
  //              DELETE STORED VERSION
  // ====================================================

  for (final item in itensSnap.docs) {
    await item.reference.delete();
  }

  await movelModeloDoc.reference.delete();

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Móvel "$nomeMovel" adicionado ao Orçamento Nº $numeroOrcamento.',
      ),
    ),
  );
}

// ======================================================
//                   EMPTY / ERROR STATE
// ======================================================

class _PageMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _PageMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: _softBrown,
                borderRadius:
                    BorderRadius.circular(17),
              ),
              child: Icon(
                icon,
                size: 27,
                color: _darkBrown,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _softText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}