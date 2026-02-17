import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

class CreatePartyScreen extends StatefulWidget {
  const CreatePartyScreen({super.key});

  @override
  State<CreatePartyScreen> createState() => _CreatePartyScreenState();
}

class _CreatePartyScreenState extends State<CreatePartyScreen> {
  // Logic states matching the Go Struct
  bool autoLock = true;
  double maxCapacity = 10;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 22, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header: Replaced "Mint" with "Create" ---
              Text("Create a\nNew Party", 
                style: GoogleFonts.playfairDisplay(fontSize: 42, fontWeight: FontWeight.bold, height: 1.1)),
              const SizedBox(height: 10),
              const Text("Host a gathering and curate your crowd.", 
                style: TextStyle(color: AppColors.textCyan, letterSpacing: 1.2, fontWeight: FontWeight.w500)),
              
              const SizedBox(height: 40),

              // --- Section 1: Core Identity ---
              _sectionHeader("THE VIBE", AppColors.textPink),
              _glassTextField("Event Title", "e.g. Saturday Rooftop Sessions", Icons.celebration),
              const SizedBox(height: 15),
              _glassTextField("Description", "What's the plan? Set the tone for your guests.", Icons.notes, maxLines: 3),
              
              const SizedBox(height: 30),

              // --- Section 2: Visuals ---
              _sectionHeader("EVENT PHOTOS", AppColors.textCyan),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _photoPickerBox(true), // Add button
                    _photoPickerBox(false), // Placeholder
                    _photoPickerBox(false),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- Section 3: Logistics ---
              _sectionHeader("TIME & PLACE", Colors.white),
              Row(
                children: [
                  Expanded(child: _glassActionTile("Date", "${selectedDate.day}/${selectedDate.month}", Icons.calendar_today)),
                  const SizedBox(width: 15),
                  Expanded(child: _glassActionTile("Start Time", selectedTime.format(context), Icons.access_time)),
                ],
              ),
              const SizedBox(height: 15),
              _glassTextField("City", "Which city is this in?", Icons.location_city),
              const SizedBox(height: 15),
              _glassTextField("Secret Address", "This stays hidden until you accept a guest.", Icons.lock_outline),

              const SizedBox(height: 30),

              // --- Section 4: Guest List Mechanics ---
              _sectionHeader("GUEST LIST & CAPACITY", AppColors.gold),
              WaterGlass(
                height: 140,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Guest Limit", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("${maxCapacity.toInt()} People", style: const TextStyle(color: AppColors.gold)),
                        ],
                      ),
                      Slider(
                        value: maxCapacity,
                        min: 2, max: 100,
                        activeColor: AppColors.gold,
                        onChanged: (v) => setState(() => maxCapacity = v),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Close invite when full", style: TextStyle(fontSize: 14)),
                          Switch(
                            value: autoLock,
                            activeColor: AppColors.textCyan,
                            onChanged: (v) => setState(() => autoLock = v),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- Section 5: Curation ---
              _sectionHeader("CURATION TAGS", AppColors.textPink),
              _label("Vibe Style"),
              Wrap(
                spacing: 10,
                children: [
                  _vibeChip("#Chill", true),
                  _vibeChip("#Dance", false),
                  _vibeChip("#Networking", false),
                  _vibeChip("#DinnerParty", true),
                ],
              ),
              const SizedBox(height: 15),
              _glassTextField("Music Genre", "e.g. House, Lo-fi, 80s", Icons.music_note),

              const SizedBox(height: 30),

              // --- Section 6: Financials: Replaced "Pool" terminology with "Fund" ---
              _sectionHeader("PARTY FUND (CHIP-IN)", AppColors.textCyan),
              _glassTextField("Group Goal for Supplies (\$)", "0.00", Icons.shopping_basket, keyboardType: TextInputType.number),
              const Text("Guests contribute this amount to help with drinks/food.", 
                style: TextStyle(color: Colors.white38, fontSize: 12)),

              const SizedBox(height: 50),

              // --- Final Action: Celebrate ---
              _buildCreateButton(),
              const SizedBox(height: 100), 
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(height: 1, width: 30, color: color.withOpacity(0.3)),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)));

  Widget _glassTextField(String label, String hint, IconData icon, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        WaterGlass(
          height: maxLines == 1 ? 60 : 100,
          borderRadius: 16,
          child: TextField(
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white38, size: 20),
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassActionTile(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        WaterGlass(
          height: 60,
          borderRadius: 16,
          child: Row(
            children: [
              const SizedBox(width: 15),
              Icon(icon, color: AppColors.textCyan, size: 18),
              const SizedBox(width: 12),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _photoPickerBox(bool isAdd) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: WaterGlass(
        height: 100,
        borderRadius: 20,
        child: Icon(isAdd ? Icons.add_a_photo : Icons.image, color: isAdd ? AppColors.textPink : Colors.white10),
      ),
    );
  }

  Widget _vibeChip(String label, bool active) {
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (v) {},
      selectedColor: AppColors.textPink.withOpacity(0.3),
      backgroundColor: Colors.white.withOpacity(0.05),
      labelStyle: TextStyle(color: active ? AppColors.textPink : Colors.white38, fontSize: 12),
      side: BorderSide(color: active ? AppColors.textPink : Colors.transparent),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity, height: 65,
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: AppColors.textCyan.withOpacity(0.3), blurRadius: 20)],
        gradient: const LinearGradient(colors: [AppColors.textCyan, AppColors.electricPurple]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        onPressed: () {
          // Logic to save the gathering
        },
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send, color: Colors.black, size: 20),
            SizedBox(width: 10),
            Text("CREATE PARTY", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}