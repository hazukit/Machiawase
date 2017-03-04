//
//  CameraViewController.swift
//  Machiawase
//
//  Created by naru on 2017/03/04.
//  Copyright © 2017年 hazukit. All rights reserved.
//

import UIKit
import CoreLocation
import FirebaseDatabase

class CameraViewController: UIViewController, CLLocationManagerDelegate {
    
    var lm: CLLocationManager! = nil
    var heading: CLLocationDirection! = nil
    //    var currentLocation: MLocation! = nil
    var toLocation: MLocation! = nil // 後で配列にする
    var currentLocation:CLLocation!
    private let ref = FIRDatabase.database().reference()
    private var firebaseName: String! = nil
    private var firebaseId: String! = nil
    private var peoples: [People] = []

    struct MLocation {
        public var latitude: CLLocationDegrees!
        public var longitude: CLLocationDegrees!
        public var altitude: CLLocationDistance!
    }
    
    struct People {
        var identifier: String
        var name: String
        var latitude: Double
        var longitude: Double
        var altitude: Double
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        
        let userDefaults = UserDefaults.standard
        firebaseName = userDefaults.string(forKey: "name")
        firebaseId = userDefaults.string(forKey: "firebaseId")
        
        ref.child("users").observe(.value, with: { snapshot in
            self.observeOtherLocation(snapshot: snapshot)
        })
        
        self.view.addSubview(self.captureStillImageView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        toLocation = MLocation()
        toLocation.latitude = 35.698353
        toLocation.longitude = 139.773114
        toLocation.altitude = 0
        
        self.captureStillImageView.setupCamera()
        self.captureStillImageView.startSession()
        if CLLocationManager.locationServicesEnabled() {
            lm = CLLocationManager()
            lm.delegate = self
            lm.requestAlwaysAuthorization()
            lm.desiredAccuracy = kCLLocationAccuracyBest
            lm.distanceFilter = 300
            lm.startUpdatingLocation()
            lm.startUpdatingHeading();
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.captureStillImageView.stopSession()
        lm.stopUpdatingHeading();
        lm.stopUpdatingLocation();
    }
    
    // MARK: Elements
    
    lazy var peopleManager: PeopleManager = PeopleManager(with: self.view)
    
    lazy var captureStillImageView: CaptureStillImageView = {
        let view: CaptureStillImageView = CaptureStillImageView(frame: self.view.bounds)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }()
    
    // MARK: -
    // MARK: private methods
    
    private func convertToPoint(heading hd: CLLocationDirection!, distance dis:CLLocationDistance, fromLocation fromLc: CLLocation!,  toLocation toLc: CLLocation!) -> (x:CGFloat,y:CGFloat){
        
        //        toLocation.latitude = 35.6923069230659
        //        toLocation.longitude = 139.768417420218
        let latitude = (toLc.coordinate.latitude - fromLc.coordinate.latitude)
        let longitude = (toLc.coordinate.longitude - fromLc.coordinate.longitude)
        let altitude = (toLc.altitude - fromLc.altitude)
        
        //let x = y
        let rang = atan2(latitude, longitude) - 90
        let y = altitude * 0.5
        let x = dis * cos(rang * M_PI/180)
        
        print("point lat:", fromLc.coordinate.latitude)
        print("point lot:", fromLc.coordinate.longitude)
        print("point x:", x)
        print("point y:", y)
        print("point hd:", hd)
        print("point rang:", rang)
//        print("point rang2:", rang2/(M_PI / 180))
//        print("point rang:", rang2 - hd)
        return (CGFloat(x),CGFloat(y))
    }
    
    private func update() {
        if (currentLocation == nil || heading == nil) {
            return
        }
        var peopleArray:[PeopleLocation] = []
        for people in peoples {
            let to = CLLocation.init(coordinate: CLLocationCoordinate2D.init(latitude: people.latitude, longitude: people.longitude), altitude: people.altitude, horizontalAccuracy: 0, verticalAccuracy: 0, course: -1, speed: 0, timestamp: Date())
            let distance = currentLocation.distance(from: to)
            let v = convertToPoint(heading: heading, distance: distance,fromLocation: currentLocation, toLocation: to)
            let altitude = (currentLocation.altitude - to.altitude)
            
            let p:PeopleLocation = PeopleLocation(identifier: people.identifier, name: people.name, x: v.x, y: v.y, distance: Int(distance), differenceOfAltitude: Int(altitude))
            peopleArray.append(p)
        }
        peopleManager.update(with: peopleArray)
    }
    
    private func displayPoint(heading hd: CLLocationDirection!, fromLocation fromLc: CLLocation!,  toLocation toLc: MLocation!) {
        if (hd == nil || fromLc == nil || toLc == nil) {
            return
        }
        
        var location = MLocation()
        location.latitude = fromLc.coordinate.latitude
        location.longitude = fromLc.coordinate.longitude
        location.altitude = fromLc.altitude
        uploadMyLocation(fromLocation: location)
        /*
        let to = CLLocation.init(coordinate: CLLocationCoordinate2D.init(latitude: toLocation.latitude, longitude: toLocation.longitude), altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: -1, speed: 0, timestamp: Date())
        let distance = fromLc.distance(from: to)
        
        let v = convertToPoint(heading: hd, distance: distance,fromLocation: fromLc, toLocation: to)
        let altitude = (toLc.altitude - fromLc.altitude)
        let p:PeopleLocation = PeopleLocation(identifier: "test", name: "yuri", x: v.x, y: v.y, distance: Int(distance), differenceOfAltitude: Int(altitude))
        peopleManager.update(with: [p])
 */
    }
    
    
    // MARK: -
    // MARK: CLLocationManagerDelegate methods
    /** 位置情報取得成功時 */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else {
            return
        }
        //        currentLocation = MLocation()
        //        currentLocation.latitude = newLocation.coordinate.latitude
        //        currentLocation.longitude = newLocation.coordinate.longitude
        //        currentLocation.altitude = newLocation.altitude
        currentLocation = newLocation;
        
        displayPoint(heading: heading, fromLocation: currentLocation, toLocation: toLocation)
    }
    
    /** 方向取得成功時 */
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = ((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading);
        
        //        heading = newHeading
        displayPoint(heading: heading, fromLocation: currentLocation, toLocation: toLocation)
    }
    
    /** 位置情報取得失敗時 */
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status:   CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            lm.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways, .authorizedWhenInUse:
            break
        }
    }
    
    /** upload my location data to firebase */
    private func uploadMyLocation(fromLocation fromLc: MLocation) {
        if let name: String = self.firebaseName {
            if let id: String = self.firebaseId {
                let post = ["id": ["id" : id], "user": ["name": name], "location": ["longitude": fromLc.longitude, "latitude": fromLc.latitude, "altitude": fromLc.altitude]] as [String : Any]
                let childUpdates = ["/users/\(id)/": post]
                ref.updateChildValues(childUpdates)
            }
        }
    }
    
    /** observe firebase**/
    private func observeOtherLocation(snapshot: FIRDataSnapshot) {
        guard let dic = snapshot.value as? Dictionary<String, AnyObject> else {
            return
        }
        var peopleInfo: [People] = []
        for data in dic {
            var people: People = People.init(identifier: "", name: "", latitude: 0.0, longitude: 0.0, altitude: 0.0)
            
            let name = data.value["user"]
            let location = data.value["location"]
            let id = data.value["id"]
            if let userName: [String : String] = name as! [String : String]? {
                if let user: String = userName["name"] {
                    people.name = user
                }
            }
            if let userLocation: [String : Double] = location as! [String : Double]? {
                if let alt: Double = userLocation["altitude"] {
                    people.altitude = alt
                }
                if let lat: Double = userLocation["latitude"] {
                    people.latitude = lat
                }
                if let lon: Double = userLocation["longitude"] {
                    people.longitude = lon
                }
            }
            if let userId: [String : String] = id as! [String : String]? {
                if let identifier: String = userId["identifier"] {
                    people.identifier = identifier
                }
            }
            peopleInfo.append(people)
        }
        if !self.peoples.isEmpty {
            self.peoples.removeAll()
        }
        self.peoples = peopleInfo
        update()
    }
    
}
