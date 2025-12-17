# Interactive Bézier Rope Simulation

### 📝 Assignment for Flam Placement
**Author:** Jaiprakash Yadav
**Date:** December 2025

## 📌 Overview
This project implements an interactive cubic Bézier curve that behaves like a physical rope. It features a custom physics engine (spring-mass damper system) and manual mathematical implementations of Bézier curves and tangent vectors, strictly adhering to the "no prebuilt APIs" constraint.

## 🎥 Demo
<img width="2796" height="1788" alt="image" src="https://github.com/user-attachments/assets/17fdcc03-03c7-45d5-bf72-aa19322f2e5b" />


## 🛠 Technical Implementation

### 1. Manual Math Implementation
Instead of using SwiftUI's `addCurve`, I implemented the cubic Bézier formula from scratch:
`B(t) = (1-t)³P₀ + 3(1-t)²tP₁ + 3(1-t)t²P₂ + t³P₃`
The curve is drawn by sampling `t` at 0.01 intervals to ensure smooth rendering at 60 FPS.

### 2. Physics Engine
The control points (`P1` and `P2`) are not static; they are modeled as physics objects with:
* **Stiffness (k):** 0.15 (Controls the snap)
* **Damping:** 0.85 (Simulates friction/air resistance)
This creates a natural "drag" effect when the user pulls the rope.

### 3. Interaction
* **Input:** Custom `DragGesture` logic tracks the user's touch/cursor.
* **Visuals:** Tangent vectors (Red lines) are calculated using the first derivative `B'(t)` and visualized at 5 distinct intervals along the curve.

## 🚀 How to Run
1.  Clone the repository.
2.  Open `BezierRope.xcodeproj` in Xcode.
3.  Select an iOS Simulator (e.g., iPhone 15).
4.  Press **Cmd + R** to run.
5.  **Interaction:** Click and drag on the simulator screen to pull the rope.
