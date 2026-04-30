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

import SwiftUI
import UniformTypeIdentifiers

struct ChannelFilesView: View {
    @ObservedObject var model: ChannelFilesModel
    @State private var showingFileImporter = false
    @State private var showingDownloadFolderImporter = false

    var body: some View {
        List {
            if !model.transfers.isEmpty {
                Section("Transfers") {
                    ForEach(model.transfers) { transfer in
                        FileTransferRowView(transfer: transfer, cancel: {
                            model.cancelTransfer(transfer)
                        })
                    }
                }
            }

            Section("Files") {
                if model.files.isEmpty {
                    Text(model.hasCurrentChannel ? "No files" : "Not in a channel")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.files) { file in
                        ChannelFileRowView(
                            file: file,
                            canDownload: model.canDownloadFiles,
                            download: { requestDownload(file) },
                            delete: { model.requestDelete(file) }
                        )
                    }
                }
            }

            if !model.downloadedFiles.isEmpty {
                Section("Downloaded") {
                    ForEach(model.downloadedFiles) { file in
                        HStack {
                            Label(file.name, systemImage: "doc")
                            Spacer()
                            ShareLink(item: file.url) {
                                Image(systemName: "square.and.arrow.up")
                                    .accessibilityLabel("Share")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(model.channelTitle)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    model.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .accessibilityLabel("Refresh")
                }

                Button {
                    showingFileImporter = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .accessibilityLabel("Upload")
                }
                .disabled(!model.canUploadFiles)
            }
        }
        .refreshable {
            model.refresh()
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                urls.forEach { model.uploadFile(at: $0) }
            case .failure(let error):
                model.errorMessage = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $showingDownloadFolderImporter,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            model.downloadPendingFile(to: result)
        }
        .confirmationDialog("Delete File",
            isPresented: Binding(
                get: { model.filePendingDeletion != nil },
                set: { if !$0 { model.filePendingDeletion = nil } }
            ),
            presenting: model.filePendingDeletion
        ) { file in
            Button("Delete", role: .destructive) {
                model.confirmDelete(file)
            }
            Button("Cancel", role: .cancel) {
                model.filePendingDeletion = nil
            }
        } message: { file in
            Text(String(format: String(localized: "Delete %@?"), file.name))
        }
        .alert("Error",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onAppear {
            model.refresh()
        }
    }

    private func requestDownload(_ file: ChannelFileRow) {
        model.requestDownload(file)
        if model.filePendingDownload != nil {
            showingDownloadFolderImporter = true
        }
    }
}

private struct ChannelFileRowView: View {
    let file: ChannelFileRow
    let canDownload: Bool
    let download: () -> Void
    let delete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(file.name)
                .font(.body)
            Text(file.formattedSize)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(fileDetail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: "Download") {
            if canDownload {
                download()
            }
        }
        .accessibilityAction(named: "Delete") {
            delete()
        }
        .contextMenu {
            Button("Download") {
                download()
            }
            Button("Delete") {
                delete()
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                delete()
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                download()
            } label: {
                Label("Download", systemImage: "arrow.down.circle")
            }
            .disabled(!canDownload)
        }
    }

    private var fileDetail: String {
        let owner = file.username.isEmpty
            ? String(localized: "Unknown user", comment: "files")
            : file.username
        guard !file.uploadTime.isEmpty else {
            return owner
        }
        return "\(owner), \(file.uploadTime)"
    }
}

private struct FileTransferRowView: View {
    let transfer: FileTransferRow
    let cancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(transfer.displayName)
                        .font(.body)
                    Text(transfer.directionText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    cancel()
                } label: {
                    Image(systemName: "xmark.circle")
                        .accessibilityLabel("Cancel")
                }
                .buttonStyle(.borderless)
            }

            ProgressView(value: transfer.progress)
                .accessibilityLabel("Progress")
                .accessibilityValue(transfer.progressText)

            HStack {
                Text(transfer.transferredText)
                Spacer()
                Text(transfer.progressText)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}
