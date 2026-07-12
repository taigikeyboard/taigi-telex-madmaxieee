import TaigiTelexLib

/// Framework-independent operations that an input client can perform.
public enum ClientOperation: Equatable {
  case setMarkedText(String, selectionLength: Int)
  case insertText(String)
}

/// The client operations and event disposition for a controller action.
public struct ClientOperationPlan: Equatable {
  public let operations: [ClientOperation]
  public let isHandled: Bool

  public init(operations: [ClientOperation], isHandled: Bool) {
    self.operations = operations
    self.isHandled = isHandled
  }
}

/// Maps controller-facing engine results to client operations without IMK types.
public enum ClientOperationAdapter {
  public static func process(_ result: TelexResult) -> ClientOperationPlan {
    switch result {
    case let .update(display):
      return ClientOperationPlan(operations: [markedText(display)], isHandled: true)
    case let .commitAndPassthrough(committedText):
      return ClientOperationPlan(operations: [.insertText(committedText)], isHandled: false)
    case let .commitAndUpdate(committedText, newDisplay):
      return ClientOperationPlan(
        operations: [.insertText(committedText), markedText(newDisplay)], isHandled: true)
    case let .commit(committedText):
      return ClientOperationPlan(operations: [.insertText(committedText)], isHandled: true)
    }
  }

  public static func backspace(_ result: TelexResult?) -> ClientOperationPlan {
    guard let result else {
      return ClientOperationPlan(operations: [], isHandled: false)
    }
    return process(result)
  }

  public static func returnKey(composingDisplay: String?) -> ClientOperationPlan {
    guard let composingDisplay else {
      return ClientOperationPlan(operations: [], isHandled: false)
    }
    return commit(composingDisplay)
  }

  public static func commit(_ composingDisplay: String) -> ClientOperationPlan {
    ClientOperationPlan(operations: [.insertText(composingDisplay)], isHandled: true)
  }

  public static func cancel() -> ClientOperationPlan {
    ClientOperationPlan(operations: [markedText("")], isHandled: true)
  }

  private static func markedText(_ display: String) -> ClientOperation {
    .setMarkedText(display, selectionLength: display.utf16.count)
  }
}
