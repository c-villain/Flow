import SwiftUI

/// Custom layout for FlowVStack in the implementation for iOS < 16
/// - Automatically calculates the height of each item and wraps to a new column if there’s not enough vertical space.
/// - Adapts to the height of the container in which `FlowVStackLayoutBackported` resides.
/// - Limits the number of **visible** columns using the `maxColumns` parameter (but still lays out all content).
/// - Writes the total number of columns to an external @Binding `columnCount` (including those not visible due to the limit).
///
struct FlowVStackLayoutBackported<Content: View>: View {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let maxColumns: Int
    @Binding var columnCount: Int

    private let content: () -> Content

    init(
        horizontalSpacing: CGFloat = 8,
        verticalSpacing: CGFloat = 8,
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .top,
        maxColumns: Int = .max,
        columnCount: Binding<Int> = .constant(1),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.maxColumns = maxColumns
        self._columnCount = columnCount
        self.content = content
    }

    var body: some View {
        _VariadicView.Tree(
            FlowColumnWrapper(
                horizontalSpacing: horizontalSpacing,
                verticalSpacing: verticalSpacing,
                horizontalAlignment: horizontalAlignment,
                verticalAlignment: verticalAlignment,
                maxColumns: maxColumns,
                columnCount: $columnCount
            )
        ) {
            content()
        }
    }

    // MARK: - Private wrapper type

    private struct FlowColumnWrapper: _VariadicView_UnaryViewRoot {
        @Environment(\.animation) private var animation: Animation?

        let horizontalSpacing: CGFloat
        let verticalSpacing: CGFloat
        let horizontalAlignment: HorizontalAlignment
        let verticalAlignment: VerticalAlignment
        let maxColumns: Int
        @Binding var columnCount: Int

        /// Store the measured “natural” size of each element.
        @State private var sizes: [_VariadicView_Children.Element.ID: CGSize] = [:]

        /// Store the final position of each element.
        @State private var positions: [_VariadicView_Children.Element.ID: CGPoint] = [:]

        /// Final width of the container.
        @State private var totalWidth: CGFloat = 0

        func body(children: _VariadicView.Children) -> some View {
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    // 1) Invisible pass to measure each element:
                    ForEach(children) { child in
                        child
                            .fixedSize()
                            .opacity(0)
                            .background(
                                GeometryReader { proxy in
                                    Color.clear
                                        .onAppear {
                                            updateSize(
                                                for: child,
                                                children: children,
                                                size: proxy.size,
                                                containerHeight: geo.size.height
                                            )
                                        }
                                }
                            )
                    }

                    // 2) Actual rendering: place views using calculated coordinates.
                    ForEach(children) { child in
                        if let pos = positions[child.id],
                           let sz = sizes[child.id] {
                            child
                                .frame(width: sz.width, height: sz.height)
                                .position(pos) // Center coordinate
                        }
                    }
                }
                .valueChanged(of: maxColumns) { newMaxColumns in
                    recalcLayout(
                        children: children,
                        containerHeight: geo.size.height,
                        maxColumns: newMaxColumns
                    )
                }
            }
            .frame(width: totalWidth)
            .clipped()
        }

        // MARK: - Measuring and layout logic

        private func updateSize(
            for item: _VariadicView_Children.Element,
            children: _VariadicView.Children,
            size: CGSize,
            containerHeight: CGFloat
        ) {
            // If an item is “taller” than the container, clip it forcibly.
            sizes[item.id] = size.height > containerHeight
            ? CGSize(width: size.width, height: containerHeight)
            : size

            // Recalculate layout after every update.
            recalcLayout(
                children: children,
                containerHeight: containerHeight,
                maxColumns: maxColumns
            )
        }

        /// Main layout method:
        ///  1) Split all elements into columns (ignoring `maxColumns` to determine the actual count).
        ///  2) Determine the total number of columns (`neededColumns`) and pass it out via `columnCount`.
        ///  3) Lay out all elements by calculating their coordinates (even those beyond `maxColumns`).
        ///  4) Final width = the sum of the widths of the first `min(neededColumns, maxColumns)` columns + spacing.

        private func recalcLayout(
            children: _VariadicView.Children,
            containerHeight: CGFloat,
            maxColumns: Int
        ) {
            var columns: [[_VariadicView_Children.Element.ID]] = []
            var columnWidths: [CGFloat] = []
            var columnHeights: [CGFloat] = []

            // Current column
            var currentColumnIDs: [_VariadicView_Children.Element.ID] = []
            var currentColumnWidth: CGFloat = 0
            var currentColumnHeight: CGFloat = 0

            // 1) Split into columns as long as containerHeight allows.
            for child in children {
                let sz = sizes[child.id] ?? .zero

                // If the item doesn't fit in the current column, start a new one:
                if !currentColumnIDs.isEmpty,
                   currentColumnHeight + sz.height + verticalSpacing > containerHeight {
                    // Finalize the previous column
                    columns.append(currentColumnIDs)
                    columnWidths.append(currentColumnWidth)
                    columnHeights.append(currentColumnHeight)

                    // Start a new one
                    currentColumnIDs = [child.id]
                    currentColumnWidth = sz.width
                    currentColumnHeight = sz.height
                } else {
                    // Add item to the current column
                    currentColumnIDs.append(child.id)

                    if currentColumnIDs.count > 1 {
                        // Add verticalSpacing only between elements
                        currentColumnHeight += verticalSpacing
                    }
                    currentColumnHeight += sz.height
                    currentColumnWidth = max(currentColumnWidth, sz.width)
                }
            }
            // Append the final column if any elements remain
            if !currentColumnIDs.isEmpty {
                columns.append(currentColumnIDs)
                columnWidths.append(currentColumnWidth)
                columnHeights.append(currentColumnHeight)
            }

            let neededColumns = columns.count

            // Report the total number of columns
            DispatchQueue.main.async {
                self.columnCount = neededColumns
            }

            // 2) Position all elements (even those beyond maxColumns).
            var newPositions: [_VariadicView_Children.Element.ID: CGPoint] = [:]

            // Current X coordinate
            var originX = CGFloat.zero

            for (colIndex, column) in columns.enumerated() {
                let colWidth = columnWidths[colIndex]
                let colHeight = columnHeights[colIndex]

                // Calculate vertical offset for the whole column to apply verticalAlignment
                let yOffset: CGFloat
                switch verticalAlignment {
                case .top:
                    yOffset = 0
                case .center:
                    yOffset = max((containerHeight - colHeight) / 2, 0)
                case .bottom:
                    yOffset = max(containerHeight - colHeight, 0)
                default:
                    yOffset = 0
                }

                // Position elements from top to bottom
                var currentY = yOffset
                for childID in column {
                    let sz = sizes[childID] ?? .zero
                    let pos = CGPoint(
                        x: originX + sz.width / 2,
                        y: currentY + sz.height / 2
                    )
                    newPositions[childID] = pos

                    currentY += sz.height + verticalSpacing
                }

                // Shift X for the next column
                originX += colWidth + horizontalSpacing
            }

            // Remove the last extra spacing if columns > 0
            if neededColumns > 0 {
                originX -= horizontalSpacing
            }

            // 3) Final width is calculated using the first `visibleColumns` (or all if fewer).
            let visibleColumns = min(neededColumns, maxColumns)

            // Total width of visible columns + spacing between them
            let finalWidth: CGFloat = {
                guard neededColumns > 0 && visibleColumns > 0 else {
                    return 0
                }
                let visibleWidths = Array(columnWidths.prefix(visibleColumns))
                let widthSum = visibleWidths.reduce(0, +)
                let totalSpacing = CGFloat(visibleColumns - 1) * horizontalSpacing
                return widthSum + totalSpacing
            }()

            // 4) Apply horizontal alignment to the whole set of columns
            //    (e.g. center or trailing alignment of the whole block of columns)
            //    To do this, we calculate a shift (startX) and apply it to each element.
            let totalUsedWidth = originX > 0 ? originX : finalWidth
            let startX: CGFloat
            switch horizontalAlignment {
            case .leading:
                startX = 0
            case .center:
                startX = max((totalUsedWidth < finalWidth ? finalWidth : totalUsedWidth)
                             .difference(from: finalWidth) / 2, 0)
            case .trailing:
                startX = max((totalUsedWidth < finalWidth ? finalWidth : totalUsedWidth)
                             .difference(from: finalWidth), 0)
            default:
                startX = 0
            }

            // Update positions with startX offset
            for (id, pos) in newPositions {
                newPositions[id] = CGPoint(x: pos.x + startX, y: pos.y)
            }

            // Update positions and width (with animation if available)
            DispatchQueue.main.async {
                self.positions = newPositions
                withAnimation(animation ?? .none) {
                    self.totalWidth = max(finalWidth, 0)
                }
            }
        }
    }
}

// Convenience method for subtraction:
private extension CGFloat {
    func difference(from other: CGFloat) -> CGFloat {
        self - other
    }
}
