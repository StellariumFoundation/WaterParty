import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

class CreatePartyScreen extends StatelessWidget {
  const CreatePartyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Host an\nExperience", style: GoogleFonts.playfairDisplay(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 30),
              _label("The Vibe"),
              _glassTextField("e.g. Midnight Jazz & Cocktails", Icons.music_note),
              const SizedBox(height: 20),
              _label("Guest Limit"),
              Row(children: [_slotChip("3", true), const SizedBox(width: 10), _slotChip("5", false), const SizedBox(width: 10), _slotChip("∞", false)]),
              const SizedBox(height: 20),
              _label("Rotation Fund (Entry Pool)"),
              _glassTextField("\$20.00", Icons.attach_money),
              const SizedBox(height: 40),
              _buildMintButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 16)));
  
  Widget _glassTextField(String hint, IconData icon) {
    return WaterGlass(
      height: 60, borderRadius: 16,
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(prefixIcon: Icon(icon, color: Colors.white54), hintText: hint, hintStyle: const TextStyle(color: Colors.white30), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
      ),
    );
  }

  Widget _slotChip(String label, bool selected) {
    return SizedBox(width: 80, child: WaterGlass(height: 50, borderRadius: 15, border: selected ? 2 : 1, child: Center(child: Text(label, style: TextStyle(color: selected ? AppColors.gold : Colors.white, fontWeight: FontWeight.bold)))));
  }

  Widget _buildMintButton() {
    return Container(
      width: double.infinity, height: 60,
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF7C3AED)]), borderRadius: BorderRadius.circular(20)),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        onPressed: () {},
        child: const Text("Mint Party Card", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}