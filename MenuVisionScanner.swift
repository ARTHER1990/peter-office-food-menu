import Foundation
import Vision
import AppKit

guard CommandLine.arguments.count > 1 else {
    print("❌ Usage: MenuVisionScanner <path_to_image_file>")
    exit(1)
}

let imagePath = CommandLine.arguments[1]
let fileURL = URL(fileURLWithPath: (imagePath as NSString).expandingTildeInPath)

guard FileManager.default.fileExists(atPath: fileURL.path) else {
    print("❌ File not found at path: \(fileURL.path)")
    exit(1)
}

guard let image = NSImage(contentsOf: fileURL),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("❌ Cannot load image as CGImage: \(fileURL.path)")
    exit(1)
}

print("🔍 กำลังประมวลผลอ่านข้อความจากภาพ: \(fileURL.lastPathComponent)...")

let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
let request = VNRecognizeTextRequest { request, error in
    guard let observations = request.results as? [VNRecognizedTextObservation] else {
        print("⚠️ ไม่พบข้อความในภาพ")
        return
    }
    
    print("📋 ข้อความที่ตรวจพบทั้งหมด (\(observations.count) บรรทัด):")
    print("──────────────────────────────────────────")
    for (index, observation) in observations.enumerated() {
        let topCandidate = observation.topCandidates(1).first?.string ?? ""
        print("[\(index + 1)] \(topCandidate)")
    }
    print("──────────────────────────────────────────")
    print("✅ สแกนสำเร็จ!")
}

// Support Thai and English recognition
if #available(macOS 13.0, *) {
    request.recognitionLanguages = ["th-TH", "en-US"]
}
request.recognitionLevel = .accurate
request.usesLanguageCorrection = true

do {
    try requestHandler.perform([request])
} catch {
    print("❌ OCR Error: \(error.localizedDescription)")
}
