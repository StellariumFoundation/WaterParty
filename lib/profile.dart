import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'theme.dart';
import 'providers.dart';
import 'models.dart';
import 'websocket.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool isEditing = false;
  bool _isUploading = false;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await image.readAsBytes();
        final hash = await ref.read(authProvider.notifier).uploadImage(bytes, "image/jpeg");
        
        final user = ref.read(authProvider);
        if (user != null) {
          final updatedPhotos = [...user.profilePhotos, hash];
          await ref.read(authProvider.notifier).updateUserProfile(profilePhotos: updatedPhotos);
          
          // Wire to backend
          ref.read(socketServiceProvider).sendMessage('UPDATE_PROFILE', {
            'ID': user.id,
            'ProfilePhotos': updatedPhotos,
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

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
    _interests = List.from(user.interests);
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

    ref.read(authProvider.notifier).updateUserProfile(
      realName: _realNameCtrl.text, 
      bio: _bioCtrl.text, 
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
                          const SizedBox(height: 100),
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  Widget _buildPhotoCarousel(User user) {
    final photos = user.profilePhotos;

    return SizedBox(
      height: 400,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: photos.isEmpty && !isEditing
                ? 1
                : photos.length + (isEditing ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < photos.length) {
                final photoUrl = photos[index].startsWith("http")
                    ? photos[index]
                    : "https://waterparty.onrender.com/assets/${photos[index]}";
                return Image.network(photoUrl, fit: BoxFit.cover);
              }
              if (isEditing) return _buildAddPhotoCard();
              return Image.network("https://images.unsplash.com/photo-1511367461989-f85a21fda167?q=80&w=1000", fit: BoxFit.cover); 
            },
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8)
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: WaterGlass(
              width: 100,
              height: 35,
              borderRadius: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield, color: AppColors.gold, size: 14),
                  const SizedBox(width: 5),
                  Text("${user.trustScore} TRUST",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                          )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoCard() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUploadPhoto,
      child: Container(
        color: Colors.white.withOpacity(0.05),
        child: Center(
          child: _isUploading
              ? const CircularProgressIndicator(color: AppColors.textCyan)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo,
                        color: Colors.white24, size: 50),
                    const SizedBox(height: 15),
                    Text("UPLOAD VIBE",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            )),
                  ],
                ),
        ),
      ),
    );
  }

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
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(fontSize: 32),
                      decoration: const InputDecoration(
                          hintText: "Your Name", border: InputBorder.none),
                    )
                  : Text(
                      "${user.realName}, $_age",
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(fontSize: 32),
                    ),
            ),
            if (isEditing)
              SizedBox(
                width: 60,
                child: TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _age = int.tryParse(v) ?? _age,
                  decoration: InputDecoration(
                      hintText: "$_age",
                      labelText: "Age",
                      border: InputBorder.none),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              )
          ],
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("ABOUT ME",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                )),
        const SizedBox(height: 5),
        isEditing
            ? WaterGlass(
                height: 100,
                child: TextField(
                  controller: _bioCtrl,
                  maxLines: 4,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                  decoration: const InputDecoration(
                      border: InputBorder.none, contentPadding: EdgeInsets.all(15)),
                ),
              )
            : Text(_bioCtrl.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: Colors.white70,
                    )),
      ],
    );
  }

  Widget _buildLifestyleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("LIFESTYLE",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                )),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _buildInfoTile(
                    Icons.height,
                    "Height",
                    "$_heightCm cm")),
            const SizedBox(width: 10),
            Expanded(
                child: _buildDropdownTile(Icons.local_bar, "Drinks", _drinking,
                    (v) => setState(() => _drinking = v))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _buildDropdownTile(Icons.smoking_rooms, "Smoke",
                    _smoking, (v) => setState(() => _smoking = v))),
            const SizedBox(width: 10),
            Expanded(
                child: _buildDropdownTile(Icons.spa, "Weed", _cannabis,
                    (v) => setState(() => _cannabis = v))),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownTile(
      IconData icon, String label, String value, Function(String) onChanged) {
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
                  value: _habitOptions.contains(value)
                      ? value
                      : _habitOptions.first,
                  dropdownColor: Colors.grey[900],
                  isDense: true,
                  items: _habitOptions
                      .map((opt) => DropdownMenuItem(
                          value: opt,
                          child: Text(opt,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onChanged(v);
                  },
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
      height: 60,
      borderRadius: 15,
      child: Row(
        children: [
          const SizedBox(width: 15),
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white38, fontSize: 9)),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWorkEducationSection() {
    return Column(
      children: [
        _buildListInput(_jobCtrl, Icons.work, "Job Title", "Add Job"),
        const SizedBox(height: 10),
        _buildListInput(_companyCtrl, Icons.business, "Company", "Add Company"),
        const SizedBox(height: 10),
        _buildListInput(_schoolCtrl, Icons.school, "School", "Add School"),
        const SizedBox(height: 10),
        _buildListInput(
            _instaCtrl, Icons.camera_alt, "Instagram", "Add Handle"),
      ],
    );
  }

  Widget _buildListInput(TextEditingController ctrl, IconData icon, String hint,
      String emptyLabel) {
    if (!isEditing && ctrl.text.isEmpty) return const SizedBox();

    return WaterGlass(
      height: 55,
      borderRadius: 15,
      child: TextField(
        controller: ctrl,
        enabled: isEditing,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textCyan, size: 18),
          hintText: hint,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white24,
              ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("MY VIBE",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                )),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (isEditing ? _commonInterests : _interests).map((tag) {
            final isSelected = _interests.contains(tag);
            return GestureDetector(
              onTap: isEditing
                  ? () {
                      setState(() {
                        isSelected
                            ? _interests.remove(tag)
                            : _interests.add(tag);
                      });
                    }
                  : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.textCyan.withOpacity(0.2)
                      : Colors.white10,
                  border: Border.all(
                      color: isSelected ? AppColors.textCyan : Colors.transparent),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(tag,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected ? Colors.white : Colors.white38)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
