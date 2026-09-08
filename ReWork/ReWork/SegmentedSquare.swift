//
//  SegmentedSquare.swift
//  ReWork
//
//  Created by Daniel Molodet on 27/08/2026.
//

import SwiftUI

/// The rounded-rectangle counterpart to SegmentedRing. `trim` works on any
/// Shape — it takes a fraction of the total path length — so the segments
/// follow the corners with no custom path maths.
struct SegmentedSquare: View {
    let completed: Int
    let total: Int
    let color: Color
    var size: CGFloat = 28
    var lineWidth: CGFloat = 3

    private var corner: CGFloat { size * 0.30 }
    private var gap: CGFloat { total > 1 ? 0.05 : 0 }

    var body: some View {
        ZStack {
            ForEach(0..<max(total, 1), id: \.self) { index in
                let slice = 1.0 / CGFloat(max(total, 1))
                RoundedRectangle(cornerRadius: corner)
                    .inset(by: lineWidth / 2)
                    .trim(from: CGFloat(index) * slice + gap / 2,
                          to: CGFloat(index + 1) * slice - gap / 2)
                    .stroke(
                        color.opacity(index < completed ? 1 : 0.18),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
            }
            
            if completed >= total {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(color)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            } else if completed > 0 {
                Text("\(completed)")
                    .font(.system(size: size * 0.46, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
                    .contentTransition(.numericText(value: Double(completed)))
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .padding(8)
        .contentShape(Rectangle())
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: completed)
    }
}
