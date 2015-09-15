//
//  CLLocationMiddleManager.swift
//  CLLocationMiddleManager
//
//  Created by Matt Condon on 9/15/15.
//  Copyright (c) 2015 mattc. All rights reserved.
//

import UIKit
import CoreLocation

class Waypoint : NSObject {
  var time : NSDate = NSDate()
  var lat : Double = 0.0
  var lng : Double = 0.0
}

class CLLocationMiddleManager: CLLocationManager, NSXMLParserDelegate {

  var xmlParser: NSXMLParser!
  var waypoints : [Waypoint] = []
  var timer : NSTimer?

  var timeAtLastWaypoint : NSDate?
  var previousLocation : CLLocation?
  var previousWaypoint : Waypoint?
  var nextWaypoint : Waypoint?

  var latestWaypoint : Waypoint?
  var latestTimeStr : String?

  var lastDataIndex = 0

  // MARK: init

  convenience init(file: String) {
    self.init()

    let path = NSBundle.mainBundle().pathForResource(file, ofType: "gpx")
    let data = NSData(contentsOfFile: path!)

    xmlParser = NSXMLParser(data: data!)
    xmlParser.delegate = self
    xmlParser.parse()
  }

  // MARK: overrides

  override func startUpdatingLocation() {
    timer?.invalidate()
    timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "calculateLocation", userInfo: nil, repeats: true)
  }

  override func stopUpdatingLocation() {
    timer?.invalidate()
    timer = nil
  }

  // MARK: core logic

  func calculateLocation() {
    if previousWaypoint == nil {
      timeAtLastWaypoint = NSDate()
      previousWaypoint = waypoints[lastDataIndex]
      previousLocation = generateNewLocation(previousWaypoint!)
    }
    var nextDataIndex = (lastDataIndex + 1) % waypoints.count
    nextWaypoint = waypoints[nextDataIndex]

    // now extrapolate between waypoints based on time
    let lastLocation = generateNewLocation(previousWaypoint!)
    let nextLocation = generateNewLocation(nextWaypoint!)
    let totalD = lastLocation.distanceFromLocation(nextLocation)
    let deltaT = NSDate().timeIntervalSinceDate(timeAtLastWaypoint!)
    let totalT = nextWaypoint!.time.timeIntervalSinceDate(previousWaypoint!.time)

    if deltaT > totalT {
      // we passed the waypoint, swap 'em
      lastDataIndex = nextDataIndex
      previousWaypoint = nextWaypoint
      nextDataIndex = (lastDataIndex + 1) % waypoints.count
      nextWaypoint = waypoints[nextDataIndex]
      timeAtLastWaypoint = NSDate()
      previousLocation = nextLocation
      return
    }

    // deltaT / totalT = deltaD / totalD
    let deltaD = (deltaT / totalT) * totalD

    let newLocation = previousLocation?.newLocation(atDistance: deltaD, towardsLocation: nextLocation)

    self.delegate?.locationManager!(self, didUpdateLocations: [newLocation!])
  }

  func generateNewLocation(waypoint : Waypoint) -> CLLocation {

    let coord = CLLocationCoordinate2D(latitude: waypoint.lat, longitude: waypoint.lng)

    let altitude = 0.0
    let horizontalAccuracy = 50.0
    let verticalAccuracy = 50.0
    let timestamp = NSDate()

    var location : CLLocation!
    if (false || previousLocation != nil) {
      // @TODO(shrugs) - debug this
      let course = RAD2DEG((previousLocation?.bearingInRadians(towardsLocation: previousLocation!))!)
      location = CLLocation(
        coordinate: coord,
        altitude: 0.0,
        horizontalAccuracy: horizontalAccuracy,
        verticalAccuracy: verticalAccuracy,
        course: course,
        speed: 0.0,
        timestamp: timestamp
      )
    } else {
      location = CLLocation(
        coordinate: coord,
        altitude: altitude,
        horizontalAccuracy: horizontalAccuracy,
        verticalAccuracy: verticalAccuracy,
        timestamp: timestamp
      )
    }

    return location

  }

  // MARK: XML parsing logic for parsing GPX files

  func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
    switch elementName {
    case "wpt":
      latestWaypoint = Waypoint()
      latestWaypoint!.lat = (attributeDict["lat"]! as NSString).doubleValue
      latestWaypoint!.lng = (attributeDict["lon"]! as NSString).doubleValue
    case "time":
      if let _ = latestWaypoint {
        latestTimeStr = ""
      }
    default:
      return
    }

  }

  func parser(parser: NSXMLParser, foundCharacters string: String) {
    if let _ = latestWaypoint {
      if latestTimeStr != nil {
        latestTimeStr! += string
      }
    }
  }

  func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    switch elementName {
    case "wpt":
      latestWaypoint = nil
    case "time":
      if latestWaypoint != nil {
        latestWaypoint?.time = convertDateString(latestTimeStr!)
        latestTimeStr = nil

        waypoints.append(latestWaypoint!)
        latestWaypoint = nil
      }
    default:
      return
    }
  }

  func convertDateString(str: String) -> NSDate {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    formatter.locale = NSLocale.systemLocale()
    return formatter.dateFromString(str)!
  }

}








