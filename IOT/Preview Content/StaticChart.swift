//
//  StaticChart.swift
//  IOT
//
//  Created by Leo Cheung on 27/10/2023.
//

import SwiftUI
import Charts

struct StaticChart: View {
    var body: some View {
        Chart {
            BarMark(
                x: .value("Department", "Finance"),
                y: .value("Profit", 300000)
            )
        }.padding()
        
        Chart(Profit.data) {
            BarMark(
                x: .value("Department", $0.department),
                y: .value("Profit", $0.profit)
            ).foregroundStyle(by: .value("Department", $0.department))
        }.padding()
    }
}

struct Profit: Identifiable {
    let department: String
    let profit: Double
    var id: String { department }
}

extension Profit {
    
    static let data: [Profit] = [
        Profit(department: "Production", profit: 15000),
        Profit(department: "Marketing", profit: 8000),
        Profit(department: "Finance", profit: 10000)
    ]
}


