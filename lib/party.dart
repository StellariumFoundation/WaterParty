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
              // --- Header ---
              Text("Mint an\nExperience", 
                style: GoogleFonts.playfairDisplay(fontSize: 42, fontWeight: FontWeight.bold, height: 1.1)),
              const SizedBox(height: 10),
              const Text("Operationalize the social liquidity.", 
                style: TextStyle(color: AppColors.textCyan, letterSpacing: 1.2, fontWeight: FontWeight.w500)),
              
              const SizedBox(height: 40),

              // --- Section 1: Core Identity ---
              _sectionHeader("IDENTITY", AppColors.textPink),
              _glassTextField("Title", "Give the vibe a name...", Icons.title),
              const SizedBox(height: 15),
              _glassTextField("Description", "What happens here?", Icons.notes, maxLines: 3),
              
              const SizedBox(height: 30),

              // --- Section 2: Visuals ---
              _sectionHeader("PARTY PHOTOS", AppColors.textCyan),
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

              // --- Section 3: Scheduling & Location ---
              _sectionHeader("LOGISTICS", Colors.white),
              Row(
                children: [
                  Expanded(child: _glassActionTile("Date", "${selectedDate.day}/${selectedDate.month}", Icons.calendar_today)),
                  const SizedBox(width: 15),
                  Expanded(child: _glassActionTile("Start", selectedTime.format(context), Icons.access_time)),
                ],
              ),
              const SizedBox(height: 15),
              _glassTextField("City", "e.g. San Francisco", Icons.location_city),
              const SizedBox(height: 15),
              _glassTextField("Secret Address", "Revealed only to matched guests", Icons.lock_outline),

              const SizedBox(height: 30),

              // --- Section 4: Slot Mechanics ---
              _sectionHeader("SLOT PROTOCOL", AppColors.gold),
              WaterGlass(
                height: 140,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Max Capacity", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("${maxCapacity.toInt()} Guests", style: const TextStyle(color: AppColors.gold)),
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
                          const Text("Auto-Lock on Full", style: TextStyle(fontSize: 14)),
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

              // --- Section 5: The Vibe ---
              _sectionHeader("VIBE & CURATION", AppColors.textPink),
              _label("Vibe Tags"),
              Wrap(
                spacing: 10,
                children: [
                  _vibeChip("#Chill", true),
                  _vibeChip("#Rage", false),
                  _vibeChip("#DeepTalks", false),
                  _vibeChip("#Networking", true),
                ],
              ),
              const SizedBox(height: 15),
              _glassTextField("Music Genres", "Techno, Jazz, Hip-Hop...", Icons.music_note),

              const SizedBox(height: 30),

              // --- Section 6: Financials ---
              _sectionHeader("ROTATION POOL", AppColors.textCyan),
              _glassTextField("Pool Goal (\$)", "0.00", Icons.account_balance_wallet, keyboardType: TextInputType.number),
              const Text("Guests will pledge this amount to join.", 
                style: TextStyle(color: Colors.white38, fontSize: 12)),

              const SizedBox(height: 50),

              // --- Final Action ---
              _buildMintButton(),
              const SizedBox(height: 100), // Bottom padding
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

  Widget _buildMintButton() {
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
          // Execution: This would serialize the form into the 'Party' struct
        },
        child: const Text("PUBLISH PARTY CARD", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
    );
  }
}