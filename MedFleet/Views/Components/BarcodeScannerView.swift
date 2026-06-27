import SwiftUI
import VisionKit

struct BarcodeScannerSheet: UIViewControllerRepresentable {
    let onFound: (String) -> Void
    let onError: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFound: onFound, onError: onError)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let types: Set<DataScannerViewController.RecognizedDataType> = [
            .barcode(symbologies: [.ean8, .ean13, .upce, .code39, .code128, .itf14, .qr, .pdf417, .aztec, .dataMatrix])
        ]

        let controller = DataScannerViewController(
            recognizedDataTypes: types,
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator

        DispatchQueue.main.async {
            do {
                try controller.startScanning()
            } catch {
                onError("تعذر تشغيل الكاميرا للمسح")
            }
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onFound: (String) -> Void
        private let onError: (String) -> Void
        private var didEmit = false

        init(onFound: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
            self.onFound = onFound
            self.onError = onError
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            guard !didEmit else { return }
            for item in addedItems {
                if case .barcode(let code) = item,
                   let payload = code.payloadStringValue,
                   !payload.isEmpty {
                    didEmit = true
                    onFound(payload)
                    return
                }
            }
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            onError("المسح غير متاح على هذا الجهاز")
        }
    }
}

struct BarcodeScannerAvailability {
    static var isAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }
}
