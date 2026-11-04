// Pure decision for how CefProfileHost.shutdown() ends cef_host.
//
// cef_host persists a profile's cookie store only while it shuts itself down
// (after kOpShutdown, CefShutdown). A SIGTERM straight after kOpShutdown, or the
// EOF of the agent-control CDP pipe (which makes the browser quit at once), cuts
// that short and loses the cookies set in the last ~30 s. A graceful shutdown
// therefore leaves cef_host time to exit by itself, and keeps the CDP pipe open
// until it has.
//
// Dependency-light (Swift stdlib only) → unit-testable standalone with `swiftc`:
//   ./test/run_host_shutdown_tests.sh
import Foundation

enum HostShutdownPolicy {
  /// How long cef_host is left to exit by itself after kOpShutdown. Its own
  /// hard-exit deadline is 6 s, so it is gone before this runs out.
  static let graceSeconds: TimeInterval = 8

  enum Plan: Equatable {
    /// Close the CDP pipe and SIGTERM straight away.
    case terminateNow
    /// No CDP pipe: SIGTERM only if the host is still up after the grace period.
    case terminateAfterGrace
    /// CDP pipe open: close it, and SIGTERM, only once the host has exited or the
    /// grace period is up.
    case closeCdpAfterExit
  }

  static func plan(graceSeconds: TimeInterval, hasCdpPipe: Bool, hostPid: Int32) -> Plan {
    if graceSeconds <= 0 { return .terminateNow }
    if hasCdpPipe && hostPid > 0 { return .closeCdpAfterExit }
    return .terminateAfterGrace
  }
}
