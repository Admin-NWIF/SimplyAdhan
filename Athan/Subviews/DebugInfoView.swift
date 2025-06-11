//
//  DebugInfoView.swift
//  SimplyAthan
//
//  Created by Usman Hasan on 6/6/25.
//
import SwiftUI
import Foundation

struct DebugInfoView: View {
    @EnvironmentObject var prayerSettings: PrayerSettings

    
    var body: some View {
        Text("Timezone: \(prayerSettings.timezone)")
        Text("City: \(prayerSettings.selectedCity)")
    }
}
