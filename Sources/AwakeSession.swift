import Foundation
import IOKit.pwr_mgt

enum AwakeError: LocalizedError {
  case system(IOReturn)

  var errorDescription: String? {
    switch self {
    case .system(let code):
      return "macOS could not activate keep-awake (error \(code))."
    }
  }
}

/// Owns one power assertion. It never edits the user's system sleep settings.
final class AwakeSession {
  private(set) var assertion: IOPMAssertionID = 0
  private(set) var endDate: Date?
  private let now: () -> Date

  var isActive: Bool { assertion != 0 }

  init(now: @escaping () -> Date = Date.init) {
    self.now = now
  }

  func start(keepDisplayOn: Bool, duration: TimeInterval) throws {
    try setDisplayMode(keepDisplayOn: keepDisplayOn)
    setDuration(duration)
  }

  /// Replacing the mode preserves the existing session deadline.
  func setDisplayMode(keepDisplayOn: Bool) throws {
    var replacement: IOPMAssertionID = 0
    let type =
      keepDisplayOn
      ? kIOPMAssertionTypePreventUserIdleDisplaySleep
      : kIOPMAssertionTypePreventUserIdleSystemSleep
    let result = IOPMAssertionCreateWithName(
      type as CFString,
      IOPMAssertionLevel(kIOPMAssertionLevelOn),
      "Eveille - keeping your Mac awake" as CFString,
      &replacement
    )
    guard result == kIOReturnSuccess else { throw AwakeError.system(result) }

    // Acquire first so a failed replacement cannot interrupt a working session.
    let previous = assertion
    assertion = replacement
    if previous != 0 { IOPMAssertionRelease(previous) }
  }

  /// Zero means unlimited. Changing duration restarts an active countdown.
  func setDuration(_ duration: TimeInterval) {
    endDate = isActive && duration > 0 ? now().addingTimeInterval(duration) : nil
  }

  func expireIfNeeded() {
    if let endDate, now() >= endDate { stop() }
  }

  func stop() {
    if assertion != 0 {
      IOPMAssertionRelease(assertion)
      assertion = 0
    }
    endDate = nil
  }

  deinit { stop() }
}
