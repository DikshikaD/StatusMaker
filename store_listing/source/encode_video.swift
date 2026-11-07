// Encodes numbered JPEG frames (plus an optional WAV soundtrack) into an
// H.264/AAC MP4 with AVFoundation.
// Usage: swift encode_video.swift <frames_dir> <out.mp4> <fps> [audio.wav]
import AVFoundation
import AppKit

let args = CommandLine.arguments
let dir = URL(fileURLWithPath: args[1])
let out = URL(fileURLWithPath: args[2])
let fps = Int32(args[3]) ?? 30
let audioURL = args.count > 4 ? URL(fileURLWithPath: args[4]) : nil

let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
    .filter { $0.hasSuffix(".jpg") }.sorted()
guard let first = NSImage(contentsOf: dir.appendingPathComponent(files[0])),
      let firstCG = first.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fatalError("cannot read first frame")
}
let width = firstCG.width, height = firstCG.height

try? FileManager.default.removeItem(at: out)
let writer = try AVAssetWriter(outputURL: out, fileType: .mp4)
let video = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: width,
    AVVideoHeightKey: height,
    AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: 14_000_000,
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
    ],
])
video.expectsMediaDataInRealTime = false
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: video, sourcePixelBufferAttributes: [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
    kCVPixelBufferWidthKey as String: width,
    kCVPixelBufferHeightKey as String: height,
])
writer.add(video)

var audioInput: AVAssetWriterInput?
var audioOutput: AVAssetReaderTrackOutput?
var reader: AVAssetReader?
if let audioURL {
    let asset = AVURLAsset(url: audioURL)
    let track = asset.tracks(withMediaType: .audio)[0]
    reader = try AVAssetReader(asset: asset)
    let output = AVAssetReaderTrackOutput(track: track, outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM])
    reader!.add(output)
    audioOutput = output
    let input = AVAssetWriterInput(mediaType: .audio, outputSettings: [
        AVFormatIDKey: kAudioFormatMPEG4AAC,
        AVNumberOfChannelsKey: 2,
        AVSampleRateKey: 44100,
        AVEncoderBitRateKey: 192_000,
    ])
    input.expectsMediaDataInRealTime = false
    writer.add(input)
    audioInput = input
}

writer.startWriting()
reader?.startReading()
writer.startSession(atSourceTime: .zero)

let group = DispatchGroup()
group.enter()
var index = 0
video.requestMediaDataWhenReady(on: DispatchQueue(label: "video")) {
    while video.isReadyForMoreMediaData {
        if index >= files.count {
            video.markAsFinished()
            group.leave()
            return
        }
        autoreleasepool {
            let name = files[index]
            guard let img = NSImage(contentsOf: dir.appendingPathComponent(name)),
                  let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
            var buffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer)
            guard let pb = buffer else { return }
            CVPixelBufferLockBaseAddress(pb, [])
            let ctx = CGContext(data: CVPixelBufferGetBaseAddress(pb), width: width, height: height,
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pb),
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
            CVPixelBufferUnlockBaseAddress(pb, [])
            adaptor.append(pb, withPresentationTime: CMTime(value: CMTimeValue(index), timescale: fps))
        }
        index += 1
    }
}

if let audioInput, let audioOutput {
    group.enter()
    audioInput.requestMediaDataWhenReady(on: DispatchQueue(label: "audio")) {
        while audioInput.isReadyForMoreMediaData {
            if let sample = audioOutput.copyNextSampleBuffer() {
                audioInput.append(sample)
            } else {
                audioInput.markAsFinished()
                group.leave()
                return
            }
        }
    }
}

group.wait()
let done = DispatchSemaphore(value: 0)
writer.finishWriting { done.signal() }
done.wait()
if writer.status != .completed { fatalError("encode failed: \(String(describing: writer.error))") }
print("encoded \(files.count) frames" + (audioURL != nil ? " with audio" : ""))
