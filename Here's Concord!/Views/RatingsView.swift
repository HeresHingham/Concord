//
//  RatingsView.swift
//  Here's Concord!
//
//  Created by Cameron Conway on 9/1/26.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

struct RatingsView: View {
  @Binding var place: Place
  @Binding var showRatingSelector: Bool
  @State var rating: Double = 0.0
  
  var label = "How many grapes?"
  var maximumRating: Double = 5.0  
  var offImage: Image?
  var starImage = Image("Reviews/Grape")
  var halfStarImage = Image("Reviews/HalfGrape")
  let start = 1.0
  var offColor = Color.gray
  var onColor = Color.yellow
  
  var body: some View {
    GeometryReader { geometry in
      HStack {
        if label.isEmpty == false {
          Text(label)
            .font(.system(size: 12))
            .frame(width: 120.0)
        }
        
        ForEach(Array(stride(from: 1.0, through: maximumRating, by: 1.0)), id: \.self) { number in
          Button {
            rating = number
          } label: {
            number > rating ? Image("Reviews/GrapeGray") : number.truncatingRemainder(dividingBy: 1.0) == 0 ? Image("Reviews/Grape") : Image("Reviews/HalfGrapeGray")
          }
          .padding(-2)
        }
        Spacer()
        Button {
          if rating > 0 {
            place.concordReviews += 1
            place.concordRatings += place.concordRatings == "" ? String(rating) : ";" + String(rating)
            place.updateConcordRating()
            let db = Firestore.firestore()
            let placeRef = db.collection("ConcordPlace").document(place.documentID)
            placeRef.updateData(["concordRatings" : place.concordRatings, "concordReviews" : place.concordReviews])
            @AppStorage("Rated:\(place.id)") var rated: String = ""
            rated = "true"
          }
          showRatingSelector = false
        } label: {
          Text("Rate")
            .foregroundStyle(.white)
            .font(.system(size: 13, weight: .bold))
            .frame(width: 45.0)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .padding(.top, 1)
        Button {
          showRatingSelector = false
        } label: {
          Image(systemName: "x.square.fill")
            .font(.system(size: 32))
            .tint(.red)
            .cornerRadius(25)
        }
      }
      .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? geometry.size.width * 0.373 : geometry.size.width * 0.86, height: 11)
      .padding(.top, 4)
    }
  }
  
  func image(for number: Double) -> Image {
    if number > rating {
      offImage ?? starImage
    } else {
      starImage
    }
  }
}



