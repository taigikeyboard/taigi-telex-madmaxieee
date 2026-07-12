import InputMethodKit
import TaigiTelexAdapter

@objc(TaigiTelexInputController)
class TaigiTelexInputController: IMKInputController {
  private let session = InputSession()

  override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
    super.init(server: server, delegate: delegate, client: inputClient)
  }

  /// Called by the system when input mode changes
  override func setValue(_ value: Any!, forTag _: Int, client sender: Any!) {
    guard let modeId = value as? String else {
      return
    }

    guard let client = sender as? IMKTextInput else {
      return
    }
    let plan = session.selectSource(modeId)
    apply(plan, client: client)
    if !plan.operations.isEmpty {
      super.commitComposition(sender)
    }
  }

  /// Called when the application becomes active
  override func activateServer(_ sender: Any!) {
    super.activateServer(sender)
    if let client = sender as? IMKTextInput {
      apply(session.activate(), client: client)
    }
  }

  /// Called when the application resigns active
  override func deactivateServer(_ sender: Any!) {
    if let client = sender as? IMKTextInput {
      let plan = session.deactivate()
      apply(plan, client: client)
      if !plan.operations.isEmpty {
        super.commitComposition(sender)
      }
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
      if let client = sender as? IMKTextInput {
        let plan = session.commitComposition()
        apply(plan, client: client)
        if !plan.operations.isEmpty {
          super.commitComposition(sender)
        }
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
    let plan = session.backspace()
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
    let plan = session.returnKey()
    apply(plan, client: client)
    return plan.isHandled
  }

  private func handleCharacterInput(_ event: NSEvent, client: IMKTextInput, sender: Any!) -> Bool {
    guard let characters = event.characters, let firstChar = characters.first else {
      return false
    }

    let plan = session.process(firstChar)
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

    apply(session.commitComposition(), client: client)

    super.commitComposition(sender)
  }

  override func cancelComposition() {
    if let client = client() {
      apply(session.cancelComposition(), client: client)
    } else {
      _ = session.cancelComposition()
    }

    super.cancelComposition()
  }
}
