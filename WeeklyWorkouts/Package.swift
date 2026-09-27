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
        .library(
            name: "WeeklyWorkoutsUI",
            targets: ["WeeklyWorkoutsUI"]
        ),
    ],
    targets: [
        .target(
            name: "WeeklyWorkouts",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .target(
            name: "WeeklyWorkoutsUI",
            dependencies: ["WeeklyWorkouts"],
            resources: [
                .process("Resources"),
            ],
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
