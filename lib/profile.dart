import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Logic: Toggle between view and edit mode
  bool isEditing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),

              // --- Reputation Stats (Non-Editable) ---
              _buildReputationGrid(),
              const SizedBox(height: 30),

              // --- Photos Section ---
              _sectionLabel("VISUAL IDENTITY", AppColors.textCyan),
              _buildPhotoGallery(),
              const SizedBox(height: 30),

              // --- Personal Details ---
              _sectionLabel("CORE IDENTITY", AppColors.textPink),
              _editableField("Username", "@john_v", Icons.alternate_email),
              _editableField("Real Name", "John Victor", Icons.badge),
              _editableField("Bio", "Architect of the Vibe. Engineering human connection through the Stellarium Foundation.", Icons.short_text, maxLines: 3),
              
              const SizedBox(height: 30),

              // --- Demographics ---
              _sectionLabel("DEMOGRAPHICS", Colors.white),
              Row(
                children: [
                  Expanded(child: _editableField("Age", "28", Icons.cake)),
                  const SizedBox(width: 15),
                  Expanded(child: _editableField("Height (cm)", "185", Icons.height)),
                ],
              ),

              const SizedBox(height: 30),

              // --- Social Lubricants (Preferences) ---
              _sectionLabel("SOCIAL LUBRICANTS", AppColors.gold),
              _buildPreferenceChips("Drinking", ["Sober", "Social", "Heavy"], "Social"),
              _buildPreferenceChips("Smoking", ["No", "Social", "Yes"], "No"),
              _buildPreferenceChips("Cannabis", ["No", "Occasionally", "Yes"], "Occasionally"),

              const SizedBox(height: 30),

              // --- Professional & Education ---
              _sectionLabel("PROFESSIONAL STATUS", AppColors.textCyan),
              _editableField("Job Title", "Software Architect", Icons.work),
              _editableField("Company", "Stellarium Foundation", Icons.business),
              _editableField("School", "Stanford University", Icons.school),

              const SizedBox(height: 30),

              // --- Social Proof ---
              _sectionLabel("SOCIAL PROOF", AppColors.textPink),
              _editableField("Instagram", "@john_v_insta", Icons.camera_alt),
              _editableField("X / Twitter", "@john_v_x", Icons.close),
              _editableField("LinkedIn", "linkedin.com/in/johnv", Icons.link),

              const SizedBox(height: 30),

              // --- Financial & System ---
              _sectionLabel("SYSTEM PROTOCOL", Colors.white),
              _infoTile("Wallet Address", "0x71C...39B4", Icons.account_balance_wallet),
              _infoTile("Verification Status", "Verified Citizen", Icons.verified),

              const SizedBox(height: 50),
              _buildActionButtons(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150, height: 150,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.goldGradient),
              ),
              const CircleAvatar(
                radius: 70,
                backgroundImage: NetworkImage("https://images.unsplash.com/photo-1500648767791-00dcc994a43e"),
              ),
              Positioned(
                bottom: 0,
                child: WaterGlass(
                  width: 100, height: 30, borderRadius: 20,
                  child: const Text("98.4 TRUST", style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("John Victor", style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              const Icon(Icons.verified, color: AppColors.textCyan, size: 24),
            ],
          ),
          const Text("ELO SCORE: 2450", style: TextStyle(color: AppColors.textCyan, letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildReputationGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statBox("12", "HOSTED"),
        _statBox("45", "ATTENDED"),
        _statBox("0", "FLAKES", color: Colors.redAccent),
      ],
    );
  }

  Widget _statBox(String value, String label, {Color? color}) {
    return WaterGlass(
      width: 100, height: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color ?? Colors.white)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Text(text, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: color.withOpacity(0.2))),
        ],
      ),
    );
  }

  Widget _editableField(String label, String value, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 8),
          WaterGlass(
            height: maxLines == 1 ? 60 : 100,
            borderRadius: 15,
            child: TextField(
              enabled: isEditing,
              maxLines: maxLines,
              controller: TextEditingController(text: value),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: AppColors.textCyan, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(15),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceChips(String label, List<String> options, String current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: options.map((opt) {
            bool selected = opt == current;
            return ChoiceChip(
              label: Text(opt),
              selected: selected,
              onSelected: isEditing ? (val) {} : null,
              selectedColor: AppColors.gold.withOpacity(0.2),
              backgroundColor: Colors.white.withOpacity(0.05),
              labelStyle: TextStyle(color: selected ? AppColors.gold : Colors.white38, fontSize: 12),
              side: BorderSide(color: selected ? AppColors.gold : Colors.transparent),
            );
          }).toList(),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildPhotoGallery() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _photoBox("https://images.unsplash.com/photo-1500648767791-00dcc994a43e"),
          _photoBox("https://images.unsplash.com/photo-1506794778202-cad84cf45f1d"),
          if (isEditing) _addPhotoBox(),
        ],
      ),
    );
  }

  Widget _photoBox(String url) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }

  Widget _addPhotoBox() {
    return WaterGlass(
      width: 100, height: 100, borderRadius: 15,
      child: const Icon(Icons.add_a_photo, color: AppColors.textPink),
    );
  }

  Widget _infoTile(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WaterGlass(
        height: 60,
        child: ListTile(
          leading: Icon(icon, color: AppColors.textCyan),
          title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.white38)),
          trailing: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEditing ? Colors.greenAccent : AppColors.textCyan,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: () => setState(() => isEditing = !isEditing),
        child: Text(
          isEditing ? "SAVE ARCHIVE" : "EDIT PROTOCOL",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
      ),
    );
  }
}