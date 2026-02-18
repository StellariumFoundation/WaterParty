// profile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  bool isEditing = false;
  late TabController _tabController;
  
  // Controllers to capture input
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize controllers with current data from Provider
    final user = ref.read(authProvider);
    _nameController = TextEditingController(text: user?.name ?? "");
    _bioController = TextEditingController(text: user?.bio ?? "");
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (isEditing) {
      // Logic: Save Changes to Global State
      ref.read(authProvider.notifier).updateUserProfile(
        _nameController.text, 
        _bioController.text, 
        "@updated_handle" // Simplified for demo
      );
    }
    setState(() => isEditing = !isEditing);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox(); // Should handle this better in production

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildCompactHeader(user),
            const SizedBox(height: 20),
            
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: WaterGlass(
                height: 50,
                borderRadius: 25,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.textCyan,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.textCyan,
                  unselectedLabelColor: Colors.white38,
                  tabs: const [
                    Tab(text: "PROFILE"),
                    Tab(text: "LIFESTYLE"),
                    Tab(text: "SOCIALS"),
                  ],
                ),
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIdentityTab(user), // Pass user data down
                  Container(), // Placeholders for brevity
                  Container(), 
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
              child: _buildActionButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader(var user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: WaterGlass(
        height: 100,
        child: Row(
          children: [
            const SizedBox(width: 15),
            CircleAvatar(
              radius: 35,
              backgroundImage: NetworkImage(user.imageUrl),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Uses Controller if editing, or Text if not
                  isEditing 
                    ? SizedBox(height: 30, child: TextField(controller: _nameController, style: GoogleFonts.playfairDisplay(color: Colors.white))) 
                    : Text(user.name, style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold)),
                  
                  Text("Trust Score: ${user.reputation}", style: const TextStyle(color: AppColors.textCyan, fontSize: 11)),
                ],
              ),
            ),
            _miniStat(user.hostedCount.toString(), "HOST"),
            _miniStat(user.joinedCount.toString(), "JOIN"),
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

  Widget _buildIdentityTab(var user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _compactField("Bio", _bioController, Icons.short_text, maxLines: 2),
          // Additional fields...
        ],
      ),
    );
  }

  Widget _compactField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WaterGlass(
        height: maxLines == 1 ? 55 : 80,
        borderRadius: 15,
        child: TextField(
          enabled: isEditing,
          maxLines: maxLines,
          controller: controller, // Bound to controller
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

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEditing ? Colors.greenAccent : AppColors.textCyan,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: _toggleEdit,
        child: Text(
          isEditing ? "SAVE CHANGES" : "EDIT PROFILE",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}