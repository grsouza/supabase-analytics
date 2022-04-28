// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SupabaseAnalytics",
  platforms: [.iOS(.v13)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "SupabaseAnalytics",
      targets: ["SupabaseAnalytics"])
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
    .package(url: "https://github.com/supabase-community/supabase-swift", branch: "master"),
    .package(url: "https://github.com/devicekit/DeviceKit", from: "4.5.2"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "SupabaseAnalytics",
      dependencies: [
        .product(name: "Supabase", package: "supabase-swift"),
        "DeviceKit",
      ]),
    .testTarget(
      name: "SupabaseAnalyticsTests",
      dependencies: ["SupabaseAnalytics"]),
  ]
)
