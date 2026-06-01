import AListCore
import SwiftUI

struct StatusBadge: View {
    let state: AListServiceState

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(color)
    }

    private var title: String {
        switch state {
        case .stopped:
            "Stopped"
        case .running:
            "Running"
        case .failed:
            "Failed"
        }
    }

    private var systemImage: String {
        switch state {
        case .stopped:
            "circle"
        case .running:
            "checkmark.circle.fill"
        case .failed:
            "xmark.octagon.fill"
        }
    }

    private var color: Color {
        switch state {
        case .stopped:
            .secondary
        case .running:
            .green
        case .failed:
            .red
        }
    }
}
