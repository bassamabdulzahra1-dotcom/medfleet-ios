import SwiftUI
import CoreLocation

struct PharmaciesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var pharmacies: [Pharmacy] = []
    @State private var loading = true
    @StateObject private var location = LocationService()

    var body: some View {
        OpenModuleLayout(onBack: { dismiss() }) {
            Group {
                if loading { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
                else {
                    List(pharmacies) { p in
                        VStack(alignment: .trailing, spacing: 6) {
                            Text(p.name).font(.headline)
                            if let r = p.region { Text(r).font(.caption).foregroundStyle(MFColors.muted) }
                            HStack {
                                Button("تثبيت الموقع") { Task { await lock(p) } }.font(.caption)
                                Spacer()
                                Button("تسجيل زيارة") { Task { await checkin(p) } }
                                    .buttonStyle(.borderedProminent)
                                    .tint(MFColors.gold)
                            }
                        }
                    }
                }
            }
        }
        .overlay(alignment: .bottomLeading) {
            NavigationLink(value: AppRoute.addPharmacy) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(MFColors.gold)
                    .shadow(radius: 4)
            }
            .padding(24)
        }
        .task { await load() }
        .onAppear { location.request() }
    }

    private func load() async {
        guard let api = appState.api else { return }
        pharmacies = (try? await api.listPharmacies()) ?? []
        loading = false
    }

    private func checkin(_ p: Pharmacy) async {
        guard let api = appState.api, let loc = location.coordinate else { return }
        try? await api.checkin(pharmacyId: p.id, lat: loc.latitude, lng: loc.longitude)
    }

    private func lock(_ p: Pharmacy) async {
        guard let api = appState.api, let loc = location.coordinate else { return }
        _ = try? await api.lockLocation(pharmacyId: p.id, lat: loc.latitude, lng: loc.longitude)
        await load()
    }
}

@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func request() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        coordinate = locations.last?.coordinate
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

struct AddPharmacyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var location = LocationService()

    @State private var name = ""
    @State private var region = ""
    @State private var address = ""
    @State private var phone = ""
    @State private var saving = false

    var body: some View {
        OpenModuleLayout(onBack: { dismiss() }) {
            Form {
                TextField("اسم الصيدلية", text: $name)
                TextField("المنطقة", text: $region)
                TextField("العنوان", text: $address)
                TextField("الهاتف", text: $phone).keyboardType(.phonePad)
                if location.coordinate != nil {
                    Text("تم تحديد الموقع ✓").foregroundStyle(MFColors.ok)
                } else {
                    Button("تحديد الموقع") { location.request() }
                }
                Button("حفظ") { Task { await save() } }.disabled(saving || name.isEmpty)
            }
            .padding(.top, 48)
        }
        .onAppear { location.request() }
    }

    private func save() async {
        guard let api = appState.api else { return }
        saving = true
        defer { saving = false }
        let req = PharmacyCreateRequest(
            name: name, address: address.nilIfEmpty, region: region.nilIfEmpty,
            contactPhone: phone.nilIfEmpty, classification: "C",
            latitude: location.coordinate?.latitude, longitude: location.coordinate?.longitude,
            geofenceM: 100
        )
        if (try? await api.createPharmacy(req)) != nil { dismiss() }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
