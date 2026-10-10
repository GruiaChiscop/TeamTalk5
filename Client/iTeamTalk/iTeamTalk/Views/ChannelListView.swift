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
import TeamTalkKit

// MARK: - Container view

struct ChannelListContainerView: View {
    @State var model: ChannelListModel
    @State private var isPressingTalkButton = false
    @ScaledMetric(relativeTo: .title3) private var talkButtonMinHeight: CGFloat = 50

    var body: some View {
        VStack(spacing: 0) {
            ChannelListView(model: model)

            // Black text on system green/red keeps well above 4.5:1 contrast in
            // both light and dark mode, and the label and icon change along with
            // the color so the state never depends on color alone.
            Label(model.pushToTalk.isTransmitting ? "Transmitting" : "Talk",
                  systemImage: model.pushToTalk.isTransmitting ? "mic.fill" : "mic")
                .font(.title3.weight(.semibold))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: talkButtonMinHeight)
                // A color background extends into the safe area by default, which
                // painted the area behind the tab bar green as well.
                .background(model.pushToTalk.isTransmitting ? Color.red : Color.green,
                            ignoresSafeAreaEdges: [])
                .foregroundStyle(.black)
                .brightness(isPressingTalkButton ? -0.15 : 0)
                .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressingTalkButton else { return }
                        isPressingTalkButton = true
                        model.pushToTalk.txBtnDown()
                    }
                    .onEnded { _ in
                        guard isPressingTalkButton else { return }
                        isPressingTalkButton = false
                        model.pushToTalk.txBtnUp()
                    }
            )
            .accessibilityLabel("Push to Talk")
            .accessibilityHint(model.pushToTalk.pttHint)
            .accessibilityValue(model.pushToTalk.isTransmitting
                ? Text("Active")
                : Text("Inactive"))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {
                model.pushToTalk.txBtnAccessibilityAction()
            }
        }
        .navigationTitle(model.navigationTitle)
        .alert("Enter Password", isPresented: $model.showingJoinPasswordAlert) {
            SecureField("Password", text: $model.joinPassword)
            Button("Join") { model.confirmJoinWithPassword() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Password")
        }
        .alert("Error", isPresented: $model.isPresentingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}

// MARK: - List view

struct ChannelListView: View {
    let model: ChannelListModel
    @ScaledMetric(relativeTo: .body) private var rowIconSize: CGFloat = 36
    @ScaledMetric(relativeTo: .body) private var messageIconSize: CGFloat = 24

    var body: some View {
        // Nested DisclosureGroups instead of an OutlineGroup, which has no way
        // to open a group from code - needed to expand the channel the user is in.
        List {
            ForEach(model.rootNodes) { node in
                ChannelTreeNodeView(node: node, model: model, row: row)
            }
        }
    }

    @ViewBuilder
    private func row(_ node: ChannelTreeNode) -> some View {
        switch node.kind {
        case .channel(let channel):
            channelRow(channel)
        case .user(let user):
            userRow(user)
        }
    }

    private func userRow(_ user: TeamTalkUser) -> some View {
        let details = model.userDetails(user)
        let isMoveSelected = model.moderation.isMoveUserSelected(userID: user.userID)
        return HStack(spacing: 10) {
            Image(details.iconName)
                .resizable()
                .frame(width: rowIconSize, height: rowIconSize)
                .accessibilityLabel(details.iconAccessibilityLabel)

            VStack(alignment: .leading, spacing: 2) {
                Text(details.title)
                    .font(.body)
                    .lineLimit(1)
                if let subtitle = details.subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 12)

            if isMoveSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            Button {
                model.showTextMessages(user: user)
            } label: {
                Image(details.messageIconName)
                    .resizable()
                    .frame(width: messageIconSize, height: messageIconSize)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Text Messaging")
        }
        .accessibilityElement(children: .combine)
        .contentShape(Rectangle())
        .onTapGesture {
            model.showUserDetail(user)
        }
        .accessibilityAction(named: "Show user details") {
            model.showUserDetail(user)
        }
        .accessibilityAction(named: "Message this user") {
            model.showTextMessages(user: user)
        }
        .accessibilityAction(named: "Mute") {
            model.moderation.muteUser(userID: user.userID)
        }
        .accessibilityAction(named: model.moderation.moveUserActionTitle(userID: user.userID)) {
            model.moderation.moveUser(userID: user.userID)
        }
        .accessibilityAction(named: "Kick user") {
            model.moderation.kickUser(userID: user.userID)
        }
        .accessibilityAction(named: "Ban user") {
            model.moderation.banUser(userID: user.userID)
        }
    }

    private func channelRow(_ channel: TeamTalkChannel) -> some View {
        let details = model.channelDetails(channel)
        let hasSelectedUsers = !model.moderation.moveusers.isEmpty

        let content = HStack(spacing: 10) {
            Image(details.iconName)
                .resizable()
                .frame(width: rowIconSize, height: rowIconSize)
                .accessibilityLabel(details.iconAccessibilityLabel)

            VStack(alignment: .leading, spacing: 2) {
                Text(details.title)
                    .font(.body)
                    .lineLimit(1)
                if let subtitle = details.subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 12)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(model.moderation.moveDestinationAccessibilityHint())
        .contentShape(Rectangle())
        .onTapGesture {
            model.joinNewChannel(channel)
        }
        .swipeActions(edge: .trailing) {
            // swipeActions buttons are automatically exposed to VoiceOver as a
            // custom action of their own - adding a matching .accessibilityAction
            // below would just announce this one twice.
            Button(details.actionTitle) {
                model.showChannelDetail(channel)
            }
            .tint(.blue)
        }

        // Direct tap expands/collapses under VoiceOver (that's fine - it's the
        // native DisclosureGroup behavior), so Join is a named action
        // instead. Move only makes sense - and only appears - once users are
        // actually selected, in which case it comes before Join.
        return Group {
            if hasSelectedUsers {
                content
                    .accessibilityAction(named: "Move users here") {
                        model.moderation.moveIntoChannel(channelID: channel.channelID)
                    }
                    .accessibilityAction(named: "Join") {
                        model.joinNewChannel(channel)
                    }
            } else {
                content
                    .accessibilityAction(named: "Join") {
                        model.joinNewChannel(channel)
                    }
            }
        }
    }
}

// MARK: - Tree node

private struct ChannelTreeNodeView<Row: View>: View {
    let node: ChannelTreeNode
    let model: ChannelListModel
    let row: (ChannelTreeNode) -> Row

    var body: some View {
        if let children = node.children, case .channel(let channel) = node.kind {
            DisclosureGroup(isExpanded: isExpanded(channel.channelID)) {
                ForEach(children) { child in
                    ChannelTreeNodeView(node: child, model: model, row: row)
                }
            } label: {
                row(node)
            }
        } else {
            row(node)
        }
    }

    private func isExpanded(_ channelID: TeamTalkChannelID) -> Binding<Bool> {
        Binding(
            get: { model.expandedChannelIDs.contains(channelID) },
            set: { expanded in
                if expanded {
                    model.expandedChannelIDs.insert(channelID)
                } else {
                    model.expandedChannelIDs.remove(channelID)
                }
            }
        )
    }
}

// MARK: - Detail structs

struct ChannelUserDetails {
    let title: String
    let subtitle: String?
    let iconName: String
    let iconAccessibilityLabel: String
    let messageIconName: String
}

struct ChannelDisplayDetails {
    let title: String
    let subtitle: String?
    let iconName: String
    let iconAccessibilityLabel: String
    let actionTitle: String
}
