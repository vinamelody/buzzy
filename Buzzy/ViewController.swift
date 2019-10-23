//
//  ViewController.swift
//  Buzzy
//
//  Created by Vina Melody on 5/10/19.
//  Copyright © 2019 Vina Melody. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController {

    let lbl: UILabel = {
        let lbl = UILabel()
        lbl.text = "Results..."
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.numberOfLines = 0
        return lbl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Hey"
        view.backgroundColor = .white

        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }

        captureSession.addInput(input)
        captureSession.startRunning()

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame

        // we need to access the camera's frame image
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)

        view.addSubview(lbl)
        NSLayoutConstraint.activate([
            lbl.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            lbl.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            lbl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])

    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // camera will be able to capture sequences of buffer here
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }

        let request = VNCoreMLRequest(model: model ) { (finishedReq, err) in
            if let error = err {
                print(error)
            }
//            print(finishedReq.results)
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            guard let firstObservation = results.first else { return }
            let text = "Object is \(firstObservation.confidence) a \(firstObservation.identifier)"
            DispatchQueue.main.async {
                self.lbl.text = text
            }
        }

        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}

