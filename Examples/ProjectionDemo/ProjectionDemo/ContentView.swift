import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
//                NavigationLink("(Bare) SoftwareRendererView") {
//                    SoftwareRendererView() { _, _, _ in
//                    }
//                }
                NavigationLink("MeshView") {
                    MeshView()
                }
                NavigationLink("BoxesView") {
                    BoxesView()
                }
                NavigationLink("HalfEdgeView") {
                    HalfEdgeView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
