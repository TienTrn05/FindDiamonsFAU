import 'package:flutter/material.dart';

class CharacterPalette {
  const CharacterPalette(
    this.skin,
    this.hair,
    this.shirt,
    this.trousers,
    this.eyes,
  );
  final Color skin;
  final Color hair;
  final Color shirt;
  final Color trousers;
  final Color eyes;

  static const steve = CharacterPalette(
    Color(0xFFCD9261),
    Color(0xFF4B2C17),
    Color(0xFF13B5B3),
    Color(0xFF4034A1),
    Color(0xFF5E59B8),
  );
  static const knight = CharacterPalette(
    Color(0xFFC59568),
    Color(0xFF171B23),
    Color(0xFF5D626D),
    Color(0xFF242A35),
    Color(0xFFFFFFFF),
  );
  static const panda = CharacterPalette(
    Color(0xFFF1E9D8),
    Color(0xFF242629),
    Color(0xFF2C78BE),
    Color(0xFFB92B28),
    Color(0xFF242629),
  );
  static const neon = CharacterPalette(
    Color(0xFF182B20),
    Color(0xFF08140D),
    Color(0xFF27E347),
    Color(0xFF092A15),
    Color(0xFF33FF5A),
  );
  static const explorer = CharacterPalette(
    Color(0xFFD4A16A),
    Color(0xFF5B4527),
    Color(0xFFB67B3F),
    Color(0xFF416956),
    Color(0xFF384C3A),
  );
  static const robot = CharacterPalette(
    Color(0xFFB1BFC3),
    Color(0xFF4C6975),
    Color(0xFF779EAD),
    Color(0xFF3C505D),
    Color(0xFF75FFF1),
  );
  static const shoes = Color(0xFF626764);
  static const eyeWhite = Color(0xFFFFFFFF);
  static const outline = Color(0xFF2F383A);
  static const gold = Color(0xFFE6B638);

  static CharacterPalette of(String name) => switch (name) {
    'knight' => knight,
    'panda' => panda,
    'neon' => neon,
    'explorer' => explorer,
    'robot' => robot,
    _ => steve,
  };
}
