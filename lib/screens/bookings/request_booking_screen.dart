import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/listing_model.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../utils/helpers.dart';

class RequestBookingScreen extends StatefulWidget {
  final ListingModel listing;

  const RequestBookingScreen({
    super.key,
    required this.listing,
  });

  @override
  State<RequestBookingScreen> createState() => _RequestBookingScreenState();
}

class _RequestBookingScreenState extends State<RequestBookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  int _durationMonths = 1;
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitRequest() async {
    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    final booking = BookingModel(
      id: '', // Will be set in Firestore
      listingId: widget.listing.id,
      listingTitle: widget.listing.title,
      listingImage: widget.listing.images.isNotEmpty ? widget.listing.images.first : '',
      requesterId: user.id,
      requesterName: user.name,
      requesterPhoto: user.photoUrl,
      ownerId: widget.listing.userId,
      ownerName: widget.listing.userName ?? 'Host',
      moveInDate: _selectedDate,
      durationMonths: _durationMonths,
      totalPrice: widget.listing.price * _durationMonths,
      message: _messageController.text.trim(),
    );

    final success = await context.read<BookingProvider>().createBooking(booking);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Helpers.showSnackBar(context, 'Booking request sent successfully!');
        Navigator.pop(context);
      } else {
        Helpers.showSnackBar(context, 'Failed to send request. Try again.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Booking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Listing Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.network(
                        widget.listing.images.isNotEmpty ? widget.listing.images.first : '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.home_work),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.listing.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('${widget.listing.price.toInt()} TND / month', style: const TextStyle(color: AppTheme.primaryColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Date Picker
            const Text('When do you want to move in?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Text(DateFormat('MMMM dd, yyyy').format(_selectedDate)),
                    const Spacer(),
                    const Text('Change', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Duration
            const Text('Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                _durationButton(1),
                _durationButton(3),
                _durationButton(6),
                _durationButton(12),
              ],
            ),
            const SizedBox(height: 32),

            // Message
            const Text('Introduce yourself (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _messageController,
              label: 'Message',
              hintText: 'I am a student at ENIT, looking for a quiet place...',
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            // Price Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Price Estimate', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${(widget.listing.price * _durationMonths).toInt()} TND',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            CustomButton(
              text: 'Send Request',
              onPressed: _submitRequest,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }

  Widget _durationButton(int months) {
    final isSelected = _durationMonths == months;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: () => setState(() => _durationMonths = months),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$months m',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
