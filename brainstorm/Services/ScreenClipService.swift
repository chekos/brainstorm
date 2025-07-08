//
//  ScreenClipService.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import Foundation
import AppKit
import Vision
import CoreImage

@MainActor
class ScreenClipService: ObservableObject {
    @Published var isClipping = false
    @Published var lastClipImage: NSImage?
    @Published var lastOCRText: String = ""
    
    private var clippingWindow: NSWindow?
    private var selectionOverlay: SelectionOverlayView?
    
    func startScreenClipping() {
        guard !isClipping else { return }
        
        isClipping = true
        showSelectionOverlay()
    }
    
    func stopScreenClipping() {
        guard isClipping else { return }
        
        isClipping = false
        hideSelectionOverlay()
    }
    
    private func showSelectionOverlay() {
        // Create full-screen overlay window
        guard let mainScreen = NSScreen.main else { return }
        
        let overlayView = SelectionOverlayView { [weak self] selectedRect in
            self?.captureScreen(rect: selectedRect)
        }
        
        clippingWindow = NSWindow(
            contentRect: mainScreen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        clippingWindow?.contentView = overlayView
        clippingWindow?.level = .screenSaver
        clippingWindow?.isOpaque = false
        clippingWindow?.backgroundColor = NSColor.clear
        clippingWindow?.ignoresMouseEvents = false
        clippingWindow?.makeKeyAndOrderFront(nil)
        
        selectionOverlay = overlayView
    }
    
    private func hideSelectionOverlay() {
        clippingWindow?.close()
        clippingWindow = nil
        selectionOverlay = nil
    }
    
    private func captureScreen(rect: NSRect) {
        guard let screen = NSScreen.main else { return }
        
        // Convert coordinates from view to screen
        let screenRect = NSRect(
            x: rect.minX,
            y: screen.frame.height - rect.maxY,
            width: rect.width,
            height: rect.height
        )
        
        // Capture the screen region
        let cgImage = CGWindowListCreateImage(
            screenRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .nominalResolution
        )
        
        guard let cgImage = cgImage else {
            stopScreenClipping()
            return
        }
        
        let image = NSImage(cgImage: cgImage, size: rect.size)
        lastClipImage = image
        
        // Perform OCR on the captured image
        performOCR(on: cgImage)
        
        stopScreenClipping()
    }
    
    private func performOCR(on cgImage: CGImage) {
        let request = VNRecognizeTextRequest { [weak self] request, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("OCR error: \(error.localizedDescription)")
                    self?.lastOCRText = ""
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    self?.lastOCRText = ""
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                self?.lastOCRText = recognizedText
            }
        }
        
        // Configure for better accuracy
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform OCR: \(error.localizedDescription)")
            lastOCRText = ""
        }
    }
    
    func createScreenClipCapture(for packet: Packet, title: String? = nil) -> Capture {
        let capture = Capture(
            type: .screenClip,
            title: title ?? "Screen Clip",
            content: lastOCRText
        )
        capture.packet = packet
        return capture
    }
}

class SelectionOverlayView: NSView {
    private var startPoint: NSPoint?
    private var endPoint: NSPoint?
    private var isSelecting = false
    
    private let onSelectionComplete: (NSRect) -> Void
    
    init(onSelectionComplete: @escaping (NSRect) -> Void) {
        self.onSelectionComplete = onSelectionComplete
        super.init(frame: .zero)
        
        // Add escape key handler
        let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Escape key
                self.cancelSelection()
                return nil
            }
            return event
        }
        
        // Store monitor reference for cleanup
        objc_setAssociatedObject(self, "eventMonitor", monitor, .OBJC_ASSOCIATION_RETAIN)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // Clean up event monitor
        if let monitor = objc_getAssociatedObject(self, "eventMonitor") as? Any {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        isSelecting = true
        needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard isSelecting else { return }
        endPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        guard isSelecting,
              let start = startPoint,
              let end = endPoint else { return }
        
        let rect = NSRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        
        if rect.width > 10 && rect.height > 10 {
            onSelectionComplete(rect)
        }
        
        resetSelection()
    }
    
    private func cancelSelection() {
        resetSelection()
        window?.close()
    }
    
    private func resetSelection() {
        startPoint = nil
        endPoint = nil
        isSelecting = false
        needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        // Draw semi-transparent overlay
        NSColor.black.withAlphaComponent(0.3).setFill()
        bounds.fill()
        
        // Draw selection rectangle
        if let start = startPoint, let end = endPoint {
            let rect = NSRect(
                x: min(start.x, end.x),
                y: min(start.y, end.y),
                width: abs(end.x - start.x),
                height: abs(end.y - start.y)
            )
            
            // Clear the selected area
            NSColor.clear.setFill()
            rect.fill()
            
            // Draw selection border
            NSColor.white.setStroke()
            let path = NSBezierPath(rect: rect)
            path.lineWidth = 2.0
            path.stroke()
            
            // Draw crosshairs
            drawCrosshairs(at: start)
            drawCrosshairs(at: end)
        }
        
        // Draw instructions
        drawInstructions()
    }
    
    private func drawCrosshairs(at point: NSPoint) {
        NSColor.white.setStroke()
        
        let crosshairSize: CGFloat = 10
        let horizontalPath = NSBezierPath()
        horizontalPath.move(to: NSPoint(x: point.x - crosshairSize, y: point.y))
        horizontalPath.line(to: NSPoint(x: point.x + crosshairSize, y: point.y))
        horizontalPath.lineWidth = 1.0
        horizontalPath.stroke()
        
        let verticalPath = NSBezierPath()
        verticalPath.move(to: NSPoint(x: point.x, y: point.y - crosshairSize))
        verticalPath.line(to: NSPoint(x: point.x, y: point.y + crosshairSize))
        verticalPath.lineWidth = 1.0
        verticalPath.stroke()
    }
    
    private func drawInstructions() {
        let text = "Drag to select an area to clip • Press Escape to cancel"
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 14),
            .shadow: {
                let shadow = NSShadow()
                shadow.shadowColor = NSColor.black.withAlphaComponent(0.7)
                shadow.shadowOffset = NSSize(width: 1, height: -1)
                shadow.shadowBlurRadius = 2
                return shadow
            }()
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        
        let drawPoint = NSPoint(
            x: (bounds.width - textSize.width) / 2,
            y: bounds.height - 100
        )
        
        attributedString.draw(at: drawPoint)
    }
}