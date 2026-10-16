.pragma library

// Hand drawn vector glyphs. `s` is stroked, `f` is filled.
// Icons live on a 24 unit grid, emblems on a 64 unit grid.

var circle = function (cx, cy, r) {
  return "M" + (cx - r) + " " + cy + "a" + r + " " + r + " 0 1 0 " + (2 * r) + " 0a" + r + " " + r + " 0 1 0 " + (-2 * r) + " 0"
}

var speaker = "M3 9h4l5-4v14l-5-4H3z"
var cloud = "M7 17h10a3.5 3.5 0 0 0 .4-6.97A5 5 0 0 0 7.6 8.6 4.2 4.2 0 0 0 7 17z"
var cloudHigh = "M7 14h10a3.5 3.5 0 0 0 .4-6.97A5 5 0 0 0 7.6 5.6 4.2 4.2 0 0 0 7 14z"

var icons = {
  dot: { f: circle(12, 12, 3) },
  volume: { s: speaker + "M15.5 9.5a3.5 3.5 0 0 1 0 5M18 7a7 7 0 0 1 0 10" },
  "volume-low": { s: speaker + "M15.5 9.5a3.5 3.5 0 0 1 0 5" },
  "volume-mute": { s: speaker + "M16 9.5l5 5M21 9.5l-5 5" },
  mic: { s: "M9 3h6v10H9zM5.5 11v1a6.5 6.5 0 0 0 13 0v-1M12 18.5V21M8.5 21h7" },
  "mic-off": { s: "M9 3h6v10H9zM5.5 11v1a6.5 6.5 0 0 0 13 0v-1M12 18.5V21M8.5 21h7M3 3l18 18" },
  play: { f: "M7 4.5v15l12-7.5z" },
  pause: { f: "M6.5 5h4v14h-4zM13.5 5h4v14h-4z" },
  next: { f: "M5 5v14l9-7zM16 5h3v14h-3z" },
  prev: { f: "M19 5v14l-9-7zM5 5h3v14H5z" },
  wifi: { s: "M2 9.5a14.5 14.5 0 0 1 20 0M5.2 12.8a10 10 0 0 1 13.6 0M8.4 16.1a5.4 5.4 0 0 1 7.2 0", f: "M10.8 18.6h2.4V21h-2.4z" },
  lan: { s: "M9 2.5h6v5H9zM12 7.5v4M4 11.5h16M4 11.5v4M12 11.5v4M20 11.5v4M2 15.5h4v5H2zM10 15.5h4v5h-4zM18 15.5h4v5h-4z" },
  offline: { s: "M2 9.5a14.5 14.5 0 0 1 20 0M5.2 12.8a10 10 0 0 1 13.6 0M8.4 16.1a5.4 5.4 0 0 1 7.2 0M3 3l18 18" },
  bell: { s: "M6 16.5V11a6 6 0 0 1 12 0v5.5l2 2H4zM10 21.5h4" },
  "bell-off": { s: "M6 16.5V11a6 6 0 0 1 12 0v5.5l2 2H4zM10 21.5h4M3 3l18 18" },
  calendar: { s: "M3.5 5.5h17v15h-17zM3.5 10h17M8 3v5M16 3v5", f: "M7 13h3v3H7z" },
  sun: { s: circle(12, 12, 4) + "M12 2v2.5M12 19.5V22M2 12h2.5M19.5 12H22M4.9 4.9l1.8 1.8M17.3 17.3l1.8 1.8M4.9 19.1l1.8-1.8M17.3 6.7l1.8-1.8" },
  moon: { s: "M20 14.5A8.5 8.5 0 1 1 9.5 4a6.8 6.8 0 0 0 10.5 10.5z" },
  cloud: { s: cloud },
  partly: { s: "M7 4.5v1.6M2.6 9H4.2M3.9 5.9l1.1 1.1M10.1 5.9L9 7M4.6 10.8a3 3 0 0 1 4.6-3.5" + "M8 20h9.5a3.2 3.2 0 0 0 .4-6.37A4.6 4.6 0 0 0 9 12.5a3.8 3.8 0 0 0-1 7.5z" },
  "night-partly": { s: "M10.5 8.2A4 4 0 0 1 5.3 3.5a4.2 4.2 0 0 0 5.2 4.7z" + "M8 20h9.5a3.2 3.2 0 0 0 .4-6.37A4.6 4.6 0 0 0 9 12.5a3.8 3.8 0 0 0-1 7.5z" },
  rain: { s: cloudHigh + "M8 17l-1.5 4M12 17l-1.5 4M16 17l-1.5 4" },
  snow: { s: cloudHigh + "M8 17.5v3M6.5 19h3M15.5 17.5v3M14 19h3", f: "M11.2 19.2h1.6v1.6h-1.6z" },
  storm: { s: cloudHigh, f: "M12.5 14l-3.5 5h2.5l-1 4 4.5-6h-2.6l1.1-3z" },
  fog: { s: "M4 8h16M2.5 12h19M5 16h14M8 20h8" },
  wind: { s: "M3 8.5h10.5a2.8 2.8 0 1 0-2.8-2.8M3 12.5h15a3 3 0 1 1-3 3M3 16.5h7" },
  drop: { s: "M12 3l5.2 8.3a6 6 0 1 1-10.4 0z" },
  temp: { s: "M10 4a2 2 0 0 1 4 0v9.3a4 4 0 1 1-4 0zM12 9v7" },
  lock: { s: "M5.5 10.5h13v10h-13zM8 10.5V7.5a4 4 0 0 1 8 0v3M12 14v3" },
  unlock: { s: "M5.5 10.5h13v10h-13zM8 10.5V7.5a4 4 0 0 1 7.6-1.8M12 14v3" },
  power: { s: "M12 2.5v9M6.8 6a7.5 7.5 0 1 0 10.4 0" },
  chip: { s: "M6.5 6.5h11v11h-11zM9 2.5v4M12 2.5v4M15 2.5v4M9 17.5v4M12 17.5v4M15 17.5v4M2.5 9h4M2.5 12h4M2.5 15h4M17.5 9h4M17.5 12h4M17.5 15h4", f: "M10 10h4v4h-4z" },
  matrix: { s: "M3 3h5v5H3zM16 3h5v5h-5zM9.5 9.5h5v5h-5zM3 16h5v5H3zM16 16h5v5h-5z", f: "M9.5 3h5v5h-5zM3 9.5h5v5H3zM16 9.5h5v5h-5zM9.5 16h5v5h-5z" },
  close: { s: "M6 6l12 12M18 6L6 18" },
  left: { s: "M15 5l-7 7 7 7" },
  right: { s: "M9 5l7 7-7 7" },
  up: { s: "M5 15l7-7 7 7" },
  down: { s: "M5 9l7 7 7-7" },
  eye: { s: "M2 12s3.8-6.5 10-6.5S22 12 22 12s-3.8 6.5-10 6.5S2 12 2 12z", f: circle(12, 12, 3) },
  "eye-off": { s: "M2 12s3.8-6.5 10-6.5S22 12 22 12s-3.8 6.5-10 6.5S2 12 2 12zM3 3l18 18" },
  user: { s: circle(12, 8, 4) + "M4 21v-1.5A5.5 5.5 0 0 1 9.5 14h5a5.5 5.5 0 0 1 5.5 5.5V21" },
  refresh: { s: "M20 12a8 8 0 1 1-2.4-5.7M20 3.5v5.5h-5.5" },
  skull: { s: "M5 11.5a7 7 0 0 1 14 0v4l-2 1.2V20H7v-3.3l-2-1.2zM10 20v1.5M14 20v1.5", f: "M8 11h3v3H8zM13 11h3v3h-3z" },
  trash: { s: "M4 6.5h16M9 6.5V3.5h6v3M6 6.5l1 14h10l1-14M10 10v7M14 10v7" },
  monitor: { s: "M3 4h18v12H3zM8 20.5h8M12 16v4.5" },
  image: { s: "M3 4.5h18v15H3zM3 16l5-5.5 4.5 4.5 3-3 5.5 5.5", f: circle(15.5, 8.5, 1.7) },
  music: { s: "M9 18V5.5l11-2.5v13M9 18a2.8 2.8 0 1 1-5.6 0 2.8 2.8 0 1 1 5.6 0zM20 16a2.8 2.8 0 1 1-5.6 0 2.8 2.8 0 1 1 5.6 0z" },
  ram: { s: "M2.5 7h19v10h-19zM6 10v4M10 10v4M14 10v4M18 10v4M5 17v3M19 17v3" },
  menu: { s: "M4 6h16M4 12h16M4 18h10" },
  terminal: { s: "M3 4h18v16H3zM7 9l3 3-3 3M12 15h5" },
  bolt: { f: "M13.5 2L5 13.5h6L9.5 22 19 9.5h-6.3z" },
  shield: { s: "M12 2.5l8 3v6c0 5-3.4 8.6-8 10-4.6-1.4-8-5-8-10v-6z" },
  wallet: { s: "M3 7h18v13H3zM3 7l13-4v4M15 12h6v4h-6z" },
  hack: { s: "M4 4h16v16H4zM8 9l3 3-3 3M13 15h3" },
  check: { s: "M4 12.5l5 5L20 6.5" }
}

// The Blackwall has no manufacturer, hence no official logo: it keeps a drawn emblem.
// Every corporation uses its official logo instead (see Logo.qml / OsBadge.qml).
var emblems = {
  blackwall: {
    s: "M4 10h56v44H4zM4 21h56M4 32h56M4 43h56M18 10v11M44 10v11M10 21v11M50 21v11M18 32v11M44 32v11M10 43v11M50 43v11",
    f: "M29 4l7 13-8 9 10 11-7 19 2 0 9-19-9-11 8-9-8-13z"
  }
}
