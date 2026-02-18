import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  bool isEditing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState(); // FIXED: Removed the 'super.key' error
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildCompactHeader(),
            const SizedBox(height: 20),
            
            // --- Compact Tab Navigation ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: WaterGlass(
                height: 50,
                borderRadius: 25,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.textCyan,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: AppColors.textCyan,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: "PROFILE"),
                    Tab(text: "LIFESTYLE"),
                    Tab(text: "SOCIALS"),
                  ],
                ),
              ),
            ),

            // --- Tab Content Area ---
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIdentityTab(),
                  _buildLifestyleTab(),
                  _buildSocialsTab(),
                ],
              ),
            ),

            // --- Global Action Button ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
              child: _buildActionButton(),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. COMPACT HEADER (Reputation & Photo) ---
  Widget _buildCompactHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: WaterGlass(
        height: 100,
        child: Row(
          children: [
            const SizedBox(width: 15),
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                const CircleAvatar(
                  radius: 35,
                  backgroundImage: NetworkImage("https://images.unsplash.com/photo-1500648767791-00dcc994a43e"),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black, 
                    borderRadius: BorderRadius.circular(10), 
                    border: Border.all(color: AppColors.gold, width: 0.5)
                  ),
                  child: const Text("98.4 TRUST", style: TextStyle(color: AppColors.gold, fontSize: 8, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("John Victor", style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text("Reputation: 2450", style: TextStyle(color: AppColors.textCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            _miniStat("12", "HOST"),
            _miniStat("45", "JOIN"),
            const SizedBox(width: 15),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String val, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: const TextStyle(fontSize: 8, color: Colors.white38)),
        ],
      ),
    );
  }

  // --- 2. IDENTITY TAB (Bio, Work, Photos) ---
  Widget _buildIdentityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildPhotoStrip(),
          const SizedBox(height: 20),
          _compactField("Bio", "Architect of the Vibe.", Icons.short_text, maxLines: 2),
          Row(
            children: [
              Expanded(child: _compactField("Job", "Architect", Icons.work)),
              const SizedBox(width: 10),
              Expanded(child: _compactField("Company", "Stellarium", Icons.business)),
            ],
          ),
          _compactField("School", "Stanford University", Icons.school),
        ],
      ),
    );
  }

  // --- 3. LIFESTYLE TAB ---
  Widget _buildLifestyleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _compactField("Age", "28", Icons.cake)),
              const SizedBox(width: 10),
              Expanded(child: _compactField("Height", "185cm", Icons.height)),
            ],
          ),
          const SizedBox(height: 10),
          _compactPreference("Drinking", ["Sober", "Social", "Yes"], "Social"),
          _compactPreference("Smoking", ["No", "Social", "Yes"], "No"),
          _compactPreference("Cannabis", ["No", "Social", "Yes"], "Social"),
        ],
      ),
    );
  }

  // --- 4. SOCIALS TAB ---
  Widget _buildSocialsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _compactField("Instagram", "@john_v", Icons.camera_alt),
          _compactField("X (Twitter)", "@john_v", Icons.close),
          _compactField("LinkedIn", "john-victor", Icons.link),
          const SizedBox(height: 10),
          _compactInfoTile("Location", "San Francisco, CA", Icons.location_on),
        ],
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _compactField(String label, String value, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WaterGlass(
        height: maxLines == 1 ? 55 : 80,
        borderRadius: 15,
        child: TextField(
          enabled: isEditing,
          maxLines: maxLines,
          controller: TextEditingController(text: value),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: AppColors.textCyan, fontSize: 10),
            prefixIcon: Icon(icon, color: Colors.white38, size: 18),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          ),
        ),
      ),
    );
  }

  Widget _compactPreference(String label, List<String> options, String current) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WaterGlass(
        height: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textCyan, fontSize: 10, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: options.map((opt) {
                bool selected = opt == current;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(opt, style: const TextStyle(fontSize: 10)),
                    selected: selected,
                    onSelected: isEditing ? (v) {} : null,
                    selectedColor: AppColors.textCyan.withOpacity(0.2),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: selected ? AppColors.textCyan : Colors.white10),
                  ),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoStrip() {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _miniPhoto("https://images.unsplash.com/photo-1500648767791-00dcc994a43e"),
          _miniPhoto("https://images.unsplash.com/photo-1506794778202-cad84cf45f1d"),
          if (isEditing) 
            GestureDetector(
              onTap: () {},
              child: WaterGlass(width: 80, height: 80, borderRadius: 15, child: const Icon(Icons.add_a_photo, size: 20, color: AppColors.textPink)),
            ),
        ],
      ),
    );
  }

  Widget _miniPhoto(String url) {
    return Container(
      width: 80, height: 80,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15), 
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
      ),
    );
  }

  Widget _compactInfoTile(String label, String value, IconData icon) {
    return WaterGlass(
      height: 55,
      child: ListTile(
        visualDensity: VisualDensity.compact,
        leading: Icon(icon, color: Colors.white38, size: 18),
        title: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        trailing: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEditing ? Colors.greenAccent : AppColors.textCyan,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: () => setState(() => isEditing = !isEditing),
        child: Text(
          isEditing ? "SAVE CHANGES" : "EDIT PROFILE",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
    );
  }
}