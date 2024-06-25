import SwiftUI
import CoreGraphicsSupport

public struct WrappingHStack: Layout {
    public struct Cache {
        var origins: [Int: CGPoint] = [:]
        var sizes: [Int: CGSize] = [:]
    }

    var spacing: CGSize

    public init() {
        self.spacing = CGSize(8, 8)
    }

    public func makeCache(subviews: Subviews) -> Cache {
        var cache = Cache()
        for (index, subview) in subviews.enumerated() {
            let size = cache.sizes[index] ?? subview.sizeThatFits(.unspecified)
            cache.sizes[index] = size
        }
        return cache
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        print(proposal)
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        for (index, _) in subviews.enumerated() {
            let size = cache.sizes[index]!
            if x + size.width > (proposal.width ?? .infinity) {
                x = 0
                y += lineHeight + spacing.height
                lineHeight = 0
            }
            cache.origins[index] = CGPoint(x: x, y: y)

            x += size.width + spacing.width
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, x)
        }

        print(CGSize(width: maxWidth, height: y + lineHeight))
        return CGSize(width: maxWidth, height: y + lineHeight)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        for (index, subview) in subviews.enumerated() {
            let origin = cache.origins[index]!
            let size = cache.sizes[index]!
            subview.place(at: bounds.origin + origin, proposal: .init(size))
        }
    }
}


#Preview {
    let items: [String] = Array(1...20).map { "Item \($0)" }

    WrappingHStack {
        ForEach(items, id: \.self) { item in
            Text(item)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
        }
    }
    .border(Color.red)

}
