part of '../Orçamento Base/orcamento_page.dart';

enum _AcaoMovel {
  duplicar,
  guardar,
  excluir,
}

// ======================================================
//                  SEÇÃO DE MÓVEIS
// ======================================================

extension _MoveisExtension on _OrcamentoPageState {
  Widget _buildMoveisSection(BuildContext context) {
    const darkBrown = Color(0xFF5A3825);
    const softBrown = Color(0xFFF4EEEA);
    const border = Color(0xFFE8E3DF);
    const softText = Color(0xFF77716D);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),

        StreamBuilder<QuerySnapshot>(
          stream: _moveisStream,
          builder: (context, snapshot) {
            // =================================================
            //                        ERROR
            // =================================================

            if (snapshot.hasError) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: border,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Erro ao carregar móveis',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: softText,
                      ),
                    ),
                  ],
                ),
              );
            }

            // =================================================
            //                       LOADING
            // =================================================

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: border,
                  ),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: darkBrown,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Carregando móveis...',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: softText,
                      ),
                    ),
                  ],
                ),
              );
            }

            // =================================================
            //                       EMPTY
            // =================================================

            if (!snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: border,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: softBrown,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.chair_outlined,
                        color: darkBrown,
                        size: 25,
                      ),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'Nenhum móvel adicionado',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Use o botão + para adicionar o primeiro móvel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: softText,
                      ),
                    ),
                  ],
                ),
              );
            }

            // =================================================
            //                       SEARCH
            // =================================================

            final busca =
                _movelSearch.trim().toLowerCase();

            final docs = snapshot.data!.docs.where(
              (doc) {
                final data =
                    doc.data()
                            as Map<String, dynamic>? ??
                        {};

                final nome = (data['nome'] ?? '')
                    .toString()
                    .trim()
                    .toLowerCase();

                final numeroMovel =
                    (data['numeroMovel'] ?? '')
                        .toString()
                        .toLowerCase();

                if (busca.isEmpty) {
                  return true;
                }

                return nome.contains(busca) ||
                    numeroMovel.contains(busca);
              },
            ).toList();

            // =================================================
            //                        SORT
            // =================================================

            docs.sort(
              (a, b) {
                final dataA =
                    a.data()
                            as Map<String, dynamic>? ??
                        {};

                final dataB =
                    b.data()
                            as Map<String, dynamic>? ??
                        {};

                final numeroA =
                    (dataA['numeroMovel'] as num?)
                            ?.toInt() ??
                        0;

                final numeroB =
                    (dataB['numeroMovel'] as num?)
                            ?.toInt() ??
                        0;

                return _moveisDescending
                    ? numeroB.compareTo(numeroA)
                    : numeroA.compareTo(numeroB);
              },
            );

            // =================================================
            //                  NO SEARCH RESULTS
            // =================================================

            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: border,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: softBrown,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.search_off_rounded,
                        color: darkBrown,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nenhum móvel encontrado',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Não encontramos resultados para "$_movelSearch".',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: softText,
                      ),
                    ),
                  ],
                ),
              );
            }

            // =================================================
            //                    MÓVEIS LIST
            // =================================================

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildMovelCard(
                    context,
                    doc,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
