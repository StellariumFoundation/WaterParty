// party.dart
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
  // Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  double maxCapacity = 10;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 22, minute: 0);

  void _handleCreateParty() {
    final user = ref.read(authProvider);
    if (user == null) return;

    // 1. Create the Model
    final newParty = Party(
      id: const Uuid().v4(),
      title: _titleController.text.isEmpty ? "Untitled Party" : _titleController.text,
      description: _descController.text,
      hostName: user.name,
      imageUrl: "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7", // Placeholder
      date: selectedDate,
      time: selectedTime,
      capacity: maxCapacity.toInt(),
      tags: ["#New", "#Vibe"],
    );

    // 2. Add to Provider
    ref.read(partyFeedProvider.notifier).addParty(newParty);

    // 3. Navigate to Feed (Index 0)
    ref.read(navIndexProvider.notifier).state = 0;
    
    // Optional: Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Party Created!")));
  }

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
              Text("Create a\nNew Party", 
                style: GoogleFonts.playfairDisplay(fontSize: 42, fontWeight: FontWeight.bold, height: 1.1)),
              
              const SizedBox(height: 40),
              
              _glassTextField("Event Title", "e.g. Saturday Rooftop", Icons.celebration, controller: _titleController),
              const SizedBox(height: 15),
              _glassTextField("Description", "What's the plan?", Icons.notes, maxLines: 3, controller: _descController),

              const SizedBox(height: 30),
              
              // (Existing Slider code for capacity...)
              Text("Capacity: ${maxCapacity.toInt()}"),
              Slider(value: maxCapacity, min: 2, max: 100, onChanged: (v) => setState(() => maxCapacity = v), activeColor: AppColors.gold),

              const SizedBox(height: 50),
              _buildCreateButton(),
              const SizedBox(height: 100), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassTextField(String label, String hint, IconData icon, {int maxLines = 1, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: const TextStyle(color: Colors.white70))),
        WaterGlass(
          height: maxLines == 1 ? 60 : 100,
          borderRadius: 16,
          child: TextField(
            controller: controller, // Bound controller
            maxLines: maxLines,
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

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity, height: 65,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.textCyan, AppColors.electricPurple]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        onPressed: _handleCreateParty,
        child: const Text("CREATE PARTY", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}