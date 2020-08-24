//
//  ShareLocationViewController.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 24.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ShareLocationViewController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, MKMapViewDelegate {
    @IBOutlet weak var locationSwitch: UISwitch!
    @IBOutlet weak var searchTextField: UITextField!
    var locationManager: CLLocationManager?
    var userAnnotation : MyPointAnnotation!
    var tapAnnotation : MyPointAnnotation!
    var annotatios : [MKAnnotation] = []
    var locationUpdateTime : Int64 = 0
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    var snapShotOptions: MKMapSnapshotter.Options = MKMapSnapshotter.Options()
    var snapShot: MKMapSnapshotter!
    override func viewDidLoad() {
        super.viewDidLoad()
        locationSwitch.isOn = UserDefaults.init().optionalBool(forKey: "userLocation") ?? true
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            locationManager?.startUpdatingLocation()
        }
        let gestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(self.handleTap(_:)))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
        mapView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationMessage(_:)), name: NSNotification.Name("notification"), object: nil)
        
    }
    
    @objc func notificationMessage(_ notification: NSNotification) {
        if let _ = notification.userInfo?["sender"] as? String {
            if let _ = notification.userInfo?["chatUID"] as? String {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    
    @IBAction func shareAction(_ sender: Any) {
        if !(self.location.text?.isEmpty ?? false) {
            snapShotOptions.region = mapView.region
            snapShotOptions.size = mapView.frame.size
            snapShotOptions.scale = UIScreen.main.scale
            
            snapShot = MKMapSnapshotter(options: snapShotOptions)
            
            snapShot.cancel()
            
            snapShot.start { (snapshot, error) -> Void in
                if error == nil {
                    let x = (snapshot?.image.size.width)! / 6
                    let y = (snapshot?.image.size.height)! / 2 - (snapshot?.image.size.width)! / 6
                    let width = (snapshot?.image.size.width)! * 0.66
                    let height = (snapshot?.image.size.width)! * 0.33
                    let mapImage = snapshot!.image.sd_croppedImage(with: CGRect.init(x: x, y: y, width: width, height: height))
                    let locationData : [String: Any] = [ "image" : mapImage, "coordinate" : self.location.text!]
                    NotificationCenter.default.post(name: Notification.Name("shareLocation"), object: nil, userInfo: locationData)
                    self.dismiss(animated: true, completion: nil)
                } else {
                    print("error")
                }
            }
        }
    }
    
    
    @IBAction func currentChanged(_ sender: UISwitch) {
        if !sender.isOn && self.userAnnotation != nil{
            self.mapView.removeAnnotation(self.userAnnotation)
        }
        UserDefaults.init().set(sender.isOn, forKey: "userLocation")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if self.locationUpdateTime == 0 || Date().millisecondsSince1970 - self.locationUpdateTime > 30000 {
            if self.userAnnotation != nil {
                self.mapView.removeAnnotation(self.userAnnotation)
            }
            if UserDefaults.init().optionalBool(forKey: "userLocation") ?? true {
                let coor : CLLocationCoordinate2D = manager.location!.coordinate
                self.location.text = String.init(format: "%.6f,%.6f", coor.latitude, coor.longitude)
                self.userAnnotation = MyPointAnnotation()
                self.userAnnotation.coordinate = coor
                self.userAnnotation.title = "You"
                self.userAnnotation.pinTintColor = Constants.blue
                let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: coor.latitude, longitude:coor.longitude), span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
                DispatchQueue.main.async {
                    self.locationUpdateTime = Date().millisecondsSince1970
                    self.mapView.setRegion(region, animated: true)
                    self.mapView.addAnnotation(self.userAnnotation)
                }
            }
        }
    }
    
    @objc func handleTap(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            if self.tapAnnotation != nil {
                self.mapView.removeAnnotation(self.tapAnnotation)
            }
            let location = gestureRecognizer.location(in: mapView)
            let coor = mapView.convert(location, toCoordinateFrom: mapView)
            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: coor.latitude, longitude:coor.longitude), span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
            self.location.text = String.init(format: "%.6f,%.6f", coor.latitude, coor.longitude)
            self.tapAnnotation = MyPointAnnotation()
            self.tapAnnotation.coordinate = coor
            self.tapAnnotation.pinTintColor = Constants.orange
            
            DispatchQueue.main.async {
                self.mapView.setRegion(region, animated: true)
                self.mapView.addAnnotation(self.tapAnnotation)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let selectedAnnotation = view.annotation
        self.location.text = String.init(format: "%.6f,%.6f", selectedAnnotation?.coordinate.latitude as! CVarArg, selectedAnnotation?.coordinate.longitude as! CVarArg)
        mapView.centerCoordinate = selectedAnnotation?.coordinate as! CLLocationCoordinate2D
    }
    
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "myAnnotation") as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myAnnotation")
        } else {
            annotationView?.annotation = annotation
        }
        
        if let annotation = annotation as? MyPointAnnotation {
            annotationView?.pinTintColor = annotation.pinTintColor
        }
        
        return annotationView
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text?.count ?? 0 > 0 {
            self.search(text: textField.text!)
            textField.text = ""
        }
        textField.resignFirstResponder()
        
        return true
    }
    
    func search (text : String){
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = text
        searchRequest.region = mapView.region
        
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            guard let response = response else {
                print("Error: \(error?.localizedDescription ?? "Unknown error").")
                return
            }
            
            self.mapView.removeAnnotations(self.annotatios)
            self.annotatios.removeAll()
            for item in response.mapItems {
                let mkanot = item.placemark
                self.annotatios.append(mkanot)
                self.mapView.addAnnotation(mkanot)
            }
        }
    }
    
}

class MyPointAnnotation : MKPointAnnotation {
    var pinTintColor: UIColor?
}
