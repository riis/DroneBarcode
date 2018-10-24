//
//  FlightPlanner.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/23/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import DJISDK

class FlightPlanner {
    private var isInitialHeading = true
    
    private var initialYaw = 0.0
    private var turnAroundYaw = 180.0
    private var currentYaw = 0.0
    
    private var turnTime = 0
    private var turnTimer: Timer? = nil
    
    private var pitchTime = 0.0
    private var pitchTimer: Timer? = nil
    
    private var callbackTimes: [UInt64] = []
    
    private var callback: FlightControlCallback!
    private var flightController: DJIFlightController!
    
    init(flightController: DJIFlightController, callback: FlightControlCallback) {
        self.flightController = flightController
        self.callback = callback
    }
    
    func setUpParameters(initialYaw: Double) {
        self.initialYaw = initialYaw
        self.currentYaw = initialYaw
        
        if self.initialYaw > 0 {
            self.turnAroundYaw = self.initialYaw - 180
        } else {
            self.turnAroundYaw = self.initialYaw + 180
        }
    }
    
    func turn() {
        if self.isInitialHeading {
            self.currentYaw = self.turnAroundYaw
        } else {
            self.currentYaw = self.initialYaw
        }
        
        self.isInitialHeading = !self.isInitialHeading
        
        self.turnTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: (#selector(turnDroneCommand)), userInfo: nil, repeats: true)
    }
    
    @objc func turnDroneCommand() {
        self.turnTime += 1
        
        let data = Utils.getTurnAroundFlightCommand(self.currentYaw)
        
        self.flightController.send(data, withCompletion: { (error) in
            if error != nil {
                self.callback.onError(error: error)
            }
        })
        
        if self.turnTime >= 7 {
            self.turnTimer?.invalidate()
            self.turnTime = 0
            self.callback.onCommandSuccess()
        }
    }
    
    func changePitch() {
        let data = Utils.getPitchFlightCommand(0.5, self.currentYaw)
        
        self.flightController.send(data, withCompletion: { (error) in
            if error != nil {
                self.callback.onError(error: error)
            }
        })
        // There are other scheduledTimer methods, but they do not appear to work as consistently as this one
//        self.pitchTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: (#selector(pitchDroneCommand)), userInfo: nil, repeats: true)
    }
    
    func forwardShort(value: Float? = 0.25, callback send: @escaping (String) -> Void) {
        self.turnTime = 0
        self.turnTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: (#selector(doForward)), userInfo: nil, repeats: true)
    }
    
    @objc func doForward() {
        DispatchQueue.global().async {
            self.turnTime = self.turnTime + 1
            if self.turnTime >= 10 {
                self.turnTimer?.invalidate()
            }
            var data = DJIVirtualStickFlightControlData(pitch: 0, roll: 0, yaw: Float(self.currentYaw), verticalThrottle: 0)
            data.roll = Float(0.25)
            let benchmark = Benchmark()
            benchmark.startBenchmark()
            self.flightController.send(data, withCompletion: {(error) in
                benchmark.endBenchmark()
                self.logTime(benchmark.getTimeNano())
                if error != nil {
                    //self.send("Forward short error: " + error!.localizedDescription)
                } else {
                    //self.send("Sent forward command (roll 0.2500)")
                }
            })
        }
    }
    
    func backwardShort(value: Float? = -0.5, callback send: @escaping (String) -> Void) {
        DispatchQueue.global().async {
            var data = DJIVirtualStickFlightControlData(pitch: 0, roll: 0, yaw: Float(self.currentYaw), verticalThrottle: 0)
            data.roll = Float(value!)
            let benchmark = Benchmark()
            benchmark.startBenchmark()
            self.flightController.send(data, withCompletion: {(error) in
                benchmark.endBenchmark()
                self.logTime(benchmark.getTimeNano())
                if error != nil {
                    send("Backward short error: " + error!.localizedDescription)
                } else {
                    send(String(format: "Sent backward command (roll %.4f)", value!))
                }
            })
        }
    }
    
    func rightShort(value: Float? = 0.5, callback send: @escaping (String) -> Void) {
        DispatchQueue.global().async {
            var data = DJIVirtualStickFlightControlData(pitch: 0, roll: 0, yaw: Float(self.currentYaw), verticalThrottle: 0)
            data.pitch = Float(value!)
            let benchmark = Benchmark()
            benchmark.startBenchmark()
            self.flightController.send(data, withCompletion: {(error) in
                benchmark.endBenchmark()
                self.logTime(benchmark.getTimeNano())
                if error != nil {
                    send("Right short error: " + error!.localizedDescription)
                } else {
                    send(String(format: "Sent right command (pitch %.4f)", value!))
                }
            })
        }
    }
    
    func leftShort(value: Float? = -0.5, callback send: @escaping (String) -> Void) {
        DispatchQueue.global().async {
            var data = DJIVirtualStickFlightControlData(pitch: 0, roll: 0, yaw: Float(self.currentYaw), verticalThrottle: 0)
            data.pitch = Float(value!)
            let benchmark = Benchmark()
            benchmark.startBenchmark()
            self.flightController.send(data, withCompletion: {(error) in
                benchmark.endBenchmark()
                self.logTime(benchmark.getTimeNano())
                if error != nil {
                    send("Left short error: " + error!.localizedDescription)
                } else {
                    send(String(format: "Sent left command (pitch %.4f)", value!))
                }
            })
        }
    }
    
    func up(value: Float? = 0.5, callback send: @escaping (String) -> Void) {
        DispatchQueue.global().async {
            var data = DJIVirtualStickFlightControlData(pitch:0, roll:0, yaw: Float(self.currentYaw), verticalThrottle: 0)
            data.verticalThrottle = value!
            let benchmark = Benchmark()
            benchmark.startBenchmark()
            self.flightController.send(data, withCompletion: {(error) in
                if error != nil {
                    send("Up command error: " + error!.localizedDescription)
                } else {
                    benchmark.endBenchmark()
                    self.logTime(benchmark.getTimeNano())
                    send(String(format: "Sent up command (vertical throttle %.4f)", value!))
                }
            })
        }
    }
    
    func down(value: Float? = -0.5, callback send: @escaping (String) -> Void) {
        DispatchQueue.global().async {
            var data = DJIVirtualStickFlightControlData(pitch:0, roll:0, yaw: Float(self.currentYaw), verticalThrottle: 0)
            data.verticalThrottle = value!
            self.flightController.send(data, withCompletion: {(error) in
                if error != nil {
                    send("Down error: " + error!.localizedDescription)
                } else {
                    send(String(format: "Sent down command (vertical throttle %.4f)", value!))
                }
            })
        }
    }
    
    @objc func pitchDroneCommand() {
        self.pitchTime += 0.2
        
        // Pitch controls left/right. Positive pitch values go right. Range is -15 to 15
        // Roll controlls forward/backward. Positive values go forward. Range is -15 to 15
        let data = Utils.getPitchFlightCommand(0.5, self.currentYaw)

        self.flightController.send(data, withCompletion: { (error) in
            if error != nil {
                self.callback.onError(error: error)
            }
        })
        
        if self.pitchTime >= 1 {
            self.pitchTimer?.invalidate()
            self.pitchTime = 0.0
            self.callback.onCommandSuccess()
        }
    }
    
    func changeAltitude() {
        let data = DJIVirtualStickFlightControlData(pitch: 0, roll: 0, yaw: Float(self.currentYaw), verticalThrottle: Float(0.5))
        
        self.flightController?.send(data, withCompletion: { (error) in
            if error != nil {
                self.callback.onError(error: error)
            }
        })
    }
    
    func logTime(_ time: UInt64) {
        self.callbackTimes.append(time)
    }
    
    func saveTimes() {
        Benchmark.saveTimesToDataFile(self.callbackTimes, file: "nanosecond-times.txt")
    }
}
