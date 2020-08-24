//
//  CopyLocationViewController.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 2.07.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit
import MapKit

class CopyLocationViewController: UIViewController, MKMapViewDelegate {
    
    var userAnnotation : MyPointAnnotation!
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    var snapShotOptions: MKMapSnapshotter.Options = MKMapSnapshotter.Options()
    var snapShot: MKMapSnapshotter!
    var coordinate = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        let corrArray = self.coordinate.split(separator: ",").map(String.init)
        let coor = CLLocationCoordinate2D.init(latitude: CLLocationDegrees.init(corrArray.first?.toDouble() ?? 0.0), longitude: CLLocationDegrees.init(corrArray.last?.toDouble() ?? 0.0))
        self.location.text = String.init(format: "%.6f,%.6f", coor.latitude, coor.longitude)
        self.userAnnotation = MyPointAnnotation()
        self.userAnnotation.coordinate = coor
        self.userAnnotation.pinTintColor = .red
        mapView.addAnnotation(self.userAnnotation)
        mapView.centerCoordinate = coor
        mapView.setCameraZoomRange(MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 3000), animated: false)
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
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
