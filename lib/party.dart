import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import 'theme.dart';
import 'providers.dart';
import 'models.dart';
import 'websocket.dart';

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

  double _capacity = 10;
  bool _autoLock = true;
  bool _hasPool = false;
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 22, minute: 0);
  
  final List<String> _selectedTags = [];
  final List<String> _availableTags = ["#CHILL", "#RAVE", "#NETWORK", "#DINNER", "#ART", "#TECH"];
  
  final List<String> _selectedMusic = [];
  final List<String> _availableMusic = ["TECHNO", "HOUSE", "HIPHOP", "JAZZ", "ROCK", "AMBIENT"];
  
  final List<String> _rules = [];
  String _selectedMood = "CHILL";

  void _handleCreateParty() {
    final user = ref.read(authProvider);
    if (user == null) return;

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

    final newParty = Party(
      id: partyId,
      hostId: user.id,
      title: _titleController.text.isEmpty ? "UNTITLED VIBE" : _titleController.text.toUpperCase(),
      description: _descController.text,
      partyPhotos: ["https://images.unsplash.com/photo-1516450360452-9312f5e86fc7"], 
      startTime: startDateTime,
      endTime: startDateTime.add(const Duration(hours: 6)),
      status: PartyStatus.OPEN,
      isLocationRevealed: false,
      address: _addressController.text,
      city: _cityController.text,
      geoLat: 0.0,
      geoLon: 0.0,
      maxCapacity: _capacity.toInt(),
      currentGuestCount: 0,
      slotRequirements: {},
      autoLockOnFull: _autoLock,
      vibeTags: _selectedTags,
      musicGenres: _selectedMusic,
      mood: _selectedMood,
      rules: _rules,
      rotationPool: pool,
      chatRoomId: const Uuid().v4(),
    );

    ref.read(socketServiceProvider).sendMessage('CREATE_PARTY', newParty.toMap());
    ref.read(navIndexProvider.notifier).setIndex(0);
  }

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
              _sectionHeader("ESSENCE"),
              WaterGlass(
                height: 180,
                borderRadius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _compactInput(_titleController, "EVENT TITLE", FontAwesomeIcons.bolt),
                      const Divider(color: Colors.white10, height: 30),
                      Expanded(child: _compactInput(_descController, "SET THE TONE...", Icons.notes, maxLines: 3)),
                    ],
                  ),
                ),
              ),
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
              _inputField(_cityController, "CITY", FontAwesomeIcons.locationDot),
              const SizedBox(height: 15),
              _inputField(_addressController, "ADDRESS (HIDDEN UNTIL LOCK)", FontAwesomeIcons.mapPin),
              const SizedBox(height: 25),
              _sectionHeader("VIBE & SOUND"),
              _chipSelect("CURATION TAGS", _availableTags, _selectedTags),
              const SizedBox(height: 15),
              _chipSelect("SONIC FREQUENCIES", _availableMusic, _selectedMusic),
              const SizedBox(height: 25),
              _sectionHeader("PROTOCOL (RULES)"),
              _buildRuleInput(),
              const SizedBox(height: 25),
              _sectionHeader("MECHANICS"),
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("HOST\nA VIBE",
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  letterSpacing: 2,
                )),
        GestureDetector(
          onTap: () {},
          child: WaterGlass(
              width: 70,
              height: 70,
              borderRadius: 20,
              child: const Icon(FontAwesomeIcons.camera,
                  color: Colors.white24, size: 24)),
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

  Widget _buildCapacitySlider() {
    return WaterGlass(
      height: 100,
      borderRadius: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("MAX CAPACITY: ${_capacity.toInt()}",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
          Slider(
            value: _capacity,
            min: 2,
            max: 200,
            activeColor: AppColors.textCyan,
            inactiveColor: Colors.white10,
            onChanged: (v) => setState(() => _capacity = v),
          ),
          Text(_autoLock ? "AUTO-LOCK ON FULL" : "MANUAL LOCK",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _autoLock ? AppColors.textCyan : Colors.white38,
                    fontSize: 9,
                  )),
        ],
      ),
    );
  }

  Widget _buildPoolToggle() {
    return GestureDetector(
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
                      hintText: "\$0",
                      hintStyle: TextStyle(color: Colors.white10),
                      border: InputBorder.none),
                ),
              )
            else
              Text("ENABLE ROTATION POOL",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white24,
                        fontWeight: FontWeight.bold,
                      )),
          ],
        ),
      ),
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
        child: Text("IGNITE VIBE",
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
}
