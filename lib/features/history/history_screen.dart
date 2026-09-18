import 'package:flutter/material.dart';
import '../../shared/app_gradients.dart';
import 'models/history_ticket_model.dart';
import 'widgets/history_card_widget.dart';

/// 1:1 Strict Recreation of `#view-history` from Web Prototype/index.html
class HistoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final List<HistoryTicketModel>? historyTickets;
  final int initialTabIndex;

  const HistoryScreen({
    super.key,
    this.onBack,
    this.historyTickets,
    this.initialTabIndex = 0,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late int _selectedTabIndex;
  late final PageController _pageController;
  late List<HistoryTicketModel> _historyTickets;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _pageController = PageController(initialPage: _selectedTabIndex);
    _historyTickets = widget.historyTickets ?? HistoryTicketModel.getSampleHistory();
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.historyTickets != null) {
      _historyTickets = widget.historyTickets!;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _selectedTabIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  List<HistoryTicketModel> get _completedTickets =>
      _historyTickets.where((t) => t.status == HistoryStatus.completed).toList();

  List<HistoryTicketModel> get _expiredTickets =>
      _historyTickets.where((t) => t.status == HistoryStatus.expired).toList();

  List<HistoryTicketModel> get _refundedTickets =>
      _historyTickets.where((t) => t.status == HistoryStatus.refunded).toList();

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppGradients.pageGradient,
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Bar & Title (.history-content & .history-title)
          Padding(
            padding: EdgeInsets.fromLTRB(16, topSafe + 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trip History',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181C1A), // var(--color-on-surface)
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Animated Sliding Tab Bar (.history-tabs-container)
                _buildTabBar(),
              ],
            ),
          ),

          // 3. Slider Pager Content (.history-slider-wrapper)
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              onPageChanged: (index) {
                setState(() => _selectedTabIndex = index);
              },
              children: [
                // Slide 0: Completed Trips
                _buildSlideList(
                  key: const PageStorageKey('history_completed_list'),
                  tickets: _completedTickets,
                  emptyTitle: 'No trips in history.',
                  emptySubtitle: 'Your completed tickets will appear here.',
                  bottomSafe: bottomSafe,
                ),

                // Slide 1: Expired Trips
                _buildSlideList(
                  key: const PageStorageKey('history_expired_list'),
                  tickets: _expiredTickets,
                  emptyTitle: 'No expired trips.',
                  emptySubtitle: 'Your expired tickets will appear here.',
                  bottomSafe: bottomSafe,
                ),

                // Slide 2: Refunded Trips
                _buildSlideList(
                  key: const PageStorageKey('history_refunded_list'),
                  tickets: _refundedTickets,
                  emptyTitle: 'No refunded trips.',
                  emptySubtitle: 'Your refunded tickets will appear here.',
                  bottomSafe: bottomSafe,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F0), // var(--color-surface-low)
        borderRadius: BorderRadius.circular(9999), // var(--radius-full)
        border: Border.all(
          color: const Color(0xFF005140), // var(--color-primary)
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 3;

          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, _) {
              double currentPage = _selectedTabIndex.toDouble();
              if (_pageController.hasClients &&
                  _pageController.position.hasContentDimensions) {
                currentPage = _pageController.page ?? _selectedTabIndex.toDouble();
              }

              return Stack(
                children: [
                  // Real-time Smooth Sliding Active Indicator
                  Positioned(
                    left: (currentPage * tabWidth).clamp(0.0, constraints.maxWidth - tabWidth),
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B9175), Color(0xFF005140)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26005140),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab Buttons Row
                  Row(
                    children: [
                      _buildTabOption(
                        index: 0,
                        icon: Icons.check_circle_outline,
                        label: 'Completed',
                        currentPage: currentPage,
                      ),
                      _buildTabOption(
                        index: 1,
                        icon: Icons.history,
                        label: 'Expired',
                        currentPage: currentPage,
                      ),
                      _buildTabOption(
                        index: 2,
                        icon: Icons.currency_exchange,
                        label: 'Refunded',
                        currentPage: currentPage,
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTabOption({
    required int index,
    required IconData icon,
    required String label,
    required double currentPage,
  }) {
    final progress = (1.0 - (currentPage - index).abs()).clamp(0.0, 1.0);
    final activeColor = Color.lerp(
      const Color(0xFF3E4945),
      Colors.white,
      progress,
    )!;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabTapped(index),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: activeColor,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: activeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlideList({
    Key? key,
    required List<HistoryTicketModel> tickets,
    required String emptyTitle,
    required String emptySubtitle,
    required double bottomSafe,
  }) {
    if (tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(32, 0, 32, 96 + bottomSafe),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0x1F6E7A75),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history,
                  size: 36,
                  color: Color(0xFF6E7A75),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF181C1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                emptySubtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF3E4945),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      key: key,
      padding: EdgeInsets.fromLTRB(16, 4, 16, 96 + bottomSafe),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        return HistoryCardWidget(ticket: tickets[index]);
      },
    );
  }
}
