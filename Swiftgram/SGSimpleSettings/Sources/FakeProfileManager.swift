import Foundation

// MARK: - Модели данных мода «Профиль»

public struct FakeNftUsername: Codable, Equatable, Hashable {
    public var username: String
    public var priceTon: Double
    public var purchaseDate: Int32

    public init(username: String, priceTon: Double, purchaseDate: Int32 = Int32(Date().timeIntervalSince1970)) {
        self.username = username
        self.priceTon = priceTon
        self.purchaseDate = purchaseDate
    }
}

public struct FakeStarGiftItem: Codable, Equatable, Hashable {
    public var id: UUID
    public var baseGiftId: Int64
    public var backdropColorHex: String
    public var patternName: String
    public var giftNumber: Int32
    public var canTransfer: Bool
    public var canResell: Bool

    public init(
        id: UUID = UUID(),
        baseGiftId: Int64 = 0,
        backdropColorHex: String = "#D4AF37",
        patternName: String = "Star",
        giftNumber: Int32 = 1,
        canTransfer: Bool = true,
        canResell: Bool = true
    ) {
        self.id = id
        self.baseGiftId = baseGiftId
        self.backdropColorHex = backdropColorHex
        self.patternName = patternName
        self.giftNumber = giftNumber
        self.canTransfer = canTransfer
        self.canResell = canResell
    }
}

// MARK: - Потокобезопасный синглтон управления Fake Profile

public final class FakeProfileManager {
    public static let shared = FakeProfileManager()
    
    // Используем NSRecursiveLock во избежание дэдлока при вложенных вызовах
    private let lock = NSRecursiveLock()
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let isVisualPremium = "FakeProfile_isVisualPremium"
        static let fakeStarsBalance = "FakeProfile_fakeStarsBalance"
        static let isFakePhoneEnabled = "FakeProfile_isFakePhoneEnabled"
        static let fakePhone = "FakeProfile_fakePhone"
        static let fakePhonePriceTon = "FakeProfile_fakePhonePriceTon"
        static let fakeChannelTitle = "FakeProfile_fakeChannelTitle"
        static let fakeBusinessLocation = "FakeProfile_fakeBusinessLocation"
        static let fakeBusinessHours = "FakeProfile_fakeBusinessHours"
        static let fakeUsernames = "FakeProfile_fakeUsernames"
        static let fakeGifts = "FakeProfile_fakeGifts"
        static let currentAccountPeerId = "FakeProfile_currentAccountPeerId"
    }
    
    private init() {
        // Установка начальных значений по умолчанию при первом запуске
        if self.defaults.object(forKey: Keys.fakePhone) == nil {
            self.defaults.set("+888 0000 0000", forKey: Keys.fakePhone)
        }
        if self.defaults.object(forKey: Keys.fakePhonePriceTon) == nil {
            self.defaults.set(150.0, forKey: Keys.fakePhonePriceTon)
        }
    }
    
    // Идентификатор текущего авторизованного пользователя
    public var currentAccountPeerId: Int64? {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            if self.defaults.object(forKey: Keys.currentAccountPeerId) == nil {
                return nil
            }
            let val = Int64(self.defaults.integer(forKey: Keys.currentAccountPeerId))
            return val != 0 ? val : nil
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            if let val = newValue {
                self.defaults.set(val, forKey: Keys.currentAccountPeerId)
            } else {
                self.defaults.removeObject(forKey: Keys.currentAccountPeerId)
            }
        }
    }
    
    public func isCurrentAccountPeer(id: Int64) -> Bool {
        self.lock.lock()
        defer { self.lock.unlock() }
        if self.defaults.object(forKey: Keys.currentAccountPeerId) != nil {
            let current = Int64(self.defaults.integer(forKey: Keys.currentAccountPeerId))
            if current != 0 {
                return current == id
            }
        }
        return true
    }
    
    // 1. Telegram Premium и Звезды
    public var isVisualPremium: Bool {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.defaults.bool(forKey: Keys.isVisualPremium)
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.defaults.set(newValue, forKey: Keys.isVisualPremium)
        }
    }
    
    public var fakeStarsBalance: Int64? {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            if self.defaults.object(forKey: Keys.fakeStarsBalance) == nil {
                return nil
            }
            return Int64(self.defaults.integer(forKey: Keys.fakeStarsBalance))
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            if let val = newValue {
                self.defaults.set(Int(val), forKey: Keys.fakeStarsBalance)
            } else {
                self.defaults.removeObject(forKey: Keys.fakeStarsBalance)
            }
        }
    }
    
    // 2. Данные профиля (Номер, Канал, Бизнес)
    public var isFakePhoneEnabled: Bool {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.defaults.bool(forKey: Keys.isFakePhoneEnabled)
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.defaults.set(newValue, forKey: Keys.isFakePhoneEnabled)
        }
    }
    
    public var fakePhone: String {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.defaults.string(forKey: Keys.fakePhone) ?? "+888 0000 0000"
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.defaults.set(newValue, forKey: Keys.fakePhone)
        }
    }
    
    public var fakePhonePriceTon: Double {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            if self.defaults.object(forKey: Keys.fakePhonePriceTon) == nil {
                return 150.0
            }
            return self.defaults.double(forKey: Keys.fakePhonePriceTon)
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.defaults.set(newValue, forKey: Keys.fakePhonePriceTon)
        }
    }
    
    public var fakeChannelTitle: String {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.defaults.string(forKey: Keys.fakeChannelTitle) ?? ""
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.defaults.set(newValue, forKey: Keys.fakeChannelTitle)
        }
    }
    
    public var fakeBusinessLocation: String {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.defaults.string(forKey: Keys.fakeBusinessLocation) ?? ""
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.defaults.set(newValue, forKey: Keys.fakeBusinessLocation)
        }
    }
    
    public var fakeBusinessHours: String {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.defaults.string(forKey: Keys.fakeBusinessHours) ?? ""
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.defaults.set(newValue, forKey: Keys.fakeBusinessHours)
        }
    }
    
    // 3. NFT-юзернеймы
    public var fakeUsernames: [FakeNftUsername] {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            guard let data = self.defaults.data(forKey: Keys.fakeUsernames),
                  let items = try? JSONDecoder().decode([FakeNftUsername].self, from: data) else {
                return []
            }
            return items
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            if let data = try? JSONEncoder().encode(newValue) {
                self.defaults.set(data, forKey: Keys.fakeUsernames)
            }
        }
    }
    
    public func addUsername(_ item: FakeNftUsername) {
        self.lock.lock()
        defer { self.lock.unlock() }
        var items: [FakeNftUsername] = []
        if let data = self.defaults.data(forKey: Keys.fakeUsernames),
           let decoded = try? JSONDecoder().decode([FakeNftUsername].self, from: data) {
            items = decoded
        }
        items.removeAll(where: { $0.username.lowercased() == item.username.lowercased() })
        items.append(item)
        if let data = try? JSONEncoder().encode(items) {
            self.defaults.set(data, forKey: Keys.fakeUsernames)
        }
    }
    
    public func removeUsername(at index: Int) {
        self.lock.lock()
        defer { self.lock.unlock() }
        var items: [FakeNftUsername] = []
        if let data = self.defaults.data(forKey: Keys.fakeUsernames),
           let decoded = try? JSONDecoder().decode([FakeNftUsername].self, from: data) {
            items = decoded
        }
        if index >= 0 && index < items.count {
            items.remove(at: index)
            if let data = try? JSONEncoder().encode(items) {
                self.defaults.set(data, forKey: Keys.fakeUsernames)
            }
        }
    }
    
    public func removeUsername(named username: String) {
        self.lock.lock()
        defer { self.lock.unlock() }
        var items: [FakeNftUsername] = []
        if let data = self.defaults.data(forKey: Keys.fakeUsernames),
           let decoded = try? JSONDecoder().decode([FakeNftUsername].self, from: data) {
            items = decoded
        }
        items.removeAll(where: { $0.username.lowercased() == username.lowercased() })
        if let data = try? JSONEncoder().encode(items) {
            self.defaults.set(data, forKey: Keys.fakeUsernames)
        }
    }
    
    // 4. Подарки в профиле
    public var fakeGifts: [FakeStarGiftItem] {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            guard let data = self.defaults.data(forKey: Keys.fakeGifts),
                  let items = try? JSONDecoder().decode([FakeStarGiftItem].self, from: data) else {
                return []
            }
            return items
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            if let data = try? JSONEncoder().encode(newValue) {
                self.defaults.set(data, forKey: Keys.fakeGifts)
            }
        }
    }
    
    public func addGift(_ item: FakeStarGiftItem) {
        self.lock.lock()
        defer { self.lock.unlock() }
        var items: [FakeStarGiftItem] = []
        if let data = self.defaults.data(forKey: Keys.fakeGifts),
           let decoded = try? JSONDecoder().decode([FakeStarGiftItem].self, from: data) {
            items = decoded
        }
        items.insert(item, at: 0)
        if let data = try? JSONEncoder().encode(items) {
            self.defaults.set(data, forKey: Keys.fakeGifts)
        }
    }
    
    public func removeGift(id: UUID) {
        self.lock.lock()
        defer { self.lock.unlock() }
        var items: [FakeStarGiftItem] = []
        if let data = self.defaults.data(forKey: Keys.fakeGifts),
           let decoded = try? JSONDecoder().decode([FakeStarGiftItem].self, from: data) {
            items = decoded
        }
        items.removeAll(where: { $0.id == id })
        if let data = try? JSONEncoder().encode(items) {
            self.defaults.set(data, forKey: Keys.fakeGifts)
        }
    }
    
    public func removeGift(at index: Int) {
        self.lock.lock()
        defer { self.lock.unlock() }
        var items: [FakeStarGiftItem] = []
        if let data = self.defaults.data(forKey: Keys.fakeGifts),
           let decoded = try? JSONDecoder().decode([FakeStarGiftItem].self, from: data) {
            items = decoded
        }
        if index >= 0 && index < items.count {
            items.remove(at: index)
            if let data = try? JSONEncoder().encode(items) {
                self.defaults.set(data, forKey: Keys.fakeGifts)
            }
        }
    }
}
