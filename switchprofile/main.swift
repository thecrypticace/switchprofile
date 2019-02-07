//
//  main.swift
//  switchprofile
//
//  Created by Jordan Pittman on 2/7/19.
//  Copyright © 2019 Cryptica Software. All rights reserved.
//

import Foundation
import Quartz
import ApplicationServices

class Display {
    let id: CGDirectDisplayID
    let uuid: CFUUID
    var isMain: Bool {
        return self.id == 0
    }

    required init?(id: CGDirectDisplayID) {
        guard let uuid = CGDisplayCreateUUIDFromDisplayID(id) else {
            return nil
        }

        self.id = id
        self.uuid = uuid.takeRetainedValue()
    }

    func switchToProfile(at url: URL) {
        let profileInfo: CFDictionary = [
            kColorSyncDeviceDefaultProfileID.takeUnretainedValue(): url,
            kColorSyncProfileUserScope.takeUnretainedValue(): "current"
        ] as CFDictionary

        ColorSyncDeviceSetCustomProfiles(
            kColorSyncDisplayDeviceClass.takeUnretainedValue(),
            self.uuid,
            profileInfo
        )
    }

    static func all() -> [Display] {
        let maxDisplays: UInt32 = 16
        var displayCount: UInt32 = 0
        var onlineDisplays = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))

        let err = CGGetOnlineDisplayList(maxDisplays, &onlineDisplays, &displayCount)
        guard case err = CGError.success else {
            return []
        }

        return onlineDisplays.map(self.init).compactMap { $0 }
    }
}

guard let mainDisplay = Display.all().first(where: { $0.isMain }) else {
    print("Can't find main display")

    exit(1)
}

let arguments = CommandLine.arguments

guard arguments.count > 1 else {
    print("Must provide profile path")

    exit(1)
}

let profilePath = arguments[1]

let fileManager = FileManager.default
if !fileManager.fileExists(atPath: profilePath) {
    print("The given profile does not exist")
    exit(1)
}

let profileUrl = URL(fileURLWithPath: profilePath)

mainDisplay.switchToProfile(at: URL(fileURLWithPath: profilePath))
