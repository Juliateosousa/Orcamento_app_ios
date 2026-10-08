part of 'orcamento_page.dart';

extension _OrcamentoDadosExtension on _OrcamentoPageState {
  // =====================================================
  //                 CARREGAR CABEÇALHO
  // =====================================================

  Future<void> _carregarCabecalhoOrcamento() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('clientes')
          .doc(widget.clienteId)
          .collection('orcamentos')
          .doc(widget.orcamentoId);

      final snap = await docRef.get();
      final data = snap.data();

      if (data == null || !mounted) return;

      setState(() {
        freteController.text =
            (data['frete'] ?? '').toString();

        extraController.text =
            (data['extra'] ?? '').toString();

        maoDeObraController.text =
            (data['maoDeObra'] ?? '').toString();

        percentualController.text =
            (data['percentual'] ?? '').toString();
      });
    } catch (e) {
      debugPrint(
        'Erro ao carregar cabeçalho do orçamento: $e',
      );
    }
  }

  // =====================================================
  //          GERAR PRÓXIMO NÚMERO DE MÓVEL GLOBAL
  // =====================================================

  Future<int> _gerarProximoNumeroMovelGlobal() async {
    final db = FirebaseFirestore.instance;

    final counterRef = db
        .collection('config')
        .doc('movel_counter');

    return db.runTransaction<int>(
      (transaction) async {
        final snap = await transaction.get(
          counterRef,
        );

        int ultimo = 0;

        if (snap.exists) {
          final data = snap.data() ?? {};
          final raw = data['ultimoNumeroMovel'];

          if (raw is int) {
            ultimo = raw;
          } else if (raw is num) {
            ultimo = raw.toInt();
          }
        }

        final proximo = ultimo + 1;

        transaction.set(
          counterRef,
          {
            'ultimoNumeroMovel': proximo,
          },
          SetOptions(
            merge: true,
          ),
        );

        return proximo;
      },
    );
  }

  // =====================================================
  //             GERAR NÚMERO DE ORÇAMENTO
  // =====================================================

  Future<int> gerarProximoNumeroOrcamento() async {
    final ref = FirebaseFirestore.instance
        .collection('config')
        .doc('contador_orcamentos');

    return FirebaseFirestore.instance.runTransaction<int>(
      (transaction) async {
        final snapshot = await transaction.get(ref);

        int atual = 0;

        if (snapshot.exists) {
          final data = snapshot.data();
          final raw = data?['ultimoNumero'];

          if (raw is int) {
            atual = raw;
          } else if (raw is num) {
            atual = raw.toInt();
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

  // =====================================================
  //         GERAR NÚMERO DE ORÇAMENTO GLOBAL
  // =====================================================

  Future<int> gerarProximoNumeroOrcamentoGlobal() async {
    final ref = FirebaseFirestore.instance
        .collection('config')
        .doc('contador_orcamentos');

    return FirebaseFirestore.instance.runTransaction<int>(
      (transaction) async {
        final snapshot = await transaction.get(ref);

        int atual = 0;

        if (snapshot.exists) {
          final data = snapshot.data() ?? {};
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

  // =====================================================
  //                  CRIAR NOVO ORÇAMENTO
  // =====================================================

  Future<void> criarNovoOrcamento(
    String clienteId,
    String clienteNome,
  ) async {
    try {
      // 1. Gera o próximo número global do orçamento.
      final numeroOrcamento =
          await gerarProximoNumeroOrcamentoGlobal();

      // 2. Cria o documento dentro do cliente.
      final novoDoc = await FirebaseFirestore.instance
          .collection('clientes')
          .doc(clienteId)
          .collection('orcamentos')
          .add({
        'numeroOrcamento': numeroOrcamento,
        'createdAt': FieldValue.serverTimestamp(),
        'clienteId': clienteId,
        'clienteNome': clienteNome,
        'pp': null,
      });

      if (!mounted) return;

      // 3. Abre o orçamento recém-criado.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrcamentoPage(
            clienteId: clienteId,
            clienteNome: clienteNome,
            orcamentoId: novoDoc.id,
            numeroOrcamento: numeroOrcamento,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao criar orçamento: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  //                  CARREGAR ORÇAMENTO
  // =====================================================

  Future<void> _carregarOrcamento() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('clientes')
          .doc(widget.clienteId)
          .collection('orcamentos')
          .doc(widget.orcamentoId);

      final doc = await docRef.get();

      if (!doc.exists) return;

      final data = doc.data();

      if (data == null || !mounted) return;

      ppController.text =
          data['pp']?.toString() ?? '';

      clienteController.text =
          data['clienteNome']?.toString() ??
              widget.clienteNome;

      telefoneClienteController.text =
          data['telefone']?.toString() ?? '';

      arquitetoController.text =
          data['arquiteto']?.toString() ?? '';
    } catch (e) {
      debugPrint(
        'Erro ao carregar orçamento: $e',
      );
    }
  }

  // =====================================================
  //                    ADICIONAR MÓVEL
  // =====================================================

  // Your original code ended here.
}
