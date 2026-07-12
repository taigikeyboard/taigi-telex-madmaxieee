import Testing

@testable import TaigiTelexAdapter
@testable import TaigiTelexLib

@Suite("Client Operation Adapter")
struct ClientOperationAdapterTests {
  @Test("Maps all Telex result cases")
  func mapsTelexResults() {
    #expect(
      ClientOperationAdapter.process(.update(display: "á"))
        == ClientOperationPlan(
          operations: [.setMarkedText("á", selectionLength: 1)], isHandled: true))
    #expect(
      ClientOperationAdapter.process(.commit("a"))
        == ClientOperationPlan(operations: [.insertText("a")], isHandled: true))
    #expect(
      ClientOperationAdapter.process(.commitAndPassthrough("a"))
        == ClientOperationPlan(operations: [.insertText("a")], isHandled: false))
    #expect(
      ClientOperationAdapter.process(.commitAndUpdate("a", "-"))
        == ClientOperationPlan(
          operations: [.insertText("a"), .setMarkedText("-", selectionLength: 1)], isHandled: true))
  }

  @Test("Uses UTF-16 selection length and clears empty marked text")
  func mapsMarkedTextSelection() {
    #expect(
      ClientOperationAdapter.process(.update(display: "😀"))
        == ClientOperationPlan(
          operations: [.setMarkedText("😀", selectionLength: 2)], isHandled: true))
    #expect(
      ClientOperationAdapter.process(.update(display: ""))
        == ClientOperationPlan(
          operations: [.setMarkedText("", selectionLength: 0)], isHandled: true))
  }

  @Test("Maps backspace, Return, commit, and cancel boundaries")
  func mapsControllerBoundaries() {
    #expect(ClientOperationAdapter.backspace(nil).isHandled == false)
    #expect(
      ClientOperationAdapter.backspace(.update(display: ""))
        == ClientOperationPlan(
          operations: [.setMarkedText("", selectionLength: 0)], isHandled: true))
    #expect(ClientOperationAdapter.returnKey(composingDisplay: nil).isHandled == false)
    #expect(
      ClientOperationAdapter.returnKey(composingDisplay: "á")
        == ClientOperationPlan(operations: [.insertText("á")], isHandled: true))
    #expect(
      ClientOperationAdapter.commit("á")
        == ClientOperationPlan(operations: [.insertText("á")], isHandled: true))
    #expect(
      ClientOperationAdapter.cancel()
        == ClientOperationPlan(
          operations: [.setMarkedText("", selectionLength: 0)], isHandled: true))
  }
}
