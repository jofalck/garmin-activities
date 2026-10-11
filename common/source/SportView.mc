import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.ActivityRecording;
import Toybox.Activity;
import Toybox.Attention;
import Toybox.Position;
import Toybox.Sensor;
import Toybox.Timer;
import Toybox.System;
import Toybox.UserProfile;
import Toybox.Lang;

// localized string, cached: labels are drawn every second
var trCache as Dictionary<ResourceId, String> = {};
function tr(id as ResourceId) as String {
    var v = trCache[id];
    if (v == null) { v = WatchUi.loadResource(id) as String; trCache[id] = v; }
    return v;
}

class SportView extends WatchUi.View {
    var session as ActivityRecording.Session? = null;
    var timer as Timer.Timer;
    var page as Number = 0;
    var hrZones as Array<Number>? = null;

    // lap state
    var lapNum as Number = 1;
    var lapStartTime as Number = 0;
    var lapStartDist as Float = 0.0;
    var lapStartAscent as Number = 0;
    var lapHrSum as Number = 0;
    var lapHrCount as Number = 0;
    var nextAutoLap as Float = AUTO_LAP_M.toFloat();
    var summary as Array<[String, String]>? = null;   // finished lap, shown for a few seconds
    var summaryUntil as Number = 0;

    // auto-pause state
    var autoPaused as Boolean = false;
    var slowSeconds as Number = 0;
    var gpsSpeed as Float = 0.0;

    function initialize() {
        View.initialize();
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        hrZones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
        // runs for the app's whole life: auto-lap/pause must keep working behind menus
        timer = new Timer.Timer();
        timer.start(method(:tick), 1000, true);
    }

    function onPosition(info as Position.Info) as Void {
        var v = info.speed;
        gpsSpeed = v == null ? 0.0 : v;
    }

    function isRecording() as Boolean { var s = session; return s != null && s.isRecording(); }
    function isStopped() as Boolean { return session != null && !isRecording() && !autoPaused; }

    function tick() as Void {
        var info = Activity.getActivityInfo();
        if (isRecording() && info != null) {
            var h = info.currentHeartRate;
            if (h != null) { lapHrSum += h; lapHrCount++; }
            var d = info.elapsedDistance;
            if (AUTO_LAP_M > 0 && d != null && d >= nextAutoLap) { lap(true); }
        }
        checkAutoPause();
        WatchUi.requestUpdate();
    }

    // pause after AUTO_PAUSE_SEC below the threshold, resume as soon as we move again
    function checkAutoPause() as Void {
        var s = session;
        if (AUTO_PAUSE_KMH <= 0 || s == null) { return; }
        var slow = gpsSpeed * 3.6 < AUTO_PAUSE_KMH;
        if (isRecording()) {
            slowSeconds = slow ? slowSeconds + 1 : 0;
            if (slowSeconds >= AUTO_PAUSE_SEC) { s.stop(); autoPaused = true; buzz(200); }
        } else if (autoPaused && !slow) {
            s.start(); autoPaused = false; slowSeconds = 0; buzz(200);
        }
    }

    function buzz(ms as Number) as Void {
        if (Attention has :vibrate) { Attention.vibrate([new Attention.VibeProfile(100, ms)]); }
    }

    function start() as Void {
        var s = session;
        if (s == null) {
            try {
                s = ActivityRecording.createSession({:name => tr(Rez.Strings.AppName), :sport => SPORT, :subSport => SUB_SPORT});
            } catch (e) {
                // Some watches reject some sport combinations; fall back so the activity is still recorded
                s = ActivityRecording.createSession({:name => tr(Rez.Strings.AppName), :sport => Activity.SPORT_GENERIC, :subSport => Activity.SUB_SPORT_GENERIC});
            }
            session = s;
        }
        s.start();
        autoPaused = false;
        slowSeconds = 0;
        buzz(400);
    }

    function stop() as Void {
        var s = session;
        if (s != null && s.isRecording()) { s.stop(); }
        autoPaused = false;   // a manual stop overrides auto-pause: we must not auto-resume
        buzz(400);
    }

    function lap(auto as Boolean) as Void {
        var s = session;
        if (s == null) { return; }
        s.addLap();
        summary = [];
        for (var i = 0; i < LAP_FIELDS.size(); i++) {
            (summary as Array).add(field(LAP_FIELDS[i] as Symbol, Activity.getActivityInfo()));
        }
        summaryUntil = System.getTimer() + 5000;

        var info = Activity.getActivityInfo();
        if (info != null) {
            var tt = info.timerTime, d = info.elapsedDistance, a = info.totalAscent;
            lapStartTime = tt == null ? 0 : tt;
            lapStartDist = d == null ? 0.0 : d;
            lapStartAscent = a == null ? 0 : a.toNumber();
        }
        // auto laps land on exact multiples; a manual lap restarts the count
        nextAutoLap = auto ? nextAutoLap + AUTO_LAP_M : lapStartDist + AUTO_LAP_M;
        lapHrSum = 0;
        lapHrCount = 0;
        lapNum++;
        buzz(auto ? 600 : 200);
        WatchUi.requestUpdate();
    }

    function save() as Void { var s = session; if (s != null) { s.save(); } System.exit(); }
    function discard() as Void { var s = session; if (s != null) { s.discard(); } System.exit(); }

    function flip(step as Number) as Void {
        page = (page + step + PAGES.size()) % PAGES.size();
        WatchUi.requestUpdate();
    }

    // [label, value] for one data field
    function field(f as Symbol, i as Activity.Info?) as [String, String] {
        if (f == :clock) {
            var c = System.getClockTime();
            return [tr(Rez.Strings.Clock), c.hour.format("%02d") + ":" + c.min.format("%02d")];
        }
        if (f == :lapNum) { return [tr(Rez.Strings.Lap), lapNum.toString()]; }
        if (f == :lapAvgHr) { return [tr(Rez.Strings.LapAvgHr), lapHrCount == 0 ? "--" : (lapHrSum / lapHrCount).toString()]; }
        if (i == null) { return ["", "--"]; }
        var tt = i.timerTime, d = i.elapsedDistance;
        var lapMs = tt == null ? null : tt - lapStartTime;
        var lapM = d == null ? null : d - lapStartDist;
        if (f == :timer) { return [tr(Rez.Strings.Timer), hms(tt)]; }
        if (f == :lapTime) { return [tr(Rez.Strings.LapTime), hms(lapMs)]; }
        if (f == :distance) { return [tr(Rez.Strings.Km), d == null ? "--" : (d / 1000.0).format("%.2f")]; }
        if (f == :lapDist) { return [tr(Rez.Strings.LapKm), lapM == null ? "--" : (lapM / 1000.0).format("%.2f")]; }
        if (f == :hr) { return [tr(Rez.Strings.Hr), num(i.currentHeartRate)]; }
        if (f == :avgHr) { return [tr(Rez.Strings.AvgHr), num(i.averageHeartRate)]; }
        if (f == :speed) { return [tr(Rez.Strings.Kmh), kmh(i.currentSpeed)]; }
        if (f == :avgSpeed) { return [tr(Rez.Strings.AvgKmh), kmh(i.averageSpeed)]; }
        if (f == :pace) { return [tr(Rez.Strings.Pace), pace(i.currentSpeed)]; }
        if (f == :avgPace) { return [tr(Rez.Strings.AvgPace), pace(i.averageSpeed)]; }
        if (f == :lapPace) {
            return [tr(Rez.Strings.LapPace), (lapMs == null || lapM == null || lapMs <= 0) ? "--" : pace(lapM / (lapMs / 1000.0))];
        }
        if (f == :ascent) { return [tr(Rez.Strings.Ascent), num(i.totalAscent)]; }
        if (f == :lapAscent) { var a = i.totalAscent; return [tr(Rez.Strings.LapAscent), a == null ? "--" : (a.toNumber() - lapStartAscent).toString()]; }
        if (f == :descent) { return [tr(Rez.Strings.Descent), num(i.totalDescent)]; }
        if (f == :altitude) { return [tr(Rez.Strings.Altitude), num(i.altitude)]; }
        if (f == :calories) { return [tr(Rez.Strings.Kcal), num(i.calories)]; }
        return ["?", "--"];
    }

    function num(v as Numeric?) as String { return v == null ? "--" : v.toNumber().toString(); }
    function kmh(v as Float?) as String { return v == null ? "--" : (v * 3.6).format("%.1f"); }
    // min/km; below ~2 km/h pace is meaningless noise
    function pace(mps as Float?) as String {
        if (mps == null || mps < 0.55) { return "--"; }
        var s = (1000 / mps).toNumber();
        return (s / 60) + ":" + (s % 60).format("%02d");
    }
    function hms(ms as Number?) as String {
        if (ms == null) { return "--"; }
        var t = ms / 1000;
        var mmss = (t % 3600 / 60).format("%02d") + ":" + (t % 60).format("%02d");
        return t >= 3600 ? (t / 3600) + ":" + mmss : mmss;
    }

    function hrColor(hr as Number?) as Number {
        var z = hrZones;
        if (hr == null || z == null || z.size() < 6) { return Graphics.COLOR_WHITE; }
        if (hr <= z[1]) { return Graphics.COLOR_LT_GRAY; }
        if (hr <= z[2]) { return Graphics.COLOR_BLUE; }
        if (hr <= z[3]) { return Graphics.COLOR_GREEN; }
        if (hr <= z[4]) { return Graphics.COLOR_ORANGE; }
        return Graphics.COLOR_RED;
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth(), h = dc.getHeight(), cx = w / 2;
        var c = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var info = Activity.getActivityInfo();
        var showSummary = summary != null && System.getTimer() < summaryUntil;

        // header: status, coloured so pause / no GPS are obvious at a glance
        var gpsOk = Position.getInfo().accuracy >= Position.QUALITY_USABLE;
        var status = tr(Rez.Strings.AppName), color = Graphics.COLOR_GREEN;
        if (session == null) { status = gpsOk ? tr(Rez.Strings.GpsOk) : tr(Rez.Strings.GpsWait); color = gpsOk ? Graphics.COLOR_GREEN : Graphics.COLOR_YELLOW; }
        else if (autoPaused) { status = tr(Rez.Strings.AutoPause); color = Graphics.COLOR_YELLOW; }
        else if (!isRecording()) { status = tr(Rez.Strings.StoppedHdr); color = Graphics.COLOR_RED; }
        else if (showSummary) { status = tr(Rez.Strings.Lap) + " " + (lapNum - 1); color = Graphics.COLOR_BLUE; }
        var top = h * 16 / 100;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, w, top);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, top * 6 / 10, Graphics.FONT_XTINY, status, c);

        // three stacked fields: the current page, or the finished lap's summary
        var syms = PAGES[page] as Array<Symbol>;
        var rows = showSummary ? summary as Array<[String, String]> : [] as Array<[String, String]>;
        if (!showSummary) {
            for (var r = 0; r < syms.size(); r++) { rows.add(field(syms[r], info)); }
        }
        var rowH = (h - top) / rows.size();
        for (var r = 0; r < rows.size(); r++) {
            var y = top + r * rowH;
            var lv = rows[r];
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y + 12, Graphics.FONT_XTINY, lv[0], c);
            var valColor = (!showSummary && syms[r] == :hr && info != null) ? hrColor(info.currentHeartRate) : Graphics.COLOR_WHITE;
            dc.setColor(valColor, Graphics.COLOR_TRANSPARENT);
            // shrink the font if the value would hit the round edge
            var font = dc.getTextWidthInPixels(lv[1], Graphics.FONT_NUMBER_MEDIUM) < w * 3 / 4
                ? Graphics.FONT_NUMBER_MEDIUM : Graphics.FONT_NUMBER_MILD;
            dc.drawText(cx, y + rowH / 2 + 8, font, lv[1], c);
            if (r > 0) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(0, y, w, y);
            }
        }

        // page dots on the left edge, inside the middle row
        if (!showSummary) {
            for (var p = 0; p < PAGES.size(); p++) {
                dc.setColor(p == page ? Graphics.COLOR_WHITE : Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(8, top + rowH * 3 / 2 + (p * 2 - PAGES.size() + 1) * 6, 3);
            }
        }
    }
}
