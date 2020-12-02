//
//  ContentView.swift
//  ARExperience
//
//  Created by Jowanza Joseph on 11/22/20.
//

import SwiftUI
import SwiftUICam
import ARGear

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .padding()
    }
}

//struct ContentView: View {
//    @ObservedObject var events = UserEvents()
//    var body: some View {
//        ZStack {
//              CameraView(events: events, applicationName: "SwiftUICam")
//          CameraInterfaceView(events: events)
//        }
//    }
//}

private func setupCamera() {
    arCamera = ARGCamera()
    
    arCamera.sampleBufferHandler = { [weak self] output, sampleBuffer, connection in
        guard let self = self else { return }
        
        self.serialQueue.async {

            self.argSession?.update(sampleBuffer, from: connection)
        }
    }
    
    arCamera.metadataObjectsHandler = { [weak self] metadataObjects, connection in
        guard let self = self else { return }
        
        self.serialQueue.async {
            self.argSession?.update(metadataObjects, from: self.arCamera.cameraConnection!)
        }
    }
    
    self.permissionCheck {
        self.arCamera.startCamera()
        
        self.setCameraInfo()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
