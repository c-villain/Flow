import SwiftUI

struct ExampleView: View {
    
    var body: some View {
        TabView {
            chips
            filters
            vChips
        }
    }
    
    // MARK: - FlowHStack Demo
    var chips: some View {
        ChipsView()
            .tabItem {
                Image(systemName: "tag.circle")
                Text("FlowHStack")
            }
    }
    
    // MARK: - FlowVStack Demo
    var vChips: some View {
        VChipsView()
            .tabItem {
                Image(systemName: "tag.circle")
                Text("FlowHStack")
            }
    }
    
    var filters: some View {
        FiltersView()
            .tabItem {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                Text("Filters")
            }
    }
}

struct ExampleView_Previews: PreviewProvider {
    static var previews: some View {
        ExampleView()
    }
}
