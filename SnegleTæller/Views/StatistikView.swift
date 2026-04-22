import SwiftUI

struct StatistikView: View {
    enum StatistikPeriode: String, CaseIterable {
        case dag = "Dag"
        case uge = "Uge"
        case måned = "Måned"
        case år = "År"
    }

    @State private var valgtPeriode: StatistikPeriode = .dag
    @AppStorage("sneglePerDag") private var snegleDataString: String = "{}"

    var body: some View {
        ZStack {
            Image("nature-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.2)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Statistik")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .padding(.top, 16)

                    infoCard {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                            spacing: 8
                        ) {
                            ForEach(StatistikPeriode.allCases, id: \.self) { periode in
                                Button {
                                    valgtPeriode = periode
                                } label: {
                                    Text(periode.rawValue)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(valgtPeriode == periode ? .black : .white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(
                                            valgtPeriode == periode
                                            ? Color.white
                                            : Color.white.opacity(0.12)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    infoCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(titelForValgtPeriode())
                                .font(.headline)
                                .foregroundColor(.white)

                            let entries = dataForValgtPeriode()
                            let maxAntal = max(entries.map { $0.value }.max() ?? 0, 1)
                            let chartHeight: CGFloat = 180

                            if entries.isEmpty {
                                Text("Ingen data endnu")
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 40)
                            } else {
                                HStack(alignment: .bottom, spacing: 8) {
                                    ForEach(entries, id: \.key) { entry in
                                        let width = søjleBredde(for: entries.count)
                                        let height = CGFloat(entry.value) / CGFloat(maxAntal) * chartHeight

                                        VStack(spacing: 8) {
                                            Text("\(entry.value)")
                                                .font(.caption.weight(.medium))
                                                .foregroundColor(.white)
                                                .frame(height: 16)

                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(Color("AccentColor"))
                                                .frame(width: width, height: max(height, 8))

                                            Text(entry.label)
                                                .font(.caption.weight(.medium))
                                                .foregroundColor(.white.opacity(0.9))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                                .frame(width: width, height: 16)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 240, alignment: .bottom)
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 80)
            }
        }
      //  .onAppear {
        //    indsætTestData()
       // }
    }

    @ViewBuilder
    func infoCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding()
            .frame(maxWidth: 350)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(radius: 4)
    }

    func søjleBredde(for count: Int) -> CGFloat {
        switch count {
        case 0...6:
            return 42
        case 7:
            return 34
        case 8...10:
            return 26
        default:
            return 20
        }
    }

    func hentSnegleData() -> [String: Int] {
        if let data = snegleDataString.data(using: .utf8),
           let result = try? JSONDecoder().decode([String: Int].self, from: data) {
            return result
        }
        return [:]
    }

    struct ChartEntry {
        let key: String
        let label: String
        let value: Int
    }

    func dataForValgtPeriode() -> [ChartEntry] {
        switch valgtPeriode {
        case .dag:
            return sidste7Dage()
        case .uge:
            return sidste6Uger()
        case .måned:
            return månederIÅr()
        case .år:
            return sidste5År()
        }
    }

    func titelForValgtPeriode() -> String {
        switch valgtPeriode {
        case .dag:
            return "Snegle pr. dag"
        case .uge:
            return "Snegle pr. uge"
        case .måned:
            return "Snegle pr. måned"
        case .år:
            return "Snegle pr. år"
        }
    }

    func sidste7Dage() -> [ChartEntry] {
        let data = hentSnegleData()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let labels: [Int: String] = [
            1: "søn",
            2: "man",
            3: "tirs",
            4: "ons",
            5: "tors",
            6: "fre",
            7: "lør"
        ]

        let today = calendar.startOfDay(for: Date())

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -(6 - offset), to: today) else { return nil }
            let key = formatter.string(from: date)
            let weekday = calendar.component(.weekday, from: date)
            let label = labels[weekday] ?? "-"
            let value = data[key] ?? 0
            return ChartEntry(key: key, label: label, value: value)
        }
    }

    func sidste6Uger() -> [ChartEntry] {
        let rawData = hentSnegleData()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var grouped: [String: Int] = [:]

        for (dato, antal) in rawData {
            guard let date = formatter.date(from: dato) else { continue }
            let year = calendar.component(.yearForWeekOfYear, from: date)
            let week = calendar.component(.weekOfYear, from: date)
            let key = "\(year)-W\(String(format: "%02d", week))"
            grouped[key, default: 0] += antal
        }

        let today = Date()
        let currentWeekDate = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today

        return (0..<6).compactMap { offset in
            guard let date = calendar.date(byAdding: .weekOfYear, value: -(5 - offset), to: currentWeekDate) else { return nil }
            let year = calendar.component(.yearForWeekOfYear, from: date)
            let week = calendar.component(.weekOfYear, from: date)
            let key = "\(year)-W\(String(format: "%02d", week))"
            let label = "U\(week)"
            let value = grouped[key] ?? 0
            return ChartEntry(key: key, label: label, value: value)
        }
    }

    func månederIÅr() -> [ChartEntry] {
        let rawData = hentSnegleData()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let currentYear = calendar.component(.year, from: Date())
        let monthLabels = [
            1: "jan", 2: "feb", 3: "mar", 4: "apr",
            5: "maj", 6: "jun", 7: "jul", 8: "aug",
            9: "sep", 10: "okt", 11: "nov", 12: "dec"
        ]

        var grouped: [Int: Int] = [:]

        for (dato, antal) in rawData {
            guard let date = formatter.date(from: dato) else { continue }
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)

            if year == currentYear {
                grouped[month, default: 0] += antal
            }
        }

        return (1...12).map { month in
            ChartEntry(
                key: "\(currentYear)-\(String(format: "%02d", month))",
                label: monthLabels[month] ?? "\(month)",
                value: grouped[month] ?? 0
            )
        }
    }

    func sidste5År() -> [ChartEntry] {
        let rawData = hentSnegleData()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let currentYear = calendar.component(.year, from: Date())
        let years = Array((currentYear - 4)...currentYear)

        var grouped: [Int: Int] = [:]

        for (dato, antal) in rawData {
            guard let date = formatter.date(from: dato) else { continue }
            let year = calendar.component(.year, from: date)
            grouped[year, default: 0] += antal
        }

        return years.map { year in
            ChartEntry(
                key: "\(year)",
                label: "\(year)",
                value: grouped[year] ?? 0
            )
        }
    }

    func indsætTestData() {
        let testData: [String: Int] = [
            "2024-06-10": 2,
            "2024-07-15": 4,
            "2024-09-20": 1,

            "2025-01-05": 3,
            "2025-02-14": 6,
            "2025-03-03": 2,
            "2025-03-18": 5,
            "2025-04-10": 7,
            "2025-06-21": 4,
            "2025-08-09": 3,
            "2025-10-30": 6,

            "2026-01-01": 1,
            "2026-01-02": 2,
            "2026-01-03": 3,
            "2026-02-10": 5,
            "2026-02-11": 4,
            "2026-03-05": 6,
            "2026-03-06": 2,
            "2026-03-07": 7,
            "2026-04-01": 3,
            "2026-04-02": 5,
            "2026-04-10": 4,
            "2026-04-15": 6,
            "2026-04-18": 2,
            "2026-04-19": 8,
            "2026-04-20": 3,
            "2026-04-21": 7
        ]

        if let encoded = try? JSONEncoder().encode(testData),
           let jsonString = String(data: encoded, encoding: .utf8) {
            snegleDataString = jsonString
        }
    }
}
