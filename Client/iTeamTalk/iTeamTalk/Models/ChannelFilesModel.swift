/*
 * Copyright (c) 2005-2018, BearWare.dk
 *
 * Contact Information:
 *
 * Bjoern D. Rasmussen
 * Kirketoften 5
 * DK-8260 Viby J
 * Denmark
 * Email: contact@bearware.dk
 * Phone: +45 20 20 54 59
 * Web: http://www.bearware.dk
 *
 * This source code is part of the TeamTalk SDK owned by
 * BearWare.dk. Use of this file, or its compiled unit, requires a
 * TeamTalk SDK License Key issued by BearWare.dk.
 *
 * The TeamTalk SDK License Agreement along with its Terms and
 * Conditions are outlined in the file License.txt included with the
 * TeamTalk SDK distribution.
 *
 */

import Foundation
import Observation
import TeamTalkKit
import UIKit

struct ChannelFileRow: Identifiable, Hashable {
    let file: TeamTalkRemoteFile

    var id: String {
        "\(file.channelIdentifier)-\(file.fileID)"
    }

    var channelID: TeamTalkChannelID {
        file.channelIdentifier
    }

    var fileID: TeamTalkFileID {
        file.fileID
    }

    var name: String {
        file.name
    }

    var username: String {
        file.username
    }

    var uploadTime: String {
        file.uploadTime
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file)
    }

    static func == (lhs: ChannelFileRow, rhs: ChannelFileRow) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct FileTransferRow: Identifiable {
    let transfer: TeamTalkFileTransfer

    var id: TeamTalkTransferID {
        transfer.transferID
    }

    var isDownload: Bool {
        transfer.isDownload
    }

    var remoteFileName: String {
        transfer.remoteFileName
    }

    var localFilePath: String {
        transfer.localFilePath
    }

    var localURL: URL? {
        guard !localFilePath.isEmpty else { return nil }
        return URL(fileURLWithPath: localFilePath)
    }

    var displayName: String {
        if !remoteFileName.isEmpty {
            return remoteFileName
        }
        if let localURL {
            return localURL.lastPathComponent
        }
        return String(localized: "File", comment: "files")
    }

    var progress: Double {
        transfer.progress
    }

    var progressText: String {
        "\(Int(progress * 100))%"
    }

    var transferredText: String {
        let transferred = ByteCountFormatter.string(fromByteCount: transfer.transferredBytes, countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: transfer.fileSize, countStyle: .file)
        return "\(transferred) / \(total)"
    }

    var directionText: String {
        isDownload
            ? String(localized: "Downloading", comment: "files")
            : String(localized: "Uploading", comment: "files")
    }
}

struct FailedTransfer: Identifiable {
    let id = UUID()
    let message: String
    let retry: () -> Void
}

struct DownloadedFileRow: Identifiable {
    let url: URL

    var id: String {
        url.path
    }

    var name: String {
        url.lastPathComponent
    }
}

@Observable
final class ChannelFilesModel {
    let session: TeamTalkSession

    var files = [ChannelFileRow]()
    var transfers = [FileTransferRow]()
    var downloadedFiles = [DownloadedFileRow]()
    var channelTitle = String(localized: "Files", comment: "files")
    var errorMessage: String?
    var filePendingDownload: ChannelFileRow?
    var filePendingDeletion: ChannelFileRow?
    var failedTransfer: FailedTransfer?

    var isPresentingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    var isPresentingDeleteConfirmation: Bool {
        get { filePendingDeletion != nil }
        set { if !newValue { filePendingDeletion = nil } }
    }

    var isPresentingFailedTransfer: Bool {
        get { failedTransfer != nil }
        set { if !newValue { failedTransfer = nil } }
    }

    private var channelID: TeamTalkChannelID = .none
    private var announcedDownloadProgress = [TeamTalkTransferID: Set<Int>]()
    private var downloadSecurityScopes = [String: URL]()
    private let fileManager = FileManager.default

    init(session: TeamTalkSession) {
        self.session = session
    }

    deinit {
        releaseAllDownloadSecurityScopes()
    }

    @MainActor
    private func presentError(_ message: String) {
        errorMessage = message
    }

    // Keeps the already-copied local file around (instead of deleting it on
    // failure) so retry can just resubmit it, no need to re-pick it from Files.
    @MainActor
    private func presentUploadFailure(_ message: String, retryURL: URL, channel: TeamTalkChannel) {
        failedTransfer = FailedTransfer(message: message) { [weak self] in
            self?.retryUpload(from: retryURL, to: channel)
        }
    }

    // Re-prompts for a destination folder rather than trying to remember the
    // one from the failed attempt, whose security-scoped access was released
    // once the failure was handled.
    @MainActor
    private func presentDownloadFailure(_ message: String, retryFile: ChannelFileRow) {
        failedTransfer = FailedTransfer(message: message) { [weak self] in
            self?.requestDownload(retryFile)
        }
    }

    private func retryUpload(from localURL: URL, to channel: TeamTalkChannel) {
        Task { [weak self, session] in
            do {
                _ = try await session.uploadFile(at: localURL, to: channel)
            } catch {
                if let self {
                    await self.presentUploadFailure(error.localizedDescription, retryURL: localURL, channel: channel)
                }
            }
        }
    }

    var canUploadFiles: Bool {
        channelID.isValid && session.hasUserRight(.canUploadFiles)
    }

    var canDownloadFiles: Bool {
        channelID.isValid && session.hasUserRight(.canDownloadFiles)
    }

    var hasCurrentChannel: Bool {
        channelID.isValid
    }

    func refresh() {
        channelID = session.myChannelIdentifier
        updateChannelTitle()

        guard channelID.isValid, let channel = session.channel(id: channelID) else {
            files = []
            transfers = []
            return
        }

        files = session.remoteFiles(in: channel)
            .map(ChannelFileRow.init)
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    func uploadFile(at url: URL) {
        guard canUploadFiles else {
            errorMessage = String(localized: "You do not have permission to upload files.", comment: "files")
            return
        }

        guard let targetChannel = session.channel(id: channelID) else {
            errorMessage = String(localized: "Current channel is unavailable.", comment: "files")
            return
        }

        do {
            let localURL = try prepareUploadFile(from: url)

            Task { [weak self, session] in
                do {
                    _ = try await session.uploadFile(at: localURL, to: targetChannel)
                } catch {
                    if let self {
                        await self.presentUploadFailure(error.localizedDescription, retryURL: localURL, channel: targetChannel)
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func requestDownload(_ file: ChannelFileRow) {
        guard canDownloadFiles else {
            errorMessage = String(localized: "You do not have permission to download files.", comment: "files")
            return
        }

        filePendingDownload = file
    }

    func downloadPendingFile(to result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let directoryURL = urls.first, let file = filePendingDownload else {
                filePendingDownload = nil
                return
            }
            filePendingDownload = nil
            download(file, to: directoryURL)

        case .failure(let error):
            filePendingDownload = nil
            if !isUserCancelled(error) {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func download(_ file: ChannelFileRow, to directoryURL: URL) {
        guard canDownloadFiles else {
            errorMessage = String(localized: "You do not have permission to download files.", comment: "files")
            return
        }

        let didAccess = directoryURL.startAccessingSecurityScopedResource()

        do {
            let localURL = try uniqueFileURL(in: directoryURL, filename: file.name)
            if didAccess {
                downloadSecurityScopes[localURL.path] = directoryURL
            }
            let fileManager = self.fileManager

            Task { [weak self, session] in
                do {
                    try await session.downloadFile(file.file, to: localURL)
                } catch {
                    try? fileManager.removeItem(at: localURL)
                    if let self {
                        self.releaseDownloadSecurityScope(for: localURL)
                        await self.presentDownloadFailure(error.localizedDescription, retryFile: file)
                    }
                }
            }
        } catch {
            if didAccess {
                directoryURL.stopAccessingSecurityScopedResource()
            }
            errorMessage = error.localizedDescription
        }
    }

    func requestDelete(_ file: ChannelFileRow) {
        filePendingDeletion = file
    }

    func confirmDelete(_ file: ChannelFileRow) {
        filePendingDeletion = nil

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.session.deleteFile(file.file)
            } catch {
                await self.presentError(error.localizedDescription)
            }
        }
    }

    func cancelTransfer(_ transfer: FileTransferRow) {
        if session.cancelFileTransfer(transfer.transfer) {
            removeTransfer(id: transfer.id)
            announcedDownloadProgress.removeValue(forKey: transfer.id)
            if transfer.isDownload, let localURL = transfer.localURL {
                try? fileManager.removeItem(at: localURL)
                releaseDownloadSecurityScope(for: localURL)
            }
        }
    }

    private func updateChannelTitle() {
        guard channelID.isValid, let channel = session.channel(id: channelID) else {
            channelTitle = String(localized: "Files", comment: "files")
            return
        }

        let name = channel.parentID == 0
            ? String(localized: "root channel", comment: "files")
            : channel.name
        channelTitle = String(format: String(localized: "Files in %@", comment: "files"), name)
    }

    private func prepareUploadFile(from url: URL) throws -> URL {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let localURL = try uniqueFileURL(in: uploadsDirectory(), filename: url.lastPathComponent)
        try fileManager.copyItem(at: url, to: localURL)
        return localURL
    }

    private func uploadsDirectory() throws -> URL {
        let directory = try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("TeamTalk Uploads", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func uniqueFileURL(in directory: URL, filename: String) throws -> URL {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let sourceURL = URL(fileURLWithPath: filename)
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let pathExtension = sourceURL.pathExtension
        let cleanBaseName = baseName.isEmpty ? String(localized: "File", comment: "files") : baseName

        var candidate = directory.appendingPathComponent(sourceURL.lastPathComponent)
        var index = 2
        while fileManager.fileExists(atPath: candidate.path) {
            let name = pathExtension.isEmpty
                ? "\(cleanBaseName) \(index)"
                : "\(cleanBaseName) \(index).\(pathExtension)"
            candidate = directory.appendingPathComponent(name)
            index += 1
        }
        return candidate
    }

    private func updateTransfer(_ transfer: TeamTalkFileTransfer) {
        let row = FileTransferRow(transfer: transfer)

        switch transfer.status {
        case .active:
            if let index = transfers.firstIndex(where: { $0.id == row.id }) {
                transfers[index] = row
            } else {
                transfers.append(row)
            }
            announceTransferProgressIfNeeded(for: row)
        case .finished:
            removeTransfer(id: row.id)
            announcedDownloadProgress.removeValue(forKey: row.id)
            if row.isDownload, let localURL = row.localURL {
                downloadedFiles.insert(DownloadedFileRow(url: localURL), at: 0)
            } else {
                cleanupUploadCopy(for: row)
                refresh()
            }
            announceTransferComplete(for: row)
        case .error:
            removeTransfer(id: row.id)
            let message = String(format: String(localized: "File transfer failed: %@", comment: "files"), row.remoteFileName)
            if row.isDownload {
                cleanupTransferFile(for: row)
                if let originalFile = files.first(where: { $0.name == row.remoteFileName }) {
                    Task { @MainActor [weak self] in
                        self?.presentDownloadFailure(message, retryFile: originalFile)
                    }
                } else {
                    errorMessage = message
                }
            } else if !row.localFilePath.isEmpty, let targetChannel = session.channel(id: channelID) {
                // Keep the cached copy for retry - don't cleanupTransferFile() here.
                let localURL = URL(fileURLWithPath: row.localFilePath)
                Task { @MainActor [weak self] in
                    self?.presentUploadFailure(message, retryURL: localURL, channel: targetChannel)
                }
            } else {
                cleanupTransferFile(for: row)
                errorMessage = message
            }
        case .closed:
            removeTransfer(id: row.id)
            cleanupTransferFile(for: row)
        default:
            break
        }
    }

    private func cleanupTransferFile(for transfer: FileTransferRow) {
        announcedDownloadProgress.removeValue(forKey: transfer.id)
        if transfer.isDownload, let localURL = transfer.localURL {
            try? fileManager.removeItem(at: localURL)
            releaseDownloadSecurityScope(for: localURL)
        } else {
            cleanupUploadCopy(for: transfer)
        }
    }

    private func cleanupUploadCopy(for transfer: FileTransferRow) {
        guard let localURL = transfer.localURL else { return }
        guard let uploadsDirectory = try? uploadsDirectory() else { return }
        guard localURL.path.hasPrefix(uploadsDirectory.path) else { return }
        try? fileManager.removeItem(at: localURL)
    }

    private func removeTransfer(id: TeamTalkTransferID) {
        transfers.removeAll { $0.id == id }
    }

    private func cleanupActiveTransfers() {
        transfers.forEach { cleanupTransferFile(for: $0) }
        transfers = []
    }

    private func announceTransferProgressIfNeeded(for transfer: FileTransferRow) {
        guard transfer.transfer.fileSize > 0 else { return }

        let percent = Int(transfer.progress * 100)
        let thresholds = [25, 50, 75]
        let announced = announcedDownloadProgress[transfer.id, default: []]
        guard let threshold = thresholds.last(where: { percent >= $0 && !announced.contains($0) }) else {
            return
        }

        for crossedThreshold in thresholds where crossedThreshold <= threshold {
            announcedDownloadProgress[transfer.id, default: []].insert(crossedThreshold)
        }
        let format = transfer.isDownload
            ? String(localized: "%@, %d%% downloaded", comment: "files")
            : String(localized: "%@, %d%% uploaded", comment: "files")
        announceVoiceOver(String(format: format, transfer.displayName, threshold))
    }

    private func announceTransferComplete(for transfer: FileTransferRow) {
        let format = transfer.isDownload
            ? String(localized: "Download complete: %@", comment: "files")
            : String(localized: "Upload complete: %@", comment: "files")
        announceVoiceOver(String(format: format, transfer.displayName))
    }

    private func announceVoiceOver(_ announcement: String) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        guard UIApplication.shared.applicationState == .active else { return }
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }

    private func releaseDownloadSecurityScope(for localURL: URL) {
        guard let directoryURL = downloadSecurityScopes.removeValue(forKey: localURL.path) else { return }
        directoryURL.stopAccessingSecurityScopedResource()
    }

    private func releaseAllDownloadSecurityScopes() {
        downloadSecurityScopes.values.forEach {
            $0.stopAccessingSecurityScopedResource()
        }
        downloadSecurityScopes.removeAll()
    }

    private func isUserCancelled(_ error: Error) -> Bool {
        let error = error as NSError
        return error.domain == NSCocoaErrorDomain && error.code == NSUserCancelledError
    }

}

extension ChannelFilesModel: TeamTalkEventObserver {
    func handleTeamTalkEvent(_ event: TeamTalkEvent) {
        switch event.kind {
        case .connectionLost:
            channelID = .none
            files = []
            cleanupActiveTransfers()
            downloadedFiles = []
            filePendingDownload = nil
            filePendingDeletion = nil
            announcedDownloadProgress.removeAll()
            releaseAllDownloadSecurityScopes()
            updateChannelTitle()

        case .userJoined(let user):
            if user.userID == session.myUserIdentifier {
                refresh()
            }

        case .userLeft(_, let user):
            if user.userID == session.myUserIdentifier {
                channelID = .none
                files = []
                cleanupActiveTransfers()
                filePendingDownload = nil
                filePendingDeletion = nil
                updateChannelTitle()
            }

        case .channelUpdated(let channel):
            if channel.channelID == channelID {
                updateChannelTitle()
            }

        case .fileCreated(let file), .fileRemoved(let file):
            playSound(.file_UPDATE)
            if file.channelIdentifier == channelID {
                refresh()
            }

        case .fileTransfer(let transfer):
            playSound(.file_COMPLETE)
            updateTransfer(transfer)

        default:
            break
        }
    }
}
