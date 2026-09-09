//
//  Models.swift
//  Here's Concord!
//
//  Created by Cameron Conway on 9/1/26.
//

import Foundation
import SwiftData
import MapKit
import YouTubePlayerKit
import Combine
  
@Model
  final class Place: Codable, ObservableObject {
    
    enum CodingKeys: CodingKey {
      case documentID
      case address
      case archStyle
      case estimatedValue
      case googleId
      case googleRating
      case googleReviews
      case googleUrl
      case concordRatings
      case concordReviews
      case hours
      case iconSize
      case imageCount    
      case locationLat
      case locationLng
      case lotSize
      case menuUrl
      case name  
      case notes
      case phone
      case shortName
      case specialNotes
      case specials
      case squareFeet
      case type
      case website
      case yearBuilt
      case yelpCategory
      case yelpId
      case yelpRating
      case yelpReviews
      case yelpPrice
      case yelpUrl
      case instagram
      case videoUrl
    }
    
    var documentID = ""
    var address = ""
    var archStyle = ""
    var googleId = ""
    var googleRating = 0.0
    var googleReviews = 0
    var googleUrl = ""
    var concordRatings = ""
    var concordReviews = 0
    var hours = ""
    var iconSize = 0.0
    var imageCount = 0
    var locationLat = 0.0
    var locationLng = 0.0
    var menuUrl = ""
    @Attribute(.unique) var name = ""
    var notes = ""
    var phone = ""
    var shortName = ""
    var specials = ""
    var specialNotes = ""
    var type = 0
    var timestamp: Date
    var website = ""
    var yelpCategory = ""
    var yelpId = ""
    var yelpRating = 0.0
    var yelpReviews = 0
    var yelpPrice = ""
    var yelpUrl = ""
    var estimatedValue = ""
    var lotSize = 0.0
    var squareFeet = 0
    var yearBuilt = 0
    var instagram = ""
    var videoUrl = ""

    @Transient var sizeHeight: Double?
    @Transient var sizeWidth: Double?
    @Transient var hasSpecial = false
    @Transient var selected = false
    @Transient var concordReviewAverage: Double = 0
    
    var coordinates: CLLocationCoordinate2D {
      CLLocationCoordinate2D(latitude: locationLat, longitude: locationLng)
    }

    init() {
      self.timestamp = Date.now
    }
    
    init(timestamp: Date) {
      self.timestamp = timestamp
    }
    
    required init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.documentID = try container.decode(String.self, forKey: .documentID)
      self.address = try container.decode(String.self, forKey: .address)
      self.googleId = try container.decode(String.self, forKey: .googleId)
      self.googleRating = try container.decode(Double.self, forKey: .googleRating)
      self.googleReviews = try container.decode(Int.self, forKey: .googleReviews)
      self.concordRatings = try container.decode(String.self, forKey: .concordRatings)
      self.concordReviews = try container.decode(Int.self, forKey: .concordReviews)
      self.hours = try container.decode(String.self, forKey: .hours)
      self.iconSize = try container.decode(CGFloat.self, forKey: .iconSize)
      self.imageCount = try container.decode(Int.self, forKey: .imageCount)      
      self.locationLat = try container.decode(Double.self, forKey: .locationLat)
      self.locationLng = try container.decode(Double.self, forKey: .locationLng)
      self.menuUrl = try container.decode(String.self, forKey: .menuUrl)
      self.name = try container.decode(String.self, forKey: .name)      
      self.notes = try container.decode(String.self, forKey: .notes)
      self.phone = try container.decode(String.self, forKey: .phone)
      self.shortName = try container.decode(String.self, forKey: .shortName)
      self.specials = try container.decode(String.self, forKey: .specials)
      self.specialNotes = try container.decode(String.self, forKey: .specialNotes)
      self.type = try container.decode(Int.self, forKey: .type)
      self.website = try container.decode(String.self, forKey: .website)
      self.yelpCategory = try container.decode(String.self, forKey: .yelpCategory)
      self.yelpId = try container.decode(String.self, forKey: .yelpId)
      self.yelpRating = try container.decode(Double.self, forKey: .yelpRating)
      self.yelpReviews = try container.decode(Int.self, forKey: .yelpReviews)
      self.yelpPrice = try container.decode(String.self, forKey: .yelpPrice)
      self.yelpUrl = try container.decode(String.self, forKey: .yelpUrl)
      self.archStyle = try container.decode(String.self, forKey: .archStyle)
      self.estimatedValue = try container.decode(String.self, forKey: .estimatedValue)
      self.lotSize = try container.decode(Double.self, forKey: .lotSize)
      self.squareFeet = try container.decode(Int.self, forKey: .squareFeet)
      self.yearBuilt = try container.decode(Int.self, forKey: .yearBuilt)
      self.instagram = try container.decode(String.self, forKey: .instagram)
      self.videoUrl = try container.decode(String.self, forKey: .videoUrl)
      self.timestamp = Date.now
    }
    
    func updateConcordRating() {
      if concordRatings != "" {
        let ratings = concordRatings.components(separatedBy: ";")
        var ratingTotal = 0.0
        
        for rating in ratings {
          ratingTotal += Double(rating)!
        }
        
        let averageRating = ratingTotal / Double(ratings.count)
        
        if averageRating >= 1.0 && averageRating < 1.5 {
          concordReviewAverage = 1.0
        } else if averageRating >= 1.5 && averageRating < 2.0 {
          concordReviewAverage = 1.5
        } else if averageRating >= 2.0 && averageRating < 2.5 {
          concordReviewAverage = 2.0
        } else if averageRating >= 2.5 && averageRating < 3.0 {
          concordReviewAverage = 2.5
        } else if averageRating >= 3.0 && averageRating < 3.5 {
          concordReviewAverage = 3.0
        } else if averageRating >= 3.5 && averageRating < 4.0 {
          concordReviewAverage = 3.5
        } else if averageRating >= 4.0 && averageRating < 4.5 {
          concordReviewAverage = 4.0
        } else if averageRating >= 4.5 && averageRating < 5.0 {
          concordReviewAverage = 4.5
        } else {
          concordReviewAverage = 5.0
        }
      }
    }
    
    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(name, forKey: .name)
    }
  }
    
  @Model
  final class Tour: Identifiable, Codable, Equatable {
    enum CodingKeys: CodingKey {
      case documentID
      case tourId
      case name
      case desc
    }
    var documentID = ""
    var tourId = -1
    var name = ""
    var desc = ""
    var timestamp: Date
    
    required init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.documentID = try container.decode(String.self, forKey: .documentID)
      self.tourId = try container.decode(Int.self, forKey: .tourId)
      self.name = try container.decode(String.self, forKey: .name)
      self.desc = try container.decode(String.self, forKey: .desc)
      self.timestamp = Date.now
    }
    
    init() {
      self.timestamp = Date.now
    }
    
    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(name, forKey: .name)
    }
  }

  @Model
  final class TourPlace: Identifiable, Codable, Equatable {
    enum CodingKeys: CodingKey {
      case documentID
      case tourId
      case placeDocId
      case notes
      case name
    }
    var documentID = ""
    var tourId = -1
    var placeDocId = ""
    var name = ""
    var notes = ""
    var timestamp: Date
    
    init() {
      self.timestamp = Date.now
    }
    
    required init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.documentID = try container.decode(String.self, forKey: .documentID)
      self.tourId = try container.decode(Int.self, forKey: .tourId)
      self.placeDocId = try container.decode(String.self, forKey: .placeDocId)
      self.name = try container.decode(String.self, forKey: .name)
      self.notes = try container.decode(String.self, forKey: .notes)
      self.timestamp = Date.now
    }
    
    func encode(to encoder: Encoder) throws {
    }
  }
  
  @Model
  final class Video: Identifiable, Codable, Equatable {
    enum CodingKeys: CodingKey {
      case documentID
      case name
      case youtubeId
    }
    var documentID = ""
    var name = ""
    var youtubeId = ""
    var timestamp: Date
    
    required init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.documentID = try container.decode(String.self, forKey: .documentID)
      self.name = try container.decode(String.self, forKey: .name)
      self.youtubeId = try container.decode(String.self, forKey: .youtubeId)
      self.timestamp = Date.now
    }
    
    init() {
      self.timestamp = Date.now
    }
    
    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(name, forKey: .name)
    }
  }


func imageNameIfSpecialIsToday(special: String, showSpecial: Bool) -> String { 
  if special != "" && showSpecial == true {
    if special.contains(",") {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "MM/dd/yyyy"
      dateFormatter.locale = Locale(identifier: "en_US_POSIX")
      let parts = special.components(separatedBy: ",")
      let dates = parts[1].components(separatedBy: "-")
      
      if dates.count > 1 {
        let startDate = dateFormatter.date(from: dates[0])!
        let endDate = dateFormatter.date(from: dates[1])!
        if Calendar.current.compare(Date.now, to: startDate, toGranularity: .day) == .orderedAscending || Calendar.current.compare(Date.now, to: endDate, toGranularity: .day) == .orderedDescending {
          return ""
        } else {
          return parts[0]
        }
      } else if let singleDate:Date = dateFormatter.date(from: parts[1]) {
        if Calendar.current.isDate(Date.now, inSameDayAs: singleDate) {
          return parts[0]
        } else {
          return ""
        }
      } else {
        let specials = special.components(separatedBy: ",")
        if specials[1].contains("`") {
          let daysOfTheWeek = specials[1].components(separatedBy: "`")
          var foundDay = false

          daysOfTheWeek.forEach { day in
            if let dayNumber = Int(day) {
              if Date.now.dayNumberOfWeek() == dayNumber {
                foundDay = true
              }
            }
          }
          
          if foundDay == true {
            return specials[0]
          }
        }
        if let dayNumber = Int(specials[1]) {
          if Date.now.dayNumberOfWeek() != dayNumber {
            return ""
          } else {
            return specials[0]
          }
        } else {
          return parts[0]
        }
      }
    } else {
      return special
    }
  } else {
    return ""
  }
}
