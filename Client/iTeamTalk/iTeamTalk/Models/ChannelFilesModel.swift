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
 * Web: http:
 www.bearware.dk
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
import TeamTalkKit

struct ChannelFileRow: Identifiable, Hashable {
    let file: RemoteFile

    var id: String {
        "\(file.nChannelID)-\(file.nFileID)"
    }

    var channelID: Int32 {
        file.nChannelID
    }

    var fileID: Int32 {
        file.nFileID
    }

    var name: String {
        TeamTalkString.remoteFile(.fileName, from: file)
    }

    var username: String {
        TeamTalkString.remoteFile(.username, from: file)
    }

    var uploadTime: String {
        TeamTalkString.remoteFile(.uploadTime, from: file)
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: file.nFileSize, countStyle: .file)
    }

    static func == (lhs: ChannelFileRow, rhs: ChannelFileRow) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct FileTransferRow: Identifiable {
    let transfer: FileTransfer

    var id: Int32 {
        transfer.nTransferID
    }

    var isDownload: Bool {
        transfer.bInbound != 0
    }

    var remoteFileName: String {
        TeamTalkString.fileTransfer(.remoteFileName, from: transfer)
    }

    var localFilePath: String {
        TeamTalkString.fileTransfer(.localFilePath, from: transfer)
    }

    var localURL: URL? {
        guard !localFilePath.isEmpty else { return nil }
        return URL(fileURLWithPath: localFilePath)
    }

    var progress: Double {
        guard transfer.nFileSize > 0 else { return 0 }
        return min(1, max(0, Double(transfer.nTransferred) / Double(transfer.nFileSize)))
    }

    var progressText: String {
        "\(Int(progress * 100))%"
    }

    var transferredText: String {
        let transferred = ByteCountFormatter.string(fromByteCount: transfer.nTransferred, countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: transfer.nFileSize, countStyle: .file)
        return "\(transferred) / \(total)"
    }

    var directionText: String {
        isDownload
            ? String(localized: "Downloading", comment: "files")
            : String(localized: "Uploading", comment: "files")
    }
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

private enum ChannelFilesCommand {
    case upload(URL)
    case download(URL)
    case delete(ChannelFileRow)
}

final class ChannelFilesModel: ObservableObject {
    @Published var files = [ChannelFileRow]()
    @Published var transfers = [FileTransferRow]()
    @Published var downloadedFiles = [DownloadedFileRow]()
    @Published var channelTitle = String(localized: "Files", comment: "files")
    @Published var errorMessage: String?
    @Published var filePendingDeletion: ChannelFileRow?

    private var channelID: Int32 = 0
    private var activeCommands = [Int32: ChannelFilesCommand]()
    private let fileManager = FileManager.default

    var canUploadFiles: Bool {
        channelID > 0 &&
            (TeamTalkClient.shared.myUserRights & USERRIGHT_UPLOAD_FILES.rawValue) != 0
    }

    var canDownloadFiles: Bool {
        channelID > 0 &&
            (TeamTalkClient.shared.myUserRights & USERRIGHT_DOWNLOAD_FILES.rawValue) != 0
    }

    var hasCurrentChannel: Bool {
        channelID > 0
    }

    func refresh() {
        channelID = TeamTalkClient.shared.myChannelID
        updateChannelTitle()

        guard channelID > 0 else {
            files = []
            transfers = []
            return
        }

        files = TeamTalkClient.shared.channelFiles(in: channelID)
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

        do {
            let localURL = try prepareUploadFile(from: url)
            let cmdid = TeamTalkClient.shared.uploadFile(at: localURL, toChannelID: channelID)
            guard cmdid > 0 else {
                try? fileManager.removeItem(at: localURL)
                errorMessage = String(format: String(localized: "Failed to upload file %@", comment: "files"), localURL.lastPathComponent)
                return
            }
            activeCommands[cmdid] = .upload(localURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func download(_ file: ChannelFileRow) {
        guard canDownloadFiles else {
            errorMessage = String(localized: "You do not have permission to download files.", comment: "files")
            return
        }

        do {
            let localURL = try uniqueFileURL(in: downloadsDirectory(), filename: file.name)
            let cmdid = TeamTalkClient.shared.downloadFile(
                channelID: file.channelID,
                fileID: file.fileID,
                to: localURL
            )
            guard cmdid > 0 else {
                errorMessage = String(format: String(localized: "Failed to download file %@", comment: "files"), file.name)
                return
            }
            activeCommands[cmdid] = .download(localURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func requestDelete(_ file: ChannelFileRow) {
        filePendingDeletion = file
    }

    func confirmDelete(_ file: ChannelFileRow) {
        let cmdid = TeamTalkClient.shared.deleteFile(channelID: file.channelID, fileID: file.fileID)
        guard cmdid > 0 else {
            errorMessage = String(format: String(localized: "Failed to delete file %@", comment: "files"), file.name)
            return
        }
        activeCommands[cmdid] = .delete(file)
        filePendingDeletion = nil
    }

    func cancelTransfer(_ transfer: FileTransferRow) {
        if TeamTalkClient.shared.cancelFileTransfer(id: transfer.id) {
            removeTransfer(id: transfer.id)
            if transfer.isDownload, let localURL = transfer.localURL {
                try? fileManager.removeItem(at: localURL)
            }
        }
    }

    private func updateChannelTitle() {
        guard channelID > 0 else {
            channelTitle = String(localized: "Files", comment: "files")
            return
        }

        let name = TeamTalkClient.shared.withChannel(id: channelID) { channel in
            if channel.nParentID == 0 {
                return String(localized: "root channel", comment: "files")
            }
            return TeamTalkString.channel(.name, from: channel)
        }
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

    private func downloadsDirectory() throws -> URL {
        let directory = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("TeamTalk Downloads", isDirectory: true)
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

    private func updateTransfer(_ transfer: FileTransfer) {
        let row = FileTransferRow(transfer: transfer)

        switch transfer.nStatus {
        case FILETRANSFER_ACTIVE:
            if let index = transfers.firstIndex(where: { $0.id == row.id }) {
                transfers[index] = row
            } else {
                transfers.append(row)
            }
        case FILETRANSFER_FINISHED:
            removeTransfer(id: row.id)
            if row.isDownload, let localURL = row.localURL {
                downloadedFiles.insert(DownloadedFileRow(url: localURL), at: 0)
            } else {
                cleanupUploadCopy(for: row)
                refresh()
            }
        case FILETRANSFER_ERROR:
            removeTransfer(id: row.id)
            cleanupTransferFile(for: row)
            errorMessage = String(format: String(localized: "File transfer failed: %@", comment: "files"), row.remoteFileName)
        case FILETRANSFER_CLOSED:
            removeTransfer(id: row.id)
            cleanupTransferFile(for: row)
        default:
            break
        }
    }

    private func cleanupTransferFile(for transfer: FileTransferRow) {
        if transfer.isDownload, let localURL = transfer.localURL {
            try? fileManager.removeItem(at: localURL)
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

    private func removeTransfer(id: Int32) {
        transfers.removeAll { $0.id == id }
    }

    private func commandFailed(_ command: ChannelFilesCommand) {
        switch command {
        case .upload(let url):
            try? fileManager.removeItem(at: url)
        case .download(let url):
            try? fileManager.removeItem(at: url)
        case .delete:
            break
        }
    }
}

extension ChannelFilesModel: TeamTalkEvent {
    func handleTTMessage(_ m: TTMessage) {
        switch m.nClientEvent {
        case CLIENTEVENT_CON_LOST:
            channelID = 0
            files = []
            transfers = []
            activeCommands.removeAll()
            updateChannelTitle()

        case CLIENTEVENT_CMD_PROCESSING:
            if !TeamTalkMessagePayload.isActive(m) {
                activeCommands.removeValue(forKey: m.nSource)
            }

        case CLIENTEVENT_CMD_ERROR:
            if let command = activeCommands.removeValue(forKey: m.nSource) {
                commandFailed(command)
                errorMessage = TeamTalkString.clientError(TeamTalkMessagePayload.clientError(from: m))
            }

        case CLIENTEVENT_CMD_USER_JOINED:
            let user = TeamTalkMessagePayload.user(from: m)
            if user.nUserID == TeamTalkClient.shared.myUserID {
                refresh()
            }

        case CLIENTEVENT_CMD_USER_LEFT:
            let user = TeamTalkMessagePayload.user(from: m)
            if user.nUserID == TeamTalkClient.shared.myUserID {
                channelID = 0
                files = []
                transfers = []
                updateChannelTitle()
            }

        case CLIENTEVENT_CMD_CHANNEL_UPDATE:
            let channel = TeamTalkMessagePayload.channel(from: m)
            if channel.nChannelID == channelID {
                updateChannelTitle()
            }

        case CLIENTEVENT_CMD_FILE_NEW, CLIENTEVENT_CMD_FILE_REMOVE:
            playSound(.file_UPDATE)
            let file = TeamTalkMessagePayload.remoteFile(from: m)
            if file.nChannelID == channelID {
                refresh()
            }

        case CLIENTEVENT_FILETRANSFER:
            playSound(.file_COMPLETE)
            updateTransfer(TeamTalkMessagePayload.fileTransfer(from: m))

        default:
            break
        }
    }
}
