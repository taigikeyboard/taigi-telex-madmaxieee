import InputMethodKit
import TaigiTelexAdapter
import TaigiTelexLib

@objc(TaigiTelexInputController)
class TaigiTelexInputController: IMKInputController {
  private var engine: TelexEngine

  private static let currentModeKey = "taigiTelex.currentMode"

  override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
    // Read last used mode from UserDefaults, fallback to TL
    let savedModeString =
      UserDefaults.standard.string(forKey: Self.currentModeKey)
      ?? InputMode.tl.rawValue
    let initialMode = InputMode(rawValue: savedModeString) ?? .tl
    engine = TelexEngine(inputMode: initialMode)
    super.init(server: server, delegate: delegate, client: inputClient)
  }

  /// Called by the system when input mode changes
  override func setValue(_ value: Any!, forTag _: Int, client sender: Any!) {
    guard let modeId = value as? String else {
      return
    }

    guard let newMode = InputMode(rawValue: modeId) else {
      return
    }

    // Only update if mode actually changed
    if engine.inputMode != newMode {

      // Persist the mode change
      UserDefaults.standard.set(newMode.rawValue, forKey: Self.currentModeKey)

      // Commit any pending composition before switching
      if !engine.isEmpty {
        commitComposition(sender)
      }

      // Create new engine with new mode
      engine = TelexEngine(inputMode: newMode)
    } else {
    }
  }

  /// Called when the application becomes active
  override func activateServer(_ sender: Any!) {
    super.activateServer(sender)
    // Ensure we're in sync with the persisted mode when app becomes active
    let savedModeString =
      UserDefaults.standard.string(forKey: Self.currentModeKey)
      ?? InputMode.tl.rawValue
    if let savedMode = InputMode(rawValue: savedModeString), engine.inputMode != savedMode {
      if !engine.isEmpty {
        commitComposition(sender)
      }
      engine = TelexEngine(inputMode: savedMode)
    }
  }

  /// Called when the application resigns active
  override func deactivateServer(_ sender: Any!) {
    // Commit any pending composition when leaving the app
    if !engine.isEmpty {
      commitComposition(sender)
    }
    super.deactivateServer(sender)
  }

  @objc(handleEvent:client:)
  override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
    guard event.type == .keyDown else {
      return false
    }

    guard let client = sender as? IMKTextInput else {
      return false
    }

    if shouldPassThroughModifierKeys(event, sender: sender) {
      return false
    }

    if let result = handleSpecialKeys(event, client: client) {
      return result
    }

    return handleCharacterInput(event, client: client, sender: sender)
  }

  private func shouldPassThroughModifierKeys(_ event: NSEvent, sender: Any!) -> Bool {
    let modifierFlags = event.modifierFlags
    if modifierFlags.contains(.command) || modifierFlags.contains(.control)
      || modifierFlags.contains(.option)
    {
      if !engine.isEmpty {
        commitComposition(sender)
      }
      return true
    }
    return false
  }

  private func handleSpecialKeys(_ event: NSEvent, client: IMKTextInput) -> Bool? {
    if event.keyCode == 51 {
      return handleBackspace(client: client)
    }

    if event.keyCode == 36 {
      return handleReturn(client: client)
    }

    return nil
  }

  private func handleBackspace(client: IMKTextInput) -> Bool {
    let plan = ClientOperationAdapter.backspace(engine.backspace())
    apply(plan, client: client)
    return plan.isHandled
  }

  private func apply(_ plan: ClientOperationPlan, client: IMKTextInput) {
    for operation in plan.operations {
      switch operation {
      case let .setMarkedText(text, selectionLength):
        client.setMarkedText(
          text,
          selectionRange: NSRange(location: selectionLength, length: 0),
          replacementRange: NSRange(location: NSNotFound, length: NSNotFound),
        )
      case let .insertText(text):
        client.insertText(
          text,
          replacementRange: NSRange(location: NSNotFound, length: NSNotFound),
        )
      }
    }
  }

  private func handleReturn(client: IMKTextInput) -> Bool {
    let display: String?
    if case let .composing(_, composingDisplay) = engine.state {
      display = composingDisplay
    } else {
      display = nil
    }
    let plan = ClientOperationAdapter.returnKey(composingDisplay: display)
    apply(plan, client: client)
    if plan.isHandled {
      engine.reset()
    }
    return plan.isHandled
  }

  private func handleCharacterInput(_ event: NSEvent, client: IMKTextInput, sender: Any!) -> Bool {
    guard let characters = event.characters, let firstChar = characters.first else {
      return false
    }

    let result = engine.process(firstChar)
    return processEngineResult(result, event: event, client: client, sender: sender)
  }

  private func processEngineResult(
    _ result: TelexResult,
    event: NSEvent,
    client: IMKTextInput,
    sender: Any!,
  ) -> Bool {
    let plan = ClientOperationAdapter.process(result)
    apply(plan, client: client)
    return plan.isHandled
  }

  private func createKeyEvent(_ event: NSEvent, char: Character) -> NSEvent? {
    NSEvent.keyEvent(
      with: .keyDown,
      location: .zero,
      modifierFlags: [],
      timestamp: event.timestamp,
      windowNumber: event.windowNumber,
      context: nil,
      characters: String(char),
      charactersIgnoringModifiers: String(char),
      isARepeat: false,
      keyCode: 0,
    )
  }

  override func commitComposition(_ sender: Any!) {
    guard let client = sender as? IMKTextInput else { return }

    if case let .composing(_, display) = engine.state {
      apply(ClientOperationAdapter.commit(display), client: client)
      engine.reset()
    }

    super.commitComposition(sender)
  }

  override func cancelComposition() {
    if let client = client() {
      apply(ClientOperationAdapter.cancel(), client: client)
    }

    engine.reset()
    super.cancelComposition()
  }
}
