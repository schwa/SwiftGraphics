//
//  File.swift
//  
//
//  Created by Jonathan Wight on 9/16/23.
//

import Foundation

func degreesToRadians<T>(_ angle: T) -> T where T: FloatingPoint {
    angle * .pi / 180
}

func radiansToDegrees<T>(_ angle: T) -> T where T: FloatingPoint {
    angle * 180 / .pi
}
