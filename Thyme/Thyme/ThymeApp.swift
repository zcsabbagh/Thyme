//
//  ThymeApp.swift
//  Thyme
//
//  Created by Zane Sabbagh on 3/30/24.
//

import SwiftUI
import UserNotifications
import ActivityKit
import WidgetKit

@main
struct ThymeApp: App {
    let persistenceController = PersistenceController.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var activity: Activity<TimerAttributes>? = nil

    init() {
        requestNotificationAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                // .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
                case .background: Task { startActivity() }
                default: break
            }
        }
    }



    private func requestNotificationAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            if let error = error {
                print("Notification authorization request error: \(error)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }

   func startActivity() {
        let attributes = TimerAttributes(timerName: "CS 221: Artificial Intelligence")
        let state = TimerAttributes.TimerStatus(endTime: Date().addingTimeInterval(60 * 5))
        activity = try? Activity<TimerAttributes>.request(attributes: attributes, contentState: state, pushType: nil)
    }

    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "App Closed"
        content.body = "The app has been closed."
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }


}
