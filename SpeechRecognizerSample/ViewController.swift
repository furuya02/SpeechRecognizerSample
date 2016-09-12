//
//  ViewController.swift
//  SpeechRecognizerSample
//
//  Created by hirauchi.shinichi on 2016/09/11.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//

import UIKit
import Speech
import AVFoundation

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var outputTextView: UITextView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    fileprivate let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
    fileprivate var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    fileprivate var recognitionTask: SFSpeechRecognitionTask?
    fileprivate let audioEngine = AVAudioEngine()
    fileprivate var translator = Translator()
    fileprivate var talker = AVSpeechSynthesizer()

    enum Mode {
        case none
        case recording
        case translation
    }
    fileprivate var mode = Mode.none

    override func viewDidLoad() {
        super.viewDidLoad()
        speechRecognizer.delegate = self

        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                self.button.isEnabled = true
            case .denied: // 音声認識へのアクセスが拒否された
                self.button.isEnabled = false
            case .restricted: // この端末で音声認識が出来ない
                self.button.isEnabled = false
            case .notDetermined: // 音声認識が許可されていない
                self.button.isEnabled = false
            }
        }
        setMode(.none)
    }

    // MARK: - Action
    @IBAction func tapButton(_ sender: AnyObject) {
        switch mode {
        case .none:
            do {
                try self.startRecording()
                setMode(.recording)
            } catch {

            }
            break
        case .recording:
            stopRecording()
            startTranslation()
            setMode(.translation)
            break
        case .translation:
            break
        }
    }

    // MARK: - Private

    fileprivate func startRecording() throws {

        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object")
        }

        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            if let result = result {
                if (self.mode == .recording) {
                    self.inputTextView.text = result.bestTranscription.formattedString
                }
                isFinal = result.isFinal
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    fileprivate func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
    }

    fileprivate func startTranslation() {
        translator.conversion(inputTextView.text, complate: { result in
            self.outputTextView.text = result
            let utterance = AVSpeechUtterance(string: result)
            utterance.voice = AVSpeechSynthesisVoice(language: "en")
            self.talker.speak(utterance)
            self.setMode(.none)
        })
    }

    func setMode(_ mode:Mode){
        self.mode = mode
        switch mode {
        case .none:
            button.setTitle("開始", for: .normal)
            indicator.isHidden = true
            indicator.stopAnimating()
        case .recording:
            inputTextView.text = ""
            outputTextView.text = ""
            button.setTitle("翻訳", for: .normal)
            indicator.isHidden = true
        case .translation:
            button.setTitle("", for: .normal)
            indicator.isHidden = false
            indicator.startAnimating()
        }
    }

    // MARK: - SFSpeechRecognizerDelegate

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            button.isEnabled = true // 利用可能
        } else {
            button.isEnabled = false // 利用不能
        }
    }

}
