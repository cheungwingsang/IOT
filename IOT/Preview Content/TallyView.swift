//
//  TallyView.swift
//  IOT
//
//  Created by Leo Cheung on 27/10/2023.
//

import SwiftUI
import Charts

struct TallyView: View {
    
    @State var readings = [Reading]()
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Chart(readings) {
            LineMark(
                x: .value("Time", $0.time),
                y: .value("Count", $0.count)
            )
        }.padding()
            .onAppear(perform: startLoad)
            .onReceive(timer) { input in
                startLoad()
            }
    }
}


struct Reading: Identifiable {
    let time: Date
    let count: Int
    var id: String { time.description }
}

struct EzData: Decodable {
    let status: Int
    let data: String
}
extension TallyView {
    
    func handleClientError(_: Error) {
        return
    }
    
    func handleServerError(_: URLResponse?) {
        return
    }
    
    func startLoad() {
        
        let url = URL(string: "https://ezdata.m5stack.com/api/store/57AhFPH0BWitsTNqJbbltltu9FJSj1Ll/count")!
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            if let error = error {
                self.handleClientError(error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                self.handleServerError(response)
                return
            }
            
            if let data = data, let ezData = try? JSONDecoder().decode(EzData.self, from: data) {
                
                let reading = Reading(time: Date.now, count: Int(ezData.data) ?? 0)
                
                if (self.readings.count == 20) {
                    self.readings.removeFirst()
                }
                self.readings.append(reading)
            }
        }
        
        task.resume()
    }
    
}
#Preview {
    TallyView()
}
