//
//  ContentView.swift
//  Athan
//
//  Created by Usman Hasan on 5/25/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isAppInitialized = false
    
    let handler = PrayerTimesHandler()
    
    var body: some View {
        Group {
            if isAppInitialized {
                TabView {
                    PrayerTimesView()
                        .tabItem {
                            Image(systemName: "clock")
                            Text("Prayer Times")
                        }
                    
                    QiblaView()
                        .tabItem {
                            Image(systemName: "location.north.line")
                            Text("Qibla")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Image(systemName: "gearshape")
                            Text("Settings")
                        }
                }
            } else {
                LoadingView()   
            }
        }
        .onAppear() {
                DispatchQueue.main.async {
                    isAppInitialized = true
                }
        }
    }
}
