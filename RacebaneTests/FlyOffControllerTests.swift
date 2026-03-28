import XCTest
@testable import Racebane

final class FlyOffControllerTests: XCTestCase {

    func testDangerLevelIsZeroOnStraight() {
        let controller = FlyOffController()

        let danger = controller.dangerLevel(
            speed: 10.0,
            curvatureRadius: .infinity,
            throttleGripPenalty: 1.0
        )

        XCTAssertEqual(danger, 0, accuracy: 0.001)
    }

    func testFullThrottleIsMoreDangerousThanLiftingGas() {
        let controller = FlyOffController()

        let fullThrottleDanger = controller.dangerLevel(
            speed: 5.0,
            curvatureRadius: 2.5,
            throttleGripPenalty: 1.0
        )
        let liftedDanger = controller.dangerLevel(
            speed: 5.0,
            curvatureRadius: 2.5,
            throttleGripPenalty: 0.0
        )

        XCTAssertGreaterThan(fullThrottleDanger, liftedDanger)
    }

    func testTightCurveHasMoreDangerThanWideCurveAtSameSpeed() {
        let controller = FlyOffController()

        let tightCurveDanger = controller.dangerLevel(
            speed: 5.0,
            curvatureRadius: 2.5,
            throttleGripPenalty: 0.5
        )
        let wideCurveDanger = controller.dangerLevel(
            speed: 5.0,
            curvatureRadius: 4.0,
            throttleGripPenalty: 0.5
        )

        XCTAssertGreaterThan(tightCurveDanger, wideCurveDanger)
    }

    func testLiftingGasCanPreventFlyOffNearLimit() {
        let controller = FlyOffController()
        let borderlineSpeed: Float = 20.5

        XCTAssertTrue(
            controller.checkFlyOff(
                speed: borderlineSpeed,
                curvatureRadius: 2.5,
                throttleGripPenalty: 1.0
            )
        )
        XCTAssertFalse(
            controller.checkFlyOff(
                speed: borderlineSpeed,
                curvatureRadius: 2.5,
                throttleGripPenalty: 0.0
            )
        )
    }

    func testCanStayOnTrackAtSeventyKilometersPerHourInStandardCurve() {
        let controller = FlyOffController()
        let speedAtSeventyKmh: Float = 70.0 / 3.6

        XCTAssertFalse(
            controller.checkFlyOff(
                speed: speedAtSeventyKmh,
                curvatureRadius: 2.5,
                throttleGripPenalty: 1.0
            )
        )
    }

    func testTrackPathStoresCurveDirection() {
        let leftTrack = TrackPath(definition: TrackDefinition(name: "Venstre", pieces: [.curveLeft]))
        let rightTrack = TrackPath(definition: TrackDefinition(name: "Hojre", pieces: [.curveRight]))
        let straightTrack = TrackPath(definition: TrackDefinition(name: "Lige", pieces: [.straight]))

        XCTAssertEqual(leftTrack.points.first?.curveDirection, 1)
        XCTAssertEqual(rightTrack.points.first?.curveDirection, -1)
        XCTAssertEqual(straightTrack.points.first?.curveDirection, 0)
    }
}
