import Foundation
import IOKit.pwr_mgt

func verify(_ condition: @autoclosure () -> Bool, _ message: String) {
  guard condition() else {
    fputs("FAIL: \(message)\n", stderr)
    exit(1)
  }
  print("PASS: \(message)")
}

func assertionType(_ id: IOPMAssertionID) -> String? {
  guard let properties = IOPMAssertionCopyProperties(id)?.takeRetainedValue() as? [String: Any]
  else { return nil }
  return properties[kIOPMAssertionTypeKey] as? String
}

do {
  var time = Date(timeIntervalSinceReferenceDate: 1_000)
  let session = AwakeSession(now: { time })
  verify(!session.isActive && session.endDate == nil, "Starts inactive")
  try session.start(keepDisplayOn: true, duration: 60)
  let firstID = session.assertion
  verify(
    assertionType(firstID) == kIOPMAssertionTypePreventUserIdleDisplaySleep,
    "Display mode creates the correct macOS assertion")
  let deadline = session.endDate
  time = time.addingTimeInterval(20)
  try session.setDisplayMode(keepDisplayOn: false)
  verify(
    assertionType(session.assertion) == kIOPMAssertionTypePreventUserIdleSystemSleep,
    "System-only mode creates the correct macOS assertion")
  verify(assertionType(firstID) == nil, "Replacing the mode releases the previous assertion")
  verify(session.endDate == deadline, "Changing mode preserves the countdown")
  time = time.addingTimeInterval(39)
  session.expireIfNeeded()
  verify(session.isActive, "Session remains active before its deadline")
  time = time.addingTimeInterval(1)
  let expiringID = session.assertion
  session.expireIfNeeded()
  verify(
    !session.isActive && assertionType(expiringID) == nil && session.endDate == nil,
    "Reaching the deadline releases the assertion and clears the timer")
  session.expireIfNeeded()
  verify(!session.isActive, "An expired session does not restart itself")
  try session.start(keepDisplayOn: true, duration: 60)
  time = time.addingTimeInterval(30)
  session.setDuration(120)
  verify(
    session.endDate == time.addingTimeInterval(120), "Changing duration restarts the countdown")
  session.setDuration(0)
  time = time.addingTimeInterval(86_400)
  session.expireIfNeeded()
  verify(session.isActive && session.endDate == nil, "Unlimited sessions do not expire")
  let finalID = session.assertion
  session.stop()
  verify(
    !session.isActive && assertionType(finalID) == nil, "Stopping releases the macOS assertion")
  session.stop()
  verify(!session.isActive, "Repeated stop is harmless")
  session.setDuration(60)
  verify(session.endDate == nil, "Changing duration while inactive does not start a session")
  var transient: AwakeSession? = AwakeSession()
  try transient!.start(keepDisplayOn: true, duration: 0)
  let transientID = transient!.assertion
  transient = nil
  verify(assertionType(transientID) == nil, "Releasing the session cleans up its assertion")
  print("All 14 checks passed.")
} catch {
  fputs("FAIL: \(error)\n", stderr)
  exit(1)
}
