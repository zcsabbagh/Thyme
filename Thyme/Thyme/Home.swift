//
//  Home.swift
//  Thyme
//
//  Created by Zane Sabbagh on 3/30/24.
//

import Foundation
import SwiftUI
import EventKit
import Combine
import UIKit
import AVFoundation
import PhotosUI

struct HomeView: View {
    @State private var events: [EKEvent] = []
     @State private var currentDate = Date()
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var isShowingKeyboard = false
    @FocusState private var isTextFieldFocused: Bool // Add this line to manage focus state
    
    @State private var inputText: String = ""
    @State private var inputImage: UIImage?
    
    
    private let eventStore = EKEventStore()
    
    var body: some View {
        NavigationView {
            VStack  {
                // Header for the day and date
                VStack(alignment: .leading) {
                    Text(currentDate, format: .dateTime.weekday(.wide)).textCase(.uppercase)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.vertical, -10)
                    Text(currentDate, format: .dateTime.day().month().year())
                        .fontWeight(.light)
                }
                .padding([.horizontal, .vertical], 30)
                .frame(maxWidth: .infinity, alignment: .leading)

                ScrollView {
                    // All Day Events header
                    if !allDayEvents.isEmpty {
                        HStack {
                            Text("ALL DAY")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.horizontal, 30)
                        
                        eventListView(events: allDayEvents)
                    }
                    // Schedule header for non-all-day events
                    if !nonAllDayEvents.isEmpty {
                        HStack {
                            Text("SCHEDULE")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 5)
                        eventListView(events: nonAllDayEvents)
                    }

                }
                .padding(.horizontal)




                Spacer()
                Spacer()

                if isShowingKeyboard { keyboardInputView }
            }
            .gesture(DragGesture().onEnded(handleSwipe))
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: {
                        requestMediaLibraryAccess()
                        self.showingImagePicker = true
                    }) {
                        Image(systemName: "arrow.up.circle")
                    }
                    Button(action: {
                        requestCameraAccess()
                        showingCamera = true
                    }) {
                        Image(systemName: "camera")
                    }
                    
                    Button(action: {
                        withAnimation {
                            isTextFieldFocused = true
                            isShowingKeyboard.toggle()
                            
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                requestAccessToCalendar()
            }
            
            /* let user take a photo of the calendar event they want to add */
            .sheet(isPresented: $showingCamera, onDismiss: {
                if let image = inputImage {  makeRequest(textInput: nil, imageInput: image) }
            }) { CameraView(image: $inputImage) }
            
            /* let the user use an image from their camera roll */
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage, onDismiss: {
                    if let image = inputImage { makeRequest(textInput: nil, imageInput: image) }
                })
            }
            .onDrop(of: ["public.image"], isTargeted: nil) { providers -> Bool in
                providers.first?.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        if let image = image as? UIImage {
                            self.inputImage = image
                            self.makeRequest(textInput: nil, imageInput: image)
                        } else if let error = error {
                            print("Error loading image: \(error.localizedDescription)")
                        }
                    }
                }
                return true
            }
        }
    }

    private var nonAllDayEvents: [EKEvent] {
        events.filter { !$0.isAllDay }
    }

    private var allDayEvents: [EKEvent] {
        events.filter { $0.isAllDay }
    }

    private func eventListView(events: [EKEvent]) -> some View {
            LazyVStack(spacing: 0) {
                ForEach(events, id: \.eventIdentifier) { event in
                    HStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                            .frame(width: 6)
                        VStack(alignment: .leading) {
                            Text(event.title)
                                .fontWeight(.medium)
                            if !event.isAllDay {
                                Text(event.startDate, style: .time) + Text(" → ") + Text(event.endDate, style: .time)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer() // Pushes the content to the left
                    }
                    .padding(.vertical, 10) // Increased vertical padding for more spacing between items
                    .padding(.horizontal) // Add padding on the horizontal edges
                    .frame(maxWidth: .infinity, alignment: .leading) // Make all list items the same length
                    .background(Color.white) // Set the background color to white
                    .cornerRadius(10) // Set the corner radius to match the design
                    .shadow(color: .gray, radius: 3, x: 1, y: 2) // Add a drop shadow
                    .padding(.horizontal, 8) // Decrease the width of each list item slightly by adding horizontal padding
                    .padding(.vertical, 5)
                }
            }
    }
    
    private func requestAccessToCalendar() {
        eventStore.requestFullAccessToEvents { (granted, error) in
            if granted {
                loadEvents(for: currentDate)
            } else {
                // Handle the error or denial of access
            }
        }
    }
    
    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                // Camera access granted, proceed to open the camera
            } else {
                // Handle the error or denial of access
            }
        }
    }

    private func requestMediaLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                // Access has been granted.
                print("Media Library access granted")
            case .denied, .restricted:
                // Access has been denied or restricted.
                print("Media Library access denied or restricted")
            case .notDetermined:
                // Access has not been determined.
                print("Media Library access not determined")
            case .limited:
                print("Media Library access limited")
            @unknown default:
                // Handle future cases
                print("Unknown Media Library access status")
            }
        }
    }
    
    private func loadEvents(for date: Date) {
        let startDate = Calendar.current.startOfDay(for: date)
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        events = eventStore.events(matching: predicate)
    }
    
    private func handleSwipe(_ gesture: DragGesture.Value) {
        let horizontalSwipe = gesture.translation.width
        let swipeThreshold: CGFloat = 50.0
        
        if abs(horizontalSwipe) > swipeThreshold {
            withAnimation {
                if horizontalSwipe > 0 {
                    // Swipe right - Load previous day
                    currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
                } else {
                    // Swipe left - Load next day
                    currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
                }
                loadEvents(for: currentDate) // Reload events for the new date
            }
        }

    }
    
    private func makeRequest(textInput: String?, imageInput: UIImage?) {
        print("Entering makeRequest")
        let title = "Zane & Noosh"
        let startDate = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date())!
        let endDate = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date())!
        
        createEvent(title: title, startDate: startDate, endDate: endDate)
    }
    
    private func createEvent(title: String, startDate: Date, endDate: Date, location: String? = nil, notes: String? = nil, url: URL? = nil) {
        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.calendar = eventStore.defaultCalendarForNewEvents
        newEvent.title = title
        newEvent.startDate = startDate
        newEvent.endDate = endDate
        
        
        if let location = location {
            newEvent.location = location
        }
        if let notes = notes {
            newEvent.notes = notes
        }
        if let url = url {
            newEvent.url = url
        }
        
        do {
            try eventStore.save(newEvent, span: .thisEvent)
            loadEvents(for: currentDate)
        } catch {
            // Handle errors related to saving the event
            print("Error saving event: \(error.localizedDescription)")
        }
    }
    
    private var keyboardInputView: some View {
        HStack {
            TextField("Enter text here...", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .background(Color.gray)
                .cornerRadius(20)
                .padding(5)
                .foregroundColor(.white)
                .focused($isTextFieldFocused) // Use the focused modifier to control focus
                .padding()
            
            Button(action: {
                makeRequest(textInput: inputText, imageInput: nil)
                inputText = "" // Clear the text field after sending
                isTextFieldFocused.toggle()
                isShowingKeyboard.toggle()
            }) {
                Text("Send")
                    .foregroundColor(.blue)
            }
            .padding()
        }
        .transition(.move(edge: .bottom)) // Smooth transition for the input area
        .animation(.default, value: isShowingKeyboard) // Updated to use animation(_:value:) modifier
    }
    
    
    
    
    
    
    
    
    
    
    
}








struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
        @Binding var image: UIImage?
        var onDismiss: () -> Void
        
        func makeUIViewController(context: Context) -> PHPickerViewController {
            var config = PHPickerConfiguration()
            config.selectionLimit = 1 // Allow only a single image to be selected
            config.filter = .images // Show only images
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = context.coordinator
            return picker
        }
        
        func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self, onDismiss: onDismiss)
        }
        
        class Coordinator: NSObject, PHPickerViewControllerDelegate {
            let parent: ImagePicker
            let onDismiss: () -> Void
            
            init(_ parent: ImagePicker, onDismiss: @escaping () -> Void) {
                self.parent = parent
                self.onDismiss = onDismiss
            }
            
            func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
                picker.dismiss(animated: true, completion: onDismiss)
                guard let provider = results.first?.itemProvider else { return }
                if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { image, _ in
                        DispatchQueue.main.async {
                            self.parent.image = image as? UIImage
                        }
                    }
                }
            }
        }
}
