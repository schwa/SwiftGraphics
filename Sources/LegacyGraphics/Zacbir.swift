//
//  Zacbir.swift
//  GraphicsDemos
//
//  Created by Jonathan Wight on 4/25/17.
//  Copyright © 2017 schwa.io. All rights reserved.
//

#if os(macOS)
    import AppKit
    import CoreGraphics

    // import Foundation

    func band<T>(_ items: [T], _ value: CGFloat, _ upper: CGFloat, _ lower: CGFloat = 0) -> T {
        let percentile = (value - lower) / (upper - lower)
        var index = Int(round(percentile * CGFloat(items.count - 1)))
        index = clamp(index, lower: items.startIndex, upper: items.endIndex)
        return items[index]
    }

    func gen_color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor {
        NSColor(deviceRed: r / 255, green: g / 255, blue: b / 255, alpha: 1)
    }

    protocol ColorProtocol {
    }

    protocol ColorPaletteProtocol {
        var colors: [ColorProtocol] { get }
    }

    protocol NamedColorPaletteProtocol: ColorPaletteProtocol {
        var namedColors: [String: ColorProtocol] { get }
    }

    protocol CGColorConvertable {
        var cgColor: CGColor { get }
    }

    extension NSColor: ColorProtocol, CGColorConvertable {
    }

    struct Solarized: ColorPaletteProtocol {
        static let base03 = gen_color(0, 43, 54)
        static let base02 = gen_color(7, 54, 66)
        static let base01 = gen_color(88, 110, 117)
        static let base00 = gen_color(101, 123, 131)
        static let base0 = gen_color(131, 148, 150)
        static let base1 = gen_color(147, 161, 161)
        static let base2 = gen_color(238, 232, 213)
        static let base3 = gen_color(253, 246, 227)
        static let yellow = gen_color(181, 137, 0)
        static let orange = gen_color(203, 75, 22)
        static let red = gen_color(220, 50, 47)
        static let magenta = gen_color(211, 54, 130)
        static let violet = gen_color(108, 113, 196)
        static let blue = gen_color(38, 139, 210)
        static let cyan = gen_color(42, 161, 152)
        static let green = gen_color(133, 153, 0)

        var colors: [ColorProtocol] {
            [
                Solarized.base03,
                Solarized.base02,
                Solarized.base01,
                Solarized.base00,
                Solarized.base0,
                Solarized.base1,
                Solarized.base2,
                Solarized.base3,
                Solarized.yellow,
                Solarized.orange,
                Solarized.red,
                Solarized.magenta,
                Solarized.violet,
                Solarized.blue,
                Solarized.cyan,
                Solarized.green,
            ]
        }

        struct Backgrounds: ColorPaletteProtocol {
            var colors: [ColorProtocol] {
                [
                    Solarized.base03,
                    Solarized.base02,
                    Solarized.base2,
                    Solarized.base3,
                ]
            }
        }
    }

//
    // let backgrounds = [base03, base02, base2, base3]
//
    // let strokes = [base01, base00, base0, base1]
//
    // let fills = [magenta, red, orange, yellow, green, cyan, blue, violet]
//
    // let warms = [magenta, red, orange, yellow]
//
    // let cools = [green, cyan, blue, violet]
//
    // let contrast = [(base03, base1), (base3, base01)]
#endif
