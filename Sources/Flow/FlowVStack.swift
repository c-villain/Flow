import SwiftUI

/// Layout component that arranges views in vertical columns and wraps them into new columns when needed.
///
/// A ``FlowVStack`` automatically wraps its content to a new column when it exceeds the available height,
/// similar to `flow` in CSS but oriented vertically. The number of columns can be limited via the ``maxColumns`` parameter.
///
/// ```swift
/// FlowVStack {
///     ForEach(tags, id: \.self) {
///         Text($0)
///     }
/// }
/// ```
///
/// ### Layout behavior
///
/// The layout automatically adapts to the container’s height, distributing child views across columns and wrapping as needed.
///
/// You can configure alignment:
/// - Use `verticalAlignment:` to control how each column is aligned vertically (e.g. `.top`, `.center`, `.bottom`)
/// - Use `horizontalAlignment:` to align views **within** a column (e.g. `.leading`, `.center`, `.trailing`)
///
/// ```swift
/// FlowVStack(
///     horizontalAlignment: .center,
///     verticalAlignment: .top
/// ) {
///     ...
/// }
/// ```
///
/// ### Customizing spacing
///
/// Use `horizontalSpacing:` and `verticalSpacing:` to define the spacing between columns and between items within each column:
///
/// ```swift
/// FlowVStack(
///     horizontalSpacing: 12,
///     verticalSpacing: 8
/// ) {
///     ...
/// }
/// ```
///
/// ### Limiting and observing columns
///
/// You can restrict the number of rendered columns using `maxColumns:` and observe the actual column count with `columnCount:`:
///
/// ```swift
/// @State private var columnCount: Int = 0
///
/// FlowVStack(maxColumns: 2, columnCount: $columnCount) {
///     ...
/// }
/// ```
///
/// If the provided content is empty, ``FlowVStack`` renders as `EmptyView` and does not occupy any space.

public struct FlowVStack<Content: View>: View {
    
    private let horizontalSpacing: CGFloat
    private let verticalSpacing: CGFloat
    private let horizontalAlignment: HorizontalAlignment
    private let verticalAlignment: VerticalAlignment
    private let maxColumns: Int
    @Binding private var columnCount: Int
    @ViewBuilder private let content: Content
    
    public init(
        horizontalSpacing: CGFloat = 8.0,
        verticalSpacing: CGFloat = 8.0,
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .top,
        maxColumns: Int = .max,
        columnCount: Binding<Int> = .constant(1),
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.maxColumns = maxColumns
        self._columnCount = columnCount
        self.content = content()
    }
    
    public var body: some View {
        if #available(iOS 16, *) {
            FlowVStackLayout(
                horizontalSpacing: horizontalSpacing,
                verticalSpacing: verticalSpacing,
                horizontalAlignment: horizontalAlignment,
                verticalAlignment: verticalAlignment,
                maxColumns: maxColumns,
                columnCount: $columnCount
            ) {
                content
            }
        } else {
            FlowVStackLayoutBackported(
                horizontalSpacing: horizontalSpacing,
                verticalSpacing: verticalSpacing,
                horizontalAlignment: horizontalAlignment,
                verticalAlignment: verticalAlignment,
                maxColumns: maxColumns,
                columnCount: $columnCount
            ) {
                content
            }
        }
    }
}

internal struct FlowVStackPreview: View {
    let initMaxColumns: Int = 1
    @State private var maxColumns: Int = 1
    @State private var columnCount: Int = 0
    @State private var isOn: Bool = false
    
    @ViewBuilder
    private func factory(_ name: String) -> some View {
        Toggle(isOn: $isOn) {
            Text(name)
        }
        .padding(.vertical, 4)
    }
    
    var body: some View {
        VStack {
            Text("Tags in a vertical flow")
                .padding(.top, 16.0)
            
            ScrollView(.horizontal) {
                FlowVStack(
                    horizontalSpacing: 8.0,
                    verticalSpacing: 8.0,
                    maxColumns: maxColumns,
                    columnCount: $columnCount
                ) {
                    factory("BMW")
                    factory("Mercedes")
                    factory("Audi")
                    factory("KIA")
                    factory("Toyota")
                    factory("Honda")
                    factory("Ford")
                    factory("Renault")
                    factory("Nissan")
                    factory("Nissan")
                    factory("Nissan")
                    factory("BMW")
                    factory("Mercedes")
                    factory("Audi")
                    factory("KIA")
                    factory("Toyota")
                    factory("Honda")
                    factory("Ford")
                    factory("Renault")
                    factory("Nissan")
                    factory("Nissan")
                    factory("Nissan")
                    factory("BMW")
                    factory("Mercedes")
                    factory("Audi")
                    factory("KIA")
                    factory("Toyota")
                    factory("Honda")
                    factory("Ford")
                    factory("Renault")
                    factory("Nissan")
                    factory("Nissan")
                    factory("Nissan")
                }
                .measured()
                .frame(maxHeight: 400)
                .lineLimit(1)  // Just an example: typically for columns, you'd rarely use lineLimit
                .clipped() // <= ‼️ Don't forget
                .contentShape(Rectangle())
                .padding(16.0)
            }
            
            Text("Total columns: \(columnCount)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {
                withAnimation(.linear(duration: 0.2)) {
                    maxColumns = (maxColumns == Int.max) ? initMaxColumns : Int.max
                }
            } label: {
                Text((maxColumns == Int.max) ? "Show only \(initMaxColumns) columns" : "Expand")
            }
            .padding(.bottom, 16.0)
        }
        .background(Color.yellow.opacity(0.2))
        .cornerRadius(8.0)
        .padding(16.0)
    }
}

struct FlowVStack_Previews: PreviewProvider {
    static var previews: some View {
        FlowVStackPreview()
    }
}
