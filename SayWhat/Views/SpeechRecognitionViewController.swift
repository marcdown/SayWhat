//
//  SpeechRecognitionViewController.swift
//  SayWhat
//
//  Created by Marc Brown on 8/29/16.
//  Copyright © 2016 creative mess. All rights reserved.
//

import Speech
import UIKit

protocol SpeechRecognitionDelegate: class {
    func speechRecognitionComplete(query: String?)
    func speechRecognitionCancelled()
}

class SpeechRecognitionViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet var textView: UITextView!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var query: String?
    weak var delegate: SpeechRecognitionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        speechRecognizer?.delegate = self
        startListening()
    }

    func startListening() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            
            if result != nil {
                self.query = result?.bestTranscription.formattedString
                self.textView.text = self.query
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.stopListening()
            }
        })
        beginAudioSetup()
    }
    
    func beginAudioSetup(){
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session isn't configured correctly")
        }
        
        let recordingFormat = audioEngine.inputNode?.outputFormat(forBus: 0)
        audioEngine.inputNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, time) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            textView.text = "Listening..."
        } catch {
            print("Audio engine failed to start")
        }

        
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode?.removeTap(onBus: 0)
        recognitionRequest = nil
        recognitionTask = nil
    }
    
    @IBAction func doneButtonTapped() {
        stopListening()
        delegate?.speechRecognitionComplete(query: query)
    }
    
    @IBAction func cancelButtonTapped() {
        stopListening()
        delegate?.speechRecognitionCancelled()
    }
    
    // MARK: SFSpeechRecognizerDelegate
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            let alertController = UIAlertController(title: nil,
                                                    message: "Speech Recognition is currently unavailable.",
                                                    preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .default) { (alertAction) in
                self.cancelButtonTapped()
            }
            alertController.addAction(alertAction)
            present(alertController, animated: true)
        }
    }
}
