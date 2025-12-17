import SwiftUI

/*
 Assignment 3: Bézier Rope Simulation
*/

// MARK: - CGPoint helpers
extension CGPoint {
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        CGPoint(x: left.x + right.x, y: left.y + right.y)
    }

    static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        CGPoint(x: left.x - right.x, y: left.y - right.y)
    }

    static func * (point: CGPoint, scalar: Double) -> CGPoint {
        CGPoint(x: point.x * scalar, y: point.y * scalar)
    }

    // Length of the vector — useful before normalizing
    var length: Double {
        sqrt(x * x + y * y)
    }

    // We normalize so the tangent only gives direction, not magnitude
    var unitVector: CGPoint {
        let len = length
        return len == 0 ? .zero : self * (1.0 / len)
    }
}

// MARK: - Simple spring-based physics point
struct SpringPoint {

    var position: CGPoint
    var velocity: CGPoint = .zero

    // These values were chosen by feel.
    // Higher stiffness felt too twitchy, lower felt sluggish.
    private let stiffness: Double = 0.15
    private let dampingFactor: Double = 0.85

    mutating func stepToward(targetPoint: CGPoint) {
        // How far are we from where we want to be?
        let offset = position - targetPoint

        // Spring force tries to pull us back toward the target
        let acceleration = offset * -stiffness

        // Integrate acceleration into velocity
        velocity = velocity + acceleration

        // Damping removes energy so things don’t oscillate forever
        velocity = velocity * dampingFactor

        // Finally update the position
        position = position + velocity
    }
}

// MARK: - Main View
struct ContentView: View {

    // These two points behave like the “loose” parts of the rope
    @State private var leftControlPoint =
        SpringPoint(position: CGPoint(x: 100, y: 300))

    @State private var rightControlPoint =
        SpringPoint(position: CGPoint(x: 200, y: 300))

    // Current finger / mouse position
    @State private var touchLocation =
        CGPoint(x: 200, y: 400)

    var body: some View {
        ZStack {

            // Dark background so the curve pops visually
            Color(red: 0.1, green: 0.1, blue: 0.1)
                .ignoresSafeArea()

            VStack(alignment: .leading) {
                Text("Interactive Bézier Rope")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Manual math + spring physics")
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()
            }
            .padding()

            // TimelineView gives us a nice ~60 FPS update loop
            TimelineView(.animation) { timeline in
                Canvas { graphicsContext, canvasSize in

                    // These endpoints never move — they anchor the rope
                    let leftAnchor =
                        CGPoint(x: canvasSize.width * 0.1,
                                y: canvasSize.height * 0.5)

                    let rightAnchor =
                        CGPoint(x: canvasSize.width * 0.9,
                                y: canvasSize.height * 0.5)

                    drawRopeScene(
                        context: graphicsContext,
                        startAnchor: leftAnchor,
                        endAnchor: rightAnchor,
                        controlA: leftControlPoint.position,
                        controlB: rightControlPoint.position
                    )
                }
                .onChange(of: timeline.date) {
                    // Offset the control points so the rope spreads naturally
                    leftControlPoint.stepToward(
                        targetPoint: CGPoint(
                            x: touchLocation.x - 50,
                            y: touchLocation.y
                        )
                    )

                    rightControlPoint.stepToward(
                        targetPoint: CGPoint(
                            x: touchLocation.x + 50,
                            y: touchLocation.y
                        )
                    )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        touchLocation = drag.location
                    }
            )
        }
    }

    // MARK: - Drawing

    func drawRopeScene(
        context: GraphicsContext,
        startAnchor: CGPoint,
        endAnchor: CGPoint,
        controlA: CGPoint,
        controlB: CGPoint
    ) {

        // A) Tangent visualization
        // These red lines help debug whether the derivative math is correct.
        let tangentDebugPath = Path { path in
            for t in stride(from: 0.1, through: 0.9, by: 0.2) {

                let curvePoint = bezierPoint(
                    t: t,
                    start: startAnchor,
                    control1: controlA,
                    control2: controlB,
                    end: endAnchor
                )

                let tangentDirection = bezierTangent(
                    t: t,
                    start: startAnchor,
                    control1: controlA,
                    control2: controlB,
                    end: endAnchor
                )

                let tangentEnd =
                    curvePoint + (tangentDirection * 150)

                path.move(to: curvePoint)
                path.addLine(to: tangentEnd)
            }
        }

        context.stroke(
            tangentDebugPath,
            with: .color(.red.opacity(0.8)),
            lineWidth: 2
        )

        // B) Main Bézier curve (manually sampled)
        // This avoids using addCurve so the math is explicit.
        var ropePath = Path()
        ropePath.move(to: startAnchor)

        for t in stride(from: 0.01, through: 1.0, by: 0.01) {
            let pointOnCurve = bezierPoint(
                t: t,
                start: startAnchor,
                control1: controlA,
                control2: controlB,
                end: endAnchor
            )
            ropePath.addLine(to: pointOnCurve)
        }

        context.stroke(
            ropePath,
            with: .color(.white),
            lineWidth: 4
        )

        // C) Draw anchors and control points
        for anchor in [startAnchor, endAnchor] {
            let rect = CGRect(
                x: anchor.x - 8,
                y: anchor.y - 8,
                width: 16,
                height: 16
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .color(.blue)
            )
        }

        for control in [controlA, controlB] {
            let rect = CGRect(
                x: control.x - 6,
                y: control.y - 6,
                width: 12,
                height: 12
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .color(.orange)
            )
        }
    }

    // MARK: - Bézier math

    // Standard cubic Bézier equation, written in steps so it’s easier to verify
    func bezierPoint(
        t: Double,
        start: CGPoint,
        control1: CGPoint,
        control2: CGPoint,
        end: CGPoint
    ) -> CGPoint {

        let oneMinusT = 1 - t

        let oneMinusTSquared = oneMinusT * oneMinusT
        let oneMinusTCubed = oneMinusTSquared * oneMinusT

        let tSquared = t * t
        let tCubed = tSquared * t

        let startTerm = start * oneMinusTCubed
        let control1Term = control1 * (3 * oneMinusTSquared * t)
        let control2Term = control2 * (3 * oneMinusT * tSquared)
        let endTerm = end * tCubed

        return startTerm + control1Term + control2Term + endTerm
    }

    // Derivative of the cubic Bézier — needed for tangents
    func bezierTangent(
        t: Double,
        start: CGPoint,
        control1: CGPoint,
        control2: CGPoint,
        end: CGPoint
    ) -> CGPoint {

        let oneMinusT = 1 - t
        let oneMinusTSquared = oneMinusT * oneMinusT
        let tSquared = t * t

        let termA = (control1 - start) * (3 * oneMinusTSquared)
        let termB = (control2 - control1) * (6 * oneMinusT * t)
        let termC = (end - control2) * (3 * tSquared)

        // Normalize so all tangents have the same visual length
        return (termA + termB + termC).unitVector
    }
}
