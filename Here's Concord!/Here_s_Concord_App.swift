//
//  Here_s_Concord_App.swift
//  Here's Concord!
//
//  Created by Cameron Conway on 9/1/26.
//

import SwiftUI
import SwiftData
import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
  @EnvironmentObject var authenticationViewModel: AuthenticationViewModel
  
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(.accentColor)
    UIPageControl.appearance().pageIndicatorTintColor = UIColor(named: "AccentSecondary")
    
    return true
  }
  
  static var orientationLock = UIInterfaceOrientationMask.all
  static var orientationForImage = false

  func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    return AppDelegate.orientationLock 
  }
}

extension String {
    var isNumber: Bool {
      return self.replacingOccurrences(of: ",", with: "").range(
            of: "^[0-9]*$",
            options: .regularExpression) != nil && self != ""
    }
}

@main
struct Here_s_Concord_App: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject private var placesViewModel = PlacesViewModel()
  @Environment(\.modelContext) private var modelContext
  
  var body: some Scene {
    WindowGroup {
      MainView()
        .environmentObject(placesViewModel)
    }
    .modelContainer(for: [Place.self]) { result in
      do {
        Task {
          do {
            try await Auth.auth().signIn(withEmail: "support@cambuilt.com", password: "jyzdyc-Tukrig-tyhgy4")
            loadData()
          }
          catch {
            print(error)
          }
        }
      }
    }
  }
  
  func loadData() {
    let db = Firestore.firestore()
    @AppStorage("ShowSpecial") var showSpecial: Bool = true
    db.collection("ConcordPlace").getDocuments { queryPlace, err in
      
      for document in queryPlace!.documents {
        let place = Place()
        place.documentID = document.documentID
        
        if let name = document.get("name") as? String {
          place.name = name
          place.address = document.get("address") as! String
          place.archStyle = document.get("archStyle") as! String
          place.googleId = document.get("googleId") as! String
          place.googleRating = document.get("googleRating") as! Double
          place.googleReviews = document.get("googleReviews") as! Int
          place.googleUrl = document.get("googleUrl") as! String
          place.concordRatings = document.get("concordRatings") as! String
          place.updateConcordRating()
          place.concordReviews = document.get("concordReviews") as! Int
          place.hours = document.get("hours") as! String
          place.iconSize = document.get("iconSize") as! Double
          place.imageCount = document.get("imageCount") as! Int
          place.locationLat = document.get("locationLat") as! Double
          place.locationLng = document.get("locationLng") as! Double
          place.menuUrl = document.get("menuUrl") as! String
          place.notes = document.get("notes") as! String
          place.phone = document.get("phone") as! String
          place.shortName = document.get("shortName") as! String
          place.specials = document.get("specials") as! String
          place.specialNotes = document.get("specialNotes") as! String
          place.type = document.get("type") as! Int
          place.website = document.get("website") as! String
          place.yelpCategory = document.get("yelpCategory") as! String
          place.yelpId = document.get("yelpId") as! String
          place.yelpRating = document.get("yelpRating") as! Double
          place.yelpReviews = document.get("yelpReviews") as! Int
          place.yelpPrice = document.get("yelpPrice") as! String
          place.yelpUrl = document.get("yelpUrl") as! String
          place.estimatedValue = document.get("estimatedValue") as! String
          place.lotSize = document.get("lotSize") as! Double
          place.squareFeet = document.get("squareFeet") as! Int
          place.yearBuilt = document.get("yearBuilt") as! Int
          place.instagram = document.get("instagram") as! String
          place.videoUrl = document.get("videoUrl") as! String
          
          placesViewModel.addPlace(place)
        }
        
        let query = db.collection("ConcordTour").order(by: "name")
        
        query.getDocuments { queryTour, err in
          for document in queryTour!.documents {
            let tour = Tour()
            tour.documentID = document.documentID
            tour.tourId = document.get("tourId") as! Int
            tour.name = document.get("name") as! String
            tour.desc = document.get("desc") as! String
            placesViewModel.addTour(tour)
          }
        }
        
        db.collection("ConcordTourPlace").getDocuments { queryTourPlace, err in
          for document in queryTourPlace!.documents {
            let tourPlace = TourPlace()
            tourPlace.documentID = document.documentID
            tourPlace.tourId = document.get("tourId") as! Int
            tourPlace.placeDocId = document.get("placeDocId") as! String
            tourPlace.name = document.get("name") as! String
            tourPlace.notes = document.get("notes") as! String
            placesViewModel.addTourPlace(tourPlace)
          }
        }
        
        let videoQuery = db.collection("ConcordVideo").order(by: "name")
        
        videoQuery.getDocuments { queryVideo, err in
          for document in queryVideo!.documents {
            let video = Video()
            video.documentID = document.documentID
            video.name = document.get("name") as! String
            video.youtubeId = document.get("youtubeId") as! String
            placesViewModel.addVideo(video)
          }
        }
      }
    }
  }
}
