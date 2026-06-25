import SwiftUI
import UIKit

// غلاف UIImagePickerController يدعم الكاميرا والمعرض ويعيد بيانات JPEG مضغوطة
struct ImagePicker: UIViewControllerRepresentable {
    enum Source { case camera, library }

    let source: Source
    let onPicked: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        switch source {
        case .camera:
            picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        case .library:
            picker.sourceType = .photoLibrary
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = ImagePicker.jpegData(from: image) {
                parent.onPicked(data)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }

    // تصغير الصورة الكبيرة وضغطها لتقليل حجم الرفع
    static func jpegData(from image: UIImage, maxDimension: CGFloat = 2000) -> Data? {
        let size = image.size
        let scaled: UIImage
        if max(size.width, size.height) > maxDimension {
            let ratio = maxDimension / max(size.width, size.height)
            let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            scaled = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        } else {
            scaled = image
        }
        return scaled.jpegData(compressionQuality: 0.7)
    }
}
