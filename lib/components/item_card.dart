import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';

import '../models/UserModel.dart';

class ItemCardLayoutGrid extends StatelessWidget {
  final int crossAxisCount;
  final List spots;
  final User user;
  final bookSpot;

  const ItemCardLayoutGrid({
    Key? key,
    required this.crossAxisCount,
    required this.spots,
    required this.bookSpot,
    required this.user,
  })  
  // we only plan to use this with 1 or 2 columns
  : assert(crossAxisCount == 1 || crossAxisCount == 2),
        assert(spots.length < 1000),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutGrid(
      // set some flexible track sizes based on the crossAxisCount
      columnSizes: List.filled(crossAxisCount, 1.fr),
      // set all the row sizes to auto (self-sizing height)
      rowSizes: List.filled((spots.length / 2 + 1).toInt(), auto),
      rowGap: 20, // equivalent to mainAxisSpacing
      columnGap: 10, // equivalent to crossAxisSpacing
      // note: there's no childAspectRatio
      children: [
        // render all the cards with *automatic child placement*
        for (var i = 0; i < spots.length; i++)
          GestureDetector(
            onTap: () => {
              if (user.parkingSpot == null) {bookSpot(spots[i])}
            },
            child: Card(
              child: Container(
                alignment: Alignment.center,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 30,
                        child: ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                            child: Image.asset(
                              "assets/images/parking.png",
                              height: 60,
                              width: 60,
                            )),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          spots[i].name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          'Kes. ${spots[i].cost.toString()}/hr',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          'Kes. ${(spots[i].lateFee * 5).toString()}/each 5 extra minutes.',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.orange),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                decoration: BoxDecoration(
                    color: Color(0xffffffff),
                    borderRadius: BorderRadius.circular(5)),
              ),
            ),
          ),
      ],
    );
  }
}
