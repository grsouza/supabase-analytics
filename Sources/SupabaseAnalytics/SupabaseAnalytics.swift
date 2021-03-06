import Combine
import DeviceKit
import Foundation
import GoTrue
import Supabase

public final class SupabaseAnalytics {

  private static var instance: SupabaseAnalytics?
  private static var shared: SupabaseAnalytics {
    guard let instance = instance else {
      fatalError(
        "SupabaseAnalytics.initialize() should be called before using it.")
    }

    return instance
  }

  private let client: SupabaseClient
  private let tableName: String
  private let useLoggedUserInfo: Bool
  private let logUserSignIn: Bool

  private var authChangeCancellable: AnyCancellable?

  private init(
    client: SupabaseClient,
    tableName: String,
    useLoggedUserInfo: Bool,
    logUserSignIn: Bool
  ) {
    self.client = client
    self.tableName = tableName
    self.useLoggedUserInfo = useLoggedUserInfo
    self.logUserSignIn = logUserSignIn
  }

  deinit {
    authChangeCancellable?.cancel()
    authChangeCancellable = nil
  }

  public static func initialize(
    client: SupabaseClient,
    tableName: String = "analytics",
    useLoggedUserInfo: Bool = true,
    logUserSignIn: Bool = true
  ) {
    instance = SupabaseAnalytics(
      client: client, tableName: tableName, useLoggedUserInfo: useLoggedUserInfo,
      logUserSignIn: logUserSignIn)

    if logUserSignIn {
      instance?.authChangeCancellable = client.auth.authEventChange
        .filter { $0 == .signedIn }
        .sink { _ in SupabaseAnalytics.logUserSession() }
    }
  }

  public static func logEvent(
    name: String, params: [String: Any]? = nil, completion: ((Error?) -> Void)? = nil
  ) {
    assert(name.count >= 2, "The name must be at least 2 characters long")

    let locale = NSLocale.current as NSLocale
    let device = Device.current

    var params = params ?? [:]
    if shared.useLoggedUserInfo {
      params["user_id"] = shared.client.auth.session?.user.id
    }

    params["country_code"] = locale.countryCode
    params["locale"] = locale.localeIdentifier
    params["timezone"] = TimeZone.current.identifier

    params["model"] = device.model
    params["system_name"] = device.systemName
    params["system_version"] = device.systemVersion
    params["device"] = device.safeDescription

    switch device.batteryState {
    case .charging(let level):
      params["battery_state"] = "charging"
      params["battery_level"] = level
    case .unplugged(let level):
      params["battery_state"] = "unplugged"
      params["battery_level"] = level
    case .full:
      params["battery_state"] = "full"
    case .none:
      break
    }

    params["low_power_mode"] = device.batteryState?.lowPowerMode
    params["orientation"] = device.orientation.description
    params["volume_total_capacity"] = Device.volumeTotalCapacity
    params["volume_available_capacity"] = Device.volumeAvailableCapacity
    params["volume_available_capacity_for_important_usage"] =
      Device.volumeAvailableCapacityForImportantUsage
    params["volume_available_capacity_for_opportunistic_usage"] =
      Device.volumeAvailableCapacityForOpportunisticUsage

    struct Event: Encodable {
      var name: String
      var params: [String: String]
      var timestamp: Date
    }

    // TODO: Accumultate events locally for sending to server in batch.
    shared.client.database.from(shared.tableName)
      .insert(
        values: Event(
          name: name.replacingOccurrences(of: " ", with: "_"),
          params: params.mapValues(String.init(describing:)),
          timestamp: Date()
        ),
        returning: .minimal
      )
      .execute { result in
        switch result {
        case .success(let response):
          NSLog("Response statusCode: %d", response.status)
          completion?(nil)
        case .failure(let error):
          NSLog("Response failure: %@", error.localizedDescription)
          completion?(error)
        }
      }
  }

  private static func logUserSession() {
    logEvent(name: "user_session")
  }
}

extension Device.Orientation: CustomStringConvertible {
  public var description: String {
    switch self {
    case .landscape:
      return "landscape"
    case .portrait:
      return "portrait"
    }
  }
}
