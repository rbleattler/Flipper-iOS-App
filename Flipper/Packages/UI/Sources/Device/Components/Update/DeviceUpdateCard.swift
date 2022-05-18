import SwiftUI

struct DeviceUpdateCard: View {
    @StateObject var viewModel: DeviceUpdateCardModel
    @Environment(\.scenePhase) private var scenePhase

    var description: String {
        switch viewModel.state {
        case .noSDCard:
            return "Install SD card in Flipper to update firmware"
        case .noInternet:
            return "Can’t connect to update server"
        case .disconnected:
            return "Connect to Flipper to see available updates"
        case .connecting:
            return "Connecting to Flipper..."
        case .noUpdates:
            return "There are no updates in selected channel"
        case .versionUpdate:
            return "Update Flipper to the latest version"
        case .channelUpdate:
            return "Firmware on Flipper doesn’t match update channel. " +
                "Selected version will be installed."
        case .updateInProgress:
            return "Now Flipper is updating in offline mode. " +
                "Look at device screen for info and wait for reconnect."
        }
    }

    var body: some View {
        Card {
            VStack(spacing: 0) {
                HStack {
                    Text("Firmware Update")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.horizontal, 12)

                if viewModel.state == .noSDCard {
                    VStack(spacing: 2) {
                        Image("NoSDCard")
                        Text("No SD сard")
                            .font(.system(size: 14, weight: .medium))
                        HStack {
                            Text(description)
                                .font(.system(size: 14, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.black30)
                        }
                        .frame(height: 31)
                        .padding(.horizontal, 12)
                    }
                    .padding(.vertical, 4)

                    Button {
                        viewModel.updateStorageInfo()
                    } label: {
                        Text("Retry")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.a2)
                    }
                    .padding(.bottom, 8)
                } else if viewModel.state == .noInternet {
                    VStack(spacing: 2) {
                        Image("NoInternet")
                        Text("No Internet connection")
                            .font(.system(size: 14, weight: .medium))
                        HStack {
                            Text(description)
                                .font(.system(size: 14, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.black30)
                        }
                        .frame(height: 31)
                        .padding(.horizontal, 12)
                    }
                    .padding(.vertical, 4)

                    Button {
                        viewModel.updateAvailableFirmware()
                    } label: {
                        Text("Retry")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.a2)
                    }
                    .padding(.bottom, 8)
                } else if viewModel.state == .disconnected {
                    VStack(spacing: 2) {
                        Image("UpdateNoDevice")
                        Text(description)
                            .font(.system(size: 14, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.black30)
                            .padding(.horizontal, 12)
                    }
                    .padding(.top, 26)
                    .padding(.bottom, 26)
                } else if viewModel.state == .connecting {
                    VStack(spacing: 4) {
                        Spinner()
                        Text(description)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black30)
                    }
                    .padding(.top, 36)
                    .padding(.bottom, 36)
                } else if viewModel.state == .updateInProgress {
                    UpdateStartedImage()
                        .padding(.top, 12)
                        .padding(.horizontal, 12)

                    Text("Update started...")
                        .padding(.top, 8)

                    VStack {
                        Text(description)
                            .font(.system(size: 14, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.black30)
                    }
                    .frame(height: 40)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .padding(.horizontal, 12)
                } else {
                    HStack {
                        Text("Update Channel")
                            .foregroundColor(.black30)

                        Spacer()

                        Menu {
                            Button("Release") {
                                viewModel.channel = .release
                            }
                            Button("Release-Candidate") {
                                viewModel.channel = .canditate
                            }
                            Button("Development") {
                                viewModel.channel = .development
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Spacer()
                                Text(viewModel.availableFirmware)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(viewModel.availableFirmwareColor)
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.black30)
                            }
                        }
                        .frame(maxHeight: .infinity)
                        .onTapGesture {
                            viewModel.updateAvailableFirmware()
                        }
                    }
                    .frame(height: 32)
                    .font(.system(size: 14))
                    .padding(.horizontal, 12)
                    .padding(.top, 6)

                    Divider()

                    UpdateButton(viewModel: viewModel)

                    VStack {
                        Text(description)
                            .font(.system(size: 12, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.black16)
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 8)
                    .padding(.horizontal, 12)
                }
            }

            Color.clear.alert(isPresented: $viewModel.showConfirmUpdate) {
                Alert(
                    title: Text("Update Firmware?"),
                    message: Text(
                        "New Firmware \(viewModel.availableFirmware) " +
                        "will be installed"),
                    primaryButton: .default(.init("Cancel")),
                    secondaryButton: .default(.init("Update").bold()) {
                        viewModel.update()
                    })
            }
            Color.clear.alert(isPresented: $viewModel.showPauseSync) {
                Alert(
                    title: Text("Pause Synchronization?"),
                    message: Text(
                        "Flipper is busy with syncing. " +
                        "Sync will be paused before updating."),
                    primaryButton: .default(.init("Continue")),
                    secondaryButton: .default(.init("Pause").bold()) {
                        viewModel.pauseSync()
                    })
            }
        }
        .fullScreenCover(isPresented: $viewModel.showUpdateView) {
            DeviceUpdateView(viewModel: .init(
                isPresented: $viewModel.showUpdateView,
                channel: viewModel.channel,
                firmware: viewModel.availableFirmwareVersion,
                onSuccess: viewModel.onSuccess
            ))
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                viewModel.updateAvailableFirmware()
            }
        }
    }
}

struct UpdateButton: View {
    @StateObject var viewModel: DeviceUpdateCardModel

    var title: String {
        switch viewModel.state {
        case .noUpdates: return "NO UPDATES"
        case .versionUpdate: return "UPDATE"
        case .channelUpdate: return "INSTALL"
        default: return ""
        }
    }

    var color: Color {
        switch viewModel.state {
        case .noUpdates: return .black20
        case .versionUpdate: return .sGreenUpdate
        case .channelUpdate: return .a1
        default: return .clear
        }
    }

    var body: some View {
        Button {
            viewModel.confirmUpdate()
        } label: {
            HStack {
                Spacer()
                Text(title)
                    .foregroundColor(.white)
                    .font(.custom("Born2bSportyV2", size: 40))
                Spacer()
            }
            .frame(height: 46)
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(9)
            .padding(.horizontal, 12)
            .padding(.top, 12)
        }
        // .disabled(viewModel.state == .noUpdates)
    }
}

struct UpdateStartedImage: View {
    @Environment(\.colorScheme) var colorScheme

    var image: String {
        colorScheme == .light ? "UpdateStartedLight" : "UpdateStartedDark"
    }

    var body: some View {
        Image(image)
    }
}
