import DeviceKit
import Foundation
import GoTrue
import Supabase

public final class SupabaseAnalytics {

  public static var shared: SupabaseAnalytics {
    guard let instance = instance else {
      fatalError(
        "SupabaseAnalytics.initialize() should be called before using SupabaseAnalytics.shared")
    }

    return instance
  }

  private static var instance: SupabaseAnalytics?

  private let client: SupabaseClient
  private let tableName: String
  private let useLoggedUserInfo: Bool
  private let logUserSignIn: Bool

  private var authChangeSubscription: Subscription?

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
    authChangeSubscription?.unsubscribe()
    authChangeSubscription = nil
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
      instance?.authChangeSubscription = client.auth.onAuthStateChange { event, session in
        if event == .signedIn {
          instance?.logUserSession()
        }
      }
    }
  }

  public func logEvent(name: String, params: [String: Any]? = nil) {
    assert(name.count >= 2, "The name must be at least 2 characters long")

    let locale = NSLocale.current as NSLocale
    let device = Device.current

    var params = params ?? [:]
    if useLoggedUserInfo {
      params["user_id"] = client.auth.user?.id
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

    // TODO: Accumultate events locally for sending to server in batch.
    client.database.from(tableName)
      .insert(
        values: [
          "name": name.replacingOccurrences(of: " ", with: "_"),
          "params": params,
          "timestamp": Date().timeIntervalSince1970,
        ],
        returning: .minimal
      )
      .execute { result in
        switch result {
        case .success(let response):
          NSLog("Response statusCode: %d", response.status)
        case .failure(let error):
          NSLog("Response failure: %@", error.localizedDescription)
        }
      }
  }

  private func logUserSession() {
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
