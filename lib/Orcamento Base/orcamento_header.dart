part of 'orcamento_page.dart';

extension HeaderExtension on _OrcamentoPageState {
  Widget _buildHeader(BuildContext context) {
    const darkBrown = Color(0xFF5A3825);
    const brown = Color(0xFF79533B);
    const softBrown = Color(0xFFF4EEEA);
    const border = Color(0xFFE8E3DF);
    const softText = Color(0xFF77716D);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhoneNarrow = constraints.maxWidth < 420;

        // ===================================================
        //                    INPUT STYLE
        // ===================================================

        InputDecoration inputDecoration({
          required String hint,
        }) {
          return InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: softText,
            ),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: brown,
                width: 1.5,
              ),
            ),
          );
        }

        // ===================================================
        //                        PP
        // ===================================================

        Widget ppField() {
          return SizedBox(
            width: 135,
            height: 40,
            child: TextField(
              controller: ppController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.text,
              cursorColor: brown,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              decoration: inputDecoration(
                hint: '8970.03.01',
              ),
              onChanged: (value) {
                _orcamentoRef.update({
                  'pp': value.trim(),
                });
              },
            ),
          );
        }

        Widget ppWidget() {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PP',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              ppField(),
            ],
          );
        }

        // ===================================================
        //                   ADDRESS + PP
        // ===================================================

        Widget addressAndPP() {
          const address = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 17,
                color: softText,
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Rua Adel Nogueira Maia, 300 - Messejana',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: softText,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          );

          // Desktop / tablet
          if (!isPhoneNarrow) {
            return Row(
              children: [
                const Expanded(
                  child: address,
                ),
                const SizedBox(width: 20),
                ppWidget(),
              ],
            );
          }

          // Phone
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              address,
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: ppWidget(),
              ),
            ],
          );
        }

        // ===================================================
        //                       PHONE
        // ===================================================

        Widget phoneRow() {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.phone_outlined,
                size: 16,
                color: softText,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  '(085) 3276-1956 / 3276-5621',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: softText,
                  ),
                ),
              ),
            ],
          );
        }

        // ===================================================
        //                      CLIENT
        // ===================================================

        Widget clienteRow() {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: softBrown,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: darkBrown,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cliente',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: softText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.clienteNome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // ===================================================
        //                     ARCHITECT
        // ===================================================

        Widget arquitetoField() {
          return SizedBox(
            width: isPhoneNarrow
                ? double.infinity
                : larguraArquiteto,
            height: 40,
            child: TextField(
              controller: arquitetoController,
              cursorColor: brown,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              decoration: inputDecoration(
                hint: 'Nome do arquiteto',
              ),
              onChanged: (value) {
                _orcamentoRef.update({
                  'arquiteto': value.trim(),
                });
              },
            ),
          );
        }

        Widget arquitetoRow() {
          if (!isPhoneNarrow) {
            return Row(
              children: [
                const Text(
                  'Arquiteto',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 12),
                arquitetoField(),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Arquiteto',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 7),
              arquitetoField(),
            ],
          );
        }

        // ===================================================
        //                      HEADER
        // ===================================================

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            isPhoneNarrow ? 16 : 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ------------------------------------------------
              // COMPANY
              // ------------------------------------------------

              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: softBrown,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.chair_outlined,
                      color: darkBrown,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Espart Móveis',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ------------------------------------------------
              // ADDRESS + PP
              // ------------------------------------------------

              addressAndPP(),

              const SizedBox(height: 10),

              // ------------------------------------------------
              // PHONE
              // ------------------------------------------------

              phoneRow(),

              const SizedBox(height: 18),

              // ------------------------------------------------
              // DIVIDER
              // ------------------------------------------------

              const Divider(
                height: 1,
                thickness: 1,
                color: border,
              ),

              const SizedBox(height: 18),

              // ------------------------------------------------
              // CLIENT
              // ------------------------------------------------

              clienteRow(),

              const SizedBox(height: 18),

              // ------------------------------------------------
              // ARCHITECT
              // ------------------------------------------------

              arquitetoRow(),
            ],
          ),
        );
      },
    );
  }
}