//
//  DJIDroneSession+GimbalCommand.swift
//  DronelinkDJI
//
//  Created by Jim McAndrew on 10/28/19.
//  Copyright © 2019 Dronelink. All rights reserved.
//
import DronelinkCore
import DJISDK

extension DJIDroneSession {
    func execute(gimbalCommand: MissionGimbalCommand, finished: @escaping CommandFinished) -> Error? {
        guard
            let gimbal = adapter.drone.gimbal(channel: gimbalCommand.channel),
            let state = gimbalState(channel: gimbalCommand.channel)?.value
        else {
            return "MissionDisengageReason.drone.gimbal.unavailable.title".localized
        }
        
        if let command = gimbalCommand as? Mission.ModeGimbalCommand {
            gimbal.setMode(command.mode.djiValue, withCompletion: finished)
            return nil
        }
        
        if let command = gimbalCommand as? Mission.OrientationGimbalCommand {
            if (command.orientation.pitch == nil && command.orientation.roll == nil && command.orientation.yaw == nil) {
                finished(nil)
                return nil
            }
            
            var pitch = command.orientation.pitch?.convertRadiansToDegrees
            if let pitchValid = pitch, abs(pitchValid + 90) < 0.1 {
                pitch = -89.9
            }
            
            gimbal.rotate(with: DJIGimbalRotation(
                pitchValue: gimbal.isAdjustPitchSupported ? pitch as NSNumber? : nil,
                rollValue: state.missionMode == .free && gimbal.isAdjustRollSupported ? command.orientation.roll?.convertRadiansToDegrees as NSNumber? : nil,
                yawValue: state.missionMode == .free && gimbal.isAdjustYawSupported ? command.orientation.yaw?.convertRadiansToDegrees as NSNumber? : nil,
                time: DJIGimbalRotation.minTime,
                mode: .absoluteAngle), completion: finished)
            return nil
        }
        
        return "MissionDisengageReason.command.type.unhandled".localized
    }
}
