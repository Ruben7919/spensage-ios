import SwiftUI

struct FlowStack<Content: View>: View {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8
    @ViewBuilder var content: Content

    var body: some View {
        FlowStackLayout(spacing: spacing, rowSpacing: rowSpacing) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FlowStackLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = frames(for: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let layout = frames(for: ProposedViewSize(width: bounds.width, height: proposal.height), subviews: subviews)
        for (index, frame) in layout.frames.enumerated() {
            guard index < subviews.count else { continue }
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func frames(for proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? 10_000
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var contentWidth: CGFloat = 0

        for subview in subviews {
            let ideal = subview.sizeThatFits(.unspecified)
            let itemWidth = min(ideal.width, maxWidth)
            let itemSize = CGSize(width: itemWidth, height: ideal.height)

            if currentX > 0 && currentX + itemSize.width > maxWidth {
                currentX = 0
                currentY += rowHeight + rowSpacing
                rowHeight = 0
            }

            let frame = CGRect(origin: CGPoint(x: currentX, y: currentY), size: itemSize)
            frames.append(frame)

            currentX += itemSize.width + spacing
            rowHeight = max(rowHeight, itemSize.height)
            contentWidth = max(contentWidth, frame.maxX)
        }

        let contentHeight = frames.isEmpty ? 0 : currentY + rowHeight
        return (CGSize(width: contentWidth, height: contentHeight), frames)
    }
}
