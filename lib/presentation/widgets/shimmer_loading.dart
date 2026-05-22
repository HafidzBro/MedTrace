import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final int itemCount;
  final ShimmerType type;

  const ShimmerLoading({
    this.itemCount = 5,
    this.type = ShimmerType.list,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: switch (type) {
        ShimmerType.list => _buildList(),
        ShimmerType.card => _buildCard(),
        ShimmerType.dashboard => _buildDashboard(),
      },
    );
  }

  Widget _buildList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => _ShimmerListItem(),
    );
  }

  Widget _buildCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(itemCount, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(height: 72, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          )),
        ],
      ),
    );
  }
}

class _ShimmerListItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 48, height: 48, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 14, width: double.infinity, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 10, width: 120, color: Colors.white),
            ],
          ),
        ),
      ],
    );
  }
}

enum ShimmerType { list, card, dashboard }
