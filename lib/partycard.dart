import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PartyCard extends StatelessWidget {
  final String title;
  final String hostName;
  final String imageUrl;
  final List<String> vibeTags;
  final int slotsOpen;

  const PartyCard({
    required this.title,
    required this.hostName,
    required this.imageUrl,
    required this.vibeTags,
    required this.slotsOpen,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          // Gradient Overlay for readability
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vibe Tags
                Wrap(
                  spacing: 8,
                  children: vibeTags.map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 12, color: Colors.white)),
                    backgroundColor: Colors.blueAccent.withOpacity(0.4),
                    padding: EdgeInsets.zero,
                  )).toList(),
                ),
                const SizedBox(height: 12),
                
                // Title
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                // Host & Slots
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 12,
                      child: Icon(Icons.person, size: 16, color: Colors.black),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Hosted by $hostName",
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$slotsOpen Slots Left",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

