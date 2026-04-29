import Foundation
import TeamTalkC

extension TeamTalkClient {
public func sendDesktopWindow(
    _ desktopWindow: DesktopWindow,
    convertTo bitmapFormat: TeamTalkBitmapFormat = .none
) -> Int32 {
    guard let instance else {
        return -1
    }

    var desktopWindow = desktopWindow
    return TT_SendDesktopWindow(instance, &desktopWindow, bitmapFormat.cValue)
}

@discardableResult
public func sendDesktopWindow(
    _ desktopWindow: TeamTalkDesktopWindow,
    convertTo bitmapFormat: TeamTalkBitmapFormat = .none
) -> Int32 {
    guard let instance else {
        return -1
    }

    return desktopWindow.withUnsafeCValue { rawValue in
        var rawValue = rawValue
        return TT_SendDesktopWindow(instance, &rawValue, bitmapFormat.cValue)
    }
}

@discardableResult
public func closeDesktopWindow() -> Bool {
    guard let instance else {
        return false
    }

    return TT_CloseDesktopWindow(instance) != 0
}

@discardableResult
public func sendDesktopCursorPosition(x: UInt16, y: UInt16) -> Bool {
    guard let instance else {
        return false
    }

    return TT_SendDesktopCursorPosition(instance, x, y) != 0
}

@discardableResult
public func sendDesktopInput(userID: Int32, inputs: [DesktopInput]) -> Bool {
    guard let instance, !inputs.isEmpty, inputs.count <= Int(TT_DESKTOPINPUT_MAX) else {
        return false
    }

    return inputs.withUnsafeBufferPointer { buffer in
        guard let baseAddress = buffer.baseAddress else {
            return false
        }
        return TT_SendDesktopInput(instance, userID, baseAddress, Int32(buffer.count)) != 0
    }
}

@discardableResult
public func sendDesktopInput(userID: TeamTalkUserID, inputs: [DesktopInput]) -> Bool {
    sendDesktopInput(userID: userID.cValue, inputs: inputs)
}

@discardableResult
public func sendDesktopInput(userID: Int32, inputs: [TeamTalkDesktopInput]) -> Bool {
    sendDesktopInput(userID: userID, inputs: inputs.map(\.cValue))
}

@discardableResult
public func sendDesktopInput(userID: TeamTalkUserID, inputs: [TeamTalkDesktopInput]) -> Bool {
    sendDesktopInput(userID: userID.cValue, inputs: inputs)
}

@discardableResult
public func sendDesktopInput(user: User, inputs: [DesktopInput]) -> Bool {
    sendDesktopInput(userID: user.userID, inputs: inputs)
}

@discardableResult
public func sendDesktopInput(user: User, inputs: [TeamTalkDesktopInput]) -> Bool {
    sendDesktopInput(userID: user.userID, inputs: inputs)
}

@discardableResult
public func sendDesktopInput(user: TeamTalkUser, inputs: [DesktopInput]) -> Bool {
    sendDesktopInput(userID: user.userID, inputs: inputs)
}

@discardableResult
public func sendDesktopInput(user: TeamTalkUser, inputs: [TeamTalkDesktopInput]) -> Bool {
    sendDesktopInput(userID: user.userID, inputs: inputs)
}

public func withAcquiredDesktopWindow<Result>(
    userID: Int32,
    _ body: (DesktopWindow) throws -> Result
) rethrows -> Result? {
    guard let instance, let desktopWindow = TT_AcquireUserDesktopWindow(instance, userID) else {
        return nil
    }

    defer {
        _ = TT_ReleaseUserDesktopWindow(instance, desktopWindow)
    }
    return try body(desktopWindow.pointee)
}

public func withAcquiredDesktopWindow<Result>(
    userID: TeamTalkUserID,
    _ body: (DesktopWindow) throws -> Result
) rethrows -> Result? {
    try withAcquiredDesktopWindow(userID: userID.cValue, body)
}

public func withAcquiredDesktopWindow<Result>(
    user: User,
    _ body: (DesktopWindow) throws -> Result
) rethrows -> Result? {
    try withAcquiredDesktopWindow(userID: user.userID, body)
}

public func withAcquiredDesktopWindow<Result>(
    user: TeamTalkUser,
    _ body: (DesktopWindow) throws -> Result
) rethrows -> Result? {
    try withAcquiredDesktopWindow(userID: user.userID, body)
}

public func withAcquiredDesktopWindow<Result>(
    userID: Int32,
    convertTo bitmapFormat: TeamTalkBitmapFormat,
    _ body: (DesktopWindow) throws -> Result
) rethrows -> Result? {
    guard let instance, let desktopWindow = TT_AcquireUserDesktopWindowEx(instance, userID, bitmapFormat.cValue) else {
        return nil
    }

    defer {
        _ = TT_ReleaseUserDesktopWindow(instance, desktopWindow)
    }
    return try body(desktopWindow.pointee)
}

public func withAcquiredDesktopWindow<Result>(
    userID: TeamTalkUserID,
    convertTo bitmapFormat: TeamTalkBitmapFormat,
    _ body: (DesktopWindow) throws -> Result
) rethrows -> Result? {
    try withAcquiredDesktopWindow(userID: userID.cValue, convertTo: bitmapFormat, body)
}

public func withAcquiredDesktopWindow<Result>(
    user: User,
    convertTo bitmapFormat: TeamTalkBitmapFormat,
    _ body: (DesktopWindow) throws -> Result
) rethrows -> Result? {
    try withAcquiredDesktopWindow(userID: user.userID, convertTo: bitmapFormat, body)
}

public func withAcquiredDesktopWindow<Result>(
    user: TeamTalkUser,
    convertTo bitmapFormat: TeamTalkBitmapFormat,
    _ body: (DesktopWindow) throws -> Result
) rethrows -> Result? {
    try withAcquiredDesktopWindow(userID: user.userID, convertTo: bitmapFormat, body)
}

public func acquireDesktopWindow(userID: Int32) -> TeamTalkDesktopWindow? {
    withAcquiredDesktopWindow(userID: userID) { TeamTalkDesktopWindow($0) }
}

public func acquireDesktopWindow(userID: TeamTalkUserID) -> TeamTalkDesktopWindow? {
    acquireDesktopWindow(userID: userID.cValue)
}

public func acquireDesktopWindow(user: User) -> TeamTalkDesktopWindow? {
    acquireDesktopWindow(userID: user.userID)
}

public func acquireDesktopWindow(user: TeamTalkUser) -> TeamTalkDesktopWindow? {
    acquireDesktopWindow(userID: user.userID)
}

public func acquireDesktopWindow(
    userID: Int32,
    convertTo bitmapFormat: TeamTalkBitmapFormat
) -> TeamTalkDesktopWindow? {
    withAcquiredDesktopWindow(userID: userID, convertTo: bitmapFormat) { TeamTalkDesktopWindow($0) }
}

public func acquireDesktopWindow(
    userID: TeamTalkUserID,
    convertTo bitmapFormat: TeamTalkBitmapFormat
) -> TeamTalkDesktopWindow? {
    acquireDesktopWindow(userID: userID.cValue, convertTo: bitmapFormat)
}

public func acquireDesktopWindow(
    user: User,
    convertTo bitmapFormat: TeamTalkBitmapFormat
) -> TeamTalkDesktopWindow? {
    acquireDesktopWindow(userID: user.userID, convertTo: bitmapFormat)
}

public func acquireDesktopWindow(
    user: TeamTalkUser,
    convertTo bitmapFormat: TeamTalkBitmapFormat
) -> TeamTalkDesktopWindow? {
    acquireDesktopWindow(userID: user.userID, convertTo: bitmapFormat)
}

public func videoCaptureDevicesInfo() -> [VideoCaptureDevice] {
    var count: Int32 = 0
    guard TT_GetVideoCaptureDevices(nil, &count) != 0, count > 0 else {
        return []
    }

    var devices = Array(repeating: VideoCaptureDevice(), count: Int(count))
    var deviceCount = count
    let didRead = devices.withUnsafeMutableBufferPointer { buffer in
        TT_GetVideoCaptureDevices(buffer.baseAddress, &deviceCount) != 0
    }
    guard didRead else {
        return []
    }

    let returnedCount = max(0, min(Int(deviceCount), devices.count))
    if returnedCount < devices.count {
        devices.removeLast(devices.count - returnedCount)
    }
    return devices
}

public func videoCaptureDevices() -> [TeamTalkVideoCaptureDevice] {
    videoCaptureDevicesInfo().map(TeamTalkVideoCaptureDevice.init)
}

@discardableResult
public func initVideoCaptureDevice(deviceID: String, format: VideoFormat) -> Bool {
    guard let instance else {
        return false
    }

    var format = format
    return TT_InitVideoCaptureDevice(instance, deviceID, &format) != 0
}

@discardableResult
public func initVideoCaptureDevice(deviceID: String, format: TeamTalkVideoFormat) -> Bool {
    initVideoCaptureDevice(deviceID: deviceID, format: format.cValue)
}

@discardableResult
public func initVideoCaptureDevice(_ device: TeamTalkVideoCaptureDevice, format: VideoFormat) -> Bool {
    initVideoCaptureDevice(deviceID: device.deviceIdentifier, format: format)
}

@discardableResult
public func initVideoCaptureDevice(_ device: TeamTalkVideoCaptureDevice, format: TeamTalkVideoFormat) -> Bool {
    initVideoCaptureDevice(deviceID: device.deviceIdentifier, format: format)
}

@discardableResult
public func closeVideoCaptureDevice() -> Bool {
    guard let instance else {
        return false
    }

    return TT_CloseVideoCaptureDevice(instance) != 0
}

}
