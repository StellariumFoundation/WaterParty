import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildAvatar(),
            const SizedBox(height: 20),
            Text("John Victor", style: GoogleFonts.playfairDisplay(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text("Architect of the Vibe", style: TextStyle(color: AppColors.gold)),
            const SizedBox(height: 40),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [_statBox("12", "Hosted"), const SizedBox(width: 15), _statBox("45", "Attended"), const SizedBox(width: 15), _statBox("4.9", "Rating")]),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [_optionTile(Icons.verified_user, "Verification Status", "Verified"), _optionTile(Icons.wallet, "Wallet Balance", "\$120.00"), _optionTile(Icons.settings, "Settings", "")]),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: Stack(alignment: Alignment.center, children: [
        Container(width: 140, height: 140, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.goldGradient)),
        const CircleAvatar(radius: 65, backgroundImage: NetworkImage("https://images.unsplash.com/photo-1500648767791-00dcc994a43e")),
        Positioned(bottom: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gold)), child: const Text("98 TRUST", style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold)))),
      ]),
    );
  }

  Widget _statBox(String val, String label) {
    return SizedBox(width: 100, child: WaterGlass(height: 80, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)), Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54))])));
  }

  Widget _optionTile(IconData icon, String title, String trailing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: WaterGlass(height: 70, borderRadius: 16, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0), child: Row(children: [Icon(icon, color: Colors.white70), const SizedBox(width: 16), Expanded(child: Text(title, style: const TextStyle(color: Colors.white))), Text(trailing, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold))]))),
    );
  }
}