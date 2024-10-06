//
//  CapturedFrame.swift
//  ODC
//
//  Created by Erik Basargin on 20/10/2024.
//

import ScreenCaptureKit

enum CaptureFrameError: Error {
    case invalidSMSampleBuffer
    case noStreamFrameInfo
    case noImageBuffer
    case noIOSurface
}

struct CapturedFrame {
    let surface: IOSurface
}

// MARK: - CapturedFrame + CMSampleBuffer

extension CapturedFrame {
    
    init?(_ sampleBuffer: CMSampleBuffer) throws {
        guard sampleBuffer.isValid else {
            throw CaptureFrameError.invalidSMSampleBuffer
        }
        
        guard let streamFrameInfoStatusRawValue = sampleBuffer.sampleAttachments.first?[.streamFrameInfoStatus] as? Int, let streamFrameInfoStatus = SCFrameStatus(rawValue: streamFrameInfoStatusRawValue) else {
            throw CaptureFrameError.noStreamFrameInfo
        }
        
        guard streamFrameInfoStatus == .complete else {
            return nil
        }
        
        guard let imageBuffer = sampleBuffer.imageBuffer else {
            throw CaptureFrameError.noImageBuffer
        }
        
        guard let surface = CVPixelBufferGetIOSurface(imageBuffer)?.takeUnretainedValue() else {
            throw CaptureFrameError.noIOSurface
        }
        
        self.surface = surface as IOSurface
    }
}

extension CMSampleBuffer.PerSampleAttachmentsDictionary.Key {
    static let streamFrameInfoStatus: Self = Self(rawValue: SCStreamFrameInfo.status.rawValue as CFString)
}

// MARK: - SCFrameStatus + CustomDebugStringConvertible

extension SCFrameStatus: @retroactive CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .complete: 
            return "Complete"
        case .idle:
            return "Idle"
        case .blank:
            return "Blank"
        case .suspended:
            return "Suspended"
        case .started:
            return "Started"
        case .stopped:
            return "Stopped"
        @unknown default:
            return "Unknown(\(self))"
        }
    }
}
