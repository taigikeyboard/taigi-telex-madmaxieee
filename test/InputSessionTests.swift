import Testing

@testable import TaigiTelexAdapter
@testable import TaigiTelexLib

@Suite("Input Session")
struct InputSessionTests {
  @Test("Defaults to TL before a source is supplied")
  func defaultsToTL() { #expect(InputSession().inputMode == .tl) }

  @Test("Valid source selects POJ")
  func selectsValidSource() {
    let session = InputSession()
    _ = session.selectSource(InputMode.poj.rawValue)
    #expect(session.inputMode == .poj)
  }

  @Test("Selecting the current source has no client operation")
  func ignoresSameSource() {
    #expect(InputSession().selectSource(InputMode.tl.rawValue).operations.isEmpty)
  }

  @Test("Invalid source values leave the selected source unchanged")
  func ignoresInvalidSource() {
    let session = InputSession()
    #expect(session.selectSource("invalid").operations.isEmpty)
    #expect(session.inputMode == .tl)
  }

  @Test("Switch commits pending composition exactly once")
  func commitsBeforeSwitch() {
    let session = InputSession()
    _ = session.process("a")
    #expect(session.selectSource(InputMode.poj.rawValue).operations == [.insertText("a")])
    #expect(session.deactivate().operations.isEmpty)
  }

  @Test("Activation preserves the supplied TL source")
  func activationPreservesTL() {
    let session = InputSession()
    _ = session.selectSource(InputMode.tl.rawValue)
    _ = session.activate()
    #expect(session.process("z").operations == [.setMarkedText("ts", selectionLength: 2)])
  }

  @Test("Activation preserves the supplied POJ source")
  func activationPreservesPOJ() {
    let session = InputSession()
    _ = session.selectSource(InputMode.poj.rawValue)
    _ = session.activate()
    #expect(session.process("z").operations == [.setMarkedText("ch", selectionLength: 2)])
  }

  @Test("Deactivation commits pending composition exactly once")
  func deactivationCommitsOnce() {
    let session = InputSession()
    _ = session.process("a")
    #expect(session.deactivate().operations == [.insertText("a")])
    #expect(session.deactivate().operations.isEmpty)
  }

  @Test("Sessions keep selected sources isolated")
  func sessionsAreIsolated() {
    let tlSession = InputSession()
    let pojSession = InputSession()
    _ = pojSession.selectSource(InputMode.poj.rawValue)
    #expect(tlSession.process("z").operations == [.setMarkedText("ts", selectionLength: 2)])
    #expect(pojSession.process("z").operations == [.setMarkedText("ch", selectionLength: 2)])
  }
}
