//
//  PrayerTimesView.swift
//  Athan
//
//  Created by Usman Hasan on 5/25/25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image("logo") // Or use a symbolic icon like "sparkles"
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 8)
                    .padding(.top)

                Text("SimplyAthan")
                    .font(.largeTitle)
                    .bold()

                Text("The call to prayer made simple. I wanted to build an Athan app that just tells you what time to pray and in what direction. No extensive ads or other features. Do one thing, and do it well.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
