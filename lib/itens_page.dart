import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'widgets/item_cards.dart';
part 'views/itens_madeira_macica_view.dart';
part 'views/itens_folha_view.dart';
part 'views/itens_litro_view.dart';
part 'views/itens_metro_view.dart';
part 'views/itens_unidade_view.dart';

class ItensPage extends StatelessWidget {
  const ItensPage({super.key});

  static const Color _brown = Color(0xFF79533B);
  static const Color _darkBrown = Color(0xFF5A3825);
  static const Color _border = Color(0xFFE8E3DF);
  static const Color _softBrown = Color(0xFFF4EEEA);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        // IMPORTANT: pure white background
        backgroundColor: Colors.white,

        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,

          titleSpacing: 24,

          title: const Text(
            'Itens',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),

          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Column(
              children: [
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: _border,
                ),

                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    10,
                  ),
                  child: const TabBar(
                    isScrollable: true,

                    tabAlignment: TabAlignment.start,

                    dividerColor: Colors.transparent,

                    labelColor: _darkBrown,
                    unselectedLabelColor: Color(0xFF77716D),

                    labelStyle: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),

                    unselectedLabelStyle: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),

                    indicator: BoxDecoration(
                      color: _softBrown,
                      borderRadius: BorderRadius.all(
                        Radius.circular(12),
                      ),
                    ),

                    indicatorSize: TabBarIndicatorSize.tab,

                    labelPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                    ),

                    tabs: [
                      Tab(
                        height: 40,
                        child: Row(
                          children: [
                            Icon(
                              Icons.layers_outlined,
                              size: 18,
                            ),
                            SizedBox(width: 7),
                            Text('Folha'),
                          ],
                        ),
                      ),

                      Tab(
                        height: 40,
                        child: Row(
                          children: [
                            Icon(
                              Icons.water_drop_outlined,
                              size: 18,
                            ),
                            SizedBox(width: 7),
                            Text('Litro'),
                          ],
                        ),
                      ),

                      Tab(
                        height: 40,
                        child: Row(
                          children: [
                            Icon(
                              Icons.straighten_outlined,
                              size: 18,
                            ),
                            SizedBox(width: 7),
                            Text('Metro'),
                          ],
                        ),
                      ),

                      Tab(
                        height: 40,
                        child: Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 18,
                            ),
                            SizedBox(width: 7),
                            Text('Unidade'),
                          ],
                        ),
                      ),

                      Tab(
                        height: 40,
                        child: Row(
                          children: [
                            Icon(
                              Icons.forest_outlined,
                              size: 18,
                            ),
                            SizedBox(width: 7),
                            Text('Madeira Maciça'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(
                  height: 1,
                  thickness: 1,
                  color: _border,
                ),
              ],
            ),
          ),
        ),

        body: const ColoredBox(
          color: Colors.white,
          child: TabBarView(
            children: [
              _ItensFolhaView(),
              _ItensLitroView(),
              _ItensMetroView(),
              _ItensUnidadeView(),
              _ItensMadeiraMacicaView(),
            ],
          ),
        ),
      ),
    );
  }
}