import SwiftUI

#if SWIFT_PACKAGE
import CodexUsageMonitorCore
#endif

struct UsageView: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        VStack(spacing: 13) {
            header

            ForEach(Array(windows.enumerated()), id: \.offset) { _, window in
                usageRow(window)
            }

            footer
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 15)
        .frame(width: 320, height: 200)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 16, y: 7)
        .padding(16)
        .frame(width: 352, height: 232)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 25, height: 25)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.50, green: 0.35, blue: 1), Color(red: 0.25, green: 0.55, blue: 1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )

            Text("CODEX 用量")
                .font(.system(size: 13, weight: .semibold, design: .rounded))

            Spacer()

            if viewModel.isRefreshing {
                ProgressView()
                    .controlSize(.small)
            } else if viewModel.isStale {
                Text("数据陈旧")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.orange)
            }

            if let plan = viewModel.snapshot?.planType {
                Text(plan.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.primary.opacity(0.07), in: Capsule())
            }
        }
    }

    private func usageRow(_ window: UsageWindow) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(window.label)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text(remainingText(window.remainingPercent))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(resetText(window.resetsAt))
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.primary.opacity(0.09))
                    if let remaining = window.remainingPercent {
                        Capsule()
                            .fill(barColor(remaining))
                            .frame(width: max(4, proxy.size.width * CGFloat(remaining) / 100))
                    }
                }
            }
            .frame(height: 6)
        }
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(viewModel.errorMessage == nil ? Color.green : Color.orange)
                .frame(width: 6, height: 6)
            Text(footerText)
                .font(.system(size: 9.5))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            if let count = viewModel.snapshot?.resetCreditsAvailable {
                Text("重置额度 \(count)")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var windows: [UsageWindow] {
        viewModel.snapshot?.windows ?? [
            UsageWindow(label: "5 小时", remainingPercent: nil, resetsAt: nil),
            UsageWindow(label: "7 天", remainingPercent: nil, resetsAt: nil)
        ]
    }

    private var footerText: String {
        if let errorMessage = viewModel.errorMessage, viewModel.snapshot == nil {
            return errorMessage
        }
        guard let updatedAt = viewModel.updatedAt else {
            return "正在读取用量…"
        }
        return "更新于 \(updatedAt.formatted(date: .omitted, time: .shortened))"
    }

    private func remainingText(_ value: Int?) -> String {
        value.map { "剩余 \($0)%" } ?? "不可用"
    }

    private func resetText(_ date: Date?) -> String {
        guard let date else {
            return ""
        }
        return "· \(date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))"
    }

    private func barColor(_ remaining: Int) -> Color {
        if remaining <= 10 {
            return .red
        }
        if remaining <= 30 {
            return .orange
        }
        return Color(red: 0.34, green: 0.55, blue: 1)
    }
}
