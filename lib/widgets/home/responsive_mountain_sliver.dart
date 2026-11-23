import 'package:flutter/material.dart';

class ResponsiveMountainSliver extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const ResponsiveMountainSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.mainAxisSpacing = 16.0,
    this.crossAxisSpacing = 16.0,
  });

  static int getCrossAxisCount(double screenWidth) {
    if (screenWidth >= 1024) {
      return 3;
    } else if (screenWidth >= 600) {
      return 2;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = getCrossAxisCount(screenWidth);

    // Layar ponsel (< 600 dp): Tampilan 1 kolom vertikal standar
    if (crossAxisCount == 1) {
      return SliverList.separated(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        separatorBuilder: (context, index) => SizedBox(height: mainAxisSpacing),
      );
    }

    // Layar tablet / lebar (>= 600 dp): Tampilan Grid responsif
    final rowCount = (itemCount / crossAxisCount).ceil();

    return SliverList.separated(
      itemCount: rowCount,
      separatorBuilder: (context, index) => SizedBox(height: mainAxisSpacing),
      itemBuilder: (context, rowIndex) {
        final startIndex = rowIndex * crossAxisCount;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int col = 0; col < crossAxisCount; col++) ...[
              if (col > 0) SizedBox(width: crossAxisSpacing),
              Expanded(
                child: startIndex + col < itemCount
                    ? itemBuilder(context, startIndex + col)
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        );
      },
    );
  }
}
