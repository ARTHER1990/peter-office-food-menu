import SwiftUI
import AppKit
import Combine
import AVFoundation

// ─────────────────────────────────────────────
// MARK: - App Version Constants
// ─────────────────────────────────────────────
let APP_VERSION = "1.0.2"
let APP_BUILD = 102

// ─────────────────────────────────────────────
// MARK: - Logo Manager
// ─────────────────────────────────────────────
class LogoManager {
    static let shared = LogoManager()
    var logoImage: NSImage?
    
    init() {
        loadLogo()
    }
    
    func loadLogo() {
        let possiblePaths = [
            (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent("05_Research_and_Development/PETER_FOOD_MENU_ALERT/company_logo.png"),
            ("~/Desktop/ART_JOB/05_Research_and_Development/PETER_FOOD_MENU_ALERT/company_logo.png" as NSString).expandingTildeInPath,
            ("~/Desktop/ART_JOB/05_Research_and_Development/PETER_FOOD_MENU_ALERT/Standalone_Repo/company_logo.png" as NSString).expandingTildeInPath,
            ("~/.peter_food_menu/company_logo.png" as NSString).expandingTildeInPath
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path),
               let img = NSImage(contentsOfFile: path) {
                self.logoImage = img
                return
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Silent App Auto-Updater (Binary & UI Updater)
// ─────────────────────────────────────────────
struct VersionInfo: Codable {
    var version: String
    var build: Int
    var updatedAt: String?
    var notes: String?
}

class AppUpdateManager {
    static let shared = AppUpdateManager()
    
    private let versionURL = URL(string: "https://raw.githubusercontent.com/ARTHER1990/peter-office-food-menu/main/version.json")!
    private let binaryURL = URL(string: "https://raw.githubusercontent.com/ARTHER1990/peter-office-food-menu/main/PeterFoodMenu")!
    private let logoURL = URL(string: "https://raw.githubusercontent.com/ARTHER1990/peter-office-food-menu/main/company_logo.png")!
    
    private var updateTimerCancellable: AnyCancellable?
    private var isUpdating = false
    
    func startCheckingForUpdates() {
        // Check immediately after launch
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.checkForNewAppVersion()
        }
        
        // Check periodically every 2 hours
        updateTimerCancellable = Timer.publish(every: 7200, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkForNewAppVersion()
            }
    }
    
    func checkForNewAppVersion() {
        guard !isUpdating else { return }
        
        var request = URLRequest(url: versionURL)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 15.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else { return }
            
            guard let info = try? JSONDecoder().decode(VersionInfo.self, from: data) else { return }
            
            if info.build > APP_BUILD {
                print("🚀 ตรวจพบเวอร์ชันใหม่: v\(info.version) (Build \(info.build)) กำลังอัปเดตเบื้องหลัง...")
                self.downloadAndApplyUpdate()
            }
        }.resume()
    }
    
    private func downloadAndApplyUpdate() {
        isUpdating = true
        let installDir = ("~/.peter_food_menu" as NSString).expandingTildeInPath
        let binaryPath = (installDir as NSString).appendingPathComponent("PeterFoodMenu")
        let tempBinaryPath = (installDir as NSString).appendingPathComponent("PeterFoodMenu.new")
        let logoPath = (installDir as NSString).appendingPathComponent("company_logo.png")
        
        // Ensure install directory exists
        try? FileManager.default.createDirectory(atPath: installDir, withIntermediateDirectories: true)
        
        // Download Logo update if present
        if let logoData = try? Data(contentsOf: logoURL) {
            try? logoData.write(to: URL(fileURLWithPath: logoPath))
        }
        
        // Download New Binary
        var request = URLRequest(url: binaryURL)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 30.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil, data.count > 50000 else {
                self?.isUpdating = false
                return
            }
            
            do {
                try data.write(to: URL(fileURLWithPath: tempBinaryPath))
                
                // Set executable permissions
                var permissions = [FileAttributeKey.posixPermissions: 0o755]
                try? FileManager.default.setAttributes(permissions, ofItemAtPath: tempBinaryPath)
                
                // Strip quarantine if needed
                let stripTask = Process()
                stripTask.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
                stripTask.arguments = ["-cr", tempBinaryPath]
                try? stripTask.run()
                stripTask.waitUntilExit()
                
                // Replace binary
                if FileManager.default.fileExists(atPath: binaryPath) {
                    _ = try? FileManager.default.removeItem(atPath: binaryPath)
                }
                try FileManager.default.moveItem(atPath: tempBinaryPath, toPath: binaryPath)
                
                print("✅ อัปเดตโปรแกรมเป็นเวอร์ชันใหม่เรียบร้อย! กำลังรีโหลดอัตโนมัติ...")
                
                // Silently relaunch new binary
                DispatchQueue.main.async {
                    let restartProcess = Process()
                    restartProcess.executableURL = URL(fileURLWithPath: binaryPath)
                    try? restartProcess.run()
                    
                    // Exit old instance cleanly
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NSApp.terminate(nil)
                    }
                }
            } catch {
                print("⚠️ อัปเดตล้มเหลว: \(error.localizedDescription)")
                self?.isUpdating = false
            }
        }.resume()
    }
}

// ─────────────────────────────────────────────
// MARK: - Charming Sound Engine (Luxury Crystal Chime)
// ─────────────────────────────────────────────
class SoundManager {
    static let shared = SoundManager()
    private var player: AVAudioPlayer?
    private var cachedWavData: Data?
    
    init() {
        generateCharmingChimeData()
    }
    
    private func generateCharmingChimeData() {
        let sampleRate = 44100.0
        let duration = 1.8
        let numSamples = Int(sampleRate * duration)
        
        var samples = [Float](repeating: 0.0, count: numSamples)
        let notes: [(start: Double, freq: Double, amp: Float)] = [
            (0.00, 739.99, 0.45),
            (0.11, 932.33, 0.55),
            (0.22, 1108.73, 0.75),
            (0.26, 1479.98, 0.35)
        ]
        
        for note in notes {
            let startIdx = Int(note.start * sampleRate)
            for i in startIdx..<numSamples {
                let t = Double(i - startIdx) / sampleRate
                let env = Float(exp(-3.0 * t))
                let val = Float(sin(2.0 * .pi * note.freq * t) +
                                0.35 * sin(4.0 * .pi * note.freq * t) +
                                0.15 * sin(6.0 * .pi * note.freq * t))
                samples[i] += val * env * note.amp
            }
        }
        
        var maxVal: Float = 0.001
        for s in samples { if abs(s) > maxVal { maxVal = abs(s) } }
        
        var wavData = Data()
        wavData.append("RIFF".data(using: .ascii)!)
        var fileSize = UInt32(36 + numSamples * 2)
        wavData.append(Data(bytes: &fileSize, count: 4))
        wavData.append("WAVEfmt ".data(using: .ascii)!)
        var subchunk1Size: UInt32 = 16
        var audioFormat: UInt16 = 1
        var numChannels: UInt16 = 1
        var sampleRateUInt: UInt32 = 44100
        var byteRate: UInt32 = 44100 * 2
        var blockAlign: UInt16 = 2
        var bitsPerSample: UInt16 = 16
        wavData.append(Data(bytes: &subchunk1Size, count: 4))
        wavData.append(Data(bytes: &audioFormat, count: 2))
        wavData.append(Data(bytes: &numChannels, count: 2))
        wavData.append(Data(bytes: &sampleRateUInt, count: 4))
        wavData.append(Data(bytes: &byteRate, count: 4))
        wavData.append(Data(bytes: &blockAlign, count: 2))
        wavData.append(Data(bytes: &bitsPerSample, count: 2))
        wavData.append("data".data(using: .ascii)!)
        var dataSize = UInt32(numSamples * 2)
        wavData.append(Data(bytes: &dataSize, count: 4))
        
        for s in samples {
            var sample16 = Int16(max(-32767, min(32767, (s / maxVal) * 28000.0)))
            wavData.append(Data(bytes: &sample16, count: 2))
        }
        
        self.cachedWavData = wavData
    }
    
    func playCharmingChime() {
        guard let data = cachedWavData else {
            NSSound(named: "Glass")?.play()
            return
        }
        
        do {
            player = try AVAudioPlayer(data: data)
            player?.volume = 0.85
            player?.prepareToPlay()
            player?.play()
        } catch {
            NSSound(named: "Glass")?.play()
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - UI: Dynamic Rotating Animated Eating Mascot
// ─────────────────────────────────────────────
struct MascotTheme {
    var face1: String
    var face2: String
    var food: String
    var sparkle: String
}

struct AnimatedEatingMascot: View {
    @State private var isChewing: Bool = false
    @State private var isBouncing: Bool = false
    @State private var steamOffset: CGFloat = 0
    @State private var steamOpacity: Double = 0.8
    @State private var sparkleScale: CGFloat = 0.8
    @State private var themeIndex: Int = Int.random(in: 0..<6)
    
    let themes: [MascotTheme] = [
        MascotTheme(face1: "😋", face2: "🤤", food: "🍚", sparkle: "✨"),
        MascotTheme(face1: "🐱", face2: "😻", food: "🍜", sparkle: "♨️"),
        MascotTheme(face1: "🐻", face2: "🤤", food: "🍛", sparkle: "✨"),
        MascotTheme(face1: "🐶", face2: "👅", food: "🍗", sparkle: "⭐"),
        MascotTheme(face1: "🐰", face2: "🥰", food: "🍧", sparkle: "💖"),
        MascotTheme(face1: "🐼", face2: "😋", food: "🍱", sparkle: "🥢")
    ]
    
    var currentTheme: MascotTheme {
        return themes[themeIndex % themes.count]
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                Text(currentTheme.sparkle)
                    .font(.system(size: 9))
                    .offset(y: steamOffset)
                    .opacity(steamOpacity)
                
                Text(isChewing ? currentTheme.face1 : currentTheme.face2)
                    .font(.system(size: 20))
                    .scaleEffect(isChewing ? 1.14 : 0.94)
                    .rotationEffect(.degrees(isChewing ? 5 : -5))
            }
            
            Text(currentTheme.food)
                .font(.system(size: 18))
                .offset(y: isBouncing ? -2.5 : 1.5)
        }
        .onAppear {
            themeIndex = Int.random(in: 0..<themes.count)
            
            withAnimation(.easeInOut(duration: 0.32).repeatForever(autoreverses: true)) {
                isChewing = true
            }
            withAnimation(.easeInOut(duration: 0.38).repeatForever(autoreverses: true)) {
                isBouncing = true
            }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                sparkleScale = 1.3
            }
            withAnimation(.easeOut(duration: 0.75).repeatForever(autoreverses: false)) {
                steamOffset = -8
                steamOpacity = 0.0
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Data Models
// ─────────────────────────────────────────────
struct MenuItem: Codable {
    var dayName: String
    var dish1: String?
    var dish2: String?
    var main: String?
    var soup: String?
    var dessert: String?
    var special: String?
    
    var firstDish: String {
        return dish1 ?? main ?? "-"
    }
    
    var secondDish: String {
        return dish2 ?? soup ?? "-"
    }
    
    var hasDessert: Bool {
        guard let d = dessert, !d.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, d != "-" else {
            return false
        }
        return true
    }
    
    var hasSpecial: Bool {
        guard let s = special, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, s != "-" else {
            return false
        }
        return true
    }
}

struct MenuSchedule: Codable {
    var updatedAt: String?
    var monthTitle: String?
    var announcement: String?
    var menus: [String: MenuItem]
}

// ─────────────────────────────────────────────
// MARK: - Menu State Manager
// ─────────────────────────────────────────────
class MenuManager: ObservableObject {
    static let shared = MenuManager()
    
    @Published var schedule: MenuSchedule = MenuSchedule(updatedAt: nil, monthTitle: "สิงหาคม 2569", announcement: "รายการอาหารพนักงาน", menus: [:])
    @Published var todayItem: MenuItem?
    @Published var tomorrowItem: MenuItem?
    @Published var todayDateStr: String = ""
    @Published var tomorrowDateStr: String = ""
    @Published var isAlertShowing: Bool = false
    @Published var countdownSeconds: Double = 5.0
    @Published var statusMessage: String = "พร้อมใช้งาน"
    
    private var clockTimerCancellable: AnyCancellable?
    private var syncTimerCancellable: AnyCancellable?
    private var alertDismissTimer: Timer?
    private var lastFiredDate: String = ""
    
    let remoteURL = URL(string: "https://raw.githubusercontent.com/ARTHER1990/peter-office-food-menu/main/menu_schedule.json")!
    
    var localCachePath: String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("PeterFoodMenu", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("menu_schedule.json").path
    }
    
    var projectLocalPath: String {
        let currentDir = FileManager.default.currentDirectoryPath
        let defaultPath = (currentDir as NSString).appendingPathComponent("05_Research_and_Development/PETER_FOOD_MENU_ALERT/menu_schedule.json")
        if FileManager.default.fileExists(atPath: defaultPath) {
            return defaultPath
        }
        let fallback = ("~/Desktop/ART_JOB/05_Research_and_Development/PETER_FOOD_MENU_ALERT/menu_schedule.json" as NSString).expandingTildeInPath
        return fallback
    }
    
    init() {
        loadFromLocalCache()
        fetchFromRemoteCloud()
        updateTodayAndTomorrow()
        startClockObserver()
        startPeriodicSync()
    }
    
    func loadFromLocalCache() {
        var dataToRead: Data?
        if FileManager.default.fileExists(atPath: localCachePath) {
            dataToRead = try? Data(contentsOf: URL(fileURLWithPath: localCachePath))
        } else if FileManager.default.fileExists(atPath: projectLocalPath) {
            dataToRead = try? Data(contentsOf: URL(fileURLWithPath: projectLocalPath))
        }
        
        if let data = dataToRead, let decoded = try? JSONDecoder().decode(MenuSchedule.self, from: data) {
            DispatchQueue.main.async {
                self.schedule = decoded
                self.statusMessage = "\(decoded.monthTitle ?? "สิงหาคม 2569")"
                self.updateTodayAndTomorrow()
            }
        }
    }
    
    func fetchFromRemoteCloud() {
        var request = URLRequest(url: remoteURL)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                DispatchQueue.main.async {
                    self?.loadFromLocalCache()
                }
                return
            }
            
            if let decoded = try? JSONDecoder().decode(MenuSchedule.self, from: data) {
                try? data.write(to: URL(fileURLWithPath: self.localCachePath))
                DispatchQueue.main.async {
                    self.schedule = decoded
                    self.statusMessage = "ซิงค์สำเร็จ"
                    self.updateTodayAndTomorrow()
                }
            }
        }.resume()
    }
    
    func updateTodayAndTomorrow() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        let now = Date()
        let todayKey = formatter.string(from: now)
        self.todayDateStr = todayKey
        
        if let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: now) {
            let tomorrowKey = formatter.string(from: tomorrowDate)
            self.tomorrowDateStr = tomorrowKey
            self.tomorrowItem = schedule.menus[tomorrowKey]
        }
        
        self.todayItem = schedule.menus[todayKey]
    }
    
    func startClockObserver() {
        clockTimerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] currentDate in
                self?.checkTimeAndTrigger(currentDate)
            }
    }
    
    func startPeriodicSync() {
        syncTimerCancellable = Timer.publish(every: 1800, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchFromRemoteCloud()
            }
    }
    
    private func checkTimeAndTrigger(_ date: Date) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: date)
        
        // Target: 10:50:00 AM
        if hour == 10 && minute == 50 && second == 0 {
            if lastFiredDate != todayStr {
                lastFiredDate = todayStr
                triggerCenterAlert()
            }
        }
    }
    
    func triggerCenterAlert() {
        updateTodayAndTomorrow()
        SoundManager.shared.playCharmingChime()
        
        DispatchQueue.main.async {
            self.countdownSeconds = 5.0
            self.isAlertShowing = true
            WindowManager.shared.showCenterAlertWindow()
            
            self.alertDismissTimer?.invalidate()
            
            var remaining = 5.0
            self.alertDismissTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] t in
                guard let self = self else { return }
                remaining -= 0.1
                self.countdownSeconds = max(0, remaining)
                if remaining <= 0 {
                    t.invalidate()
                    self.dismissCenterAlert()
                }
            }
        }
    }
    
    func dismissCenterAlert() {
        alertDismissTimer?.invalidate()
        alertDismissTimer = nil
        isAlertShowing = false
        WindowManager.shared.hideCenterAlertWindow()
    }
}

// ─────────────────────────────────────────────
// MARK: - UI: Center 10:50 AM Alert (With Subtle Tomorrow Preview)
// ─────────────────────────────────────────────
struct CenterAlertView: View {
    @ObservedObject var manager = MenuManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Minimal Circle Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "fork.knife")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Text Content (Today + Subtle Tomorrow Preview)
            VStack(alignment: .leading, spacing: 3) {
                // Top Header Row
                HStack(alignment: .center, spacing: 8) {
                    Text("10:50 น. • เมนูอาหารวันนี้")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.65))
                    
                    if let item = manager.todayItem, item.hasDessert {
                        Text("• 🍧 มีของหวาน")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(Color.pink.opacity(0.95))
                    }
                    
                    Spacer()
                    
                    Text("\(Int(ceil(manager.countdownSeconds)))s")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.4))
                }
                
                // Today Dishes Row (Big & Bold)
                if let item = manager.todayItem {
                    HStack(spacing: 10) {
                        Text(item.firstDish)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        if item.secondDish != "-" && !item.secondDish.isEmpty {
                            Text("•")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.35))
                            
                            Text(item.secondDish)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        AnimatedEatingMascot()
                            .padding(.leading, 2)
                    }
                } else {
                    Text("ไม่มีรายการอาหารสำหรับวันนี้")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Subtle Faded Tomorrow Preview Row
                if let tomorrow = manager.tomorrowItem {
                    HStack(spacing: 6) {
                        Text("พรุ่งนี้:")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.4))
                        
                        Text(tomorrow.firstDish)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.55))
                        
                        if tomorrow.secondDish != "-" && !tomorrow.secondDish.isEmpty {
                            Text("•")
                                .font(.system(size: 9))
                                .foregroundColor(Color.white.opacity(0.3))
                            
                            Text(tomorrow.secondDish)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.55))
                        }
                        
                        if tomorrow.hasDessert {
                            Text("(🍧 มีของหวาน)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color.pink.opacity(0.7))
                        }
                    }
                    .padding(.top, 1)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(width: 550, height: 86)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(white: 0.14).opacity(0.97))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1.2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            manager.dismissCenterAlert()
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - UI: Menu Bar Popover Detail View
// ─────────────────────────────────────────────
struct MenuBarDetailPopoverView: View {
    @ObservedObject var manager = MenuManager.shared
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ZStack {
            Color(white: 0.12).ignoresSafeArea()
            
            VStack(spacing: 10) {
                // Top Header: CRAZY FACTORY Logo + Title
                HStack(spacing: 10) {
                    if let logo = LogoManager.shared.logoImage {
                        Image(nsImage: logo)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 22)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(4)
                    } else {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Text("รายการอาหารพนักงาน")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        manager.fetchFromRemoteCloud()
                        AppUpdateManager.shared.checkForNewAppVersion()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("ซิงค์ข้อมูลและตรวจอัปเดต")
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                
                Divider().background(Color.white.opacity(0.1))
                
                // Tabs: วันนี้ / พรุ่งนี้ / ทั้งเดือน
                Picker("", selection: $selectedTab) {
                    Text("วันนี้").tag(0)
                    Text("พรุ่งนี้").tag(1)
                    Text("ทั้งเดือน").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 14)
                
                // Content
                ScrollView {
                    VStack(spacing: 8) {
                        if selectedTab == 0 {
                            if let item = manager.todayItem {
                                MinimalCardView(
                                    item: item,
                                    label: "วันนี้ • \(item.dayName)",
                                    monthBadge: manager.schedule.monthTitle ?? "สิงหาคม 2569"
                                )
                            } else {
                                EmptyStateView(dateStr: manager.todayDateStr, label: "วันนี้")
                            }
                        } else if selectedTab == 1 {
                            if let item = manager.tomorrowItem {
                                MinimalCardView(
                                    item: item,
                                    label: "พรุ่งนี้ • \(item.dayName)",
                                    monthBadge: manager.schedule.monthTitle ?? "สิงหาคม 2569"
                                )
                            } else {
                                EmptyStateView(dateStr: manager.tomorrowDateStr, label: "พรุ่งนี้")
                            }
                        } else {
                            // Full Month Overview
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("📅 เดือน: \(manager.schedule.monthTitle ?? "สิงหาคม 2569")")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white.opacity(0.7))
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                                .padding(.top, 2)
                                
                                ForEach(manager.schedule.menus.keys.sorted(), id: \.self) { key in
                                    if let item = manager.schedule.menus[key] {
                                        HStack(alignment: .top, spacing: 8) {
                                            Text(item.dayName)
                                                .font(.system(size: 9.5, weight: .bold))
                                                .foregroundColor(key == manager.todayDateStr ? .orange : .white)
                                                .frame(width: 80, alignment: .leading)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("1. " + item.firstDish)
                                                    .font(.system(size: 10.5, weight: .medium))
                                                    .foregroundColor(.white)
                                                if item.secondDish != "-" && !item.secondDish.isEmpty {
                                                    Text("2. " + item.secondDish)
                                                        .font(.system(size: 10.5, weight: .medium))
                                                        .foregroundColor(.white.opacity(0.85))
                                                }
                                                if item.hasDessert, let d = item.dessert {
                                                    Text("🍧 " + d)
                                                        .font(.system(size: 9.5))
                                                        .foregroundColor(.pink)
                                                }
                                            }
                                            Spacer()
                                        }
                                        .padding(7)
                                        .background(key == manager.todayDateStr ? Color.white.opacity(0.12) : Color.white.opacity(0.03))
                                        .cornerRadius(6)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 220)
                
                Divider().background(Color.white.opacity(0.1))
                
                // Footer
                HStack(spacing: 8) {
                    Button(action: {
                        WindowManager.shared.closePopover()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            manager.triggerCenterAlert()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "bell")
                                .font(.system(size: 9))
                            Text("ทดสอบเด้ง 10:50")
                                .font(.system(size: 9.5, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button(action: {
                        NSApp.terminate(nil)
                    }) {
                        Text("ออก")
                            .font(.system(size: 9.5))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
        }
        .frame(width: 340, height: 335)
    }
}

// ─────────────────────────────────────────────
// MARK: - UI Helper: Minimal Card View
// ─────────────────────────────────────────────
struct MinimalCardView: View {
    var item: MenuItem
    var label: String
    var monthBadge: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.85))
                
                Text("(\(monthBadge))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.5))
                
                Spacer()
                
                if item.hasDessert {
                    Text("🍧 มีของหวาน")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.pink)
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text("1.")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.5))
                    Text(item.firstDish)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
                
                if item.secondDish != "-" && !item.secondDish.isEmpty {
                    HStack(spacing: 8) {
                        Text("2.")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.5))
                        Text(item.secondDish)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .cornerRadius(8)
    }
}

struct EmptyStateView: View {
    var dateStr: String
    var label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("ไม่มีรายการอาหารสำหรับ \(label)")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            Text("วันที่: \(dateStr)")
                .font(.system(size: 9.5))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
}

// ─────────────────────────────────────────────
// MARK: - Window & Status Item Manager
// ─────────────────────────────────────────────
class WindowManager: NSObject {
    static let shared = WindowManager()
    
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var centerAlertWindow: NSPanel?
    
    func setupMenuBarAndAlerts() {
        setupStatusItem()
        setupCenterAlertWindow()
    }
    
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            if let img = NSImage(systemSymbolName: "fork.knife", accessibilityDescription: "Food Menu") {
                let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
                button.image = img.withSymbolConfiguration(config)
            } else {
                button.title = "🍴"
            }
            button.target = self
            button.action = #selector(togglePopover)
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 340, height: 335)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: MenuBarDetailPopoverView())
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            LogoManager.shared.loadLogo()
            MenuManager.shared.updateTodayAndTomorrow()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    func closePopover() {
        popover?.performClose(nil)
    }
    
    func setupCenterAlertWindow() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 86),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .screenSaver
        panel.isFloatingPanel = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: CenterAlertView())
        
        self.centerAlertWindow = panel
    }
    
    func showCenterAlertWindow() {
        guard let alert = centerAlertWindow, let screen = NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        let alertSize = alert.frame.size
        
        // จัดตำแหน่งมุมบนขวา (Top-Right Notification Style)
        let x = screenRect.maxX - alertSize.width - 20.0
        let y = screenRect.maxY - alertSize.height - 12.0
        
        alert.setFrameOrigin(NSPoint(x: x, y: y))
        alert.alphaValue = 0.0
        alert.orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            alert.animator().alphaValue = 1.0
        }
    }
    
    func hideCenterAlertWindow() {
        guard let alert = centerAlertWindow, alert.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.35
            alert.animator().alphaValue = 0.0
        }, completionHandler: {
            alert.orderOut(nil)
        })
    }
}

// ─────────────────────────────────────────────
// MARK: - Main Entry Point
// ─────────────────────────────────────────────
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        LogoManager.shared.loadLogo()
        WindowManager.shared.setupMenuBarAndAlerts()
        
        // Start Silent Self-Updater
        AppUpdateManager.shared.startCheckingForUpdates()
        
        // Auto preview once with audio
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            MenuManager.shared.triggerCenterAlert()
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
