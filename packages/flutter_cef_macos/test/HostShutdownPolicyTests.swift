// Standalone unit tests for HostShutdownPolicy: how CefProfileHost.shutdown()
// ends cef_host (straight away, or after giving it time to persist its profile).
// Swift stdlib only, so it compiles + runs with `swiftc` alone:
//   ./test/run_host_shutdown_tests.sh
import Foundation

@main
enum HostShutdownPolicyTests {
  static var failures = 0
  static func check(_ name: String, _ cond: Bool) {
    print((cond ? "  PASS  " : "  FAIL  ") + name)
    if !cond { failures += 1 }
  }

  static func main() {
    check("no grace → terminate now",
          HostShutdownPolicy.plan(graceSeconds: 0, hasCdpPipe: false, hostPid: 10) == .terminateNow)
    check("no grace with a CDP pipe → still terminate now (the old teardown)",
          HostShutdownPolicy.plan(graceSeconds: 0, hasCdpPipe: true, hostPid: 10) == .terminateNow)
    check("negative grace → terminate now",
          HostShutdownPolicy.plan(graceSeconds: -1, hasCdpPipe: true, hostPid: 10) == .terminateNow)
    check("grace, no CDP pipe → SIGTERM after the grace period",
          HostShutdownPolicy.plan(graceSeconds: 8, hasCdpPipe: false, hostPid: 10) == .terminateAfterGrace)
    check("grace with a CDP pipe → close the pipe only after the host exits",
          HostShutdownPolicy.plan(graceSeconds: 8, hasCdpPipe: true, hostPid: 10) == .closeCdpAfterExit)
    check("grace with a CDP pipe but no pid to wait on → SIGTERM after the grace period",
          HostShutdownPolicy.plan(graceSeconds: 8, hasCdpPipe: true, hostPid: 0) == .terminateAfterGrace)
    check("the default grace outlasts the host's 6 s hard-exit deadline",
          HostShutdownPolicy.graceSeconds > 6)
    if failures > 0 { print("\(failures) FAILED"); exit(1) }
    print("all passed")
  }
}
