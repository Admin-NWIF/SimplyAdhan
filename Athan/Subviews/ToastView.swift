//
//  ToastView.swift
//  SimplyAthan
//
//  Created by Usman Hasan on 6/21/25.
//
import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(12)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: UUID()) // forces re-animation
    }
}
