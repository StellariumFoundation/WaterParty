import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'providers.dart';
import 'models.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool isEditing = false;

  // --- Controllers for Text Input ---
  late TextEditingController _realNameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _jobCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _schoolCtrl;
  late TextEditingController _instaCtrl;

  // --- Local State for Non-Text Fields ---
  int _age = 18;
  int _heightCm = 170;
  String _drinking = "Social";
  String _smoking = "No";
  String _cannabis = "No";
  List<String> _interests = [];

  // Options for Dropdowns
  final List<String> _habitOptions = ["No", "Social", "Yes"];
  final List<String> _commonInterests = ["#Techno", "#Jazz", "#Art", "#Hiking", "#Foodie", "#Travel", "#Gaming", "#Yoga"];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    final user = ref.read(authProvider);
    if (user == null) return;

    _realNameCtrl = TextEditingController(text: user.realName);
    _bioCtrl = TextEditingController(text: user.bio);
    _jobCtrl = TextEditingController(text: user.jobTitle);
    _companyCtrl = TextEditingController(text: user.company);
    _schoolCtrl = TextEditingController(text: user.school);
    _instaCtrl = TextEditingController(text: user.instagramHandle);
    
    _age = user.age == 0 ? 18 : user.age;
    _heightCm = user.heightCm == 0 ? 170 : user.heightCm;
    _drinking = user.drinkingPref.isEmpty ? "Social" : user.drinkingPref;
    _smoking = user.smokingPref.isEmpty ? "No" : user.smokingPref;
    _cannabis = user.cannabisPref.isEmpty ? "No" : user.cannabisPref;
    _interests = List.from(user.interests.isEmpty ? user.vibeTags : user.interests);
  }

  @override
  void dispose() {
    _realNameCtrl.dispose();
    _bioCtrl.dispose();
    _jobCtrl.dispose();
    _companyCtrl.dispose();
    _schoolCtrl.dispose();
    _instaCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (isEditing) {
      _saveChanges();
    }
    setState(() => isEditing = !isEditing);
  }

  void _saveChanges() {
    final currentUser = ref.read(authProvider);
    if (currentUser == null) return;

    // Create updated User object
    // Note: In a real app, this copyWith would be much larger to cover all fields
    // For this example, we assume we update the fields we edited.
    final updatedUser = currentUser.copyWith(
      realName: _realNameCtrl.text,
      bio: _bioCtrl.text,
      // For the full struct update, you might need to extend copyWith in models.dart
      // or recreate the User object fully if copyWith is limited.
    );

    // 1. Update Local Provider
    // (Assuming you add a method to AuthNotifier to accept a full User object)
    // ref.read(authProvider.notifier).updateUser(updatedUser); 
    
    // 2. Send to Backend via WebSocket
    // ref.read(socketServiceProvider).sendMessage('UPDATE_PROFILE', updatedUser.toMap());
    
    // Quick Hack for demo since copyWith in models.dart was limited in previous step:
    ref.read(authProvider.notifier).updateUserProfile(
      _realNameCtrl.text, 
      _bioCtrl.text, 
      _instaCtrl.text
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // --- SCROLLABLE CONTENT ---
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoCarousel(user),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIdentitySection(user),
                          const SizedBox(height: 20),
                          _buildBioSection(),
                          const SizedBox(height: 20),
                          _buildLifestyleSection(),
                          const SizedBox(height: 20),
                          _buildWorkEducationSection(),
                          const SizedBox(height: 20),
                          _buildInterestsSection(),
                          const SizedBox(height: 100), // Spacing for FAB
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleEdit,
        backgroundColor: isEditing ? Colors.greenAccent : AppColors.textCyan,
        icon: Icon(isEditing ? Icons.check : Icons.edit, color: Colors.black),
        label: Text(
          isEditing ? "SAVE PROFILE" : "EDIT PROFILE",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- 1. PHOTO CAROUSEL (TINDER STYLE) ---
  Widget _buildPhotoCarousel(User user) {
    final photos = user.profilePhotos.isEmpty 
        ? ["https://images.unsplash.com/photo-1500648767791-00dcc994a43e"] // Fallback
        : user.profilePhotos;

    return SizedBox(
      height: 400,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: photos.length + (isEditing ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= photos.length) {
                return _buildAddPhotoCard();
              }
              return Image.network(photos[index], fit: BoxFit.cover);
            },
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.1), Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
            ),
          ),
          // Trust Score Badge
          Positioned(
            top: 20, right: 20,
            child: WaterGlass(
              width: 100, height: 35, borderRadius: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield, color: AppColors.gold, size: 14),
                  const SizedBox(width: 5),
                  Text("${user.trustScore} TRUST", style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoCard() {
    return Container(
      color: Colors.white10,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: Colors.white38, size: 40),
            SizedBox(height: 10),
            Text("Add Photo", style: TextStyle(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  // --- 2. IDENTITY (Name & Age) ---
  Widget _buildIdentitySection(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: isEditing 
                ? TextField(
                    controller: _realNameCtrl,
                    style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    decoration: const InputDecoration(hintText: "Your Name", border: InputBorder.none),
                  )
                : Text(
                    "${user.realName}, $_age",
                    style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
            ),
            if (isEditing)
               SizedBox(
                 width: 60,
                 child: TextField(
                   keyboardType: TextInputType.number,
                   onChanged: (v) => _age = int.tryParse(v) ?? _age,
                   decoration: InputDecoration(hintText: "$_age", labelText: "Age", border: InputBorder.none),
                   style: const TextStyle(color: Colors.white, fontSize: 20),
                 ),
               )
          ],
        ),
        if (!isEditing)
          Text("@${user.username}", style: const TextStyle(color: AppColors.textCyan, fontSize: 14)),
      ],
    );
  }

  // --- 3. BIO ---
  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ABOUT ME", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 5),
        isEditing
            ? WaterGlass(
                height: 100,
                child: TextField(
                  controller: _bioCtrl,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(15)),
                ),
              )
            : Text(_bioCtrl.text, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.white70)),
      ],
    );
  }

  // --- 4. LIFESTYLE (Chips/Grid) ---
  Widget _buildLifestyleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("LIFESTYLE", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildInfoTile(Icons.height, "Height", isEditing ? "$_heightCm cm" : "$_heightCm cm")), // Add slider logic if really building
            const SizedBox(width: 10),
            Expanded(child: _buildDropdownTile(Icons.local_bar, "Drinks", _drinking, (v) => setState(() => _drinking = v))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildDropdownTile(Icons.smoking_rooms, "Smoke", _smoking, (v) => setState(() => _smoking = v))),
            const SizedBox(width: 10),
            Expanded(child: _buildDropdownTile(Icons.spa, "Weed", _cannabis, (v) => setState(() => _cannabis = v))),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownTile(IconData icon, String label, String value, Function(String) onChanged) {
    if (!isEditing) {
      return _buildInfoTile(icon, label, value);
    }
    return WaterGlass(
      height: 60,
      borderRadius: 15,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white38),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _habitOptions.contains(value) ? value : _habitOptions.first,
                  dropdownColor: Colors.grey[900],
                  isDense: true,
                  items: _habitOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(color: Colors.white, fontSize: 12)))).toList(),
                  onChanged: (v) { if (v != null) onChanged(v); },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return WaterGlass(
      height: 60, borderRadius: 15,
      child: Row(
        children: [
          const SizedBox(width: 15),
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 9, color: Colors.white38)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          )
        ],
      ),
    );
  }

  // --- 5. WORK & EDUCATION ---
  Widget _buildWorkEducationSection() {
    return Column(
      children: [
        _buildListInput(Icons.work, _jobCtrl, "Job Title", "Add Job"),
        const SizedBox(height: 10),
        _buildListInput(Icons.business, _companyCtrl, "Company", "Add Company"),
        const SizedBox(height: 10),
        _buildListInput(Icons.school, _schoolCtrl, "School", "Add School"),
        const SizedBox(height: 10),
        _buildListInput(Icons.camera_alt, _instaCtrl, "Instagram", "Add Handle"),
      ],
    );
  }

  Widget _buildListInput(IconData icon, TextEditingController ctrl, String hint, String emptyLabel) {
    if (!isEditing && ctrl.text.isEmpty) return const SizedBox();

    return WaterGlass(
      height: 55, borderRadius: 15,
      child: TextField(
        controller: ctrl,
        enabled: isEditing,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textCyan, size: 18),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        ),
      ),
    );
  }

  // --- 6. INTERESTS (VIBE TAGS) ---
  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("MY VIBE", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (isEditing ? _commonInterests : _interests).map((tag) {
            final isSelected = _interests.contains(tag);
            return GestureDetector(
              onTap: isEditing ? () {
                setState(() {
                  isSelected ? _interests.remove(tag) : _interests.add(tag);
                });
              } : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.textCyan.withOpacity(0.2) : Colors.white10,
                  border: Border.all(color: isSelected ? AppColors.textCyan : Colors.transparent),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(tag, style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 12)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}