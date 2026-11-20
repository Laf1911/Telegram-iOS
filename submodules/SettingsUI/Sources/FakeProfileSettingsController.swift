import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import AlertUI
import SGSimpleSettings

private final class FakeProfileSettingsArguments {
    let context: AccountContext
    let updateVisualPremium: (Bool) -> Void
    let updateStarsBalance: (Int64?) -> Void
    let updateFakePhoneEnabled: (Bool) -> Void
    let updateFakePhone: (String) -> Void
    let updateFakePhonePriceTon: (Double) -> Void
    let updateChannelTitle: (String) -> Void
    let updateBusinessLocation: (String) -> Void
    let updateBusinessHours: (String) -> Void
    let addUsername: () -> Void
    let deleteUsername: (String) -> Void
    let addGift: () -> Void
    let deleteGift: (UUID) -> Void
    
    init(
        context: AccountContext,
        updateVisualPremium: @escaping (Bool) -> Void,
        updateStarsBalance: @escaping (Int64?) -> Void,
        updateFakePhoneEnabled: @escaping (Bool) -> Void,
        updateFakePhone: @escaping (String) -> Void,
        updateFakePhonePriceTon: @escaping (Double) -> Void,
        updateChannelTitle: @escaping (String) -> Void,
        updateBusinessLocation: @escaping (String) -> Void,
        updateBusinessHours: @escaping (String) -> Void,
        addUsername: @escaping () -> Void,
        deleteUsername: @escaping (String) -> Void,
        addGift: @escaping () -> Void,
        deleteGift: @escaping (UUID) -> Void
    ) {
        self.context = context
        self.updateVisualPremium = updateVisualPremium
        self.updateStarsBalance = updateStarsBalance
        self.updateFakePhoneEnabled = updateFakePhoneEnabled
        self.updateFakePhone = updateFakePhone
        self.updateFakePhonePriceTon = updateFakePhonePriceTon
        self.updateChannelTitle = updateChannelTitle
        self.updateBusinessLocation = updateBusinessLocation
        self.updateBusinessHours = updateBusinessHours
        self.addUsername = addUsername
        self.deleteUsername = deleteUsername
        self.addGift = addGift
        self.deleteGift = deleteGift
    }
}

private enum FakeProfileSection: Int32 {
    case premiumAndStars
    case profileData
    case nftUsernames
    case profileGifts
}

private enum FakeProfileEntry: ItemListNodeEntry {
    // 1. Секция: Telegram Premium и Звезды
    case premiumHeader(String)
    case visualPremiumToggle(Bool)
    case starsBalanceInput(String, String)
    case premiumNotice(String)
    
    // 2. Секция: Данные профиля (Номер, Канал, Бизнес)
    case profileDataHeader(String)
    case fakePhoneToggle(Bool)
    case fakePhoneInput(String, String)
    case fakePhonePriceInput(String, String)
    case fakeChannelTitleInput(String, String)
    case fakeBusinessLocationInput(String, String)
    case fakeBusinessHoursInput(String, String)
    case profileDataNotice(String)
    
    // 3. Секция: NFT-юзернеймы
    case nftUsernamesHeader(String)
    case addUsernameAction(String)
    case nftUsernameItem(index: Int, username: String, priceTon: Double)
    case nftUsernamesNotice(String)
    
    // 4. Секция: Подарки в профиле
    case giftsHeader(String)
    case addGiftAction(String)
    case giftItem(index: Int, id: UUID, title: String, subtitle: String)
    case giftsNotice(String)
    
    var section: ItemListSectionId {
        switch self {
        case .premiumHeader, .visualPremiumToggle, .starsBalanceInput, .premiumNotice:
            return FakeProfileSection.premiumAndStars.rawValue
        case .profileDataHeader, .fakePhoneToggle, .fakePhoneInput, .fakePhonePriceInput, .fakeChannelTitleInput, .fakeBusinessLocationInput, .fakeBusinessHoursInput, .profileDataNotice:
            return FakeProfileSection.profileData.rawValue
        case .nftUsernamesHeader, .addUsernameAction, .nftUsernameItem, .nftUsernamesNotice:
            return FakeProfileSection.nftUsernames.rawValue
        case .giftsHeader, .addGiftAction, .giftItem, .giftsNotice:
            return FakeProfileSection.profileGifts.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .premiumHeader:
            return 1000
        case .visualPremiumToggle:
            return 1001
        case .starsBalanceInput:
            return 1002
        case .premiumNotice:
            return 1003
            
        case .profileDataHeader:
            return 2000
        case .fakePhoneToggle:
            return 2001
        case .fakePhoneInput:
            return 2002
        case .fakePhonePriceInput:
            return 2003
        case .fakeChannelTitleInput:
            return 2004
        case .fakeBusinessLocationInput:
            return 2005
        case .fakeBusinessHoursInput:
            return 2006
        case .profileDataNotice:
            return 2007
            
        case .nftUsernamesHeader:
            return 3000
        case .addUsernameAction:
            return 3001
        case let .nftUsernameItem(index, _, _):
            return 3100 + Int32(index)
        case .nftUsernamesNotice:
            return 3999
            
        case .giftsHeader:
            return 4000
        case .addGiftAction:
            return 4001
        case let .giftItem(index, _, _, _):
            return 4100 + Int32(index)
        case .giftsNotice:
            return 4999
        }
    }
    
    static func ==(lhs: FakeProfileEntry, rhs: FakeProfileEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.premiumHeader(t1), .premiumHeader(t2)):
            return t1 == t2
        case let (.visualPremiumToggle(v1), .visualPremiumToggle(v2)):
            return v1 == v2
        case let (.starsBalanceInput(t1, v1), .starsBalanceInput(t2, v2)):
            return t1 == t2 && v1 == v2
        case let (.premiumNotice(t1), .premiumNotice(t2)):
            return t1 == t2
            
        case let (.profileDataHeader(t1), .profileDataHeader(t2)):
            return t1 == t2
        case let (.fakePhoneToggle(v1), .fakePhoneToggle(v2)):
            return v1 == v2
        case let (.fakePhoneInput(t1, v1), .fakePhoneInput(t2, v2)):
            return t1 == t2 && v1 == v2
        case let (.fakePhonePriceInput(t1, v1), .fakePhonePriceInput(t2, v2)):
            return t1 == t2 && v1 == v2
        case let (.fakeChannelTitleInput(t1, v1), .fakeChannelTitleInput(t2, v2)):
            return t1 == t2 && v1 == v2
        case let (.fakeBusinessLocationInput(t1, v1), .fakeBusinessLocationInput(t2, v2)):
            return t1 == t2 && v1 == v2
        case let (.fakeBusinessHoursInput(t1, v1), .fakeBusinessHoursInput(t2, v2)):
            return t1 == t2 && v1 == v2
        case let (.profileDataNotice(t1), .profileDataNotice(t2)):
            return t1 == t2
            
        case let (.nftUsernamesHeader(t1), .nftUsernamesHeader(t2)):
            return t1 == t2
        case let (.addUsernameAction(t1), .addUsernameAction(t2)):
            return t1 == t2
        case let (.nftUsernameItem(i1, u1, p1), .nftUsernameItem(i2, u2, p2)):
            return i1 == i2 && u1 == u2 && p1 == p2
        case let (.nftUsernamesNotice(t1), .nftUsernamesNotice(t2)):
            return t1 == t2
            
        case let (.giftsHeader(t1), .giftsHeader(t2)):
            return t1 == t2
        case let (.addGiftAction(t1), .addGiftAction(t2)):
            return t1 == t2
        case let (.giftItem(i1, id1, t1, s1), .giftItem(i2, id2, t2, s2)):
            return i1 == i2 && id1 == id2 && t1 == t2 && s1 == s2
        case let (.giftsNotice(t1), .giftsNotice(t2)):
            return t1 == t2
        default:
            return false
        }
    }
    
    static func <(lhs: FakeProfileEntry, rhs: FakeProfileEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! FakeProfileSettingsArguments
        switch self {
        // 1. Секция: Telegram Premium и Звезды
        case let .premiumHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .visualPremiumToggle(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: "Визуальный Telegram Premium",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { val in
                    args.updateVisualPremium(val)
                }
            )
        case let .starsBalanceInput(title, value):
            return ItemListSingleLineInputItem(
                presentationData: presentationData,
                title: NSAttributedString(string: title, textColor: presentationData.theme.list.itemPrimaryTextColor),
                text: value,
                placeholder: "Например, 5000",
                type: .number,
                sectionId: self.section,
                textUpdated: { text in
                    let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    args.updateStarsBalance(clean.isEmpty ? nil : Int64(clean))
                },
                action: {}
            )
        case let .premiumNotice(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section, style: .blocks)
            
        // 2. Секция: Данные профиля
        case let .profileDataHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .fakePhoneToggle(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: "Анонимный номер",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { val in
                    args.updateFakePhoneEnabled(val)
                }
            )
        case let .fakePhoneInput(title, value):
            return ItemListSingleLineInputItem(
                presentationData: presentationData,
                title: NSAttributedString(string: title, textColor: presentationData.theme.list.itemPrimaryTextColor),
                text: value,
                placeholder: "+888 0000 0000",
                type: .phone,
                sectionId: self.section,
                textUpdated: { text in
                    args.updateFakePhone(text.trimmingCharacters(in: .whitespacesAndNewlines))
                },
                action: {}
            )
        case let .fakePhonePriceInput(title, value):
            return ItemListSingleLineInputItem(
                presentationData: presentationData,
                title: NSAttributedString(string: title, textColor: presentationData.theme.list.itemPrimaryTextColor),
                text: value,
                placeholder: "150",
                type: .number,
                sectionId: self.section,
                textUpdated: { text in
                    let clean = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
                    args.updateFakePhonePriceTon(Double(clean) ?? 150.0)
                },
                action: {}
            )
        case let .fakeChannelTitleInput(title, value):
            return ItemListSingleLineInputItem(
                presentationData: presentationData,
                title: NSAttributedString(string: title, textColor: presentationData.theme.list.itemPrimaryTextColor),
                text: value,
                placeholder: "Название канала",
                type: .regular(capitalization: true, autocorrection: false),
                sectionId: self.section,
                textUpdated: { text in
                    args.updateChannelTitle(text.trimmingCharacters(in: .whitespacesAndNewlines))
                },
                action: {}
            )
        case let .fakeBusinessLocationInput(title, value):
            return ItemListSingleLineInputItem(
                presentationData: presentationData,
                title: NSAttributedString(string: title, textColor: presentationData.theme.list.itemPrimaryTextColor),
                text: value,
                placeholder: "г. Москва, ул. Арбат, 1",
                type: .regular(capitalization: true, autocorrection: true),
                sectionId: self.section,
                textUpdated: { text in
                    args.updateBusinessLocation(text.trimmingCharacters(in: .whitespacesAndNewlines))
                },
                action: {}
            )
        case let .fakeBusinessHoursInput(title, value):
            return ItemListSingleLineInputItem(
                presentationData: presentationData,
                title: NSAttributedString(string: title, textColor: presentationData.theme.list.itemPrimaryTextColor),
                text: value,
                placeholder: "Пн–Пт 09:00 – 18:00",
                type: .regular(capitalization: true, autocorrection: false),
                sectionId: self.section,
                textUpdated: { text in
                    args.updateBusinessHours(text.trimmingCharacters(in: .whitespacesAndNewlines))
                },
                action: {}
            )
        case let .profileDataNotice(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section, style: .blocks)
            
        // 3. Секция: NFT-юзернеймы
        case let .nftUsernamesHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .addUsernameAction(text):
            return ItemListActionItem(
                presentationData: presentationData,
                title: text,
                kind: .generic,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.addUsername()
                }
            )
        case let .nftUsernameItem(_, username, priceTon):
            let formattedPrice = String(format: "%.1f TON", priceTon)
            return WebBrowserDomainExceptionItem(
                presentationData: presentationData,
                systemStyle: .legacy,
                context: args.context,
                title: "@\(username)",
                label: formattedPrice,
                favicon: nil,
                sectionId: self.section,
                style: .blocks,
                deleted: {
                    args.deleteUsername(username)
                }
            )
        case let .nftUsernamesNotice(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section, style: .blocks)
            
        // 4. Секция: Подарки в профиле
        case let .giftsHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .addGiftAction(text):
            return ItemListActionItem(
                presentationData: presentationData,
                title: text,
                kind: .generic,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.addGift()
                }
            )
        case let .giftItem(_, id, title, subtitle):
            return WebBrowserDomainExceptionItem(
                presentationData: presentationData,
                systemStyle: .legacy,
                context: args.context,
                title: title,
                label: subtitle,
                favicon: nil,
                sectionId: self.section,
                style: .blocks,
                deleted: {
                    args.deleteGift(id)
                }
            )
        case let .giftsNotice(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section, style: .blocks)
        }
    }
}

public func fakeProfileSettingsController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise<Int>(0, ignoreRepeated: false)
    let stateValue = Atomic<Int>(value: 0)
    
    let updateState: () -> Void = {
        let _ = stateValue.modify { $0 + 1 }
        statePromise.set(stateValue.with { $0 })
    }
    
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    
    let arguments = FakeProfileSettingsArguments(
        context: context,
        updateVisualPremium: { value in
            FakeProfileManager.shared.isVisualPremium = value
            updateState()
        },
        updateStarsBalance: { balance in
            FakeProfileManager.shared.fakeStarsBalance = balance
            updateState()
        },
        updateFakePhoneEnabled: { value in
            FakeProfileManager.shared.isFakePhoneEnabled = value
            updateState()
        },
        updateFakePhone: { phone in
            FakeProfileManager.shared.fakePhone = phone
            updateState()
        },
        updateFakePhonePriceTon: { price in
            FakeProfileManager.shared.fakePhonePriceTon = price
            updateState()
        },
        updateChannelTitle: { title in
            FakeProfileManager.shared.fakeChannelTitle = title
            updateState()
        },
        updateBusinessLocation: { location in
            FakeProfileManager.shared.fakeBusinessLocation = location
            updateState()
        },
        updateBusinessHours: { hours in
            FakeProfileManager.shared.fakeBusinessHours = hours
            updateState()
        },
        addUsername: {
            let alert = UIAlertController(
                title: "Добавить NFT-юзернейм",
                message: "Введите имя пользователя и цену покупки на Fragment в TON",
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.placeholder = "Юзернейм (например, crow)"
                tf.autocapitalizationType = .none
                tf.autocorrectionType = .no
            }
            alert.addTextField { tf in
                tf.placeholder = "Цена в TON (например, 250)"
                tf.keyboardType = .decimalPad
            }
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            alert.addAction(UIAlertAction(title: "Добавить", style: .default, handler: { [weak alert] _ in
                guard let fields = alert?.textFields, fields.count >= 2 else { return }
                let rawUsername = (fields[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "")
                let rawPrice = (fields[1].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
                let price = Double(rawPrice) ?? 0.0
                guard !rawUsername.isEmpty else { return }
                
                let item = FakeNftUsername(username: rawUsername, priceTon: price, purchaseDate: Int32(Date().timeIntervalSince1970 - 86400 * 30))
                FakeProfileManager.shared.addUsername(item)
                updateState()
            }))
            
            context.sharedContext.mainWindow?.presentNative(alert)
        },
        deleteUsername: { username in
            FakeProfileManager.shared.removeUsername(named: username)
            updateState()
        },
        addGift: {
            let constructor = fakeGiftConstructorController(context: context, completion: {
                updateState()
            })
            presentControllerImpl?(constructor, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
        },
        deleteGift: { id in
            FakeProfileManager.shared.removeGift(id: id)
            updateState()
        }
    )
    
    let signal = combineLatest(
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        var entries: [FakeProfileEntry] = []
        let manager = FakeProfileManager.shared
        
        // 1. Секция: Telegram Premium и Звезды
        entries.append(.premiumHeader("TELEGRAM PREMIUM И ЗВЕЗДЫ"))
        entries.append(.visualPremiumToggle(manager.isVisualPremium))
        let starsText = manager.fakeStarsBalance.flatMap { "\($0)" } ?? ""
        entries.append(.starsBalanceInput("Баланс Звезд", starsText))
        entries.append(.premiumNotice("Визуально активирует статус Premium и заменяет баланс Звезд во всех экранах приложения."))
        
        // 2. Секция: Данные профиля (Номер, Канал, Бизнес)
        entries.append(.profileDataHeader("ДАННЫЕ ПРОФИЛЯ (НОМЕР, КАНАЛ, БИЗНЕС)"))
        entries.append(.fakePhoneToggle(manager.isFakePhoneEnabled))
        entries.append(.fakePhoneInput("Номер телефона", manager.fakePhone))
        entries.append(.fakePhonePriceInput("Цена номера (TON)", String(format: "%.1f", manager.fakePhonePriceTon)))
        entries.append(.fakeChannelTitleInput("Личный канал", manager.fakeChannelTitle))
        entries.append(.fakeBusinessLocationInput("Адрес (геопозиция)", manager.fakeBusinessLocation))
        entries.append(.fakeBusinessHoursInput("Часы работы", manager.fakeBusinessHours))
        entries.append(.profileDataNotice("При нажатии на номер +888 в профиле откроется официальная шторка Fragment с указанной ценой покупки."))
        
        // 3. Секция: NFT-юзернеймы
        entries.append(.nftUsernamesHeader("NFT-ЮЗЕРНЕЙМЫ"))
        entries.append(.addUsernameAction("Добавить юз"))
        for (index, u) in manager.fakeUsernames.enumerated() {
            entries.append(.nftUsernameItem(index: index, username: u.username, priceTon: u.priceTon))
        }
        entries.append(.nftUsernamesNotice("Юзернеймы отображаются в профиле как коллекционные с поддержкой шторки Fragment. Свайп влево для удаления."))
        
        // 4. Секция: Подарки в профиле
        entries.append(.giftsHeader("ПОДАРКИ В ПРОФИЛЕ"))
        entries.append(.addGiftAction("Добавить подарок в профиль"))
        for (index, gift) in manager.fakeGifts.enumerated() {
            let title = "#\(gift.giftNumber) • \(gift.patternName)"
            let subtitle = "\(gift.backdropColorHex)"
            entries.append(.giftItem(index: index, id: gift.id, title: title, subtitle: subtitle))
        }
        entries.append(.giftsNotice("Созданные подарки подмешиваются в начало вкладки подарков профиля с кнопками «Передать» и «Продать». Свайп влево для удаления."))
        
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Профиль"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks
        )
        
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    return controller
}
