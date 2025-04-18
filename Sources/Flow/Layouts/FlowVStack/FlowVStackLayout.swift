import SwiftUI

/// Custom layout for FlowVStackLayout
/// - Automatically calculates the height of each item and wraps to a new column if there’s not enough vertical space.
/// - Adapts to the height of the container in which `FlowVStackLayout` resides.
/// - Limits the number of **visible** columns using the `maxColumns` parameter (but still lays out all content).
/// - Writes the total number of columns to an external @Binding `columnCount` (including those not visible due to the limit).
///

@available(iOS 16.0, *)
struct FlowVStackLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let maxColumns: Int
    @Binding var columnCount: Int

    init(
        horizontalSpacing: CGFloat = 8,
        verticalSpacing: CGFloat = 8,
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .top,
        maxColumns: Int = .max,
        columnCount: Binding<Int> = .constant(1)
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.maxColumns = maxColumns
        self._columnCount = columnCount
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
        // Same as FlowRowLayout, all calculations are done in sizeThatFits/placeSubviews
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        // Base layout on the height of the container
        let maxHeight = proposal.height ?? .infinity

        var currentY: CGFloat = 0
        var currentColumnWidth: CGFloat = 0
        var totalWidth: CGFloat = 0
        var columnsUsed = 1

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            // If the current item doesn't fit in the column height,
            // move to the next column.
            if currentY + size.height > maxHeight, currentY > 0 {
                // Close the previous column
                totalWidth += currentColumnWidth + horizontalSpacing
                currentY = 0
                currentColumnWidth = 0
                columnsUsed += 1

                // No need to continue if we exceed maxColumns
                if columnsUsed > maxColumns {
                    break
                }
            }

            currentY += size.height + verticalSpacing
            currentColumnWidth = max(currentColumnWidth, size.width)
        }

        if columnsUsed <= maxColumns {
            // Add width of the last column
            totalWidth += currentColumnWidth
        } else {
            // Remove the last horizontalSpacing
            totalWidth -= horizontalSpacing
        }

        // Height is either constrained by proposal or computed as the max used
        let usedHeight = min(maxHeight, proposal.height ?? .infinity)

        return CGSize(width: totalWidth, height: usedHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let maxHeight = bounds.height

        // Organize subviews into "columns"
        var columns: [[(LayoutSubview, CGSize)]] = []
        var currentColumn: [(LayoutSubview, CGSize)] = []
        var currentColumnHeight: CGFloat = 0

        for subview in subviews {
            var size = subview.sizeThatFits(.unspecified)

            // If the item is taller than the container, forcibly reduce height
            // so it fits somehow (same logic as in FlowRowLayout)
            if size.height > maxHeight {
                size.height = maxHeight
            }

            if currentColumnHeight + size.height > maxHeight, !currentColumn.isEmpty {
                columns.append(currentColumn)
                currentColumn = []
                currentColumnHeight = 0
            }

            currentColumn.append((subview, size))
            currentColumnHeight += size.height + verticalSpacing
        }

        if !currentColumn.isEmpty {
            columns.append(currentColumn)
        }

        // Position columns horizontally
        var originX = bounds.minX

        for column in columns {
            // Update columnCount asynchronously (first pass gives final count)
            DispatchQueue.main.async {
                columnCount = columns.count
            }

            let columnWidth = column.map { $0.1.width }.max() ?? 0
            let columnHeight = column.map { $0.1.height }.reduce(0, +)
                + CGFloat(column.count - 1) * verticalSpacing

            // Calculate vertical start point using vertical alignment
            let startY: CGFloat
            switch verticalAlignment {
            case .top:
                startY = bounds.minY
            case .center:
                startY = bounds.minY + (bounds.height - columnHeight) / 2
            case .bottom:
                startY = bounds.maxY - columnHeight
            default:
                startY = bounds.minY
            }

            var originY = startY

            // Place elements inside the column
            for (subview, size) in column {
                let xOffset: CGFloat
                switch horizontalAlignment {
                case .leading:
                    xOffset = 0
                case .center:
                    xOffset = (columnWidth - size.width) / 2
                case .trailing:
                    xOffset = columnWidth - size.width
                default:
                    xOffset = 0
                }

                subview.place(
                    at: CGPoint(x: originX + xOffset, y: originY),
                    proposal: ProposedViewSize(width: size.width, height: size.height)
                )

                originY += size.height + verticalSpacing
            }

            originX += columnWidth + horizontalSpacing
        }
    }
}
