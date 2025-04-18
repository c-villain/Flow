import SwiftUI
import Flow

struct Manufacturer: Hashable, Identifiable {
    let id: Int
    let name: String
}

struct FiltersView: View {
    @State private var allManufacturers: [Manufacturer] = [
        Manufacturer(id: 1, name: "Toyota"),
        Manufacturer(id: 2, name: "Mercedes-Benz"),
        Manufacturer(id: 3, name: "BMW"),
        Manufacturer(id: 4, name: "Audi"),
        Manufacturer(id: 5, name: "Volkswagen"),
        Manufacturer(id: 6, name: "Hyundai"),
        Manufacturer(id: 7, name: "Kia"),
        Manufacturer(id: 8, name: "Ford"),
        Manufacturer(id: 9, name: "Chevrolet"),
        Manufacturer(id: 10, name: "Nissan"),
        Manufacturer(id: 11, name: "Mazda"),
        Manufacturer(id: 12, name: "Subaru"),
        Manufacturer(id: 13, name: "Honda"),
        Manufacturer(id: 14, name: "Peugeot"),
        Manufacturer(id: 15, name: "Renault"),
        Manufacturer(id: 16, name: "Skoda"),
        Manufacturer(id: 17, name: "LADA"),
        Manufacturer(id: 18, name: "Mitsubishi"),
        Manufacturer(id: 19, name: "Geely"),
        Manufacturer(id: 20, name: "Chery"),
        Manufacturer(id: 21, name: "Tesla"),
        Manufacturer(id: 22, name: "Volvo"),
        Manufacturer(id: 23, name: "Land Rover"),
        Manufacturer(id: 24, name: "Jaguar"),
        Manufacturer(id: 25, name: "Alfa Romeo"),
        Manufacturer(id: 26, name: "Fiat"),
        Manufacturer(id: 27, name: "Jeep"),
        Manufacturer(id: 28, name: "Dodge"),
        Manufacturer(id: 29, name: "RAM"),
        Manufacturer(id: 30, name: "Chrysler"),
        Manufacturer(id: 31, name: "Cadillac"),
        Manufacturer(id: 32, name: "Buick"),
        Manufacturer(id: 33, name: "GMC"),
        Manufacturer(id: 34, name: "Lincoln"),
        Manufacturer(id: 35, name: "Genesis"),
        Manufacturer(id: 36, name: "Infiniti"),
        Manufacturer(id: 37, name: "Acura"),
        Manufacturer(id: 38, name: "Lexus"),
        Manufacturer(id: 39, name: "Porsche"),
        Manufacturer(id: 40, name: "Mini"),
        Manufacturer(id: 41, name: "Suzuki"),
        Manufacturer(id: 42, name: "Saab"),
        Manufacturer(id: 43, name: "BYD"),
        Manufacturer(id: 44, name: "Great Wall"),
        Manufacturer(id: 45, name: "HAVAL"),
        Manufacturer(id: 46, name: "Zotye"),
        Manufacturer(id: 47, name: "FAW"),
        Manufacturer(id: 48, name: "Dongfeng")
    ]

    @State private var selected: [Manufacturer] = []

    let initMaxLines: Int = 2
    @State private var maxLines: Int = 2
    @State private var linesCount: Int = 0
    
    
    var chips: some View {
        ForEach(selected, id: \.id) { filter in
            HStack(spacing: 6) {
                Text(filter.name)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                Button {
                    if let index = selected.firstIndex(of: filter) {
                        selected.remove(at: index)
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .strokeBorder(
                        Color.black,
                        style: StrokeStyle(
                            lineWidth: 2
                        )
                    )
            )
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    Group {
                        if selected.isEmpty == false {
                            VStack(alignment: .leading) {
                                
                                FlowHStack(
                                    horizontalSpacing: 16.0,
                                    verticalSpacing: 8.0,
                                    maxLines: maxLines,
                                    lineCount: $linesCount
                                ) {
                                    chips
                                }
                                .onChange(of: linesCount) { linesCount in
                                    print("linesCount: \(linesCount)")
                                }
                                .padding(8.0)
                                .clipped() // <= ‼️ Don't forget
                                .lineLimit(1)
                                
                                if linesCount > initMaxLines {
                                    Button {
                                        withAnimation(.none) {
                                            maxLines = (maxLines == Int.max) ? initMaxLines : Int.max
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(maxLines == Int.max ? "Collapse" : "Expand")
                                            Image(systemName: maxLines == Int.max ? "chevron.up" : "chevron.down")
                                        }
                                        .font(.body)
                                        .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal, 16.0)
                                    .buttonStyle(.plain)
                                }

                            }
                        } else {
                            Spacer().frame(height: 0)
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .frame(minHeight: 0)
                    
                    ForEach(allManufacturers, id: \.self) { item in
                        Button(action: {
                            withAnimation(.none) {
                                if let index = selected.firstIndex(of: item) {
                                    selected.remove(at: index)
                                } else {
                                    selected.append(item)
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: selected.contains(item) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(selected.contains(item) ? .red : .gray)
                                Text(item.name)
                                Spacer()
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                .environment(\.defaultMinListRowHeight, 0)
                .listStyle(.plain)
                
                Button(action: {
                }) {
                    Text("Choose")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                }
            }
        }
    }
}

struct FiltersView_Previews: PreviewProvider {
    static var previews: some View {
        FiltersView()
    }
}
