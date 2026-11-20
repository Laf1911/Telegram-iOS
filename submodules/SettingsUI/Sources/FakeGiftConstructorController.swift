import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import SGSimpleSettings

// MARK: - Палитра цветов подложки (Backdrop)

public struct FakeGiftBackdropColor {
    public let name: String
    public let hex: String
    
    public static let palette: [FakeGiftBackdropColor] = [
        FakeGiftBackdropColor(name: "Золотой", hex: "#D4AF37"),
        FakeGiftBackdropColor(name: "Изумрудный", hex: "#10B981"),
        FakeGiftBackdropColor(name: "Рубиновый", hex: "#E11D48"),
        FakeGiftBackdropColor(name: "Сапфировый", hex: "#2563EB"),
        FakeGiftBackdropColor(name: "Фиолетовый", hex: "#7C3AED"),
        FakeGiftBackdropColor(name: "Обсидиан", hex: "#18181B")
    ]
}

// Пресеты моделей подарков для надежного оффлайн-выбора
public struct FakeGiftModelPreset {
    public let id: Int64
    public let name: String
    
    public static let presets: [FakeGiftModelPreset] = [
        FakeGiftModelPreset(id: 1001, name: "Звезда (Star)"),
        FakeGiftModelPreset(id: 1002, name: "Сердце (Heart)"),
        FakeGiftModelPreset(id: 1003, name: "Бриллиант (Diamond)"),
        FakeGiftModelPreset(id: 1004, name: "Кубок (Trophy)"),
        FakeGiftModelPreset(id: 1005, name: "Торт (Birthday Cake)"),
        FakeGiftModelPreset(id: 1006, name: "Ракета (Rocket)")
    ]
}

private final class FakeGiftConstructorArguments {
    let context: AccountContext
    let selectModel: (Int64, String) -> Void
    let selectBackdrop: (String) -> Void
    let updateNumber: (Int32) -> Void
    let updateTransfer: (Bool) -> Void
    let updateResell: (Bool) -> Void
    let saveGift: () -> Void
    
    init(
        context: AccountContext,
        selectModel: @escaping (Int64, String) -> Void,
        selectBackdrop: @escaping (String) -> Void,
        updateNumber: @escaping (Int32) -> Void,
        updateTransfer: @escaping (Bool) -> Void,
        updateResell: @escaping (Bool) -> Void,
        saveGift: @escaping () -> Void
    ) {
        self.context = context
        self.selectModel = selectModel
        self.selectBackdrop = selectBackdrop
        self.updateNumber = updateNumber
        self.updateTransfer = updateTransfer
        self.updateResell = updateResell
        self.saveGift = saveGift
    }
}

private enum FakeGiftConstructorSection: Int32 {
    case model
    case backdrop
    case details
    case actions
}

private enum FakeGiftConstructorEntry: ItemListNodeEntry {
    case modelHeader(String)
    case modelOption(index: Int, id: Int64, name: String, isSelected: Bool)
    
    case backdropHeader(String)
    case backdropOption(index: Int, name: String, hex: String, isSelected: Bool)
    
    case detailsHeader(String)
    case numberInput(String, String)
    case canTransferToggle(Bool)
    case canResellToggle(Bool)
    
    case saveAction(String)
    
    var section: ItemListSectionId {
        switch self {
        case .modelHeader, .modelOption:
            return FakeGiftConstructorSection.model.rawValue
        case .backdropHeader, .backdropOption:
            return FakeGiftConstructorSection.backdrop.rawValue
        case .detailsHeader, .numberInput, .canTransferToggle, .canResellToggle:
            return FakeGiftConstructorSection.details.rawValue
        case .saveAction:
            return FakeGiftConstructorSection.actions.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .modelHeader:
            return 1000
        case let .modelOption(index, _, _, _):
            return 1100 + Int32(index)
        case .backdropHeader:
            return 2000
        case let .backdropOption(index, _, _, _):
            return 2100 + Int32(index)
        case .detailsHeader:
            return 3000
        case .numberInput:
            return 3100
        case .canTransferToggle:
            return 3200
        case .canResellToggle:
            return 3300
        case .saveAction:
            return 4000
        }
    }
    
    static func ==(lhs: FakeGiftConstructorEntry, rhs: FakeGiftConstructorEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.modelHeader(t1), .modelHeader(t2)):
            return t1 == t2
        case let (.modelOption(i1, id1, n1, s1), .modelOption(i2, id2, n2, s2)):
            return i1 == i2 && id1 == id2 && n1 == n2 && s1 == s2
        case let (.backdropHeader(t1), .backdropHeader(t2)):
            return t1 == t2
        case let (.backdropOption(i1, n1, h1, s1), .backdropOption(i2, n2, h2, s2)):
            return i1 == i2 && n1 == n2 && h1 == h2 && s1 == s2
        case let (.detailsHeader(t1), .detailsHeader(t2)):
            return t1 == t2
        case let (.numberInput(t1, v1), .numberInput(t2, v2)):
            return t1 == t2 && v1 == v2
        case let (.canTransferToggle(v1), .canTransferToggle(v2)):
            return v1 == v2
        case let (.canResellToggle(v1), .canResellToggle(v2)):
            return v1 == v2
        case let (.saveAction(t1), .saveAction(t2)):
            return t1 == t2
        default:
            return false
        }
    }
    
    static func <(lhs: FakeGiftConstructorEntry, rhs: FakeGiftConstructorEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! FakeGiftConstructorArguments
        switch self {
        case let .modelHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .modelOption(_, id, name, isSelected):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: name,
                label: isSelected ? "✓" : "",
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.selectModel(id, name)
                }
            )
        case let .backdropHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .backdropOption(_, name, hex, isSelected):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "\(name) (\(hex))",
                label: isSelected ? "✓" : "",
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.selectBackdrop(hex)
                }
            )
        case let .detailsHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .numberInput(title, value):
            return ItemListSingleLineInputItem(
                presentationData: presentationData,
                title: NSAttributedString(string: title, textColor: presentationData.theme.list.itemPrimaryTextColor),
                text: value,
                placeholder: "1",
                type: .number,
                sectionId: self.section,
                textUpdated: { text in
                    if let num = Int32(text.trimmingCharacters(in: .whitespacesAndNewlines)), num > 0 {
                        args.updateNumber(num)
                    }
                },
                action: {}
            )
        case let .canTransferToggle(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: "Кнопка «Передать»",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { val in
                    args.updateTransfer(val)
                }
            )
        case let .canResellToggle(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: "Кнопка «Продать»",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { val in
                    args.updateResell(val)
                }
            )
        case let .saveAction(title):
            return ItemListActionItem(
                presentationData: presentationData,
                title: title,
                kind: .generic,
                alignment: .center,
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.saveGift()
                }
            )
        }
    }
}

private struct FakeGiftConstructorState: Equatable {
    var selectedBaseGiftId: Int64
    var selectedPatternName: String
    var selectedBackdropHex: String
    var giftNumber: Int32
    var canTransfer: Bool
    var canResell: Bool
}

public func fakeGiftConstructorController(context: AccountContext, completion: @escaping () -> Void) -> ViewController {
    let statePromise = ValuePromise<FakeGiftConstructorState>(
        FakeGiftConstructorState(
            selectedBaseGiftId: 1001,
            selectedPatternName: "Star",
            selectedBackdropHex: "#D4AF37",
            giftNumber: 1,
            canTransfer: true,
            canResell: true
        ),
        ignoreRepeated: true
    )
    let stateValue = Atomic<FakeGiftConstructorState>(value: FakeGiftConstructorState(
        selectedBaseGiftId: 1001,
        selectedPatternName: "Star",
        selectedBackdropHex: "#D4AF37",
        giftNumber: 1,
        canTransfer: true,
        canResell: true
    ))
    
    var dismissImpl: (() -> Void)?
    
    let arguments = FakeGiftConstructorArguments(
        context: context,
        selectModel: { id, name in
            let cleanName = name.components(separatedBy: " ").first ?? name
            let _ = stateValue.modify { current in
                var updated = current
                updated.selectedBaseGiftId = id
                updated.selectedPatternName = cleanName
                statePromise.set(updated)
                return updated
            }
        },
        selectBackdrop: { hex in
            let _ = stateValue.modify { current in
                var updated = current
                updated.selectedBackdropHex = hex
                statePromise.set(updated)
                return updated
            }
        },
        updateNumber: { num in
            let _ = stateValue.modify { current in
                var updated = current
                updated.giftNumber = num
                statePromise.set(updated)
                return updated
            }
        },
        updateTransfer: { val in
            let _ = stateValue.modify { current in
                var updated = current
                updated.canTransfer = val
                statePromise.set(updated)
                return updated
            }
        },
        updateResell: { val in
            let _ = stateValue.modify { current in
                var updated = current
                updated.canResell = val
                statePromise.set(updated)
                return updated
            }
        },
        saveGift: {
            let state = stateValue.with { $0 }
            let gift = FakeStarGiftItem(
                id: UUID(),
                baseGiftId: state.selectedBaseGiftId,
                backdropColorHex: state.selectedBackdropHex,
                patternName: state.selectedPatternName,
                giftNumber: state.giftNumber,
                canTransfer: state.canTransfer,
                canResell: state.canResell
            )
            FakeProfileManager.shared.addGift(gift)
            completion()
            dismissImpl?()
        }
    )
    
    // Подгрузка доступных моделей из кэша Star Gifts
    let cachedGiftsSignal = context.engine.payments.cachedStarGifts()
    
    let signal = combineLatest(
        context.sharedContext.presentationData,
        statePromise.get(),
        cachedGiftsSignal
    )
    |> map { presentationData, state, cachedGifts -> (ItemListControllerState, (ItemListNodeState, Any)) in
        var entries: [FakeGiftConstructorEntry] = []
        
        entries.append(.modelHeader("МОДЕЛЬ ПОДАРКА"))
        
        var availableModels: [(Int64, String)] = []
        if let cached = cachedGifts, !cached.isEmpty {
            for gift in cached {
                switch gift {
                case let .generic(genericGift):
                    let title = genericGift.title ?? "Gift #\(genericGift.id)"
                    availableModels.append((genericGift.id, title))
                case let .unique(uniqueGift):
                    availableModels.append((uniqueGift.id, uniqueGift.title))
                }
            }
        }
        
        // Если в кэше пусто, используем качественные дефолтные пресеты клиента
        if availableModels.isEmpty {
            for preset in FakeGiftModelPreset.presets {
                availableModels.append((preset.id, preset.name))
            }
        }
        
        for (index, model) in availableModels.prefix(8).enumerated() {
            let isSelected = (state.selectedBaseGiftId == model.0)
            entries.append(.modelOption(index: index, id: model.0, name: model.1, isSelected: isSelected))
        }
        
        entries.append(.backdropHeader("ФОН (BACKDROP)"))
        for (index, color) in FakeGiftBackdropColor.palette.enumerated() {
            let isSelected = (state.selectedBackdropHex.lowercased() == color.hex.lowercased())
            entries.append(.backdropOption(index: index, name: color.name, hex: color.hex, isSelected: isSelected))
        }
        
        entries.append(.detailsHeader("ПАРАМЕТРЫ ПОДАРКА"))
        entries.append(.numberInput("Номер экземпляра", "#\(state.giftNumber)"))
        entries.append(.canTransferToggle(state.canTransfer))
        entries.append(.canResellToggle(state.canResell))
        
        entries.append(.saveAction("Добавить подарок в профиль"))
        
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Конструктор подарка"),
            leftNavigationButton: ItemListNavigationButton(
                content: .text(presentationData.strings.Common_Cancel),
                style: .regular,
                enabled: true,
                action: {
                    dismissImpl?()
                }
            ),
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
    dismissImpl = { [weak controller] in
        controller?.dismiss()
    }
    return controller
}
