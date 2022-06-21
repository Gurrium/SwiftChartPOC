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
    private var data: [(Double, Double)] {
        Array(zip(state.distanceData, state.altitudeData))
    }

    var body: some View {
        VStack {
            Button {
                state.parse()
            } label: {
                Text("Load")
            }

            Chart(data, id: \.0) { (distance, altitude) in
                LineMark(
                    x: .value("Distance", distance),
                    y: .value("Altitude", altitude)
                )
            }
        }
    }

    private class ViewState: NSObject, ObservableObject, XMLParserDelegate {
        private enum ElementName: String, CaseIterable {
            case altitude = "AltitudeMeters"
            case distance = "DistanceMeters"
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
            objectWillChange.send()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
