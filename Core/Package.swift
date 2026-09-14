// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "FinanceBuddyCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "FinanceBuddyCore", targets: ["FinanceBuddyCore"])],
    targets: [.target(name: "FinanceBuddyCore"), .testTarget(name: "FinanceBuddyCoreTests", dependencies: ["FinanceBuddyCore"])],
    swiftLanguageModes: [.v6]
)
