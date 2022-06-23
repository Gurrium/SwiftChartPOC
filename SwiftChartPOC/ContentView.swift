//
//  ContentView.swift
//  SwiftChartPOC
//
//  Created by gurrium on 2022/06/21.
//

import SwiftUI
import Charts

struct ContentView: View {
    @StateObject
    private var state = ViewState()

    var body: some View {
        if state.data.isEmpty {
            Button {
                state.parse()
            } label: {
                Text("Load")
            }
        } else if let minDataDistance = state.data.first?.0,
                  let maxDataDistance = state.data.last?.0,
                  minDataDistance < maxDataDistance {
            VStack {
                Chart(state.data, id: \.0) { (distance, altitude) in
                    LineMark(
                        x: .value("Distance", distance),
                        y: .value("Altitude", altitude)
                    )
                }
                Slider(value: $state.minDistance, in: minDataDistance...maxDataDistance, step: 0.5) {
                    Text("始点")
                } minimumValueLabel: {
                    Text("\(minDataDistance)")
                } maximumValueLabel: {
                    Text("\(maxDataDistance)")
                }
                Slider(value: $state.maxDistance, in: minDataDistance...maxDataDistance, step: 0.5) {
                    Text("始点")
                } minimumValueLabel: {
                    Text("\(minDataDistance)")
                } maximumValueLabel: {
                    Text("\(maxDataDistance)")
                }
            }
        }
    }

    private class ViewState: NSObject, ObservableObject, XMLParserDelegate {
        private enum ElementName: String, CaseIterable {
            case altitude = "AltitudeMeters"
            case distance = "DistanceMeters"
        }

        @Published
        var minDistance = 0.0
        @Published
        var maxDistance = 0.0
        var data: [(Double, Double)] {
            let indices = distanceData.indices
            guard let lowerIndex = distanceData.lastIndex(where: { distance in
                      distance <= minDistance
                  }),
                  let upperIndex = distanceData.lastIndex(where: { distance in
                      distance <= maxDistance
                  }),
                  indices.contains(lowerIndex),
                  indices.contains(upperIndex),
                  lowerIndex <= upperIndex else {
                return Array(zip(distanceData, altitudeData))
            }

            return Array(zip(distanceData[lowerIndex...upperIndex], altitudeData[lowerIndex...upperIndex]))
        }

        private(set) var altitudeData = [Double]()
        private(set) var distanceData = [Double]()

        private var isParsingTrack = false
        private var parsingElementName: String?

        func parse() {
            guard let url = Bundle.main.url(forResource: "BRM618Kinki400", withExtension: "xml"),
                  let parser = XMLParser(contentsOf: url) else { return }

            parser.delegate = self
            parser.parse()
        }

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
            if elementName == "Track" {
                isParsingTrack = true
            }

            guard isParsingTrack else { return }

            if ElementName.allCases.map(\.rawValue).contains(elementName) {
                parsingElementName = elementName
            }
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            guard isParsingTrack else { return }
            
            parsingElementName = nil
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            guard isParsingTrack,
                  let value = Double(string) else { return }

            switch parsingElementName {
            case ElementName.altitude.rawValue:
                altitudeData.append(value)
            case ElementName.distance.rawValue:
                distanceData.append(value / 1000)
            default:
                break
            }
        }

        func parserDidEndDocument(_ parser: XMLParser) {
            minDistance = distanceData.min() ?? 0.0
            maxDistance = distanceData.max() ?? 0.0
            objectWillChange.send()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
