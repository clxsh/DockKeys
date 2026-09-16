import AppKit
import Carbon

extension ModifierChoice {
    var carbonFlags: UInt32 {
        switch self {
        case .option: return UInt32(optionKey)
        case .controlOption: return UInt32(controlKey | optionKey)
        case .commandOption: return UInt32(cmdKey | optionKey)
        case .commandShift: return UInt32(cmdKey | shiftKey)
        case .command: return UInt32(cmdKey)
        case .control: return UInt32(controlKey)
        }
    }
}

final class HotKeyManager {
    private let signature: OSType = 0x444B5953 // DKYS
    private let keyCodes = [kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4,
                            kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8,
                            kVK_ANSI_9, kVK_ANSI_0]
    private var handler: EventHandlerRef?
    private var references: [EventHotKeyRef] = []
    private var pressed = Set<Int>()
    var onPress: ((Int) -> Void)?
    private(set) var installError: OSStatus = noErr

    init() {
        var events = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        ]
        installError = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(context).takeUnretainedValue()
            var id = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
            guard status == noErr, id.signature == manager.signature else {
                return OSStatus(eventNotHandledErr)
            }
            let slot = Int(id.id) - 1
            if GetEventKind(event) == UInt32(kEventHotKeyReleased) {
                manager.pressed.remove(slot)
            } else if manager.pressed.insert(slot).inserted {
                manager.onPress?(slot)
            }
            return noErr
        }, events.count, &events, Unmanaged.passUnretained(self).toOpaque(), &handler)
    }

    // Only populated slots are registered, so empty numbers remain available to apps.
    func register(count: Int, modifier: ModifierChoice) -> [Int: OSStatus] {
        unregister()
        var failures: [Int: OSStatus] = [:]
        for slot in 0..<min(max(count, 0), keyCodes.count) {
            guard installError == noErr else { failures[slot] = installError; continue }
            var reference: EventHotKeyRef?
            let id = EventHotKeyID(signature: signature, id: UInt32(slot + 1))
            let status = RegisterEventHotKey(UInt32(keyCodes[slot]), modifier.carbonFlags,
                id, GetApplicationEventTarget(), 0, &reference)
            if status == noErr, let reference { references.append(reference) }
            else { failures[slot] = status }
        }
        return failures
    }

    func unregister() {
        references.forEach { UnregisterEventHotKey($0) }
        references.removeAll()
        pressed.removeAll()
    }

    deinit {
        unregister()
        if let handler { RemoveEventHandler(handler) }
    }
}
