//
//  This source file is part of the ODCLite open source project
//
//  Copyright (c) 2024 Erik Basargin
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import AVFoundation
import Testing

@testable import ODCLite

struct CMSampleBufferTests {

    @Test func sampleBufferWithoutIOSurface() throws {
        let imageBuffer = try makeCVImageBufferWithoutIOSurface()
        let sampleBuffer = try makeCMSampleBuffer(imageBuffer: imageBuffer)
        #expect(sampleBuffer.ioSurface == nil)
    }
    
    @Test func sampleBufferWithIOSurface() throws {
        let imageBuffer = try makeCVImageBufferWithIOSurface()
        let sampleBuffer = try makeCMSampleBuffer(imageBuffer: imageBuffer)
        #expect(sampleBuffer.ioSurface != nil)
    }
}

private extension CMSampleBufferTests {
    
    func makeCMSampleBuffer(imageBuffer: CVImageBuffer) throws -> CMSampleBuffer {
        try CMSampleBuffer(
            imageBuffer: imageBuffer,
            formatDescription: .init(imageBuffer: imageBuffer),
            sampleTiming: .init(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .zero)
        )
    }
    
    func makeCVImageBufferWithoutIOSurface() throws -> CVImageBuffer {
        var imageBuffer: CVImageBuffer?
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            100,
            100,
            kCVPixelFormatType_32BGRA,
            nil,
            &imageBuffer
        )
        return try #require(imageBuffer)
    }
    
    func makeCVImageBufferWithIOSurface() throws -> CVImageBuffer {
        let imageWidth = 10
        let ioSurfaceRef = try #require(IOSurfaceCreate([
            kIOSurfaceWidth: imageWidth,
            kIOSurfaceHeight: imageWidth,
            kIOSurfaceBytesPerElement: 4,
            kIOSurfaceBytesPerRow: imageWidth * 4,
            kIOSurfaceAllocSize: imageWidth * imageWidth * 4,
            kIOSurfacePixelFormat: kCVPixelFormatType_32BGRA,
        ] as CFDictionary))
        
        var imageBuffer: Unmanaged<CVImageBuffer>?
        CVPixelBufferCreateWithIOSurface(
            kCFAllocatorDefault,
            ioSurfaceRef,
            [:] as CFDictionary,
            &imageBuffer
        )
        
        return try #require(imageBuffer?.takeUnretainedValue())
    }
}
