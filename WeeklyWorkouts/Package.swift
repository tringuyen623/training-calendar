// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "WeeklyWorkouts",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "WeeklyWorkouts",
            targets: ["WeeklyWorkouts"]
        ),
    ],
    targets: [
        .target(
            name: "WeeklyWorkouts",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "WeeklyWorkoutsTests",
            dependencies: ["WeeklyWorkouts"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ]
)
