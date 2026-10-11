import Toybox.WatchUi;
import Toybox.Lang;

// Buttons mirror the 245's own activities:
// START = start/stop (stop opens Resume/Save/Discard), BACK = lap, UP/DOWN = screens.
class SportDelegate extends WatchUi.BehaviorDelegate {
    var view as SportView;
    function initialize(v as SportView) { BehaviorDelegate.initialize(); view = v; }

    function onSelect() as Boolean {                                     // START
        if (view.isRecording() || view.autoPaused) { view.stop(); openStopMenu(view); }
        else { view.start(); }
        WatchUi.requestUpdate();
        return true;
    }

    function onBack() as Boolean {                                       // BACK
        if (view.session == null) { return false; }                      // not started: leave the app
        if (view.isStopped()) { openStopMenu(view); }
        else if (view.isRecording()) { view.lap(false); }
        return true;
    }

    function onNextPage() as Boolean { view.flip(1); return true; }      // DOWN
    function onPreviousPage() as Boolean { view.flip(-1); return true; }  // UP
}

function openStopMenu(view as SportView) as Void {
    var menu = new WatchUi.Menu2({:title => tr(Rez.Strings.MenuStopped)});
    menu.addItem(new WatchUi.MenuItem(tr(Rez.Strings.Resume), null, :resume, null));
    menu.addItem(new WatchUi.MenuItem(tr(Rez.Strings.Save), null, :save, null));
    menu.addItem(new WatchUi.MenuItem(tr(Rez.Strings.Discard), null, :discard, null));
    WatchUi.pushView(menu, new StopMenuDelegate(view), WatchUi.SLIDE_UP);
}

class StopMenuDelegate extends WatchUi.Menu2InputDelegate {
    var view as SportView;
    function initialize(v as SportView) { Menu2InputDelegate.initialize(); view = v; }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :resume) { view.start(); WatchUi.popView(WatchUi.SLIDE_DOWN); }
        else if (id == :save) { view.save(); }
        else if (id == :discard) {
            WatchUi.pushView(new WatchUi.Confirmation(tr(Rez.Strings.DiscardQ)), new DiscardDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        }
    }
    // BACK from the menu returns to the stopped data screens (START there resumes)
}

class DiscardDelegate extends WatchUi.ConfirmationDelegate {
    var view as SportView;
    function initialize(v as SportView) { ConfirmationDelegate.initialize(); view = v; }

    function onResponse(r as WatchUi.Confirm) as Boolean {
        if (r == WatchUi.CONFIRM_YES) { view.discard(); }
        return true;
    }
}
