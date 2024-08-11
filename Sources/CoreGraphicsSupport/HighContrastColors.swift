// https://stackoverflow.com/questions/470690/how-to-automatically-generate-n-distinct-colors/4382138#4382138
// P. Green-Armytage (2010): A Colour Alphabet and the Limits of Colour Coding. // Colour: Design & Creativity (5) (2010): 10, 1-23
// https://aic-color.org/resources/Documents/jaic_v5_06.pdf
// https://ui.adsabs.harvard.edu/abs/1989SPIE.1077..322B/abstract
// https://stackoverflow.com/questions/470690/how-to-automatically-generate-n-distinct-colors/4382138#4382138

import SwiftUI

public let kellyColors: [(Float, Float, Float)] = [
    0xFFB300, // Vivid Yellow
    0x803E75, // Strong Purple
    0xFF6800, // Vivid Orange
    0xA6BDD7, // Very Light Blue
    0xC10020, // Vivid Red
    0xCEA262, // Grayish Yellow
    0x817066, // Medium Gray
    0x007D34, // Vivid Green
    0xF6768E, // Strong Purplish Pink
    0x00538A, // Strong Blue
    0xFF7A5C, // Strong Yellowish Pink
    0x53377A, // Strong Violet
    0xFF8E00, // Vivid Orange Yellow
    0xB32851, // Strong Purplish Red
    0xF4C800, // Vivid Greenish Yellow
    0x7F180D, // Strong Reddish Brown
    0x93AA00, // Vivid Yellowish Green
    0x593315, // Deep Yellowish Brown
    0xF13A13, // Vivid Reddish Orange
    0x232C16 // Dark Olive Green
].map { hex in
    let red = hex >> 16 & 0xFF
    let green = hex >> 8 & 0xFF
    let blue = hex & 0xFF
    return (Float(red) / 255, Float(green) / 255, Float(blue) / 255)
}

public extension Color {
    init(rgb: (Float, Float, Float)) {
        self = .init(red: CGFloat(rgb.0), green: CGFloat(rgb.1), blue: CGFloat(rgb.2))
    }
}

// Green-Armytage
// 240,163,255
// 0,117,220
// 153,63,0
// 76,0,92
// 25,25,25
// 0,92,49
// 43,206,72
// 255,204,153
// 128,128,128
// 148,255,181
// 143,124,0
// 157,204,0
// 194,0,136
// 0,51,128
// 255,164,5
// 255,168,187
// 66,102,0
// 255,0,16
// 94,241,242
// 0,153,143
// 224,255,102
// 116,10,255
// 153,0,0
// 255,255,128
// 255,255,0
// 255,80,5
