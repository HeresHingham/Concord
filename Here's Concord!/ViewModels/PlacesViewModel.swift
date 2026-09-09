//
//  PlacesViewModel.swift
//  Here's Concord!
//
//  Created by Cameron Conway on 9/1/26.
//

import Foundation
import MapKit
import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import AVKit
import YouTubePlayerKit
import YouTubeiOSPlayerHelper
import Combine

class PlacesViewModel: ObservableObject {
  @Published var mapCameraPosition: MapCameraPosition = MapCameraPosition.region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.46137, longitude: -71.34903), span: MKCoordinateSpan(latitudeDelta: UIDevice.current.userInterfaceIdiom == .pad ? 0.145 : 0.05, longitudeDelta: UIDevice.current.userInterfaceIdiom == .pad ? 0.145 : 0.05)))
  @Published var centerCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
  @Published var places: [Place] = []
  @Published var tourPlaces: [TourPlace] = []
  @Published var tours: [Tour] = []
  @Published var videos: [Video] = []
  @Published var selectedPlace: Place
  @Published var visible = false
  @Published var zoom: Double = 0.05
  @Published var distance: Double = 0.0
  @Published var iconResizePercent: Double = 0.0
  @Published var showCardView = false
  @Published var showAddToBasket = false
  @Published var ytPlayerView = YTPlayerView()
  @Published var scrollItemId = 0
  @Published var previewImageUrl = ""
  @Published var previewHeightMultiple = 0.75
  @Published var iconAltitudeMaximum: Int = 18600
  @Published var loadingPlaces = false
  @Published var loadingTour = true
  @Published var imagery3DMode = false
  @Published var satelliteMapStyle = MapStyle.imagery(elevation: .realistic)
  @Published var standardMapStyle = MapStyle.standard(pointsOfInterest: .including([]))
  @Published var selectedTour: Tour = Tour()

  @Published var placeFilter: PlaceFilter = .None {
    didSet {
//      let db = Firestore.firestore()
//      
//      for area in areas {
//        db.collection("ConcordPlace").whereField("type", in: [self.placeFilter.rawValue]).getDocuments { queryPlace, err in
//          if queryPlace!.documents.count > 0 {
//            switch self.placeFilter {
//            case .Dining:
//              area.iconImage = "fork.knife.circle.fill"
//            case .Shopping, .Clothing, .Pharmacy, .Salon:
//              area.iconImage = "handbag.circle.fill"
//            case .Historic:
//              area.iconImage = "house.circle.fill"
//            case .Coffee:
//              area.iconImage = "cup.and.saucer.circle.fill"
//            case .Park:
//              area.iconImage = "tree.circle.fill"
//            default:
//              area.iconImage = "map.circle.fill"
//            }
//          } else {
//            area.iconImage = "map.circle.fill"
//          }
//        }
//      }
    }
  }

  init() {
    selectedPlace = Place()
  }
  
  public func addPlace(_ place: Place) {
    places.append(place)
  }
  
  public func addTour(_ tour: Tour) {
    tours.append(tour)
  }
  
  public func addVideo(_ video: Video) {
    videos.append(video)
  }

  public func addTourPlace( _ tourPlace: TourPlace) {
    tourPlaces.append(tourPlace)
  }
  
  func setPlaceSelected(_ place: Place) {
    if selectedPlace == place && (selectedPlace.selected == true || place.selected == true) {
      place.selected = false
    } else {
      selectedPlace.selected = false
      place.selected = place.name != ""
    }
    
    withAnimation(.easeInOut) {
      selectedPlace = place
    }
    
    if place.imageCount == 0 {
      var imageCounter = 0
      let placeName = place.name
      while UIImage(named: ("\(placeName)/\(imageCounter)")) != nil {
        imageCounter += 1
      }
      place.imageCount = imageCounter
    }
    visible = true
  }

  public func updateAddToBasket(_ documentID: String) {
    @AppStorage("Basket") var basket: String = ""
    let basketArray = basket.components(separatedBy: ",")
    showAddToBasket = !basketArray.contains(documentID)
  }

  public func firstScrollItemType(place: Place) -> String {
    if scrollItemId == 0 {
      if place.name == "" {
        return "firstBasket•Video"
      } else {
        return ""
      }
    } else {
      return ""
    }
  }
}

