
//
//  MainView.swift
//  Here's Concord!
//
//  Created by Cameron Conway on 9/1/26.•
//
import Foundation
import SwiftUI
import SwiftData
import MapKit
import CoreLocation
import FirebaseFirestore
import AVKit
import YouTubePlayerKit
import YouTubeiOSPlayerHelper
import Combine

struct MainView: View {  
  @EnvironmentObject private var placesViewModel: PlacesViewModel
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.openURL) private var openUrl
  @State private var position = MapCameraPosition.region(
    MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.46137, longitude: -71.34903), span: MKCoordinateSpan(latitudeDelta: UIDevice.current.userInterfaceIdiom == .pad ? 0.145 : 0.11, longitudeDelta: UIDevice.current.userInterfaceIdiom == .pad ? 0.145 : 0.11)))
  @State private var annotationOpacity: Double = 1.0
  @State private var paths: [String] = []
  @State private var showPlaceCard = false
  @State private var longPressCoordinate: CLLocationCoordinate2D?
  @State private var lookAroundScene: MKLookAroundScene?
  @State private var isShowingLookAroundViewer: Bool = false
  @State private var isLookAroundUnavailable: Bool = false
  @State private var isInitialView: Bool = true
  @State private var cameraIsChanging: Bool = false
  @State private var tabSelection: Int = 0
  @State private var currentPage: Int = 0
  @State private var showHouses: Bool = true
  @State private var showSpecials: Bool = true
  @State private var showLabels: Bool = true
  @State private var toasts: [Toast] = []
  @State private var mapStyle: MapStyle = MapStyle.standard(pointsOfInterest: .including([]))
  @State private var interactionModes: MapInteractionModes = [.all]
  @State private var imagery3DMode = false
  @ObservedObject var location: LocationManager = LocationManager()
  
  let maxWidth: CGFloat = 475
  
  var body: some View {
    GeometryReader { geometry in
      NavigationStack(path: $paths) {
        ZStack {
          if isShowingLookAroundViewer == true {
            LookAroundPreview(initialScene: lookAroundScene, allowsNavigation: true)
              .frame(width: geometry.size.width * 0.93, height: UIDevice.current.userInterfaceIdiom == .pad ? geometry.size.height * 0.66 : geometry.size.height * 0.33)
              .cornerRadius(12)
              .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? geometry.size.height * 0.2 : geometry.size.height * 0.524)
              .zIndex(1.0)
              .overlay(alignment: .topTrailing) {
                Button {
                  isShowingLookAroundViewer = false
                }
                label: {
                  Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                }
                .foregroundColor(.white)
                .padding()
              }
          }
          
          if placesViewModel.mapCameraPosition.region != nil {
            placeMapLayer
          }
          
          VStack {
            filterHScrollToolbar
            
            Spacer()
            
            if placesViewModel.showCardView == true {
              CardView(showPlaceDetail: $showPlaceCard, mapStyle: $mapStyle, imagery3DMode: $imagery3DMode)
                .frame(minWidth: UIDevice.current.userInterfaceIdiom == .pad ? 550 : geometry.size.width * 0.93, minHeight: geometry.size.height * placesViewModel.previewHeightMultiple, maxHeight: geometry.size.height * placesViewModel.previewHeightMultiple)
                .shadow(color: .black.opacity(0.3), radius: 20)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 20 : -10)
            }
          }
        }
        .navigationTitle("Here's Concord")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .principal) {
            Image("AppToolbar")
              .resizable()
              .scaledToFit()
              .frame(height: 30)
          }
          ToolbarItem(placement: .navigationBarTrailing)  {
            ellipsisMenu
          }
        }
        .onAppear(perform: {
          @AppStorage("ShowHouses") var showHouse: Bool = true
          showHouses = showHouse
          @AppStorage("ShowSpecials") var showSpecial: Bool = true
          showSpecials = showSpecial
          @AppStorage("ShowLabels") var showLabel: Bool = true
          showLabels = showLabel
          @AppStorage("IconAltitudeMaximum") var iconAltitude = 18600
          placesViewModel.iconAltitudeMaximum = iconAltitude
        })
        .alert(isPresented: $isLookAroundUnavailable) {
          Alert(title: Text("Look Around"), message: Text("Look around is not available in this area."), dismissButton: .default(Text("OK")))
        }
      }
      .interactiveToast($toasts)
      .onAppear {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
      }
      .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
        placesViewModel.previewHeightMultiple = UIDevice.current.userInterfaceIdiom == .pad ? UIDevice.current.orientation == .portrait || UIDevice.current.orientation == .portraitUpsideDown ? 0.6 : 0.9 : 0.75
      }
    }
  }
  
  func showToast(_ text: String, _ icon: String) {
    withAnimation(.spring) {
      let toast = Toast { id in self.ToastView(id, text, icon) }
        toasts.append(toast)
    }
  }
  
  @ViewBuilder
  func ToastView(_ id: String, _ text: String, _ icon: String) -> some View {
      HStack {
        Image(systemName: icon)
        Text(text).font(.system(size: 13.0, weight: .regular, design: .default))
        Spacer()
      }
      .padding()
      .background(
          RoundedRectangle(cornerRadius: 24)
              .fill(.orange)
              .shadow(color: .black.opacity(0.06), radius: 3, x: -1, y: -3)
              .shadow(color: .black.opacity(0.06), radius: 2, x: 1, y: 3)
      )
      .padding(.horizontal)
  }
}

struct FilterButtonView: View {  
  @EnvironmentObject private var placesViewModel: PlacesViewModel
  @Environment(\.colorScheme) var colorScheme
  let title: String
  let imageName: String
  let type: PlaceFilter
  var onButtonTap: () -> Void
  
  var body: some View {
    Button(action: {
      placesViewModel.loadingTour = false
      placesViewModel.selectedTour = Tour()
      placesViewModel.iconAltitudeMaximum = 50000
      placesViewModel.placeFilter = type      
      placesViewModel.iconResizePercent = 0.0
      placesViewModel.distance = 0.0
      placesViewModel.selectedTour.tourId = -1
      let span = MKCoordinateSpan(latitudeDelta: placesViewModel.zoom, longitudeDelta: placesViewModel.zoom)
      let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.46137, longitude: -71.34903), span: span)
      withAnimation(.easeInOut) {
        placesViewModel.mapCameraPosition = MapCameraPosition.region(region)
      }
      
//      } else if title == "Update Yelp" {
//        let dataService = DataService()
//        let places = placesViewModel.places.filter { $0.areaId == 5 }
//        var counter = 0
//        places.forEach { place in
//          if place.yelpCategory == "" && counter < 11 {
//            dataService.updateYelp(name: place.name)
//            counter += 1
//          }
//        }
//      } else if title == "Update Google" {
//        let dataService = DataService()
//        let places = placesViewModel.places.filter { $0.areaId == 5 }
//        places.forEach { place in
//          dataService.updateGoogle(name: place.name)
//        }
      
      Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
        withAnimation(.easeInOut) {
          placesViewModel.showCardView = false
          placesViewModel.visible = false
          onButtonTap()
        }
      }
    }) {
      HStack {
        if type == .Basket {
          Image(imageName)
        } else {
          Image(systemName: imageName)
        }
        
        Text(title)
      }
      .padding(6)
    }
    .foregroundColor(colorScheme == .dark ? .white : .black)
    .background(placesViewModel.placeFilter == type ? Color("AccentTabColor") : colorScheme == .dark ? .black : .white)
    .font(.system(size: 10))
    .fontWeight(.semibold)
    .cornerRadius(10.0)
    .shadow(color: .black.opacity(0.75), radius: 2, x: 1, y: 1)
  }
}
  
extension MainView {  
  private var placeMapLayer: some View {
    @AppStorage("Basket") var basket: String = ""
    let basketArray = basket.components(separatedBy: ",")
    var places: [Place] = placesViewModel.places
    
    if placesViewModel.selectedTour.tourId == -1 {
      if placesViewModel.placeFilter != .None {
        if placesViewModel.placeFilter == .Shopping {
          let includedTypes: [Int] = [2, 3, 5, 9]
          places = places.filter { item in
            includedTypes.contains(item.type)
          }
        } else if placesViewModel.placeFilter == .Basket {
          places = places.filter { basketArray.contains($0.documentID) }
        } else {
          places = places.filter { $0.type == placesViewModel.placeFilter.rawValue }
        }
      }
    }
    
    let currentAltitudeFeet: Double = placesViewModel.mapCameraPosition.region!.span.latitudeDelta * 364000
    let maximumAltitudeFeet: Double = placesViewModel.selectedTour.tourId == -1 ? Double(placesViewModel.iconAltitudeMaximum) : 1000000.0
    let latDeltaHalf: Double = placesViewModel.mapCameraPosition.region!.span.latitudeDelta / 1.5
    let lngDeltaHalf: Double = placesViewModel.mapCameraPosition.region!.span.longitudeDelta / 1.5
    let lat: Double = placesViewModel.mapCameraPosition.region!.center.latitude
    let lng: Double = placesViewModel.mapCameraPosition.region!.center.longitude
    
    if placesViewModel.selectedTour.tourId == -1 {
      places = places.filter { $0.locationLat > lat - latDeltaHalf && $0.locationLat < lat + latDeltaHalf && $0.locationLat > lng - lngDeltaHalf && $0.locationLng < lng + lngDeltaHalf }
    } else {
      places = []
      let tourPlaces = placesViewModel.tourPlaces.filter { $0.tourId == placesViewModel.selectedTour.tourId}
      tourPlaces.forEach { tourPlace in
        let place = placesViewModel.places.first(where: { place in
          place.documentID == tourPlace.placeDocId
        })
        
        if place != nil {
          if tourPlace.name != "" {
            place!.name = tourPlace.name
            place!.shortName = tourPlace.name
          }
          if tourPlace.notes != "" {
            place!.notes = tourPlace.notes
          }
          places.append(place!)
        } else {
          print(tourPlace.placeDocId)
        }
      }
    }
    
    return ZStack {
      MapReader { proxy in
        Map(position: $placesViewModel.mapCameraPosition, bounds: MapCameraBounds(minimumDistance: 0), interactionModes: interactionModes, scope: nil) {
         if currentAltitudeFeet < maximumAltitudeFeet {
            ForEach(places) { place in
              if showHouses == true || (showHouses == false && place.type != 6) {
                Annotation("", coordinate: place.coordinates) {
                  PlaceAnnotationView(placeName: place.name, shortName: place.shortName, specials: place.specials, type: place.type, iconSize: place.iconSize, selected: place.selected, opacity: annotationOpacity, iconResizePercent: placesViewModel.iconResizePercent, placeFilter: placesViewModel.placeFilter, imagery3DMode: imagery3DMode, showLabels: showLabels)
                    .shadow(radius: 10)
                    .onTapGesture {
                      placesViewModel.loadingPlaces = false
                      placesViewModel.selectedPlace = place
                      if place.type < 20 {
                        placesViewModel.updateAddToBasket(place.documentID)
                        placesViewModel.previewImageUrl = ""
                        if place.videoUrl != "" {
                          Task {
                            withAnimation(.easeInOut) {
                              placesViewModel.setPlaceSelected(place)
                              placesViewModel.visible = false
                              placesViewModel.showCardView = true
                              placesViewModel.previewImageUrl = "\(place.name)/0"
                            }
                          }
                        } else {
                          withAnimation(.easeInOut) {
                            placesViewModel.setPlaceSelected(place)
                            placesViewModel.visible = false
                            placesViewModel.showCardView = true
                          }
                        }
                      }
                    }
                }
                .annotationTitles(.visible)
              }
            }
          }
          
          UserAnnotation()
        }
        .ignoresSafeArea()
        .onChange(of: imagery3DMode) { oldValue, newValue in
          mapStyle = newValue == true ? placesViewModel.satelliteMapStyle : placesViewModel.standardMapStyle
        }
        .onMapCameraChange(frequency: .onEnd) { context in
          cameraIsChanging = false
        }
        .onMapCameraChange(frequency: .continuous) { context in
          @AppStorage("IconAltitudeMaximum") var iconAltitude = 18600
          placesViewModel.iconAltitudeMaximum = placesViewModel.iconAltitudeMaximum != 50000 ? iconAltitude : placesViewModel.iconAltitudeMaximum
          let distanceDelta = placesViewModel.distance - context.camera.distance
          cameraIsChanging = true
          
          if placesViewModel.distance == 0.0 {
            placesViewModel.distance = context.camera.distance
          } else if placesViewModel.distance != context.camera.distance && abs(distanceDelta) > 20 {            
            if (UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight) && UIDevice.current.userInterfaceIdiom == .phone {
              placesViewModel.iconResizePercent = placesViewModel.distance / (context.camera.distance * 2.43)
            } else {
              placesViewModel.iconResizePercent = placesViewModel.distance / context.camera.distance
            }
          }
          
          placesViewModel.centerCoordinate = context.region.center
          
          if placesViewModel.mapCameraPosition.region == nil {
            placesViewModel.mapCameraPosition = MapCameraPosition.region(context.region)
          }
          
          let span = MKCoordinateSpan(latitudeDelta: UIDevice.current.userInterfaceIdiom == .pad ? 0.145 : 0.05, longitudeDelta: UIDevice.current.userInterfaceIdiom == .pad ? 0.145 : 0.05)
          placesViewModel.mapCameraPosition = MapCameraPosition.region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.46137, longitude: -71.34903), span: span))
          placesViewModel.loadingTour = false
        }
        .background(.white)
        .mapStyle(mapStyle)
        .mapControls {
          Button {
            let span = MKCoordinateSpan(latitudeDelta: placesViewModel.zoom, longitudeDelta: placesViewModel.zoom)
            placesViewModel.mapCameraPosition = MapCameraPosition.region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: location.userLocation?.coordinate.latitude ?? 0.0, longitude: location.userLocation?.coordinate.longitude ?? 0.0), span: span))
          } label: {
            Image(systemName: "location.fill")
          }
        }
        .simultaneousGesture (
          DragGesture(minimumDistance: 0.0)
            .onChanged { value in
              let location = value.startLocation
              if let pinLocation = proxy.convert(location, from: .local) {
                longPressCoordinate = pinLocation
              }
            }
            .simultaneously(with: LongPressGesture(minimumDuration: 0.5)
              .onEnded { _ in
                if let coordinate = longPressCoordinate {
                  let request = MKLookAroundSceneRequest(coordinate: coordinate)
                  request.getSceneWithCompletionHandler { scene, error in
                    if let error = error {
                      print("Error fetching Look Around scene: \(error.localizedDescription)")
                      return
                    }
                    if let scene {
                      lookAroundScene = scene
                      isShowingLookAroundViewer = true
                    }
                  }
                }
              }
            )
          )
        }
      }
  }
  
  private var appBanner: some View {
    Image("AppBanner")
  }
  
  private var ellipsisMenu: some View {
    Menu {
      Menu {
        ForEach(placesViewModel.tours, id: \.self) { tour in
          Button {
            withAnimation(.easeInOut) {
              placesViewModel.loadingTour = true
              placesViewModel.selectedTour = tour
              placesViewModel.iconResizePercent = 0.0
              placesViewModel.visible = false
              placesViewModel.placeFilter = .None
              let span = MKCoordinateSpan(latitudeDelta: placesViewModel.zoom, longitudeDelta: placesViewModel.zoom)
              let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.46137, longitude: -71.34903), span: span)
              placesViewModel.mapCameraPosition = MapCameraPosition.region(region)
            }
          }
          label: {
            Text(tour.name)
          }
        }
      } label: {
        Label("Tours", systemImage: "signpost.right.and.left")
      }
      
      Menu {
        ForEach(placesViewModel.videos, id: \.self) { video in
          Button {
            let urlString:String = "https://youtu.be/\(video.youtubeId)"
            guard let url:URL = URL(string: urlString) else { return }
              
            openUrl(url) { accepted in
                if !accepted {
                  _ = Alert(title: Text("Videos"), message: Text("\(video.youtubeId) video could not be opened."), dismissButton: .default(Text("OK")))
                }
            }
          }
          label: {
            Text(video.name)
          }
        }
      } label: {
        Label("Videos", systemImage: "video")
      }
      
      Toggle(isOn: $imagery3DMode) {
        Label("3D Satellite", systemImage: "square.3.layers.3d")
      }
      .disabled(placesViewModel.visible == true)
      
      Toggle(isOn: $showHouses) {
        Label("Show Houses", systemImage: "house")
      }
      .disabled(placesViewModel.visible == true)
      
      Toggle(isOn: $showSpecials) {
        Label("Show Specials", systemImage: "tag")
      }
      .disabled(placesViewModel.visible == true)
      .onChange(of: showSpecials) { oldValue, newValue in
        @AppStorage("ShowSpecials") var showSpecial: Bool = true
        showSpecial = newValue        
      }
      
      Toggle(isOn: $showLabels) {
        Label("Show Labels", systemImage: "textformat.characters")
      }
      .disabled(placesViewModel.visible == true)
      
      Button {
        let urlString:String = "mailto:support@cambuilt.com?subject=Here's%20Concord!"
        guard let url:URL = URL(string: urlString) else { return }
          
        openUrl(url) { accepted in
            if !accepted {
                // Handle the error, e.g., show an alert
            }
        }
      }
      label: {
        Label("Contact Us", systemImage: "envelope")
      }
        
    } label: {
      Image(systemName: "ellipsis")
    }
  }
  
  private var filterHScrollToolbar: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(spacing: 10) {
        FilterButtonView(title: "Basket", imageName: "Reviews/ToolbarBasket", type: .Basket) { mapStyle = placesViewModel.standardMapStyle }
        FilterButtonView(title: "Dining", imageName: "fork.knife", type: .Dining) {}
        FilterButtonView(title: "Coffee", imageName: "cup.and.saucer", type: .Coffee) {}
        FilterButtonView(title: "Shopping", imageName: "handbag", type: .Shopping) {}
        FilterButtonView(title: "Parks", imageName: "tree", type: .Park) {}       
//                FilterButtonView(title: "Update Yelp", imageName: "gear", type: 100)
//                FilterButtonView(title: "Update Google", imageName: "gear", type: 100)
      }
      .padding(.horizontal)
      .padding([.leading, .trailing], 10)
    }
    .frame(height:50)
    .background(.clear)
  }
  
  private var grapeImageSection: some View {
    GeometryReader { geometry in
      HStack(alignment: .center) {
        if (placesViewModel.selectedPlace.videoUrl != "" || placesViewModel.selectedPlace.videoUrl != "") && placesViewModel.scrollItemId == 0 {
          if placesViewModel.visible == true {
            if UIDevice.current.userInterfaceIdiom == .phone {
              YouTubeView(videoID: placesViewModel.selectedPlace.videoUrl)
                .frame(width: geometry.size.width * 0.93)
                .cornerRadius(25)
            } else {
              YouTubeView(videoID: placesViewModel.selectedPlace.videoUrl)
                .frame(width: geometry.size.width * 0.3)
                .cornerRadius(25)
            }
          } else {
            if UIDevice.current.userInterfaceIdiom == .phone {
              YouTubeView(videoID: placesViewModel.selectedPlace.videoUrl)
                .frame(width: geometry.size.width * 0.93)
                .cornerRadius(25)
            } else {
              YouTubeView(videoID: placesViewModel.selectedPlace.videoUrl)
                .frame(width: geometry.size.width * 0.3)
                .cornerRadius(25)
            }
          }
        } else {
          Image(placesViewModel.previewImageUrl)
            .resizable()
            .scaledToFit()
            .cornerRadius(25)
        }
      }
      .padding(0)
      .padding(.top, 40)
      .padding(.bottom, -40)
      .frame(width: geometry.size.width * (placesViewModel.firstScrollItemType(place: placesViewModel.selectedPlace) == "firstBasket•Video" ? 0.9 : 0.7), height: geometry.size.height * 0.248)
      .overlay(
        RoundedRectangle(cornerRadius: 25)
          .stroke(Color.accent, lineWidth: 6)
          .padding(.top, 40)
          .padding(.bottom, -40)
          .frame(width: geometry.size.width * (placesViewModel.firstScrollItemType(place: placesViewModel.selectedPlace) == "firstBasket•Video" ? UIDevice.current.userInterfaceIdiom == .phone ? 0.92 : 0.3 : 0.7), height: geometry.size.height * 0.248)
      )
    }
  }
}

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
  private let manager = CLLocationManager()
  @Published var userLocation: CLLocation?
  @Published var message: String = ""
  @Published var showMessage = false
  @Published var newPlaceAtCurrentLocation: Place?
  @Published var placesViewModel: PlacesViewModel = PlacesViewModel()
    
  func startUpdating() {
    manager.delegate = self
    manager.requestWhenInUseAuthorization()
    manager.startUpdatingLocation()
  }
  
  func stopUpdating() {
    manager.stopUpdatingLocation()
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    if let clError = error as? CLError {
        switch clError.code {
        case .denied:
            print("Location access was denied by the user.")
        case .locationUnknown:
            print("Location is currently unknown, but the manager will keep trying.")
        case .network:
            print("Network error prevented location retrieval.")
        default:
            print("A Core Location error occurred: \(clError.localizedDescription)")
        }
    } else {
        print("General error: \(error.localizedDescription)")
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    userLocation = locations.last
    
    let placesFound = placesViewModel.places.filter {   // $0.areaId == areaId &&
      return userLocation!.coordinate.latitude > $0.locationLat - 0.0005 &&
      userLocation!.coordinate.latitude < $0.locationLat + 0.0005 &&
      userLocation!.coordinate.longitude > $0.locationLng - 0.0005 &&
      userLocation!.coordinate.longitude < $0.locationLng + 0.0005
    }
    
    let placeCount = placesFound.count
    
    if placeCount > 0 {
      var closestPlace = placesFound[0]
      placesFound.forEach { place in
        if closestPlace.name != place.name {
          if abs(userLocation!.coordinate.latitude - place.locationLat) <= abs(userLocation!.coordinate.latitude - closestPlace.locationLat) &&
              abs(userLocation!.coordinate.longitude - place.locationLng) <= abs(userLocation!.coordinate.longitude - closestPlace.locationLng)
          {
            closestPlace = place
          }
        }
      }
      
      newPlaceAtCurrentLocation = closestPlace
    }
  }
}

class IconImage: ObservableObject {
  @Published var name: String
  
  init(_name: String) {
    name = _name
  }
}

struct YouTubeView: UIViewRepresentable {
  @EnvironmentObject private var placesViewModel: PlacesViewModel
  let videoID: String

  func makeUIView(context: Context) -> YTPlayerView {
    let playerVars: [AnyHashable: Any] = ["autoplay": 1, "controls": 0, "origin": "https://www.youtube.com", "playsinline": 1]
    placesViewModel.ytPlayerView.load(withVideoId: videoID, playerVars: playerVars)
    return placesViewModel.ytPlayerView
  }

  func updateUIView(_ uiView: YTPlayerView, context: Context) {
    // Update the player if the video ID changes
  }
}

enum PlaceFilter: Int {
  case None = 0
  case Dining = 1
  case Shopping = 2
  case Clothing = 3
  case Gym = 4
  case Pharmacy = 5
  case Historic = 6
  case Coffee = 7
  case Park = 8
  case Salon = 9
  case Basket = 11
}

extension Date {
    func dayNumberOfWeek() -> Int {
        return Calendar.current.dateComponents([.weekday], from: self).weekday! - 1
    }
}

