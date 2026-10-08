part of '../itens_page.dart';

// =====================================================
//                       COLORS
// =====================================================

const Color _itemCardDarkBrown = Color(0xFF5A3825);
const Color _itemCardBrown = Color(0xFF79533B);
const Color _itemCardSoftBrown = Color(0xFFF4EEEA);
const Color _itemCardBorder = Color(0xFFE8E3DF);
const Color _itemCardSoftText = Color(0xFF77716D);

// =====================================================
//                         FOLHA
// =====================================================

class _FolhaItemRowCard extends StatelessWidget {
  final String nome;
  final String precoText;
  final String areaText;
  final String perdaText;
  final VoidCallback onTap;

  const _FolhaItemRowCard({
    required this.nome,
    required this.precoText,
    required this.areaText,
    required this.perdaText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseItemCard(
      icon: Icons.dashboard_outlined,
      nome: nome,
      onTap: onTap,
      info: [
        _ItemCardInfo(
          label: 'Preço',
          value: precoText,
        ),
        _ItemCardInfo(
          label: 'Área',
          value: areaText,
        ),
        _ItemCardInfo(
          label: 'Perda',
          value: perdaText,
        ),
      ],
    );
  }
}

// =====================================================
//                          COLA
// =====================================================

class _ColaItemRowCard extends StatelessWidget {
  final String nome;
  final bool hasPrecoL;
  final bool hasLm2;
  final String precoLText;
  final String lm2Text;
  final VoidCallback? onTap;

  const _ColaItemRowCard({
    required this.nome,
    required this.hasPrecoL,
    required this.hasLm2,
    required this.precoLText,
    required this.lm2Text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<_ItemCardInfo> info = [];

    if (hasPrecoL) {
      info.add(
        _ItemCardInfo(
          label: 'Preço / L',
          value: precoLText,
        ),
      );
    }

    if (hasLm2) {
      info.add(
        _ItemCardInfo(
          label: 'L/m²',
          value: lm2Text,
        ),
      );
    }

    if (info.isEmpty) {
      info.add(
        const _ItemCardInfo(
          label: 'Valor',
          value: '-',
        ),
      );
    }

    return _BaseItemCard(
      icon: Icons.water_drop_outlined,
      nome: nome,
      onTap: onTap,
      info: info,
    );
  }
}

// =====================================================
//                         LITRO
// =====================================================

class _LitroItemRowCard extends StatelessWidget {
  final String nome;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _LitroItemRowCard({
    required this.nome,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseItemCard(
      icon: Icons.format_paint_outlined,
      nome: nome,
      onTap: onTap,
      info: [
        _ItemCardInfo(
          label: label,
          value: value,
        ),
      ],
    );
  }
}

// =====================================================
//                          METRO
// =====================================================

class _MetroItemRowCard extends StatelessWidget {
  final String nome;
  final String precoText;
  final String metragemText;
  final VoidCallback onTap;

  const _MetroItemRowCard({
    required this.nome,
    required this.precoText,
    required this.metragemText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseItemCard(
      icon: Icons.straighten_rounded,
      nome: nome,
      onTap: onTap,
      info: [
        _ItemCardInfo(
          label: 'Preço/m',
          value: precoText,
        ),
        _ItemCardInfo(
          label: 'Metragem',
          value: metragemText,
        ),
      ],
    );
  }
}

// =====================================================
//                        UNIDADE
// =====================================================

class _UnidadeItemRowCard extends StatelessWidget {
  final String nome;
  final String precoText;
  final VoidCallback onTap;

  const _UnidadeItemRowCard({
    required this.nome,
    required this.precoText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseItemCard(
      icon: Icons.inventory_2_outlined,
      nome: nome,
      onTap: onTap,
      info: [
        _ItemCardInfo(
          label: 'Preço / Und',
          value: precoText,
        ),
      ],
    );
  }
}

// =====================================================
//                     BASE ITEM CARD
// =====================================================

class _BaseItemCard extends StatelessWidget {
  final IconData icon;
  final String nome;
  final List<_ItemCardInfo> info;
  final VoidCallback? onTap;

  const _BaseItemCard({
    required this.icon,
    required this.nome,
    required this.info,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: _itemCardSoftBrown,
        highlightColor: _itemCardSoftBrown.withValues(alpha: 0.45),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _itemCardBorder,
            ),
          ),
          child: Row(
            children: [
              // ---------------- ICON ----------------

              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _itemCardSoftBrown,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: _itemCardDarkBrown,
                  size: 21,
                ),
              ),

              const SizedBox(width: 14),

              // ---------------- NAME ----------------

              Expanded(
                flex: 3,
                child: Text(
                  nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // ---------------- INFORMATION ----------------

              Flexible(
                flex: 4,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    for (final item in info)
                      _ItemCardInfoWidget(
                        label: item.label,
                        value: item.value,
                      ),
                  ],
                ),
              ),

              if (onTap != null) ...[
                const SizedBox(width: 10),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _itemCardSoftText,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
//                      INFO MODEL
// =====================================================

class _ItemCardInfo {
  final String label;
  final String value;

  const _ItemCardInfo({
    required this.label,
    required this.value,
  });
}

// =====================================================
//                      INFO WIDGET
// =====================================================

class _ItemCardInfoWidget extends StatelessWidget {
  final String label;
  final String value;

  const _ItemCardInfoWidget({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _itemCardSoftText,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
