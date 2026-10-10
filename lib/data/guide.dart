import 'package:flutter/material.dart';

class GuideSection {
  const GuideSection(this.title, this.icon, this.points);
  final String title;
  final IconData icon;
  final List<String> points;
}

const guideSections = <GuideSection>[
  GuideSection('How scoring works', Icons.scoreboard_outlined, [
    'Points go 0 (love), 15, 30, 40, then game.',
    'At 40-40 it is deuce. Win the next point for "advantage", then one more to win the game. Lose it and you are back to deuce.',
    'In no-ad scoring, 40-40 is one deciding point; the receiver chooses which side to receive on.',
    'A set is won by the first to 6 games with a lead of at least 2 (6-4, 7-5). At 6-6 a tiebreak is usually played.',
    'Matches are usually best of 3 sets. University and club matches often replace the third set with a 10-point match tiebreak.',
  ]),
  GuideSection('Tiebreaks', Icons.timer_outlined, [
    'First to 7 points with a lead of 2 (a match tiebreak is first to 10).',
    'The player due to serve serves the first point. After that, each player serves two points in a row, alternating.',
    'Change ends after every 6 points.',
    'The tiebreak counts as one game, so the set score is recorded as 7-6.',
    'The player who received first in the tiebreak serves first in the next set.',
  ]),
  GuideSection('Serving', Icons.sports_tennis, [
    'Serve from behind the baseline, between the centre mark and the sideline.',
    'Start each game serving from the right (deuce) side, then alternate sides every point.',
    'The serve must land in the diagonally opposite service box. You get two attempts.',
    'A serve that touches the net and lands in is a "let" and is replayed.',
    'Stepping on the baseline before you hit the ball is a foot fault.',
    'Players change ends after the 1st, 3rd, 5th… game of every set.',
  ]),
  GuideSection('Doubles basics', Icons.groups_outlined, [
    'The court is wider: the tramlines (alleys) are in after the serve.',
    'Teams choose who serves first each set; servers rotate A1, B1, A2, B2.',
    'Each receiver stays on the same side (deuce or ad) for the whole set.',
    'Communicate: call "mine", "yours", "switch" early and loudly.',
  ]),
  GuideSection('Line calls & fair play', Icons.gavel_outlined, [
    'In casual and most university matches, players call the lines on their own side.',
    'A ball touching any part of the line is in. If you are not sure it was out, it is in.',
    'Call the score before every serve so both players agree, especially in close games.',
    'Return balls to the server directly, not across a neighbouring court.',
  ]),
  GuideSection('Etiquette at the Veritas court', Icons.handshake_outlined, [
    'Respect booking times and leave promptly when the next players arrive.',
    'Wear proper non-marking tennis shoes to protect the surface.',
    'No food, glass bottles, bicycles or pets on the court. Take your rubbish with you.',
    'Wait for a point to finish before walking behind another court.',
    'Shake hands (or tap rackets) at the end of every match, win or lose.',
    'Report damaged nets, lines or fencing to the Sports Unit.',
  ]),
  GuideSection('Staying safe in the heat', Icons.wb_sunny_outlined, [
    'Play early morning or late afternoon where possible; Abuja middays are hot.',
    'Drink before, during (at every change of ends) and after play.',
    'Wear a cap and light-coloured clothing; use sunscreen.',
    'Stop and rest in the shade if you feel dizzy, sick or have a headache.',
  ]),
];
