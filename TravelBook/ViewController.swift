//
//  ViewController.swift
//  TravelBook
//
//  Created by Gizem on 28.07.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var nameText: UITextField!
    
    @IBOutlet weak var commentText: UITextField!
    
    @IBOutlet weak var mapView: MKMapView!
//    kullanıcının konumunu almak için
    var locationManager = CLLocationManager()
    var choosenLatitude = Double()
    var chosenLongitude = Double()
    var selectedTitle = ""
    var selectedTitleID : UUID!
    var annotationTitle = ""
    var annotationSubTitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
   
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
//        konumun verisi ne kadar keskinlikle kullanılacak
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//       konumu almasına appi kullanırken izin ver
        locationManager.requestWhenInUseAuthorization()
//        kullanıcının yerini alma
        locationManager.startUpdatingLocation()
        
//        GESTURERECOGNIZER
//        kullanıcı uzun bastığında çalışır
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
//        kaç saniye basmasını istiyosan bunu kullan
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
//        seçilen rowun detaylarını çekme
        if selectedTitle != "" {
//            core data
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
//            filtre eklemek idsi idstringe eşit olanları getir
            let idString = selectedTitleID!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            do{
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
//                        iç içe kontrol
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            if let subtitle = result.value(forKey: "subtitle") as? String {
                                annotationSubTitle = subtitle
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitude
                                        
//                                        her şey olduğundan emin olunca annotationumu oluştururum
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubTitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubTitle
//                                        konum değişse bile pinlediğim yeri görebilmek için
                                        locationManager.stopUpdatingLocation()
//                                        alınan güncel lokasyona götürmesi için
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                print("error")
            }
           
  
            
        } else {
//            add new data
        }
        
    }
//gestureRecognizer : UILongPressGestureRecognizer sebebi attributelerine ulaşmak
    @objc func chooseLocation(gestureRecognizer : UILongPressGestureRecognizer) {
//gestureRecognizer başladıysa yani dokunulduysa
//        pinlemek
        if gestureRecognizer.state == .began {
            let touchedPoint = gestureRecognizer.location(in: self.mapView) //nereye tıklandığını aldık
            let touchedCoordinats = mapView.convert(touchedPoint, toCoordinateFrom: self.mapView) //koordinata çevirdik
            
//            enlem ve boylamı değişkene atadım kaydetme işlemi için
            choosenLatitude = touchedCoordinats.latitude
            chosenLongitude = touchedCoordinats.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinats
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation) //haritaya ekledik
        }
        
    }
//    annotationu özelleştirmek için
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
//            annotationun rengini belirlemek için
            pinView?.tintColor = UIColor.black
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }else {
            pinView?.annotation = annotation
        }
  
        return pinView
    }
//detailDisclosure butonuna tıklandığında navigasyon oluşturabiliriz. burada tıklanıldığını anlamak için kullanılan fonksiyon= calloutAccessoryControlTapped
    //     burada tıklanılan butonla navigasyon açtırdık ve yol tarifi aldık
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
//CLGeocoder = koordinatlar ve yerler arasında bağlantı kurmamızı sağlayan bir sınıf
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks , error in
//                closure (callback func)

                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
                
            }
        }
    }
    
    
//kullanıcının konumunu aldıktan sonra ne yapacağmızı yazdığımız yer
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
    //        haritadaki zoom seviyesi
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
 
    }
    
    
    @IBAction func saveButton(_ sender: Any) {
//        kaydetme işlemi
//        app delegate çağır, NSentitydescriptionu çağırıp kullanıcının kaydetmek istediği verileri koyacağımız yer
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)  //COREDATA objemize ulaştığımız yer
        //istediğim anahtar kelimeye karşılık istediğim değerleri kaydetmek
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(choosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        do{
           try context.save()
            print("success")
        }catch {
            print("error")
        }
//        tablei güncellemek için notificationcenter kullan. bu mesajı aldığında tabloyu güncelle demek istiyoruz
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
        
    }
    
}

