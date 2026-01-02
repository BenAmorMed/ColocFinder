import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';
import 'package:intl/intl.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.uid ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Requests'),
              Tab(text: 'Received'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookingsList(isGuest: true, userId: userId),
            _BookingsList(isGuest: false, userId: userId),
          ],
        ),
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  final bool isGuest;
  final String userId;

  const _BookingsList({required this.isGuest, required this.userId});

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.read<BookingProvider>();
    final stream = isGuest 
        ? bookingProvider.streamMyRequests(userId)
        : bookingProvider.streamReceivedRequests(userId);

    return StreamBuilder<List<BookingModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return EmptyState(
            icon: Icons.bookmark_border_rounded,
            title: isGuest ? 'No requests sent' : 'No requests received',
            subtitle: isGuest 
                ? 'Your room requests will appear here.'
                : 'Requests from potential roommates will show up here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _BookingCard(booking: booking, isGuest: isGuest);
          },
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isGuest;

  const _BookingCard({required this.booking, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.listingTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isGuest ? 'Host: ${booking.ownerName}' : 'From: ${booking.requesterName}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(booking.status),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _detailItem('Move-in', DateFormat('MMM dd, yyyy').format(booking.moveInDate)),
                _detailItem('Duration', '${booking.durationMonths} months'),
                _detailItem('Total', '${booking.totalPrice.toInt()} TND'),
              ],
            ),
            if (!isGuest && booking.status == BookingStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(context, BookingStatus.rejected),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(context, BookingStatus.accepted),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    Color color = Colors.grey;
    String text = 'Unknown';

    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case BookingStatus.accepted:
        color = Colors.green;
        text = 'Accepted';
        break;
      case BookingStatus.rejected:
        color = Colors.red;
        text = 'Rejected';
        break;
      case BookingStatus.cancelled:
        color = Colors.grey;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  void _updateStatus(BuildContext context, BookingStatus status) {
    context.read<BookingProvider>().updateBookingStatus(booking.id, status);
  }
}
