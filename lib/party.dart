import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'theme.dart';
import 'providers.dart';
import 'models.dart';
import 'websocket.dart';
import 'constants.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';

class CreatePartyScreen extends ConsumerStatefulWidget {
  const CreatePartyScreen({super.key});

  @override
  ConsumerState<CreatePartyScreen> createState() => _CreatePartyScreenState();
}

class _CreatePartyScreenState extends ConsumerState<CreatePartyScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _poolAmountController = TextEditingController();
  final _ruleController = TextEditingController();
  final _partyTypeController = TextEditingController();

  double _capacity = 10;
  bool _autoLock = true;
  bool _hasPool = false;
  double? _geoLat;
  double? _geoLon;
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 22, minute: 0);
  
  final List<String> _selectedTags = [];
  final List<String> _availableTags = ["HOUSE PARTY", "RAVE", "ROOFTOP", "DINNER", "ART", "POOL PARTY"];
  
  final List<String> _rules = [];
  String _selectedMood = "CHILL";

  List<String> _partyPhotos = [];
  bool _isUploading = false;
  bool _isGettingLocation = false;

  Future<void> _useMyLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions are denied';
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _geoLat = position.latitude;
        _geoLon = position.longitude;
        _addressController.text = "MY CURRENT LOCATION";
        _cityController.text = "DETECTED ON PUBLISH";
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _openMapPicker() async {
    LatLng initial = LatLng(_geoLat ?? 0, _geoLon ?? 0);
    if (_geoLat == null || _geoLon == null) {
      // Default to current position if possible
      try {
        final pos = await Geolocator.getCurrentPosition();
        initial = LatLng(pos.latitude, pos.longitude);
      } catch (_) {}
    }

    final LatLng? picked = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(initialLocation: initial),
      ),
    );

    if (picked != null) {
      setState(() {
        _geoLat = picked.latitude;
        _geoLon = picked.longitude;
        _addressController.text = "PINNED ON MAP";
        _cityController.text = "DETECTED ON PUBLISH";
      });
    }
  }

  Future<void> _pickImage() async {
    if (_partyPhotos.length >= 16) {
      _showError("Maximum 16 photos allowed");
      return;
    }
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await image.readAsBytes();
        final hash = await ref.read(authProvider.notifier).uploadImage(bytes, "image/jpeg");
        setState(() {
          _partyPhotos.add(hash);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  void _handleCreateParty() {
    final user = ref.read(authProvider).value;
    if (user == null) return;

    if (_titleController.text.isEmpty) {
      _showError("Title is required");
      return;
    }
    if (_descController.text.isEmpty) {
      _showError("Description is required");
      return;
    }
    if (_cityController.text.isEmpty) {
      _showError("City is required");
      return;
    }
    if (_addressController.text.isEmpty) {
      _showError("Address is required");
      return;
    }
    if (_partyPhotos.isEmpty) {
      _showError("At least one photo is required");
      return;
    }

    final String partyId = const Uuid().v4();
    final DateTime startDateTime = DateTime(
      _date.year, _date.month, _date.day, _time.hour, _time.minute
    );

    Crowdfunding? pool;
    if (_hasPool && _poolAmountController.text.isNotEmpty) {
      pool = Crowdfunding(
        id: const Uuid().v4(),
        partyId: partyId,
        targetAmount: double.tryParse(_poolAmountController.text) ?? 0.0,
        currentAmount: 0.0,
        currency: "USD",
        contributors: [],
        isFunded: false,
      );
    }

    // Combine manual tags and text input
    final List<String> finalTags = List.from(_selectedTags);
    if (_partyTypeController.text.isNotEmpty) {
      finalTags.add(_partyTypeController.text.toUpperCase());
    }

    final newParty = Party(
      id: partyId,
      hostId: user.id,
      title: _titleController.text.toUpperCase(),
      description: _descController.text,
      partyPhotos: _partyPhotos, 
      startTime: startDateTime,
      endTime: startDateTime.add(Duration(hours: _durationHours.toInt())),
      status: PartyStatus.OPEN,
      isLocationRevealed: false,
      address: _addressController.text,
      city: _cityController.text,
      geoLat: _geoLat ?? 0.0,
      geoLon: _geoLon ?? 0.0,
      maxCapacity: _capacity.toInt(),
      currentGuestCount: 0,
      autoLockOnFull: _autoLock,
      vibeTags: finalTags,
      rules: _rules,
      rotationPool: pool,
      chatRoomId: const Uuid().v4(),
    );

    ref.read(socketServiceProvider).sendMessage('CREATE_PARTY', newParty.toMap());
    ref.read(navIndexProvider.notifier).setIndex(0);
  }

  void _showError(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  double _durationHours = 6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _sectionHeader("DETAILS"),
              WaterGlass(
                height: 180,
                borderRadius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _compactInput(_titleController, "PARTY TITLE (REQUIRED)", FontAwesomeIcons.bolt),
                      const Divider(color: Colors.white10, height: 30),
                      Expanded(child: _compactInput(_descController, "DESCRIPTION (REQUIRED)", Icons.notes, maxLines: 3)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              _buildPhotoGrid(),
              const SizedBox(height: 25),
              _sectionHeader("LOGISTICS"),
              Row(
                children: [
                  Expanded(child: _actionTile(FontAwesomeIcons.calendarDay, "${_date.day}/${_date.month}", _pickDate)),
                  const SizedBox(width: 15),
                  Expanded(child: _actionTile(FontAwesomeIcons.clock, _time.format(context), _pickTime)),
                ],
              ),
              const SizedBox(height: 15),
              _buildDurationSlider(),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _inputField(_cityController, "CITY (REQUIRED)", FontAwesomeIcons.locationDot)),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _openMapPicker,
                    child: WaterGlass(
                      width: 65, height: 65,
                      borderRadius: 15,
                      child: const Icon(FontAwesomeIcons.mapLocationDot, color: AppColors.textCyan),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _inputField(_addressController, "FULL ADDRESS (HIDDEN)", FontAwesomeIcons.mapPin)),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isGettingLocation ? null : _useMyLocation,
                    child: WaterGlass(
                      width: 65, height: 65,
                      borderRadius: 15,
                      child: _isGettingLocation 
                        ? const CircularProgressIndicator(color: AppColors.textCyan, strokeWidth: 2)
                        : const Icon(Icons.my_location, color: AppColors.textCyan),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              _sectionHeader("ATMOSPHERE"),
              _buildVibeExplainer(),
              const SizedBox(height: 15),
              _chipSelect("KIND OF PARTY", _availableTags, _selectedTags),
              const SizedBox(height: 15),
              _inputField(_partyTypeController, "OR DESCRIBE THE TYPE...", Icons.edit_note),
              const SizedBox(height: 15),
              _buildMoodSelector(),
              const SizedBox(height: 25),
              _sectionHeader("BASIC RULES"),
              _buildRuleInput(),
              const SizedBox(height: 25),
              _sectionHeader("CAPACITY & FUNDING"),
              _buildCapacitySlider(),
              const SizedBox(height: 15),
              _buildPoolToggle(),
              const SizedBox(height: 50),
              _buildIgniteButton(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVibeExplainer() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.textCyan.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.textCyan.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.textCyan, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              "Define the nature of your event. Is it a cozy house party, a wild rooftop rave, or a sophisticated dinner?",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector() {
    final moods = ["CHILL", "WILD", "CLASSY", "DARK", "VIBRANT"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("MOOD",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                )),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: moods.map((m) {
              final isSelected = _selectedMood == m;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = m),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.textCyan.withOpacity(0.1) : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? AppColors.textCyan : Colors.white10),
                  ),
                  child: Text(m, style: TextStyle(color: isSelected ? Colors.white : Colors.white24, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSlider() {
    return WaterGlass(
      height: 70,
      borderRadius: 15,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            const Icon(FontAwesomeIcons.hourglassHalf, color: AppColors.textCyan, size: 16),
            const SizedBox(width: 15),
            Text("DURATION: ${_durationHours.toInt()}H", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            Expanded(
              child: Slider(
                value: _durationHours,
                min: 1,
                max: 24,
                activeColor: AppColors.textCyan,
                onChanged: (v) => setState(() => _durationHours = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacitySlider() {
    return WaterGlass(
      height: 100,
      borderRadius: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("GUEST LIMIT: ${_capacity.toInt()}",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
          Slider(
            value: _capacity,
            min: 2,
            max: 1000,
            activeColor: AppColors.textCyan,
            inactiveColor: Colors.white10,
            onChanged: (v) => setState(() => _capacity = v),
          ),
          Text(_autoLock ? "AUTO-LOCK WHEN FULL" : "MANUAL LOCKING",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _autoLock ? AppColors.textCyan : Colors.white38,
                    fontSize: 9,
                  )),
        ],
      ),
    );
  }

  Widget _buildPoolToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasPool)
          Padding(
            padding: const EdgeInsets.only(left: 5, bottom: 10),
            child: Text(
              "HOW MUCH DO YOU NEED IN ADDITIONAL FUNDING?",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        GestureDetector(
          onTap: () => setState(() => _hasPool = !_hasPool),
          child: WaterGlass(
            height: 80,
            borderRadius: 20,
            borderColor: _hasPool ? AppColors.gold : Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FontAwesomeIcons.wallet,
                    color: _hasPool ? AppColors.gold : Colors.white24, size: 20),
                const SizedBox(width: 15),
                if (_hasPool)
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _poolAmountController,
                      keyboardType: TextInputType.number,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                      decoration: const InputDecoration(
                          hintText: "GOAL \$",
                          hintStyle: TextStyle(color: Colors.white10),
                          border: InputBorder.none),
                    ),
                  )
                else
                  Text("ENABLE CROWD-FUND WITH WALLET",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white24,
                            fontWeight: FontWeight.bold,
                          )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIgniteButton() {
    return GestureDetector(
      onTap: _handleCreateParty,
      child: Container(
        height: 65,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
              colors: [AppColors.textCyan, AppColors.electricPurple]),
          boxShadow: [
            BoxShadow(
                color: AppColors.textCyan.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        alignment: Alignment.center,
        child: Text("PUBLISH PARTY",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  fontSize: 16,
                )),
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime(2030));
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Widget _buildHeader() {
    return Text("HOST\nA PARTY",
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: 2,
            ));
  }

  Widget _buildPhotoGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionHeader("GALLERY"),
            Text("${_partyPhotos.length}/16", 
              style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 16, // Maximum slots
          itemBuilder: (context, index) {
            if (index < _partyPhotos.length) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      AppConstants.assetUrl(_partyPhotos[index]),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () => setState(() => _partyPhotos.removeAt(index)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 12),
                      ),
                    ),
                  ),
                ],
              );
            } else if (index == _partyPhotos.length || index < 6) {
              // Show add button for the next slot OR for the first 6 slots if they are empty
              bool isNextSlot = index == _partyPhotos.length;
              return GestureDetector(
                onTap: isNextSlot ? (_isUploading ? null : _pickImage) : null,
                child: WaterGlass(
                  borderRadius: 15,
                  child: (isNextSlot && _isUploading)
                    ? const Center(child: CircularProgressIndicator(color: AppColors.textCyan, strokeWidth: 2))
                    : Icon(Icons.add_a_photo, 
                        color: isNextSlot ? Colors.white24 : Colors.white.withOpacity(0.02)),
                ),
              );
            }
            return const SizedBox.shrink(); // Hide the remaining slots until needed
          },
        ),
        if (_partyPhotos.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text("ADD AT LEAST ONE PHOTO TO DEFINE THE VIBE",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white10, fontSize: 9)),
          ),
      ],
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(left: 5, bottom: 12),
        child: Text(text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPink,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                )),
      );

  Widget _compactInput(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white10,
              fontSize: 14,
            ),
        border: InputBorder.none,
        prefixIcon: Icon(icon, color: AppColors.textCyan, size: 18),
        isDense: true,
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon) {
    return WaterGlass(
      height: 65,
      borderRadius: 15,
      child: _compactInput(ctrl, hint, icon),
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: WaterGlass(
        height: 65,
        borderRadius: 15,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.textCyan),
            const SizedBox(width: 10),
            Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
          ],
        ),
      ),
    );
  }

  Widget _chipSelect(String title, List<String> options, List<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                )),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selected.contains(opt);
            return GestureDetector(
              onTap: () => setState(
                  () => isSelected ? selected.remove(opt) : selected.add(opt)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.textCyan.withOpacity(0.1)
                      : Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isSelected ? AppColors.textCyan : Colors.white10),
                ),
                child: Text(opt,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected ? Colors.white : Colors.white24,
                          fontWeight: FontWeight.bold,
                        )),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRuleInput() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _inputField(_ruleController, "ADD PROTOCOL...",
                    FontAwesomeIcons.shieldHalved)),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                if (_ruleController.text.isNotEmpty) {
                  setState(() {
                    _rules.add(_ruleController.text.toUpperCase());
                    _ruleController.clear();
                  });
                }
              },
              child: WaterGlass(
                  width: 65,
                  height: 65,
                  borderRadius: 15,
                  child: const Icon(Icons.add, color: AppColors.textCyan)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 5,
          children: _rules
              .map((r) => Chip(
                    label: Text(r,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            )),
                    backgroundColor: Colors.white10,
                    onDeleted: () => setState(() => _rules.remove(r)),
                  ))
              .toList(),
        )
      ],
    );
  }
}

class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;
  const MapPickerScreen({super.key, required this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("PINPOINT LOCATION", 
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textCyan, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 2
          )
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedLocation),
            child: const Text("CONFIRM", style: TextStyle(color: AppColors.textCyan, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _selectedLocation,
          initialZoom: 15,
          onTap: (tapPosition, point) => setState(() => _selectedLocation = point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.waterparty.app',
            tileBuilder: (context, tileWidget, tile) {
              return ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  -0.9, 0, 0, 0, 255,
                  0, -0.9, 0, 0, 255,
                  0, 0, -0.9, 0, 255,
                  0, 0, 0, 1, 0,
                ]),
                child: tileWidget,
              );
            },
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedLocation,
                width: 80,
                height: 80,
                child: const Icon(Icons.location_on, color: AppColors.textPink, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
