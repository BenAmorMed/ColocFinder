import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/listing_provider.dart';
import 'common/custom_button.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedRoomType;
  double _minPrice = AppConstants.minPrice;
  double _maxPrice = AppConstants.maxPrice;
  SortOption _selectedSort = SortOption.newest;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ListingProvider>();
    _selectedRoomType = provider.selectedRoomType;
    _minPrice = provider.minPrice ?? AppConstants.minPrice;
    _maxPrice = provider.maxPrice ?? AppConstants.maxPrice;
    _selectedSort = provider.selectedSort;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  context.read<ListingProvider>().clearFilters();
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          const Text('Room Type', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: AppConstants.roomTypes.map((type) {
              final isSelected = _selectedRoomType == type;
              return ChoiceChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedRoomType = selected ? type : null;
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildSortChip('Newest', SortOption.newest),
              _buildSortChip('Price: Low to High', SortOption.priceLowToHigh),
              _buildSortChip('Price: High to Low', SortOption.priceHighToLow),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Price Range', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${_minPrice.toInt()} - ${_maxPrice.toInt()} TND'),
            ],
          ),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: AppConstants.minPrice,
            max: AppConstants.maxPrice,
            divisions: 50,
            onChanged: (values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
          
          const SizedBox(height: 32),
          
          CustomButton(
            text: 'Apply Filters',
            onPressed: () {
              final provider = context.read<ListingProvider>();
              provider.setRoomTypeFilter(_selectedRoomType);
              provider.setPriceFilter(_minPrice, _maxPrice);
              provider.setSortOption(_selectedSort);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, SortOption option) {
    final isSelected = _selectedSort == option;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedSort = option;
          });
        }
      },
    );
  }
}
