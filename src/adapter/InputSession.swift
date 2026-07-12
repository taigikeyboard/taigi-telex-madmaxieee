import TaigiTelexLib

/// Per-controller input state driven by the source identifier supplied by IMK.
public final class InputSession {
  private var engine = TelexEngine(inputMode: .tl)

  public init() {}

  public var inputMode: InputMode { engine.inputMode }

  public func selectSource(_ identifier: String) -> ClientOperationPlan {
    guard let mode = InputMode(rawValue: identifier), mode != engine.inputMode else {
      return ClientOperationPlan(operations: [], isHandled: true)
    }
    let plan = commitPendingComposition()
    engine = TelexEngine(inputMode: mode)
    return plan
  }

  /// Source selection is authoritative, so activation never consults global state.
  public func activate() -> ClientOperationPlan {
    ClientOperationPlan(operations: [], isHandled: true)
  }

  public func deactivate() -> ClientOperationPlan { commitPendingComposition() }

  public func process(_ char: Character) -> ClientOperationPlan {
    ClientOperationAdapter.process(engine.process(char))
  }

  public func backspace() -> ClientOperationPlan {
    ClientOperationAdapter.backspace(engine.backspace())
  }

  public func returnKey() -> ClientOperationPlan {
    guard case let .composing(_, display) = engine.state else {
      return ClientOperationAdapter.returnKey(composingDisplay: nil)
    }
    let plan = ClientOperationAdapter.returnKey(composingDisplay: display)
    engine.reset()
    return plan
  }

  public func commitComposition() -> ClientOperationPlan { commitPendingComposition() }

  public func cancelComposition() -> ClientOperationPlan {
    engine.reset()
    return ClientOperationAdapter.cancel()
  }

  private func commitPendingComposition() -> ClientOperationPlan {
    guard case let .composing(_, display) = engine.state else {
      return ClientOperationPlan(operations: [], isHandled: true)
    }
    engine.reset()
    return ClientOperationAdapter.commit(display)
  }
}
