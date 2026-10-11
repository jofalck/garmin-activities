import Toybox.Activity;

const SPORT = Activity.SPORT_ALPINE_SKIING;
const SUB_SPORT = Activity.SUB_SPORT_BACKCOUNTRY;

const AUTO_LAP_M = 0;        // auto-lap distance in metres, 0 = off (BACK always adds a manual lap)
const AUTO_PAUSE_KMH = 1.0;    // pause below this speed, 0 = off
const AUTO_PAUSE_SEC = 60;    // ...for this many seconds (long for randonee: slow steep climbs)

// Screens, cycled with UP/DOWN, 3 fields each. Fields:
//   timer clock distance hr avgHr speed avgSpeed pace avgPace ascent descent altitude calories
//   lapTime lapDist lapPace lapAscent lapAvgHr lapNum
const PAGES = [
    [:timer, :ascent, :hr],
    [:altitude, :descent, :distance],
    [:clock, :avgHr, :calories],
];

// Shown for 5 s after every lap (values for the lap just finished)
const LAP_FIELDS = [:lapTime, :lapAscent, :lapAvgHr];
