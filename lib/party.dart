import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'theme.dart';
import 'providers.dart';
import 'models.dart';

class CreatePartyScreen extends ConsumerStatefulWidget {
  const CreatePartyScreen({super.key});

  @override
  ConsumerState<CreatePartyScreen> createState() => _CreatePartyScreenState();
}

class _CreatePartyScreenState extends ConsumerState<CreatePartyScreen> {
  // --- Input Controllers ---
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _poolAmountController = TextEditingController();

  // --- State Variables ---
  double _capacity = 10;
  bool _autoLock = true;
  bool _hasPool = false;
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 22, minute: 0);
  
  // Vibe Selection
  final List<String> _selectedTags = [];
  final List<String> _availableTags = ["#Chill", "#Rave", "#Network", "#Dinner", "#Art", "#Tech"];
  String _selectedMood = "Chill";

  void _handleCreateParty() {
    final user = ref.read(authProvider);
    if (user == null) return;

    final String partyId = const Uuid().v4();
    final DateTime startDateTime = DateTime(
      _date.year, _date.month, _date.day, _time.hour, _time.minute
    );

    // 1. Construct Optional Crowdfunding Logic
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

    // 2. Construct The Party (Matching Go Struct)
    final newParty = Party(
      id: partyId,
      hostId: user.id,
      title: _titleController.text.isEmpty ? "Untitled Vibe" : _titleController.text,
      description: _descController.text,
      // In real app, upload image -> get string URL. Using placeholder for now.
      partyPhotos: ["https://images.unsplash.com/photo-1516450360452-9312f5e86fc7"], 
      startTime: startDateTime,
      endTime: startDateTime.add(const Duration(hours: 6)), // Default duration
      status: PartyStatus.OPEN,
      isLocationRevealed: false,
      address: _addressController.text,
      city: _cityController.text,
      geoLat: 0.0, // Should use Geocoding API
      geoLon: 0.0,
      maxCapacity: _capacity.toInt(),
      currentGuestCount: 0,
      slotRequirements: {},
      autoLockOnFull: _autoLock,
      vibeTags: _selectedTags,
      musicGenres: [], // Add UI for this if needed
      mood: _selectedMood,
      rules: [],
      rotationPool: pool,
      chatRoomId: const Uuid().v4(), // Internal generation
    );

    // 3. Send to Riverpod / WebSocket
    // ref.read(socketServiceProvider).sendMessage('CREATE_PARTY', newParty.toMap());
    ref.read(partyFeedProvider.notifier).addParty(newParty);

    // 4. Reset & Nav
    ref.read(navIndexProvider.notifier).state = 0; // Go to Feed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 25),
              
              // --- 1. CORE IDENTITY ---
              WaterGlass(
                height: 180,
                borderRadius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      _compactInput(_titleController, "Event Title", Icons.auto_awesome, isHeader: true),
                      const Divider(color: Colors.white10, height: 20),
                      Expanded(child: _compactInput(_descController, "Set the tone...", Icons.notes, maxLines: 3)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // --- 2. LOGISTICS ROW ---
              Row(
                children: [
                  Expanded(child: _compactActionTile(Icons.calendar_today, "${_date.day}/${_date.month}", () => _pickDate(context))),
                  const SizedBox(width: 10),
                  Expanded(child: _compactActionTile(Icons.access_time, _time.format(context), () => _pickTime(context))),
                  const SizedBox(width: 10),
                  Expanded(child: WaterGlass(height: 60, borderRadius: 15, child: _compactInput(_cityController, "City", Icons.location_city, hideIcon: true))),
                ],
              ),
              const SizedBox(height: 15),

              // --- 3. CURATION & VIBE ---
              WaterGlass(
                height: 130,
                borderRadius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("CURATION TAGS", style: TextStyle(color: AppColors.textCyan, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableTags.map((tag) {
                          final isSelected = _selectedTags.contains(tag);
                          return GestureDetector(
                            onTap: () => setState(() => isSelected ? _selectedTags.remove(tag) : _selectedTags.add(tag)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.textCyan.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isSelected ? AppColors.textCyan : Colors.transparent),
                              ),
                              child: Text(tag, style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 11)),
                            ),
                          );
                        }).toList(),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // --- 4. MECHANICS (Capacity & Money) ---
              Row(
                children: [
                  // Capacity Slider
                  Expanded(
                    flex: 3,
                    child: WaterGlass(
                      height: 100, borderRadius: 20,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("CAPACITY: ${_capacity.toInt()}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          Slider(
                            value: _capacity, min: 2, max: 100, 
                            activeColor: AppColors.gold, inactiveColor: Colors.white10,
                            onChanged: (v) => setState(() => _capacity = v),
                          ),
                          Text(_autoLock ? "Auto-Lock: ON" : "Auto-Lock: OFF", style: TextStyle(fontSize: 9, color: _autoLock ? AppColors.textCyan : Colors.white38)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Rotation Pool
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => setState(() => _hasPool = !_hasPool),
                      child: WaterGlass(
                        height: 100, borderRadius: 20,
                        borderColor: _hasPool ? AppColors.gold : Colors.transparent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance_wallet, color: _hasPool ? AppColors.gold : Colors.white38),
                            const SizedBox(height: 5),
                            if (_hasPool)
                              SizedBox(
                                width: 60,
                                child: TextField(
                                  controller: _poolAmountController,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(hintText: "\$0", hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none),
                                ),
                              )
                            else
                              const Text("NO POOL", style: TextStyle(fontSize: 10, color: Colors.white38))
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              _buildCreateButton(),
              const SizedBox(height: 80), // Bottom nav padding
            ],
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("HOST\nA VIBE", style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w900, height: 1.0)),
        GestureDetector(
          onTap: () {}, // Add photo logic
          child: WaterGlass(width: 60, height: 60, borderRadius: 20, child: const Icon(Icons.add_a_photo, color: Colors.white38)),
        ),
      ],
    );
  }

  Widget _compactInput(TextEditingController ctrl, String hint, IconData icon, {bool isHeader = false, int maxLines = 1, bool hideIcon = false}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: isHeader 
          ? GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white) 
          : const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white24, fontSize: isHeader ? 22 : 14),
        border: InputBorder.none,
        prefixIcon: hideIcon ? null : Icon(icon, color: isHeader ? AppColors.textPink : Colors.white38, size: 20),
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );
  }

  Widget _compactActionTile(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: WaterGlass(
        height: 60, borderRadius: 15,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.textCyan),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity, height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.textCyan, AppColors.electricPurple]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        onPressed: _handleCreateParty,
        child: const Text("IGNITE PARTY", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime(2030));
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime(BuildContext context) async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }
}