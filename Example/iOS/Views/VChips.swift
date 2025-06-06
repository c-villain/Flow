import SwiftUI
import Flow

struct VChipsView: View {
    
    let initMaxColumns: Int = 1
    @State private var maxColumns: Int = 1
    @State private var columnCount: Int = 0
    @State private var inputText: String = ""

    @State private var tags: [String] = [
        "Porsche AG",
        "BMW",
        "Mercedes",
        "Audi",
        "KIA",
        "Toyota",
        "Honda",
        "Ford",
        "Renault",
        "Nissan",
        "Chevrolet",
        "Volvo",
        "Mitsubishi",
        "Subaru",
        "Lexus",
        "Chrysler",
        "Acura",
        "Jeep"
    ]
    
    @State private var hAlignment: HorizontalAlignment = .leading
    @State private var horizontalSpacing: CGFloat = 8.0
    @State private var verticalSpacing: CGFloat = 8.0

    private var alignments: [(title: String, value: HorizontalAlignment)] = [
        ("Leading", .leading),
        ("Center", .center),
        ("Trailing", .trailing)
    ]
    
    private func radioButton(title: String, value: HorizontalAlignment) -> some View {
        Button(action: {
            hAlignment = value
        }) {
            HStack {
                Image(systemName: hAlignment == value ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(hAlignment == value ? .blue : .gray)
                Text(title)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func factory(_ name: String) -> some View {
        HStack(spacing: 6) {
            Text(name)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                tags.removeAll { $0 == name }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .strokeBorder(Color.black, lineWidth: 2)
                .background(Capsule().fill(Color.white))
        )
    }

    var body: some View {
        let animation: Animation = .linear
        
        ScrollView {
            VStack {
                VStack {
                    // Input
                    HStack {
                        TextField(
                            "Add tag",
                            text: $inputText,
                            onEditingChanged: { _ in },
                            onCommit: { addTag() }
                        )
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding()
                    
                    // MARK: Spacing Controls
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Horizontal spacing: \(Int(horizontalSpacing))")
                        Slider(value: $horizontalSpacing, in: 0...32, step: 1)
                        
                        Text("Vertical spacing: \(Int(verticalSpacing))")
                        Slider(value: $verticalSpacing, in: 0...32, step: 1)
                        
                        Text("Alignment:")
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(alignments, id: \.title) { item in
                                radioButton(title: item.title, value: item.value)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
                .background(Color(hex: "#d8f3e8"))
                
                .cornerRadius(16.0)
                .padding(16.0)
                
                VStack(spacing: 16) {
                    Text("Tags")
                        .font(.headline)
                        .padding(.top, 16.0)
                    
                    ScrollView(.horizontal) {
                        FlowVStack(
                            horizontalSpacing: horizontalSpacing,
                            verticalSpacing: verticalSpacing,
                            horizontalAlignment: hAlignment,
                            maxColumns: maxColumns,
                            columnCount: $columnCount
                        ) {
//                            Text("You can use text")
//                            
//                            Button { }
//                            label: {
//                                Text("You can use button")
//                            }
                            
                            ForEach(tags, id: \.self) { tag in
                                factory(tag)
                            }
                        }
                        .frame(maxHeight: 200)
                        .animation(animation)
                        .lineLimit(1)
                        .clipped() // <= ‼️ Don't forget
                        .contentShape(Rectangle())
                        .padding(16.0)
                    }
                    
                    Text("Total columns: \(columnCount)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button {
                        withAnimation(animation) {
                            maxColumns = (maxColumns == Int.max) ? initMaxColumns : Int.max
                        }
                    } label: {
                        Text(maxColumns == Int.max ? "Show only \(initMaxColumns) columns" : "Show all")
                            .padding()
                    }
                }
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(16.0)
                .padding(16.0)
            }
        }
    }

    private func addTag() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        inputText = ""
    }
}

struct VChipsView_Previews: PreviewProvider {
    static var previews: some View {
        VChipsView()
    }
}
