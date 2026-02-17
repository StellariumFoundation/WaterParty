import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text("Connections", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMatchTile("Friday Night Run", "Locked • Location Revealed", true),
          _buildMatchTile("Crypto & Coffee", "Host Reviewing...", false),
          _buildMatchTile("Sunset Drinks", "Event Ended", false),
        ],
      ),
    );
  }

  Widget _buildMatchTile(String title, String status, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: WaterGlass(
        height: 80,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: isActive ? AppColors.gold.withOpacity(0.2) : Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(isActive ? Icons.lock_open : Icons.lock, color: isActive ? AppColors.gold : Colors.white54),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(status, style: TextStyle(color: isActive ? AppColors.gold : Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }
}