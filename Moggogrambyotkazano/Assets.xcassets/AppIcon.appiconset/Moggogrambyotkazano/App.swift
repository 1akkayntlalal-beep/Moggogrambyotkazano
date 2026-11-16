import SwiftUI

let API_URL = "https://lhr.life"

struct NFTGift: Codable, Identifiable {
var id: String { "(name)_(mint)" }
let name: String
let mint: Int
let model: String
let backdrop: String
let rarity: String
}

struct UserResponse: Codable {
let ok: Bool
let username: String?
let stars: Int?
let auth_code: String?
let nfts: [NFTGift]?
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
            MainTabView(user: u, onLogout: { user = nil; step = 1; code = "" })
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
            else if res.auth_code == code.trimmingCharacters(in: .whitespaces) { user = res }
            else { errorMsg = "Неверный код!" }
        }
    }.resume()
}
}

struct MainTabView: View {
let user: UserResponse
let onLogout: () -> Void
var body: some View {
TabView {
List { Text("Moggogram Official — Добро пожаловать!").bold() }
.tabItem { Label("Чаты", systemImage: "message.fill") }
ScrollView {
VStack(spacing: 16) {
Text("@(user.username ?? "player")").font(.title2.bold())
Text("⭐️ (user.stars ?? 0) звёзд").font(.headline)
Divider()
Text("💎 Мои NFT ((user.nfts?.count ?? 0))").font(.headline)
ForEach(user.nfts ?? []) { nft in
VStack(alignment: .leading) {
Text("💎 (nft.name) #(nft.mint) ((nft.rarity))").bold()
Text("🎨 (nft.model) | 🖼 (nft.backdrop)").font(.caption)
}.padding().frame(maxWidth: .infinity, alignment: .leading)
.background(Color(.secondarySystemBackground)).cornerRadius(12).padding(.horizontal)
}
Button("Выйти", role: .destructive, action: onLogout)
}.padding(.top)
}.tabItem { Label("Профиль и NFT", systemImage: "sparkles") }
}
}
}
