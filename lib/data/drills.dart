enum DrillCategory {
  warmUp('Warm-up'),
  groundstrokes('Groundstrokes'),
  serveReturn('Serve & return'),
  netPlay('Net play'),
  footwork('Footwork & fitness'),
  matchPlay('Match play');

  const DrillCategory(this.label);
  final String label;
}

class Drill {
  const Drill({
    required this.id,
    required this.name,
    required this.category,
    required this.level,
    required this.minutes,
    required this.players,
    required this.summary,
    required this.steps,
    required this.tips,
    this.equipment = 'Racket, balls',
  });

  final String id;
  final String name;
  final DrillCategory category;
  final String level;
  final int minutes;
  final String players;
  final String summary;
  final List<String> steps;
  final List<String> tips;
  final String equipment;
}

Drill? drillById(String id) {
  for (final d in drills) {
    if (d.id == id) return d;
  }
  return null;
}

const drills = <Drill>[
  Drill(
    id: 'dynamic-warmup',
    name: 'Dynamic court warm-up',
    category: DrillCategory.warmUp,
    level: 'All levels',
    minutes: 8,
    players: '1+',
    equipment: 'None',
    summary: 'Get your body ready to play and cut injury risk, especially in the afternoon heat.',
    steps: [
      'Jog two lengths of the court, then side-shuffle two widths facing the net.',
      'Walking lunges with a twist to the baseline and back.',
      'Arm circles forwards and backwards, 10 each; then shoulder swings across the chest.',
      'Carioca (crossover steps) along the baseline, both directions.',
      'Five short sprints from the baseline to the service line, walking back.',
      'Shadow swing 10 forehands, 10 backhands and 5 serves without a ball.',
    ],
    tips: [
      'Drink water before you start; carry a full bottle to every session.',
      'Keep it dynamic. Save long static stretches for after you play.',
    ],
  ),
  Drill(
    id: 'mini-tennis',
    name: 'Mini tennis (service box rally)',
    category: DrillCategory.warmUp,
    level: 'All levels',
    minutes: 10,
    players: '2',
    summary: 'Short, soft rallies inside the service boxes to find your timing and touch.',
    steps: [
      'Both players stand just behind the service line.',
      'Rally with soft, controlled strokes, keeping the ball inside the service boxes.',
      'Use full but slow swings with topspin; then mix in slices.',
      'Count consecutive shots and try to beat your record (aim for 30).',
    ],
    tips: ['Stay low with bent knees.', 'Small adjustment steps before every ball.'],
  ),
  Drill(
    id: 'crosscourt-rally',
    name: 'Cross-court consistency',
    category: DrillCategory.groundstrokes,
    level: 'Beginner–Intermediate',
    minutes: 15,
    players: '2',
    summary: 'Build a reliable rally ball by hitting cross-court, the highest-percentage shot in tennis.',
    steps: [
      'Rally forehand to forehand cross-court from the baseline (deuce side).',
      'Every ball must land past the service line, in the cross-court half.',
      'After 5 minutes switch to backhand to backhand (ad side).',
      'Challenge: 20 balls in a row without a miss. Start over after any error.',
    ],
    tips: ['Aim 1 metre over the net for safety and depth.', 'Recover to the middle of the baseline after each shot.'],
  ),
  Drill(
    id: 'down-the-line',
    name: 'Cross-court / down-the-line pattern',
    category: DrillCategory.groundstrokes,
    level: 'Intermediate–Advanced',
    minutes: 15,
    players: '2',
    summary: 'One player hits only cross-court, the other only down the line, so both of you run and change direction.',
    steps: [
      'Player A hits every ball cross-court; player B hits every ball down the line.',
      'Rally continuously; both players move side to side.',
      'Swap roles after 5 minutes. Finish with points played out in the pattern.',
    ],
    tips: [
      'Changing direction (down the line) is riskier — give yourself more net clearance.',
      'Use the split step every time your partner makes contact.',
    ],
  ),
  Drill(
    id: 'deep-targets',
    name: 'Depth targets',
    category: DrillCategory.groundstrokes,
    level: 'All levels',
    minutes: 12,
    players: '1–2',
    equipment: 'Racket, balls, 4 cones or towels',
    summary: 'Hit deep to push opponents back. Short balls give them the attack.',
    steps: [
      'Place cones or towels 1–2 metres inside the baseline in each corner.',
      'Feed or rally; score a point for each ball landing between the service line and the baseline.',
      'Double points for hitting a target.',
      'Play to 21, then move the targets closer to the lines.',
    ],
    tips: ['Lift the ball higher over the net rather than swinging harder.'],
  ),
  Drill(
    id: 'serve-targets',
    name: 'Serve target practice',
    category: DrillCategory.serveReturn,
    level: 'All levels',
    minutes: 15,
    players: '1',
    equipment: 'Racket, a basket of balls, 3 targets (cans or cones)',
    summary: 'A reliable serve wins free points. Practise placement: wide, body and T.',
    steps: [
      'Set targets at the T, the body position and the wide corner of the service box.',
      'Serve 10 balls to each target from the deuce side, then the ad side.',
      'Record how many land in the box and how many hit near a target.',
      'Finish with 10 second serves, focusing on spin and safety.',
    ],
    tips: [
      'Same ball toss every time — slightly in front and to the hitting side.',
      'Log your first-serve percentage and try to beat it next week.',
    ],
  ),
  Drill(
    id: 'second-serve-pressure',
    name: 'Second-serve pressure game',
    category: DrillCategory.serveReturn,
    level: 'Intermediate–Advanced',
    minutes: 10,
    players: '2',
    summary: 'Play points starting with only one serve, so every serve has to be a reliable second serve.',
    steps: [
      'The server gets one serve per point. A fault loses the point.',
      'Play games to 4 points, alternating server.',
      'The returner tries to attack every second serve.',
    ],
    tips: ['Brush up the back of the ball for topspin; it pulls the serve into the box.'],
  ),
  Drill(
    id: 'return-block',
    name: 'Return of serve: block and drive',
    category: DrillCategory.serveReturn,
    level: 'All levels',
    minutes: 12,
    players: '2',
    summary: 'Get more returns in play — the most important shot after the serve.',
    steps: [
      'Server hits first serves; the returner blocks every return back deep, cross-court.',
      'After 10 serves the server switches to second serves; the returner drives aggressively.',
      'Switch roles.',
    ],
    tips: ['Short backswing on fast serves.', 'Split step as the server tosses the ball.'],
  ),
  Drill(
    id: 'volley-reflex',
    name: 'Volley reflexes',
    category: DrillCategory.netPlay,
    level: 'All levels',
    minutes: 10,
    players: '2',
    summary: 'Quick hands at the net with compact, punching volleys.',
    steps: [
      'Both players stand on opposite sides about halfway between the net and the service line.',
      'Volley back and forth without letting the ball bounce.',
      'Keep the racket head up and in front of you.',
      'Gradually speed up; count your longest volley rally.',
    ],
    tips: ['No big swings; punch and freeze.', 'Use a continental grip.'],
  ),
  Drill(
    id: 'approach-and-volley',
    name: 'Approach, volley, overhead',
    category: DrillCategory.netPlay,
    level: 'Intermediate',
    minutes: 15,
    players: '2',
    summary: 'Learn to finish points at the net with a three-ball sequence.',
    steps: [
      'Feeder hits a short ball; the player approaches down the line.',
      'Feeder then plays a passing shot for a volley, then a lob for an overhead.',
      'Repeat 8 times, then switch roles.',
    ],
    tips: ['Split step as the opponent hits.', 'Point at the lob with your free hand for overheads.'],
  ),
  Drill(
    id: 'spider-run',
    name: 'Spider run',
    category: DrillCategory.footwork,
    level: 'All levels',
    minutes: 10,
    players: '1',
    equipment: '5 balls or cones',
    summary: 'A classic tennis fitness test for speed and change of direction.',
    steps: [
      'Place a ball on each corner of the singles court where the lines meet and one at the T.',
      'Start at the middle of the baseline. Sprint to each ball, bring it back, then go for the next.',
      'Time yourself. Rest 2 minutes; repeat 3 times.',
      'Log your best time in your practice notes.',
    ],
    tips: ['Stay low when you turn.', 'Watch the heat; rest in the shade between runs.'],
  ),
  Drill(
    id: 'split-step-shadow',
    name: 'Split-step shadow footwork',
    category: DrillCategory.footwork,
    level: 'Beginner',
    minutes: 8,
    players: '1–2',
    equipment: 'Racket',
    summary: 'Build the habit of the split step and good recovery without needing a hitting partner.',
    steps: [
      'Partner (or you) calls "forehand", "backhand", "short" or "deep".',
      'Split step, move to the ball position, shadow the swing, then recover to the centre.',
      'Do 3 sets of 45 seconds with 30 seconds rest.',
    ],
    tips: ['Land the split step on the balls of your feet.'],
  ),
  Drill(
    id: 'king-of-the-court',
    name: 'King of the court',
    category: DrillCategory.matchPlay,
    level: 'All levels',
    minutes: 20,
    players: '3–8',
    summary: 'Perfect when many students turn up to the court at once. Everyone plays, the winners stay on.',
    steps: [
      'One player is the "king" on one side; challengers queue on the other.',
      'Challenger feeds; play one point. Win and you cross to the king side.',
      'Kings score a point for every point won on the king side. First to 7 wins.',
    ],
    tips: ['Keep the queue moving quickly — no long breaks between points.'],
  ),
  Drill(
    id: 'tiebreak-practice',
    name: 'Tiebreak practice',
    category: DrillCategory.matchPlay,
    level: 'All levels',
    minutes: 20,
    players: '2',
    summary: 'Tiebreaks decide close matches. Practise playing them calmly.',
    steps: [
      'Play 7-point tiebreaks (win by two). Use the Score tab to keep count and track serves.',
      'Best of 5 tiebreaks; then finish with one 10-point match tiebreak.',
    ],
    tips: ['First serve in matters more than pace.', 'Have a routine between points: breathe, plan, then play.'],
  ),
  Drill(
    id: 'doubles-poaching',
    name: 'Doubles: poach and cover',
    category: DrillCategory.matchPlay,
    level: 'Intermediate',
    minutes: 15,
    players: '4',
    summary: 'Teach the net player to cross and the partner to cover the open court.',
    steps: [
      'Play cross-court points from the baselines with both net players in position.',
      'Net players try to poach (cross and volley) any loose cross-court ball.',
      'When your partner crosses, switch sides to cover.',
    ],
    tips: ['Agree on signals before the point.', 'Call "mine" or "yours" early.'],
  ),
];
