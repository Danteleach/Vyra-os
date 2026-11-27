// Vyra OS desktop layout — floating glass dock (Phase A4).
//
// A single centered floating dock at the bottom, macOS / elementary OS
// style, with HarmonyOS elegance: one harmonious element, generous
// spacing, soft curves, restrained gold. Built from stock Plasma 6
// panels — no third-party dock (Latte is dead upstream; the stock panel
// + Icons-only Task Manager is the supported path).
//
// Pattern: lvasiliou/win12kde (Plasma 6 global theme, MIT) — the same
// stock-Panel properties, verified against a real working layout.js:
//   panel.location / height / lengthMode / alignment / floating / hiding
//   / opacity, widget writeConfig("icon", ...) for Kickoff, and the
//   icontasks launchers list. Adapted here to a single dock (not three
//   islands) because macOS / elementary / HarmonyOS all use one dock.
//
// How it is applied: this file lives in the org.vyra.desktop
// look-and-feel (contents/layouts/org.kde.plasma.desktop-layout.js).
// Plasma runs it when the look-and-feel is first applied (fresh live
// session / first login), replacing the stock full-width bottom panel
// with the dock below. The stock panel is NOT kept — one dock only.
//
// Glassmorphism: panel.opacity = "translucent" makes the panel
// background semi-transparent; KWin's blur effect (on by default in
// Plasma 6) blurs the wallpaper behind it, giving the frosted-glass
// look. The Breeze (dark) theme draws the panel as a translucent
// rounded rectangle. If the boot test shows a solid panel instead of
// frosted glass, KWin blur is the first thing to check.
//
// Wallpaper: the layout also pins the desktop wallpaper to the black
// hero (Batch 01, 01) by direct file path, so the black wallpaper is
// the default even if the colour-scheme resolution hiccups. The
// look-and-feel defaults ([Wallpaper] Image=Vyra + ColorScheme=BreezeDark)
// give the same dark hero through the wallpaper package's images_dark/
// variant — the two layers agree, so either one alone is enough.

var plasma = getApiVersion(1);

function hasWidget(pluginId) {
    return knownWidgetTypes.indexOf(pluginId) !== -1;
}

// The black hero wallpaper (Batch 01, 01) — the default.
var blackWallpaper = "file:///usr/share/wallpapers/Vyra/contents/images_dark/3840x2160.png";

var allDesktops = desktops();
for (var i = 0; i < allDesktops.length; i++) {
    var desktop = allDesktops[i];
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktop.writeConfig("Image", blackWallpaper);
    desktop.writeConfig("FillMode", "2");
}

// ---------------------------------------------------------------- Floating dock
// One centered dock, floating above the desktop, only as wide as its
// content (lengthMode "fit"), translucent for the glass effect.
// Height 60: roomy enough for 48px icons with breathing space
// (HarmonyOS generosity), small enough to stay out of the way.

var dock = new Panel;
dock.location = "bottom";
dock.height = 60;
dock.lengthMode = "fit";
dock.alignment = "center";
dock.floating = true;
dock.hiding = "none";
dock.opacity = "translucent";

// Home / Start button — the Vyra gold V, like the Windows Start button.
// The Kickoff applet's icon is set to the "vyra" icon (hicolor theme,
// installed by Containerfile Phase A4). The icon is a named icon, not a
// file path, so it follows the icon theme and scales cleanly.
var start = dock.addWidget("org.kde.plasma.kickoff");
start.currentConfigGroup = ["General"];
start.writeConfig("icon", "vyra");

// Pinned apps + running tasks (Icons-only Task Manager). Only the
// essentials are pinned — HarmonyOS restraint, no clutter. Running apps
// join the dock with a dot indicator; clicking one raises it.
var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "preferred://filemanager",
    "preferred://browser",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.discover.desktop"
]);
tasks.writeConfig("iconSpacing", "1");
tasks.writeConfig("indicateAudioStreams", "true");
tasks.writeConfig("groupingStrategy", "1");

// System tray — icons scaled to the panel height so they match the
// dock's icon size and read as one harmonious row.
var tray = dock.addWidget("org.kde.plasma.systemtray");
tray.currentConfigGroup = ["General"];
tray.writeConfig("scaleIconsToFit", "true");

// Clock — time with the date below it, 24-hour, short date.
// Clean and quiet, the way HarmonyOS keeps the status area.
var clock = dock.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", "true");
clock.writeConfig("dateDisplayFormat", "BelowTime");
clock.writeConfig("dateFormat", "shortDate");
clock.writeConfig("use24hFormat", "2");

// Peek at Desktop — the thin sliver at the dock's end, for quickly
// clearing the screen to the wallpaper.
if (hasWidget("org.kde.plasma.showdesktop")) {
    dock.addWidget("org.kde.plasma.showdesktop");
}
