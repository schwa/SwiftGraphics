import CoreGraphics

// TODO: Move to Everythung - make generic?

// MARK: Scaling and alignment.

public enum Scaling {
    case none
    case proportionally
    case toFit
}

public enum Alignment {
    case center
    case top // swiftlint:disable:this identifier_name
    case topLeft
    case topRight
    case left
    case bottom
    case bottomLeft
    case bottomRight
    case right
}

public func scaleAndAlignRectToRect(source: CGRect, destination: CGRect, scaling: Scaling, alignment: Alignment) -> CGRect {
    var result = CGRect()
    var theScaledImageSize = source.size

    switch scaling {
    case .toFit:
        return destination

    case .proportionally:
        var theScaleFactor: CGFloat = 1
        if destination.size.width / source.size.width < destination.size.height / source.size.height {
            theScaleFactor = destination.size.width / source.size.width
        }
        else {
            theScaleFactor = destination.size.height / source.size.height
        }
        theScaledImageSize.width *= theScaleFactor
        theScaledImageSize.height *= theScaleFactor

        result.size = theScaledImageSize
    case .none:
        result.size.width = theScaledImageSize.width
        result.size.height = theScaledImageSize.height
    }

    switch alignment {
    case .center:
        result.origin.x = destination.origin.x + (destination.size.width - theScaledImageSize.width) / 2
        result.origin.y = destination.origin.y + (destination.size.height - theScaledImageSize.height) / 2
    case .top:
        result.origin.x = destination.origin.x + (destination.size.width - theScaledImageSize.width) / 2
        result.origin.y = destination.origin.y + destination.size.height - theScaledImageSize.height
    case .topLeft:
        result.origin.x = destination.origin.x
        result.origin.y = destination.origin.y + destination.size.height - theScaledImageSize.height
    case .topRight:
        result.origin.x = destination.origin.x + destination.size.width - theScaledImageSize.width
        result.origin.y = destination.origin.y + destination.size.height - theScaledImageSize.height
    case .left:
        result.origin.x = destination.origin.x
        result.origin.y = destination.origin.y + (destination.size.height - theScaledImageSize.height) / 2
    case .bottom:
        result.origin.x = destination.origin.x + (destination.size.width - theScaledImageSize.width) / 2
        result.origin.y = destination.origin.y
    case .bottomLeft:
        result.origin.x = destination.origin.x
        result.origin.y = destination.origin.y
    case .bottomRight:
        result.origin.x = destination.origin.x + destination.size.width - theScaledImageSize.width
        result.origin.y = destination.origin.y
    case .right:
        result.origin.x = destination.origin.x + destination.size.width - theScaledImageSize.width
        result.origin.y = destination.origin.y + (destination.size.height - theScaledImageSize.height) / 2
    }

    return result
}
