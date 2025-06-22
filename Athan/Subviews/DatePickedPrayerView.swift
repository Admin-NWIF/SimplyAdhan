//
//  PrayerPreviewView.swift
//  SimplyAthan
//
//  Created by Usman Hasan on 6/21/25.
//
import SwiftUI
import Foundation
import Adhan

struct DatePickedPrayerView: View {
    let selectedDate: Date
    
    @EnvironmentObject var prayerSettings: PrayerSettings
//    @EnvironmentObject var prayerTimesModel: PrayerTimesModel
    @EnvironmentObject var prayerTimesVM: PrayerTimesViewModel
    
    var body: some View {
        
        let model = PrayerTimesModel()
        let handler = PrayerTimesHandler()
        
        let prayerTimes = handler.getPrayerTimes(for: prayerSettings.coordinates, date: selectedDate, madhab: prayerSettings.madhab, method: prayerSettings.calculationMethod, timezone: prayerSettings.timezone) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let returnedModel):
                    model.date = returnedModel.date
                    model.fajr = returnedModel.fajr
                    model.sunrise = returnedModel.sunrise
                    model.dhuhr = returnedModel.dhuhr
                    model.asr = returnedModel.asr
                    model.maghrib = returnedModel.maghrib
                    model.isha = returnedModel.isha
                    model.qiyam = returnedModel.qiyam
                    model.coordinates = returnedModel.coordinates
                    model.options = returnedModel.options
                    
//                    print("Prayer times Model: " + prayerTimesModel.maghrib.description)
                    print("Local model: " + model.maghrib.description)
                    print("Returned model: " + returnedModel.maghrib.description)

                case .failure(let error):
                    print("❌ Failed to fetch prayer times:", error)
                }
            }
        }
        
        ScrollView{
            VStack(spacing: 12){
                Text(formattedDate(selectedDate))
                    .font(.headline)
                    .padding(.top)
                
                HStack {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading) {
                        Text("Current City")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(prayerSettings.selectedCity)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(red: 0.0, green: 101/255, blue: 66/255))
                .cornerRadius(12)
                .padding(.horizontal)
                
                ForEach(prayerTiles(from: model), id: \ .name) { prayer in
                    HStack {
                        Image(systemName: prayer.icon)
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text(prayer.name)
                                .font(.headline)
                            Text(prayer.time)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    func prayerTiles(from model: PrayerTimesModel) -> [(name: String, time: String, icon: String)] {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: model.options?.timezone ?? TimeZone.current.identifier)
        
        return [
            (Prayers.FAJR.rawValue, formatter.string(from: model.fajr), PrayerIcons.FAJR.rawValue),
            (Prayers.SUNRISE.rawValue, formatter.string(from: model.sunrise), PrayerIcons.SUNRISE.rawValue),
            (Prayers.DHUHR.rawValue, formatter.string(from: model.dhuhr), PrayerIcons.DHUHR.rawValue),
            (Prayers.ASR.rawValue, formatter.string(from: model.asr), PrayerIcons.ASR.rawValue),
            (Prayers.MAGHRIB.rawValue, formatter.string(from: model.maghrib), PrayerIcons.MAGHRIB.rawValue),
            (Prayers.ISHA.rawValue, formatter.string(from: model.isha), PrayerIcons.ISHA.rawValue),
            (Prayers.QIYAM.rawValue, formatter.string(from: model.qiyam), PrayerIcons.QIYAM.rawValue)
        ]
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}
