//
//  HomeView.swift
//  SnegleTæller
//
//  Created by Sascha Winther Andersern on 21/04/2026.
//

import SwiftUI
// MARK: - Custom Button Styles
struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                Color("AccentColor")
                    .opacity(configuration.isPressed ? 0.7 : 1.0)
            )
            .cornerRadius(10)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(Color.red.opacity(configuration.isPressed ? 0.7 : 1.0))
            .cornerRadius(10)
    }
}

// MARK: - Main View
struct HomeView: View {

    // 📱 Tastatur-håndtering
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    @State private var antal: String = ""
    @State private var visSnegleRegn = false
    @State private var snegleTilAnimation: [Snegl] = []
    @State private var senesteTilføjelse: (dato: String, antal: Int)?
    @State private var backupTotal: Int?
    @State private var backupDagData: [String: Int]?
    @State private var visAlert = false
    @State private var alertTekst = ""

    @AppStorage("snegleTotal") private var total = 0
    @AppStorage("sneglePerDag") private var snegleDataString: String = "{}"

    struct Snegl: Identifiable {
        let id = UUID()
        let x: CGFloat
        let delay: Double
    }

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
                    Text("SnegleTæller")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .padding(.top, 16)

                    // Total Card
                    infoCard {
                        VStack(spacing: 8) {
                            Text("Snegle i alt")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(total)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }

                    // Add Card
                    infoCard {
                        VStack(spacing: 16) {
                            Button(action: {
                                tilføjSnegle(1)
                            }) {
                                Label("1 snegl", systemImage: "plus.circle.fill")
                                    .font(.title3.bold())
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(AccentButtonStyle())

                            Divider()
                                .overlay(Color.white.opacity(0.3))

                            TextField("Indtast antal snegle", text: $antal)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            Button(action: tilføjSnegleFraInput) {
                                Label("Tilføj antal", systemImage: "number.circle.fill")
                            }
                            .buttonStyle(AccentButtonStyle())
                        }
                    }

                    // Action Card
                    infoCard {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Button(role: .destructive, action: nulstil) {
                                    Label("Nulstil", systemImage: "trash")
                                }
                                .buttonStyle(DestructiveButtonStyle())

                                Button(action: fortryd) {
                                    Label("Fortryd", systemImage: "arrow.uturn.backward")
                                }
                                .buttonStyle(AccentButtonStyle())
                            }

                            if backupTotal != nil {
                                Button(action: fortrydNulstilling) {
                                    Label("Fortryd nulstilling", systemImage: "arrow.uturn.backward.circle")
                                }
                                .buttonStyle(AccentButtonStyle())
                            }
                        }
                    }



                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 80) // mere plads til menulinje
            }

            if visSnegleRegn {
                ForEach(snegleTilAnimation) { snegl in
                    SneglEmojiView(x: snegl.x, delay: snegl.delay)
                }
            }

            // 📦 Menulinje i bunden (opdateret uden gentagelse)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: eksporterSnegleData) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.bottom, 12)
                    .padding(.trailing, 20)
                }
            }
        }
        .alert("Ugyldigt antal", isPresented: $visAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertTekst)
        }
    }

    // Card view
    @ViewBuilder
    func infoCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding()
            .frame(maxWidth: 350)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(radius: 4)
    }

    // 📅 Format dato-strenge (single declaration)
    private func formattedDato(_ dato: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = inputFormatter.date(from: dato) else { return dato }
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd-MM"
        return outputFormatter.string(from: date)
    }

    // 🐌 Snegle-regn
    struct SneglEmojiView: View {
        let x: CGFloat
        let delay: Double
        @State private var yOffset: CGFloat = -200
        @State private var opacity: Double = 1.0

        var body: some View {
            Text("🐌")
                .font(.title)
                .position(x: x, y: yOffset)
                .opacity(opacity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.easeIn(duration: 3)) {
                            yOffset = CGFloat.random(in: 700...900)
                            opacity = 0
                        }
                    }
                }
        }
    }

    // 📆 Dato-format
    func hentDagensDato() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // 🔄 Hent og gem data
    func hentSnegleData() -> [String: Int] {
        if let data = snegleDataString.data(using: .utf8),
           let result = try? JSONDecoder().decode([String: Int].self, from: data) {
            return result
        }
        return [:]
    }

    func gemSnegleData(_ data: [String: Int]) {
        if let encoded = try? JSONEncoder().encode(data),
           let jsonString = String(data: encoded, encoding: .utf8) {
            snegleDataString = jsonString
        }
    }

    func sorteretSnegleData() -> [(key: String, value: Int)] {
        return hentSnegleData().sorted { $0.key < $1.key }
    }

    // ➕ Tilføj snegle
    func tilføjSnegleFraInput() {
        guard let nySnegle = Int(antal) else {
            alertTekst = "Indtast venligst et gyldigt tal."
            visAlert = true
            return
        }

        tilføjSnegle(nySnegle)
    }

    func tilføjSnegle(_ nySnegle: Int) {
        if nySnegle <= 0 {
            alertTekst = "Indtast venligst et positivt tal."
            visAlert = true
        } else if nySnegle > 9999 {
            alertTekst = "Du kan maksimalt indtaste 9999 snegle."
            visAlert = true
        } else {
            total += nySnegle
            antal = ""
            hideKeyboard()

            let idag = hentDagensDato()
            var dagData = hentSnegleData()
            dagData[idag, default: 0] += nySnegle
            gemSnegleData(dagData)

            senesteTilføjelse = (idag, nySnegle)
            backupTotal = nil
            backupDagData = nil

            let antalSnegle = min(nySnegle, 100)
            snegleTilAnimation = (0..<antalSnegle).map { i in
                Snegl(x: CGFloat(30 + i * 30), delay: Double.random(in: 0...1))
            }

            visSnegleRegn = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                visSnegleRegn = false
            }
        }
    }

    // 🗑️ Nulstil
    func nulstil() {
        backupTotal = total
        backupDagData = hentSnegleData()
        total = 0
        snegleDataString = "{}"
        senesteTilføjelse = nil
    }

    // 🔁 Fortryd tilføjelse
    func fortryd() {
        if let sidste = senesteTilføjelse, total >= sidste.antal {
            total -= sidste.antal
            var dagData = hentSnegleData()
            dagData[sidste.dato, default: 0] -= sidste.antal
            if dagData[sidste.dato] ?? 0 <= 0 {
                dagData.removeValue(forKey: sidste.dato)
            }
            gemSnegleData(dagData)
            senesteTilføjelse = nil
        }
    }

    // 🔁 Fortryd nulstilling
    func fortrydNulstilling() {
        if let gammelTotal = backupTotal,
           let gammelDagData = backupDagData {
            total = gammelTotal
            gemSnegleData(gammelDagData)
            backupTotal = nil
            backupDagData = nil
        }
    }

    // 📤 Eksport
    func eksporterSnegleData() {
        let snegle = sorteretSnegleData()
        var csv = "Dato,Antal\n"
        for (dato, antal) in snegle {
            csv += "\(dato),\(antal)\n"
        }

        let dict = Dictionary(uniqueKeysWithValues: snegle)
        let jsonData = try? JSONEncoder().encode(dict)
        let jsonString = jsonData.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"

        let tmp = FileManager.default.temporaryDirectory
        let csvURL = tmp.appendingPathComponent("SnegleTæller.csv")
        let jsonURL = tmp.appendingPathComponent("SnegleTæller.json")

        do {
            try csv.write(to: csvURL, atomically: true, encoding: .utf8)
            try jsonString.write(to: jsonURL, atomically: true, encoding: .utf8)

            let aktivitet = UIActivityViewController(activityItems: [csvURL, jsonURL], applicationActivities: nil)

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(aktivitet, animated: true, completion: nil)
            }
        } catch {
            print("Fejl under eksport: \(error)")
        }
    }
}
