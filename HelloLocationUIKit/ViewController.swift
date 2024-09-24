//
//  ViewController.swift
//  HelloLocationUIKit
//
//  Created by 申潤五 on 2024/9/24.
//

import UIKit
import MapKit
//import CoreLocation

class ViewController: UIViewController {
    

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var searchText: UITextField!
    var locationManager: CLLocationManager!
    var searchResult: [MKMapItem] = []
    private var userTrackingModeObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 初始化 CLLocationManager
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // 請求使用位置權限
        locationManager.requestWhenInUseAuthorization()
        
        mapView.userTrackingMode = .followWithHeading
        mapView.delegate = self
        
        mapView.showsUserTrackingButton = true
        mapView.showsCompass = true
        mapView.showsScale = true
  
        let location = CLLocationCoordinate2D(
            latitude: 25.04729,
            longitude: 121.51756)
        
        let region = MKCoordinateRegion(center: location,
                           span: MKCoordinateSpan(
                            latitudeDelta: 0.01,
                            longitudeDelta: 0.01))
        self.mapView.setRegion(region, animated: true)
        
        // 開始更新位置
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    @IBAction func doSearch(_ sender: Any) {
        searchMapItem(searchText.text!, mapView.region)
    }
    
    
    func searchMapItem(_ query:String,_ region:MKCoordinateRegion){
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        request.region = region
        
        //移除 Annotations
        let annotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(annotations)
     
        
        Task {
            let search = MKLocalSearch(request: request)
            let response = try? await search.start()
            searchResult = response?.mapItems ?? []
            for item in searchResult {
                let annotation = MKPointAnnotation()
                annotation.title = item.name
                annotation.coordinate = item.placemark.coordinate
//                if let category = item.pointOfInterestCategory {
//                    let imageView = UIImageView(image: UIImage(systemName:  symbol(for: category)))
//                    let point = self.mapView.convert(annotation.coordinate, toPointTo: self.mapView)
//                    imageView.center = point
//                    self.mapView.addSubview(imageView)
//                }
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    func reAuthorizeLocation(_ manager: CLLocationManager) {
        if manager.authorizationStatus != .authorizedAlways ||
            manager.authorizationStatus != .authorizedWhenInUse{
            let alert = UIAlertController(title: "位置授權被拒絕", message: "請前往設定頁面重新授權位置訪問。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "前往設定",
                                          style: .default, handler: { _ in
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                }
            }))
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }else{
            let alert = UIAlertController(title: "獲取位置失敗", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "我知道了",style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
}
extension ViewController:MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("test")
        let center = userLocation.coordinate
        let point = self.mapView.convert(center, toPointTo: self.mapView)
        let imageView = UIImageView(image: UIImage(systemName: "car.side.fill"))
        imageView.accessibilityIdentifier = "theCar"
        imageView.tintColor = .red
        imageView.center = point
        for subview in self.mapView.subviews {
            if subview.accessibilityIdentifier == "theCar" {
                subview.removeFromSuperview()
            }
        }
        self.mapView.addSubview(imageView)
    }
    
    func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: any Error) {
        self.reAuthorizeLocation(self.locationManager!)
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    // CLLocationManagerDelegate 方法
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            self.mapView.setRegion(region, animated: true)
            let point = self.mapView.convert(center, toPointTo: self.mapView)
            let imageView = UIImageView(image: UIImage(systemName: "car.side.fill"))
            imageView.accessibilityIdentifier = "theCar"
            imageView.center = point
            for subview in mapView.subviews {
                if subview.accessibilityIdentifier == "theCar" {
                    subview.removeFromSuperview()
                }
            }
            mapView.addSubview(imageView)
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("獲取位置失敗：\(error.localizedDescription)")
        reAuthorizeLocation(manager)
   
    }
   
    
}
