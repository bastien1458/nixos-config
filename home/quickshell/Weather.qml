pragma Singleton

import QtQuick
import Quickshell

// Current conditions and a 3 day forecast from wttr.in (location from the
// Nix config, or guessed from the IP when empty). One request per 30 min.
Singleton {
  id: weather

  property bool ready: false
  property bool failed: false
  property string place: ""
  property int temp: 0
  property int feels: 0
  property int humidity: 0
  property int wind: 0
  property string condition: ""
  property string icon: "cloud"
  property var days: []
  property date updated: new Date()

  readonly property string location: Settings.weatherLocation || Theme.config.weatherLocation || ""

  function iconFor(code, night) {
    const c = parseInt(code)
    if (c === 113) return night ? "moon" : "sun"
    if (c === 116) return night ? "night-partly" : "partly"
    if (c === 119 || c === 122) return "cloud"
    if ([143, 248, 260].indexOf(c) >= 0) return "fog"
    if ([200, 386, 389, 392, 395].indexOf(c) >= 0) return "storm"
    if ([179, 227, 230, 323, 326, 329, 332, 335, 338, 368, 371, 374, 377, 350, 362, 365, 182, 317, 320].indexOf(c) >= 0) return "snow"
    return "rain"
  }

  // street names for the weather, Night City style
  function slang(code) {
    const c = parseInt(code)
    if (c === 113) return "CLEAR SKIES"
    if (c === 116) return "BROKEN CLOUDS"
    if (c === 119 || c === 122) return "SMOG CEILING"
    if ([143, 248, 260].indexOf(c) >= 0) return "TOXIC FOG"
    if ([200, 386, 389, 392, 395].indexOf(c) >= 0) return "ELECTRICAL STORM"
    if (iconFor(c, false) === "snow") return "ASH SNOW"
    return "ACID RAIN"
  }

  function refresh() {
    const xhr = new XMLHttpRequest()
    xhr.onreadystatechange = () => {
      if (xhr.readyState !== XMLHttpRequest.DONE) return
      if (xhr.status !== 200) {
        weather.failed = true
        retry.start()
        return
      }
      try {
        weather.apply(JSON.parse(xhr.responseText))
      } catch (error) {
        weather.failed = true
        console.warn("cyberdeck: weather parse error: " + error)
      }
    }
    xhr.open("GET", "https://wttr.in/" + encodeURIComponent(location) + "?format=j1")
    xhr.send()
  }

  function apply(data) {
    const now = data.current_condition[0]
    const hour = new Date().getHours()
    const night = hour < 7 || hour >= 20
    temp = parseInt(now.temp_C)
    feels = parseInt(now.FeelsLikeC)
    humidity = parseInt(now.humidity)
    wind = parseInt(now.windspeedKmph)
    condition = slang(now.weatherCode)
    icon = iconFor(now.weatherCode, night)
    const area = data.nearest_area && data.nearest_area[0]
    place = location !== "" ? location.toUpperCase() : (area ? area.areaName[0].value.toUpperCase() : "NIGHT CITY")
    days = (data.weather || []).slice(0, 3).map(d => ({
      date: d.date,
      min: parseInt(d.mintempC),
      max: parseInt(d.maxtempC),
      icon: iconFor(d.hourly && d.hourly[4] ? d.hourly[4].weatherCode : 116, false)
    }))
    updated = new Date()
    ready = true
    failed = false
  }

  onLocationChanged: refresh()

  Timer {
    interval: 30 * 60 * 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: weather.refresh()
  }

  Timer {
    id: retry
    interval: 5 * 60 * 1000
    onTriggered: weather.refresh()
  }
}
