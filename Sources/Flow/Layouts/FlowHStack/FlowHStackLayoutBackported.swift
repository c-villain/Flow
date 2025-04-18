import SwiftUI

/// Custom layout for FlowHStack in the implementation for iOS < 16
/// - Automatically calculates the width of each chip and wraps to a new line if there’s not enough space.
/// - Adapts to the width of the container in which `FlowHStackLayoutBackported` resides.
/// - Limits the number of **visible** lines using the `maxLines` parameter (but still lays out all content).
/// - Writes the total number of lines to an external @Binding `lineCount` (including those not visible due to the limit).
///
struct FlowHStackLayoutBackported<Content: View>: View {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let maxLines: Int
    @Binding var lineCount: Int

    private let content: () -> Content

    init(
        horizontalSpacing: CGFloat = 8,
        verticalSpacing: CGFloat = 8,
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .center,
        maxLines: Int = .max,
        lineCount: Binding<Int> = .constant(1),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.maxLines = maxLines
        self._lineCount = lineCount
        self.content = content
    }

    var body: some View {
        _VariadicView.Tree(
            FlowWrapper(
                horizontalSpacing: horizontalSpacing,
                verticalSpacing: verticalSpacing,
                horizontalAlignment: horizontalAlignment,
                verticalAlignment: verticalAlignment,
                maxLines: maxLines,
                lineCount: $lineCount
            )
        ) {
            content()
        }
    }

    // MARK: - Private layout handler

    private struct FlowWrapper: _VariadicView_UnaryViewRoot {

        @Environment(\.animation) private var animation: Animation?

        let horizontalSpacing: CGFloat
        let verticalSpacing: CGFloat
        let horizontalAlignment: HorizontalAlignment
        let verticalAlignment: VerticalAlignment
        let maxLines: Int
        @Binding var lineCount: Int

        /// Stores the size of each element after measurement.
        @State private var sizes: [_VariadicView_Children.Element.ID: CGSize] = [:]

        /// Stores the calculated position (x,y) of each element.
        @State private var positions: [_VariadicView_Children.Element.ID: CGPoint] = [:]

        /// Final height of the container.
        @State private var totalHeight: CGFloat = 0

        func body(children: _VariadicView.Children) -> some View {
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    // 1) Invisible measurement pass
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
                                                containerWidth: geo.size.width,
                                                maxLines: maxLines
                                            )
                                        }
                                }
                            )
                    }

                    // 2) Actual rendering using calculated positions
                    ForEach(children) { child in
                        if let pos = positions[child.id],
                           let sz = sizes[child.id] {
                            child
                                .frame(width: sz.width, height: sz.height)
                                .position(pos)
                        }
                    }
                }
                .valueChanged(of: maxLines) {
                    recalcLayout(
                        children: children,
                        containerWidth: geo.size.width,
                        maxLines: $0
                    )
                }
            }
            .frame(height: totalHeight)
        }

        // MARK: - Helper methods

        private func updateSize(
            for item: _VariadicView_Children.Element,
            children: _VariadicView.Children,
            size: CGSize,
            containerWidth: CGFloat,
            maxLines: Int
        ) {
            // Clip width if the item is wider than the container
            sizes[item.id] = size.width > containerWidth
            ? .init(width: containerWidth, height: size.height)
            : size
            recalcLayout(children: children, containerWidth: containerWidth, maxLines: maxLines)
        }

        /// Recalculating the layout:
        ///  - Determine the total number of lines `neededLines` (`lineCount`) required for all content.
        ///  - Position ALL elements at their actual coordinates (including those that exceed `maxLines`).
        ///  - But set the container height to `min(neededLines, maxLines)`.

        private func recalcLayout(children: _VariadicView.Children, containerWidth: CGFloat, maxLines: Int) {
            // Store line structures: array of IDs + max height per line
            var lines: [[_VariadicView_Children.Element.ID]] = []
            var lineHeights: [CGFloat] = []
            var lineWidths: [CGFloat] = []

            // Current line
            var currentLineIDs: [_VariadicView_Children.Element.ID] = []
            var currentLineWidth: CGFloat = 0
            var currentLineHeight: CGFloat = 0

            // 1) Break into lines (ignoring maxLines, as we need to measure all)
            for child in children {
                let sz = sizes[child.id] ?? .zero

                // Check if the element fits in the current line
                if !currentLineIDs.isEmpty,
                   currentLineWidth + sz.width + horizontalSpacing > containerWidth {
                    // Finalize the previous line
                    lines.append(currentLineIDs)
                    lineHeights.append(currentLineHeight)
                    lineWidths.append(currentLineWidth)

                    // Start a new line
                    currentLineIDs = [child.id]
                    currentLineWidth = sz.width
                    currentLineHeight = sz.height
                } else {
                    // Add element to the current line
                    currentLineIDs.append(child.id)
                    if currentLineIDs.count > 1 {
                        currentLineWidth += horizontalSpacing
                    }
                    currentLineWidth += sz.width
                    currentLineHeight = max(currentLineHeight, sz.height)
                }
            }
            if !currentLineIDs.isEmpty {
                lines.append(currentLineIDs)
                lineHeights.append(currentLineHeight)
                lineWidths.append(currentLineWidth)
            }

            let neededLines = lines.count

            // Report full line count
            DispatchQueue.main.async {
                self.lineCount = neededLines
            }

            // 2) Position all elements using their actual coordinates
            var newPositions: [_VariadicView_Children.Element.ID: CGPoint] = [:]
            var currentY: CGFloat = 0

            for lineIndex in 0..<neededLines {
                let line = lines[lineIndex]
                let lineHeight = lineHeights[lineIndex]
                let lineWidth = lineWidths[lineIndex]

                let xOffset: CGFloat
                switch horizontalAlignment {
                case .leading:
                    xOffset = 0
                case .center:
                    xOffset = max((containerWidth - lineWidth) / 2, 0)
                case .trailing:
                    xOffset = max(containerWidth - lineWidth, 0)
                default:
                    xOffset = 0
                }

                var currentX = xOffset

                for childID in line {
                    let sz = sizes[childID] ?? .zero

                    let yOffset: CGFloat
                    switch verticalAlignment {
                    case .top:
                        yOffset = 0
                    case .center:
                        yOffset = (lineHeight - sz.height) / 2
                    case .bottom:
                        yOffset = lineHeight - sz.height
                    default:
                        yOffset = 0
                    }

                    let pos = CGPoint(
                        x: currentX + sz.width / 2,
                        y: currentY + yOffset + sz.height / 2
                    )

                    newPositions[childID] = pos
                    currentX += sz.width + horizontalSpacing
                }

                currentY += lineHeight + verticalSpacing
            }

            if neededLines > 0 {
                currentY -= verticalSpacing
            }

            // 3) Container height accounts for only first maxLines
            let visibleLines = min(neededLines, maxLines)
            let finalHeight: CGFloat = {
                guard neededLines > 0 && visibleLines > 0 else { return 0 }
                let visibleHeights = Array(lineHeights.prefix(visibleLines))
                let sumHeights = visibleHeights.reduce(0, +)
                let sumSpacings = CGFloat(visibleLines - 1) * verticalSpacing
                return sumHeights + sumSpacings
            }()

            DispatchQueue.main.async {
                positions = newPositions
                withAnimation(animation ?? .none) {
                    totalHeight = max(finalHeight, 0)
                }
            }
        }
    }
}
