import SwiftUI

struct ExampleView: View {
    
    var body: some View {
        TabView {
            chips
            filters
        }
    }
    
    var chips: some View {
        ChipsView()
            .tabItem {
                Image(systemName: "tag.circle")
                Text("Chips cloud")
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
