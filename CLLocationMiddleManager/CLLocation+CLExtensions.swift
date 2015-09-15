//
//  CLLocation+CLExtensions.swift
//  CLLocationMiddleManager
//
//  Created by Matt Condon on 9/15/15.
//  Copyright (c) 2015 mattc. All rights reserved.
//

import CoreLocation
import Darwin

let kPi = M_PI

func DEG2RAD(degrees: Double) -> Double {
  return degrees * 0.01745327
}

func RAD2DEG(radians: Double) -> Double {
  return radians * 57.2957795
}

extension CLLocation {

  func bearingInRadians(#towardsLocation : CLLocation) -> Double {
    let lat1 = DEG2RAD(self.coordinate.latitude)
    let lon1 = DEG2RAD(self.coordinate.longitude)
    let lat2 = DEG2RAD(towardsLocation.coordinate.latitude)
    let lon2 = DEG2RAD(towardsLocation.coordinate.longitude)

    let dLon = lon2 - lon1
    let y = sin(dLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
    var bearing = atan2(y, x) + (2 * kPi)
    if bearing > (2 * kPi) {
      bearing = bearing - (2 * kPi)
    }
    return bearing
  }

  func newLocation(atDistance distance: Double, alongBearingInRadians bearingInRadians: Double) -> CLLocation {
    // This code translated to Swift from https://github.com/johnmckerrell/LocationManagerSimulator

    // calculate an endpoint given a startpoint, bearing and distance
    // Vincenty 'Direct' formula based on the formula as described at http://www.movable-type.co.uk/scripts/latlong-vincenty-direct.html
    // original JavaScript implementation © 2002-2006 Chris Veness

    let lat1 = DEG2RAD(self.coordinate.latitude)
    let lon1 = DEG2RAD(self.coordinate.longitude)


    let a = 6378137.0, b = 6356752.3142, f = 1.0/298.257223563;
    let s = distance
    let alpha1 = bearingInRadians
    let sinAlpha1 = sin(alpha1)
    let cosAlpha1 = cos(alpha1)

    let tanU1 = (1 - f) * tan(lat1);
    let cosU1 = 1 / sqrt((1 + tanU1 * tanU1));
    let sinU1 = tanU1 * cosU1;
    let sigma1 = atan2(tanU1, cosAlpha1);
    let sinAlpha = cosU1 * sinAlpha1;
    let cosSqAlpha = 1 - sinAlpha * sinAlpha;
    let uSq = cosSqAlpha * (a * a - b * b) / (b * b);
    let A = 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
    let B = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));

    var sigma = s / (b * A)
    var sigmaP = 2 * kPi

    var cos2SigmaM : Double!
    var sinSigma : Double!
    var cosSigma : Double!

    while abs(sigma - sigmaP) > 1e-12 {
      cos2SigmaM = cos(2 * sigma1 + sigma);
      sinSigma = sin(sigma);
      cosSigma = cos(sigma);
      let deltaSigma = B * sinSigma * (cos2SigmaM + B / 4 * (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) - B / 6 * cos2SigmaM * (-3 + 4 * sinSigma * sinSigma) * (-3 + 4 * cos2SigmaM * cos2SigmaM)));
      sigmaP = sigma;
      sigma = s / (b * A) + deltaSigma;
    }

    let tmp = sinU1 * sinSigma - cosU1 * cosSigma * cosAlpha1
    let lat2 = atan2(sinU1 * cosSigma + cosU1 * sinSigma * cosAlpha1, (1 - f) * sqrt(sinAlpha * sinAlpha + tmp * tmp));
    let lambda = atan2(sinSigma * sinAlpha1, cosU1 * cosSigma - sinU1 * sinSigma * cosAlpha1)
    let C = f / 16 * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha))
    let L = lambda - (1 - C) * f * sinAlpha * (sigma + C * sinSigma * (cos2SigmaM + C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)))

    let lon2 = lon1 + L
    return CLLocation(latitude: RAD2DEG(lat2), longitude: RAD2DEG(lon2))
  }

  func newLocation(atDistance distance: Double, towardsLocation: CLLocation) -> CLLocation {
    let bearing = self.bearingInRadians(towardsLocation: towardsLocation)
    return self.newLocation(atDistance: distance, alongBearingInRadians: bearing)
  }
  
}

