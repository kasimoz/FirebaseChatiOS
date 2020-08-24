//
//  MapViewController.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 25.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager: CLLocationManager?
    var userAnnotation : MyPointAnnotation!
    var coordinate = ""
    var username = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
        mapView.delegate = self
        let array = self.coordinate.split(separator: ",").map(String.init)
        let latitude = array[0].toDouble() ?? 0.0
        let longitude = array[1].toDouble() ?? 0.0
        let coor = CLLocationCoordinate2D.init(latitude: CLLocationDegrees.init(latitude), longitude: CLLocationDegrees.init(longitude))
        let annotation = CustomMKAnnotation(
            title: username,
            coordinate: coor)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: coor.latitude, longitude:coor.longitude), span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        DispatchQueue.main.async {
            self.mapView.setRegion(region, animated: false)
            self.mapView.addAnnotation(annotation)
        }
        
        self.navigationItem.titleView = self.setTitleView(title: "", subtitle: "")
        setCityAndDistrict(coords: CLLocation.init(latitude: CLLocationDegrees.init(latitude), longitude: CLLocationDegrees.init(longitude)))
        
    }
    
    func setCityAndDistrict(coords: CLLocation){
        CLGeocoder().reverseGeocodeLocation(coords) { (placemark, error) in
            if error != nil {
                print("CLGeocoder error")
            } else {
                
                let place = placemark! as [CLPlacemark]
                if place.count > 0 {
                    let place = placemark![0]
                    let city = place.administrativeArea ?? ""
                    let district = place.subAdministrativeArea ?? ""
                    let postalCode = place.postalCode ?? ""
                    let thoroughfare = place.thoroughfare ?? ""
                    let subThoroughfare = place.subThoroughfare ?? ""
                    let subLocality = place.subLocality ?? ""
                    
                    let title = "\(thoroughfare) \(subThoroughfare)".trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? subLocality : "\(thoroughfare) \(subThoroughfare)".trimmingCharacters(in: .whitespacesAndNewlines)
                    let subtitle = "\(postalCode) \(district) \(city)"
                    self.navigationItem.titleView = self.setTitleView(title: title, subtitle: subtitle)
                }
            }
        }
    }
    
    func setTitleView(title : String, subtitle : String) -> UIView {
        
        let titleLabel = UILabel(frame: CGRect(x: 0, y: -2, width: 0, height: 0))
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = .black
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
        titleLabel.text = title
        titleLabel.textAlignment = .left
        titleLabel.sizeToFit()
        
        
        let subtitleLabel = UILabel(frame: CGRect(x: 0, y: 18, width: 0, height: 0))
        subtitleLabel.backgroundColor = UIColor.clear
        subtitleLabel.textColor = .black
        subtitleLabel.font = UIFont.systemFont(ofSize: 12.0)
        subtitleLabel.text = subtitle
        subtitleLabel.textAlignment = .left
        subtitleLabel.sizeToFit()
        
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 30))
        titleView.addSubview(titleLabel)
        titleView.addSubview(subtitleLabel)
        
        return titleView
    }
    
    
    @IBAction func mapTypeAction(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.mapView.mapType = .standard
            break
        case 1:
            self.mapView.mapType = .hybrid
            break
        case 2:
            self.mapView.mapType = .satellite
            break
        default:
            break
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? CustomMKAnnotation else {
            return nil
        }
        // 3
        let identifier = "customMKAnnotation"
        var view: MKPinAnnotationView
        // 4
        if let dequeuedView = mapView.dequeueReusableAnnotationView(
            withIdentifier: identifier) as? MKPinAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            // 5
            view = MKPinAnnotationView(
                annotation: annotation,
                reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -8, y: -5)
            let button = UIButton.init(type: .detailDisclosure)
            button.setImage(UIImage.init(systemName: "car.fill"), for: .normal)
            button.tintColor = Constants.blue
            button.addTarget(self, action: #selector(self.directions), for: .touchUpInside)
            view.rightCalloutAccessoryView = button
        }
        return view
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = Constants.blue
        return renderer
    }
    
    @objc func directions(){
        let array = self.coordinate.split(separator: ",").map(String.init)
        let latitude = array[0].toDouble() ?? 0.0
        let longitude = array[1].toDouble() ?? 0.0
        let coordinate = CLLocationCoordinate2DMake(latitude,longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
        mapItem.name = self.username
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

class CustomMKAnnotation: NSObject, MKAnnotation {
    let title: String?
    let coordinate: CLLocationCoordinate2D
    
    init(
        title: String?,
        coordinate: CLLocationCoordinate2D
    ) {
        self.title = title
        self.coordinate = coordinate
        
        super.init()
    }
    
}
