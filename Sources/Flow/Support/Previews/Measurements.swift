import SwiftUI

struct Measurements: View {

    @State private var size: CGSize = .zero

    let showSize: Bool
    var color: Color?
    
    var body: some View {
        label.measureSize { size = $0 }
    }

    var label: some View {
        ZStack(alignment: .topTrailing) {
            Rectangle()
                .strokeBorder(
                    color ?? .red,
                    lineWidth: 1
                )
            
            Text("H:\(size.height.formatted) W:\(size.width.formatted)")
                .foregroundColor(color ?? .black)
                .font(.system(size: 8))
                .opacity(showSize ? 1 : 0)
        }
    }
}

extension View {

    public func measured(_ color: Color? = nil) -> some View {
        self
            .overlay(Measurements(showSize: true, color: color))
    }
    
    public func measured(showSize: Bool = true, _ color: Color? = nil) -> some View {
        self
            .overlay(Measurements(showSize: showSize, color: color))
    }
}

// MARK: - Previews
struct MeasurementsPreviews: PreviewProvider {

    static var previews: some View {
        vertical
            .padding()
    }

    static var vertical: some View {
        ScrollView {
            VStack {
                Rectangle()
                    .fill(Color.yellow.opacity(0.5))
                    .frame(width: 350, height: 400)
                    .measured()
                
                Color.blue.opacity(0.1)
                    .frame(height: 31.54321)
                
                Color.blue.opacity(0.4)
                    .frame(height: 31.54321)
                    .measured(showSize: false)
            }
        }
    }
}

