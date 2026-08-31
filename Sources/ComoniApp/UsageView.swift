import AppKit
import SwiftUI

#if SWIFT_PACKAGE
import ComoniCore
#endif

struct UsageView: View {
    @ObservedObject var viewModel: UsageViewModel
    @ObservedObject var presentation: OverlayPresentation

    private let morphAnimation = Animation.easeInOut(duration: 0.22)

    var body: some View {
        VStack(spacing: 0) {
            compactStrip
                .frame(height: 32)

            if presentation.isExpanded {
                Divider()
                    .padding(.horizontal, 12)
                detailRows
                    .transition(
                        .opacity.combined(
                            with: .scale(scale: 0.94, anchor: .topTrailing)
                        )
                    )
            }
        }
        .frame(
            width: presentation.isExpanded ? 360 : 250,
            height: presentation.isExpanded ? 170 : 32,
            alignment: .top
        )
        .background {
            RoundedRectangle(
                cornerRadius: presentation.isExpanded ? 14 : 0,
                style: .continuous
            )
            .fill(Color(nsColor: .windowBackgroundColor))
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: presentation.isExpanded ? 14 : 0,
                style: .continuous
            )
            .strokeBorder(
                Color(nsColor: .separatorColor).opacity(presentation.isExpanded ? 0.55 : 0),
                lineWidth: 1
            )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: presentation.isExpanded ? 14 : 0,
                style: .continuous
            )
        )
        .contentShape(Rectangle())
        .animation(morphAnimation, value: presentation.isExpanded)
    }

    private var compactStrip: some View {
        HStack(spacing: 7) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 15, height: 17)

            compactValue(label: "5小时", value: windows[0].remainingPercent)

            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.72))
                .frame(width: 1, height: 18)

            compactValue(label: "7天", value: windows[1].remainingPercent)

            Spacer(minLength: 2)

            Rectangle()
                .fill(.secondary.opacity(0.45))
                .frame(width: 1, height: 17)
        }
        .padding(.leading, 9)
        .padding(.trailing, 5)
    }

    private func compactValue(label: String, value: Int?) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value.map { "\($0)%" } ?? "--")
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(
                    isLowRemainingUsage(value)
                        ? Color(nsColor: .systemOrange)
                        : Color.primary
                )
        }
        .font(.system(size: 18, weight: .regular))
        .fixedSize()
    }

    private var detailRows: some View {
        VStack(spacing: 10) {
            detailRow(label: "5 小时重置", value: dateText(windows[0].resetsAt))
            detailRow(label: "7 天重置", value: dateText(windows[1].resetsAt))

            Divider()

            HStack(spacing: 5) {
                Text("重置额度")
                    .foregroundStyle(.secondary)
                Text(viewModel.snapshot?.resetCreditsAvailable.map(String.init) ?? "--")
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Spacer()
                Text(expiryText)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .font(.system(size: 18))
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 13)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .font(.system(size: 18))
    }

    private var windows: [UsageWindow] {
        viewModel.snapshot?.windows ?? [
            UsageWindow(label: "5 小时", remainingPercent: nil, resetsAt: nil),
            UsageWindow(label: "7 天", remainingPercent: nil, resetsAt: nil)
        ]
    }

    private func dateText(_ date: Date?) -> String {
        guard let date else {
            return "不可用"
        }
        return date.formatted(.dateTime.month().day().hour().minute())
    }

    private var expiryText: String {
        guard let date = viewModel.snapshot?.resetCreditExpiresAt else {
            return "有效期未知"
        }
        return "有效期至 \(date.formatted(.dateTime.month().day().hour().minute()))"
    }
}

@MainActor
final class OverlayPresentation: ObservableObject {
    @Published var isExpanded = false
}
