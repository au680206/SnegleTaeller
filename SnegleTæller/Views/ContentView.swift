import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Hjem", systemImage: "house.fill")
                }

            StatistikView()
                .tabItem {
                    Label("Statistik", systemImage: "chart.bar.fill")
                }
        }
    }
}
