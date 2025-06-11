//
//  QiblaView.swift
//  Athan
//
//  Created by Usman Hasan on 5/25/25.
//

import SwiftUI
import CoreLocation

struct QiblaView: View {
    @StateObject private var directionManager = QiblaDirectionManager()
    @State private var didTriggerHaptic = false
    @State private var isInRange = false

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.4), lineWidth: 4)
                    .frame(width: 250, height: 250)

                // Compass tick marks
                ForEach(0..<360, id: \.self) { angle in
                    Rectangle()
                        .fill(Color.gray.opacity(angle % 30 == 0 ? 0.6 : 0.2))
                        .frame(width: 1, height: angle % 30 == 0 ? 15 : 6)
                        .offset(y: -125)
                        .rotationEffect(.degrees(Double(angle)))
                }

                // Qibla Arrow
                Image(systemName: "arrowtriangle.up.fill")
                    .resizable()
                    .frame(width: 25, height: 40)
                    .foregroundColor(isInRange ? .green : .red)
                    .rotationEffect(.degrees(qiblaNeedleAngle))
                    .animation(.easeInOut(duration: 0.3), value: qiblaNeedleAngle)

                Text("🕋")
                    .font(.largeTitle)
                    .offset(y: -130)
            }

            Text("Qibla: \(Int(directionManager.qiblaBearing))°, Heading: \(Int(directionManager.heading))°")
                .font(.subheadline)
                .padding(.bottom)
        }
        .onChange(of: qiblaNeedleAngle) { _ in
            let newInRange = abs(qiblaNeedleAngle) < 10
            isInRange = newInRange
        }
    }

    var qiblaNeedleAngle: Double {
        let delta = directionManager.qiblaBearing - directionManager.heading
        let normalized = (delta + 360).truncatingRemainder(dividingBy: 360)
        return normalized > 180 ? normalized - 360 : normalized
    }
}
