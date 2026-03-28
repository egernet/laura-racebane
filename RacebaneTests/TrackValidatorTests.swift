import XCTest
@testable import Racebane

final class TrackValidatorTests: XCTestCase {

    // MARK: - Simulate tests

    func testStraightSegmentMovesForward() {
        let segments: [TrackSegment] = [.straight(length: 5.0)]
        let state = TrackValidator.simulate(segments: segments)

        XCTAssertEqual(state.posX, 5.0, accuracy: 0.01)
        XCTAssertEqual(state.posZ, 0.0, accuracy: 0.01)
        XCTAssertEqual(state.heading, 0.0, accuracy: 0.01)
    }

    func testCurve90DegreesLeft() {
        let segments: [TrackSegment] = [
            .curve(angle: .pi / 2, radius: 2.0)
        ]
        let state = TrackValidator.simulate(segments: segments)

        XCTAssertEqual(state.posX, 2.0, accuracy: 0.01)
        XCTAssertEqual(state.posZ, 2.0, accuracy: 0.01)
        XCTAssertEqual(state.heading, .pi / 2, accuracy: 0.01)
    }

    func testSimpleOvalSegmentsAreClosed() {
        let segments: [TrackSegment] = [
            .straight(length: 5.0),
            .curve(angle: .pi, radius: 2.0),
            .straight(length: 5.0),
            .curve(angle: .pi, radius: 2.0)
        ]
        let state = TrackValidator.simulate(segments: segments)

        XCTAssertTrue(state.isClosed, "Oval burde være lukket. pos=\(state.positionError), heading=\(state.headingError)")
    }

    func testOpenTrackIsNotClosed() {
        let segments: [TrackSegment] = [
            .straight(length: 5.0),
            .curve(angle: .pi / 2, radius: 2.0),
            .straight(length: 3.0)
        ]
        let state = TrackValidator.simulate(segments: segments)

        XCTAssertFalse(state.isClosed, "Åben bane burde ikke være lukket")
    }

    // MARK: - TrackPiece tests

    func testTrackPieceAngleDegrees() {
        XCTAssertEqual(TrackPiece.straight.angleDegrees, 0)
        XCTAssertEqual(TrackPiece.curveLeft.angleDegrees, 45)
        XCTAssertEqual(TrackPiece.curveRight.angleDegrees, -45)
        XCTAssertEqual(TrackPiece.wideCurveLeft.angleDegrees, 45)
    }

    // MARK: - Vinkel-validering

    func testBeginnerOvalAngleSum() {
        let track = TrackCatalog.beginnerOval
        XCTAssertEqual(track.totalAngleDegrees, 360, accuracy: 0.1,
                       "Begynder Oval vinkelsum burde være 360°, er \(track.totalAngleDegrees)°")
    }

    func testFigureEightAngleSum() {
        let track = TrackCatalog.figurEight
        XCTAssertEqual(track.totalAngleDegrees, 0, accuracy: 0.1,
                       "Otte-tal vinkelsum burde være 0°, er \(track.totalAngleDegrees)°")
    }

    func testGrandPrixAngleSum() {
        let track = TrackCatalog.grandPrix
        XCTAssertEqual(track.totalAngleDegrees, 360, accuracy: 0.1,
                       "Grand Prix vinkelsum burde være 360°, er \(track.totalAngleDegrees)°")
    }

    func testLaurasLoopAngleSum() {
        let track = TrackCatalog.laurasLoop
        XCTAssertEqual(track.totalAngleDegrees, 360, accuracy: 0.1,
                       "Lauras Løkke vinkelsum burde være 360°, er \(track.totalAngleDegrees)°")
    }

    // MARK: - Fuld validering (vinkel + position)

    func testAllCatalogTracksAngleSumIsValid() {
        for track in TrackCatalog.allTracks {
            XCTAssertTrue(
                TrackValidator.validateAngleSum(definition: track),
                "\(track.name): Vinkelsum er \(track.totalAngleDegrees)° (skal være 360° eller 0°)"
            )
        }
    }

    func testAllCatalogTracksAreClosed() {
        for track in TrackCatalog.allTracks {
            let state = TrackValidator.simulate(definition: track)
            XCTAssertTrue(
                state.isClosed,
                "\(track.name) er ikke lukket! pos=\(state.positionError), heading=\(state.headingError)"
            )
        }
    }

    func testAllCatalogTracksPassFullValidation() {
        for track in TrackCatalog.allTracks {
            XCTAssertTrue(
                TrackValidator.isValid(definition: track),
                "\(track.name) fejler fuld validering"
            )
        }
    }

    // MARK: - NormalizeAngle

    func testNormalizeAngle() {
        XCTAssertEqual(TrackValidator.normalizeAngle(0), 0, accuracy: 0.001)
        XCTAssertEqual(TrackValidator.normalizeAngle(2 * .pi), 0, accuracy: 0.001)
        XCTAssertEqual(TrackValidator.normalizeAngle(-2 * .pi), 0, accuracy: 0.001)
        XCTAssertEqual(TrackValidator.normalizeAngle(0.5), 0.5, accuracy: 0.001)
        XCTAssertEqual(TrackValidator.normalizeAngle(-0.5), -0.5, accuracy: 0.001)
    }
}
