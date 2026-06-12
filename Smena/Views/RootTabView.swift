import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var store: AppStore
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            DashboardView()
                .tabItem { Label("Главная", systemImage: "square.grid.2x2.fill") }
                .tag(0)

            ShiftsView()
                .tabItem { Label("Смены", systemImage: "calendar") }
                .tag(1)

            MoneyView()
                .tabItem { Label("Деньги", systemImage: "creditcard.fill") }
                .tag(2)

            PayoutsView()
                .tabItem { Label("Выплаты", systemImage: "chart.bar.fill") }
                .tag(3)

            SettingsView()
                .tabItem { Label("Настройки", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .onChange(of: selection) { _ in Haptics.selection() }
    }
}
