import SwiftUI

/// Custom layout for FlowHStack
/// - Automatically calculates the width of each chip and wraps to a new line if there’s not enough space.
/// - Adapts to the width of the container in which `FlowHStackLayout` resides.
/// - Limits the number of **visible** lines using the `maxLines` parameter (but still lays out all content).
/// - Writes the total number of lines to an external @Binding `lineCount` (including those not visible due to the limit).
///
@available(iOS 16.0, *)
struct FlowHStackLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let maxLines: Int
    @Binding var lineCount: Int

    init(
        horizontalSpacing: CGFloat = 8,
        verticalSpacing: CGFloat = 8,
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .center,
        maxLines: Int = .max,
        lineCount: Binding<Int> = .constant(1)
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.maxLines = maxLines
        self._lineCount = lineCount
    }

    struct CacheData {
        var subviewsToLayout: [LayoutSubview] = []
        var sizes: [CGSize] = []
        var totalSize: CGSize = .zero
    }

    func makeCache(subviews: Subviews) -> CacheData {
        CacheData()
    }

    func updateCache(cache: inout CacheData, subviews: Subviews) {
        // All layout is handled in sizeThatFits and placeSubviews
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var linesUsed = 1

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            // If the element doesn't fit, wrap to the next row
            if currentX + size.width > maxWidth, currentX > 0 {
                totalHeight += currentRowHeight + verticalSpacing
                currentX = 0
                currentRowHeight = 0
                linesUsed += 1

                // Stop if we've reached the max line limit
                if linesUsed > maxLines {
                    break
                }
            }

            currentX += size.width + horizontalSpacing
            currentRowHeight = max(currentRowHeight, size.height)
        }

        if linesUsed <= maxLines {
            totalHeight += currentRowHeight
        } else {
            totalHeight -= verticalSpacing
        }

        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let maxWidth = bounds.width

        // Organize subviews into rows
        var rows: [[(LayoutSubview, CGSize)]] = []
        var currentRow: [(LayoutSubview, CGSize)] = []
        var currentRowWidth: CGFloat = 0

        for subview in subviews {
            var size = subview.sizeThatFits(.unspecified)

            // If view is wider than container, force width to container width
            if size.width > maxWidth {
                size.width = maxWidth
            }

            if currentRowWidth + size.width > maxWidth, !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = []
                currentRowWidth = 0
            }

            currentRow.append((subview, size))
            currentRowWidth += size.width + horizontalSpacing
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        var originY = bounds.minY

        for row in rows {
            DispatchQueue.main.async {
                lineCount = rows.count
            }

            let rowHeight = row.map { $0.1.height }.max() ?? 0
            let rowWidth = row.map { $0.1.width }.reduce(0, +) + CGFloat(row.count - 1) * horizontalSpacing

            let startX: CGFloat
            switch horizontalAlignment {
            case .leading:  startX = bounds.minX
            case .center:   startX = bounds.minX + (bounds.width - rowWidth) / 2
            case .trailing: startX = bounds.maxX - rowWidth
            default:        startX = bounds.minX
            }

            var originX = startX

            for (subview, size) in row {
                let yOffset: CGFloat
                switch verticalAlignment {
                case .top:    yOffset = 0
                case .center: yOffset = (rowHeight - size.height) / 2
                case .bottom: yOffset = rowHeight - size.height
                default:      yOffset = 0
                }

                subview.place(
                    at: CGPoint(x: originX, y: originY + yOffset),
                    proposal: ProposedViewSize(width: size.width, height: size.height)
                )

                originX += size.width + horizontalSpacing
            }

            originY += rowHeight + verticalSpacing
        }
    }
}
