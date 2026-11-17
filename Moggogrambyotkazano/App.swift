import SwiftUI

let API_URL = "https://296b0b229e3d5b.app.lhr.life"

struct RegularGift: Codable, Identifiable {
let id: Int
let name: String
}

struct NFTGift: Codable, Identifiable {
var id: String { "(name)_(mint)" }
let name: String
let mint: Int
let model: String
let backdrop: String
let rarity: String
}

struct MarketLot: Codable, Identifiable {
let id: Int
let seller_id: Int
let name: String
let mint: Int
let model: String
let backdrop: String
let rarity: String
let price: Int
}

struct UserResponse: Codable {
let ok: Bool
let user_id: Int?
let username: String?
let stars: Int?
let auth_code: String?
let gifts: [RegularGift]?
let nfts: [NFTGift]?
}

struct MarketResponse: Codable {
let ok: Bool
let lots: [MarketLot]?
}

@main
struct MoggogramApp: App {
var body: some Scene {
WindowGroup { ContentView() }
}
}

struct ContentView: View {
@State private var phone = "+888"
@State private var code = ""
@State private var step = 1
@State private var user: UserResponse?
@State private var errorMsg = ""

var body: some View {
    NavigationStack {
        if let u = user {
            MainTabView(user: u, onRefresh: refreshProfile, onLogout: { user = nil; step = 1; code = "" })
        } else {
            VStack(spacing: 20) {
                Text("Moggogrambyotkazano").font(.title2.bold())
                if step == 1 {
                    TextField("+888...", text: $phone).textFieldStyle(.roundedBorder).padding(.horizontal, 30)
                    Button("Получить код") { fetchUser(checkCode: false) }.buttonStyle(.borderedProminent)
                } else {
                    TextField("Код из бота", text: $code).textFieldStyle(.roundedBorder).padding(.horizontal, 30)
                    Button("Войти") { fetchUser(checkCode: true) }.buttonStyle(.borderedProminent)
                }
                if !errorMsg.isEmpty { Text(errorMsg).foregroundStyle(.red) }
            }
        }
    }
}

func fetchUser(checkCode: Bool) {
    let enc = phone.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? phone
    guard let url = URL(string: "\(API_URL)/api/user?phone=\(enc)") else { return }
    URLSession.shared.dataTask(with: url) { data, _, _ in
        DispatchQueue.main.async {
            guard let data = data, let res = try? JSONDecoder().decode(UserResponse.self, from: data), res.ok else {
                errorMsg = "Ошибка или номер не найден!"; return
            }
            if !checkCode { step = 2 }
            else if res.auth_code == code.trimmingCharacters(in: .whitespaces) {
                user = res
                refreshProfile()
            } else { errorMsg = "Неверный код!" }
        }
    }.resume()
}

func refreshProfile() {
    guard let uid = user?.user_id, let url = URL(string: "\(API_URL)/api/profile?user_id=\(uid)") else { return }
    URLSession.shared.dataTask(with: url) { data, _, _ in
        DispatchQueue.main.async {
            if let data = data, let full = try? JSONDecoder().decode(UserResponse.self, from: data), full.ok {
                user = full
            }
        }
    }.resume()
}
}

struct MainTabView: View {
let user: UserResponse
let onRefresh: () -> Void
let onLogout: () -> Void
@State private var lots: [MarketLot] = []
@State private var statusAlert = ""

var body: some View {
    TabView {
        List {
            Text("Moggogram Official — Добро пожаловать!").bold()
            Text("Команды в боте: /upgrade, /transfer, /sell, /market").font(.caption).foregroundStyle(.secondary)
        }
        .tabItem { Label("Чаты", systemImage: "message.fill") }

        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    Text("🏪 Маркетплейс NFT").font(.title2.bold())
                    Spacer()
                    Button("Обновить", action: loadMarket).buttonStyle(.bordered)
                }.padding(.horizontal)

                if lots.isEmpty {
                    Text("На маркете пока пусто. Выстави свой NFT через /sell в боте!").foregroundStyle(.secondary).padding()
                } else {ForEach(lots) { lot in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("💎 \(lot.name) #\(lot.mint) (\(lot.rarity))").bold()
                            Text("🎨 \(lot.model) | 🖼 \(lot.backdrop)").font(.caption)
                            Button("🛒 Купить за \(lot.price) ⭐️") { buyLot(lot.id) }
                                .buttonStyle(.borderedProminent).tint(.orange)
                        }
                        .padding().frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground)).cornerRadius(12).padding(.horizontal)
                    }
                }
            }.padding(.top)
        }
        .onAppear(perform: loadMarket)
        .tabItem { Label("Маркет", systemImage: "bag.fill") }

        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Text("@\(user.username ?? "player")").font(.title2.bold())
                    Spacer()
                    Button("🔄", action: onRefresh)
                }.padding(.horizontal)

                Text("⭐️ \(user.stars ?? 0) звёзд").font(.headline)

                if let gifts = user.gifts, !gifts.isEmpty {
                    Divider()
                    Text("🎁 Обычные подарки (\(gifts.count))").font(.headline)
                    ForEach(gifts) { g in
                        HStack {
                            Text("🎁 \(g.name)").bold()
                            Spacer()
                            Button("✨ В NFT (250 ⭐️)") { upgradeGift(g.id) }
                                .buttonStyle(.borderedProminent).tint(.purple)
                        }
                        .padding().background(Color(.secondarySystemBackground)).cornerRadius(12).padding(.horizontal)
                    }
                }

                Divider()
                Text("💎 Мои NFT (\(user.nfts?.count ?? 0))").font(.headline)
                ForEach(user.nfts ?? []) { nft in
                    VStack(alignment: .leading) {
                        Text("💎 \(nft.name) #\(nft.mint) (\(nft.rarity))").bold()
                        Text("🎨 \(nft.model) | 🖼 \(nft.backdrop)").font(.caption)
                    }
                    .padding().frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground)).cornerRadius(12).padding(.horizontal)
                }

                Button("Выйти", role: .destructive, action: onLogout).padding(.top)
            }.padding(.top)
        }
        .tabItem { Label("Профиль и NFT", systemImage: "sparkles") }
    }
    .alert("Уведомление", isPresented: Binding(get: { !statusAlert.isEmpty }, set: { if !$0 { statusAlert = "" } })) {
        Button("ОК", role: .cancel) {}
    } message: { Text(statusAlert) }
}

func loadMarket() {
    guard let url = URL(string: "\(API_URL)/api/market") else { return }
    URLSession.shared.dataTask(with: url) { data, _, _ in
        DispatchQueue.main.async {
            if let data = data, let res = try? JSONDecoder().decode(MarketResponse.self, from: data), res.ok {
                lots = res.lots ?? []
            }
        }
    }.resume()
}

func upgradeGift(_ giftId: Int) {
    guard let uid = user.user_id, let url = URL(string: "\(API_URL)/api/upgrade") else { return }
    var req = URLRequest(url: url); req.httpMethod = "POST"
    req.httpBody = try? JSONSerialization.data(withJSONObject: ["user_id": uid, "gift_id": giftId])
    URLSession.shared.dataTask(with: req) { data, _, _ in
        DispatchQueue.main.async {
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], json["ok"] as? Bool == true {
                statusAlert = "Подарок успешно улучшен до уникального NFT!"
                onRefresh()
            } else {
                statusAlert = "Недостаточно звёзд (нужно 250 ⭐️) или ошибка!"
            }
        }
    }.resume()
}

func buyLot(_ lotId: Int) {
    guard let uid = user.
    user_id, let url = URL(string: "\(API_URL)/api/market/buy") else { return }
    var req = URLRequest(url: url); req.httpMethod = "POST"
    req.httpBody = try? JSONSerialization.data(withJSONObject: ["user_id": uid, "lot_id": lotId])
    URLSession.shared.dataTask(with: req) { data, _, _ in
        DispatchQueue.main.async {
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], json["ok"] as? Bool == true {
                statusAlert = "NFT успешно куплен на маркете!"
                loadMarket()
                onRefresh()
            } else {
                statusAlert = "Не хватает звёзд или лот уже куплен!"
            }
        }
    }.resume()
}
}
