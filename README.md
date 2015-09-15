# CLLocationMiddleManager

![Swift 2.0https://img.shields.io/badge/Swift-2.0-brightgreen.svg?style=flat-square](https://img.shields.io/badge/Swift-2.0-brightgreen.svg?style=flat-square)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat-square)](https://github.com/Carthage/Carthage)

**CLLocationMiddleManager** lets you spoof location information on devices just like the Simulator does.

Simply replace

```swift
let locationManager = CLLocationManager()
```

with

```swift
let locationManager = CLLocationMiddleManager(file: "my_gpx_route")
```

and it should all _just work_<sup>TM</sup>.

## Installation

**CLLocationMiddleManager** is Carthage-compatible.

```
github "Shrugs/CLLocationMiddleManager" >= 1.0
```

Ignore the warnings about a directory, not sure what's up with those.

## Usage

**CLLocationMiddleManager** works by interpreting a `gpx` file that's included in your app's bundle.

1. Go to [Google Maps](https://maps.google.com) and draw out a route by clicking on the map.
2. Copy the url from Google Maps
3. Go to [Coruscant Consulting's website](http://labs.coruscantconsulting.co.uk/garmin/gpxgmap/convert.php) and paste in your Google Maps link
4. Download the resulting GPX file
5. Open that file up in your favorite text editor (or Xcode)
6. Add `<time>` keys to each `wpt`.
    - For example, a waypoint should look something like `<wpt lat="42.357542" lon="-83.059571"><time>2015-09-13T14:19:35Z</time></wpt>`
    - The time is in the format `yyyy-MM-ddTHH:mm:ssZ`
    - For example, `2015-09-13T14:19:35Z` is a valid time
7. Import that GPX file into Xcode by dragging it into your **Project** pane and making sure to **Copy files if needed**
8. Add something similar to the following code in your app.

```swift

let demoMode = true // this can be a Compiler Flag or anything you want

let locationManager = demoMode ? CLLocationMiddleManager(file: "my_gpx_route") : CLLocationManager()

```

And tada, you're spoofing location on device. Woo!


