//
//  LoadingView.swift
//  Athan
//
//  Created by Usman Hasan on 5/27/25.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Spinner
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(2)

                // App icon image
                Image("logo") // use your asset name here
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

            }

            // Loading text
            Text("Initializing app...")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .ignoresSafeArea()
    }
}
