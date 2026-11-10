import CoreLocation
import Foundation

enum LocationFix {
    @MainActor
    static func current() async -> (lat: Double, lng: Double)? {
        await withCheckedContinuation { cont in
            let box = LocationBox()
            LocationBox.retain(box)
            box.resolve { result in
                LocationBox.release(box)
                cont.resume(returning: result)
            }
            box.start()
        }
    }
}

private final class LocationBox: NSObject, CLLocationManagerDelegate {
    private static var live = Set<ObjectIdentifier>()
    private static var refs = [ObjectIdentifier: LocationBox]()

    private let manager = CLLocationManager()
    private var onDone: (((lat: Double, lng: Double)?) -> Void)?
    private var finished = false

    static func retain(_ box: LocationBox) {
        let id = ObjectIdentifier(box)
        live.insert(id)
        refs[id] = box
    }

    static func release(_ box: LocationBox) {
        let id = ObjectIdentifier(box)
        live.remove(id)
        refs.removeValue(forKey: id)
    }

    func resolve(_ done: @escaping ((lat: Double, lng: Double)?) -> Void) {
        onDone = done
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func start() {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            finish(nil)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            finish(nil)
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else {
            finish(nil)
            return
        }
        finish((loc.coordinate.latitude, loc.coordinate.longitude))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(nil)
    }

    private func finish(_ value: (lat: Double, lng: Double)?) {
        guard !finished else { return }
        finished = true
        onDone?(value)
        onDone = nil
    }
}
