import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:agrozemex/core/theme/theme.dart';

class CropFilterSheet extends StatefulWidget {
  final List<String> cropTypes;
  final String? initialCropType;
  final String initialVillage;
  final bool initialUseLocation;
  final double initialMaxDistance;
  final double initialMinPrice;
  final double initialMaxPrice;
  final Position? userPosition;
  final Future<Position?> Function() onGetUserLocation;
  final void Function({
    required String? cropType,
    required String village,
    required bool useLocation,
    required double maxDistance,
    required double minPrice,
    required double maxPrice,
  })
  onApply;
  final VoidCallback onReset;

  const CropFilterSheet({
    super.key,
    required this.cropTypes,
    required this.initialCropType,
    required this.initialVillage,
    required this.initialUseLocation,
    required this.initialMaxDistance,
    required this.initialMinPrice,
    required this.initialMaxPrice,
    required this.userPosition,
    required this.onGetUserLocation,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<CropFilterSheet> createState() => _CropFilterSheetState();
}

class _CropFilterSheetState extends State<CropFilterSheet> {
  String? _selectedCropType;
  late TextEditingController _villageController;
  late bool _useLocationFilter;
  late double _maxDistance;
  late double _minPrice;
  late double _maxPrice;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _selectedCropType = widget.initialCropType;
    _villageController = TextEditingController(text: widget.initialVillage);
    _useLocationFilter = widget.initialUseLocation;
    _maxDistance = widget.initialMaxDistance;
    _minPrice = widget.initialMinPrice.clamp(0.0, 1000000.0);
    _maxPrice = widget.initialMaxPrice.clamp(0.0, 1000000.0);
  }

  @override
  void dispose() {
    _villageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AgroZemexTokens.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AgroZemexTokens.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters', style: AgroZemexTokens.headlineMedium),
              TextButton(
                onPressed: widget.onReset,
                child: Text(
                  'Reset',
                  style: AgroZemexTokens.bodyMedium.copyWith(
                    color: AgroZemexTokens.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 30),

          DropdownButtonFormField<String>(
            initialValue: _selectedCropType,
            decoration: InputDecoration(
              labelText: 'Select Crop Type',
              border: OutlineInputBorder(
                borderRadius: AgroZemexTokens.radiusEight,
              ),
            ),
            isExpanded: true,
            items: widget.cropTypes
                .map(
                  (e) => DropdownMenuItem(
                    value: e == 'All' ? null : e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedCropType = v),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: _villageController,
            decoration: InputDecoration(
              labelText: 'Village / Location',
              border: OutlineInputBorder(
                borderRadius: AgroZemexTokens.radiusEight,
              ),
              prefixIcon: const Icon(
                Icons.location_on,
                color: AgroZemexTokens.primary,
              ),
            ),
          ),

          const SizedBox(height: 20),

          SwitchListTile(
            activeThumbColor: AgroZemexTokens.primary,
            title: Text(
              'Near Me (max ${_maxDistance.round()} km)',
              style: AgroZemexTokens.bodyLarge,
            ),
            subtitle: _isLocating ? const LinearProgressIndicator() : null,
            value: _useLocationFilter,
            onChanged: (v) async {
              setState(() {
                _useLocationFilter = v;
                if (v) _isLocating = true;
              });
              if (v && widget.userPosition == null) {
                await widget.onGetUserLocation();
              }
              if (mounted) {
                setState(() {
                  _isLocating = false;
                });
              }
            },
          ),

          if (_useLocationFilter)
            Slider(
              min: 0.0,
              max: 100.0,
              activeColor: AgroZemexTokens.primary,
              value: _maxDistance,
              label: '${_maxDistance.round()} km',
              onChanged: (v) => setState(() => _maxDistance = v),
            ),

          const SizedBox(height: 20),

          Text(
            'Price Range (₹)',
            style: AgroZemexTokens.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          RangeSlider(
            min: 0.0,
            max: 1000000.0,
            divisions: 100,
            activeColor: AgroZemexTokens.primary,
            values: RangeValues(
              _minPrice.clamp(0.0, 1000000.0),
              _maxPrice.clamp(0.0, 1000000.0),
            ),
            labels: RangeLabels(
              '₹${_minPrice.round()}',
              '₹${_maxPrice.round()}',
            ),
            onChanged: (values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AgroZemexTokens.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: AgroZemexTokens.radiusEight,
                ),
              ),
              onPressed: () {
                widget.onApply(
                  cropType: _selectedCropType,
                  village: _villageController.text.trim(),
                  useLocation: _useLocationFilter,
                  maxDistance: _maxDistance,
                  minPrice: _minPrice,
                  maxPrice: _maxPrice,
                );
              },
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
