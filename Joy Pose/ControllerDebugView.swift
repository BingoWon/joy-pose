//
//  ControllerDebugView.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

// MARK: - Controller Debug View (UI Only)

struct ControllerDebugView: View {
    var onClose: (() -> Void)? = nil

    // Rainbow color configuration for light bar demo
    private let rainbowColors: [(name: String, color: Color, rgb: (Float, Float, Float))] = [
        ("Red", .red, (1.0, 0.0, 0.0)),
        ("Orange", .orange, (1.0, 0.5, 0.0)),
        ("Yellow", .yellow, (1.0, 1.0, 0.0)),
        ("Green", .green, (0.0, 1.0, 0.0)),
        ("Blue", .blue, (0.0, 0.0, 1.0)),
        ("Indigo", Color(red: 0.29, green: 0.0, blue: 0.51), (0.29, 0.0, 0.51)),
        ("Violet", Color(red: 0.56, green: 0.0, blue: 1.0), (0.56, 0.0, 1.0))
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                headerView

                // Controller info with battery and light bar
                enhancedControllerInfoView

                // DualSense visual controller representation
                dualSenseControllerView

                // Light bar color controls
                lightBarControlView

                // Enhanced terminal functions guide
                enhancedTerminalFunctionsView

                // Advanced features
                advancedFeaturesView
            }
            .padding(24)
        }
        .frame(minWidth: 700, maxWidth: 900, minHeight: 500, maxHeight: 800)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var headerView: some View {
        HStack(spacing: 16) {
            // PlayStation logo with connection status
            HStack(spacing: 8) {
                Image(systemName: "playstation.logo")
                    .font(.title2)
                    .foregroundColor(.blue)

                Image(systemName: "gamecontroller.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("DualSense Controller Debug")
                    .font(.headline)
                    .fontWeight(.bold)

                Text("Connected (UI Demo)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button("Close") {
                    onClose?()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var enhancedControllerInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Controller Information")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                // Basic info
                VStack(alignment: .leading, spacing: 4) {
                    InfoRow(label: "Name", value: "DualSense Controller")
                    InfoRow(label: "Vendor", value: "Sony Interactive Entertainment")
                    InfoRow(label: "Category", value: "Extended Gamepad")
                    InfoRow(label: "Connection", value: "USB")
                }

                Spacer()

                // Battery and status
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "battery.75percent")
                            .foregroundColor(.green)
                        Text("75%")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }

                    HStack(spacing: 8) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 12, height: 12)
                        Text("Light Bar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: .infinity)
    }

    private var dualSenseControllerView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("DualSense Controller Status")
                .font(.subheadline)
                .fontWeight(.semibold)

            VStack(spacing: 20) {
                // Battery status - DualSense style
                ZStack {
                    Image(systemName: "battery.75percent")
                        .font(.system(size: 50))
                        .foregroundColor(.green)

                    Text("75%")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }

                // Triggers section - original project layout
                VStack {
                    Text("Triggers")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 40) {
                        // L2 Trigger
                        VStack(spacing: 8) {
                            Text("L2")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.yellow)

                            ProgressView(value: 0.3)
                                .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
                                .frame(width: 60)

                            Text("30%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        // R2 Trigger
                        VStack(spacing: 8) {
                            Text("R2")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.yellow)

                            ProgressView(value: 0.7)
                                .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
                                .frame(width: 60)

                            Text("70%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Analog sticks section
                VStack {
                    Text("Analog Sticks")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 40) {
                        // Left stick
                        VStack(spacing: 8) {
                            Text("Left Stick")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.mint)

                            ZStack {
                                Circle()
                                    .stroke(.gray.opacity(0.3), lineWidth: 2)
                                    .frame(width: 60, height: 60)

                                Circle()
                                    .fill(.mint)
                                    .frame(width: 8, height: 8)
                                    .offset(x: -10, y: 5) // Demo position
                            }

                            Text("(-0.3, 0.2)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        // Right stick
                        VStack(spacing: 8) {
                            Text("Right Stick")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.mint)

                            ZStack {
                                Circle()
                                    .stroke(.gray.opacity(0.3), lineWidth: 2)
                                    .frame(width: 60, height: 60)

                                Circle()
                                    .fill(.mint)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 15, y: -8) // Demo position
                            }

                            Text("(0.5, -0.3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Face buttons section
                VStack {
                    Text("Face Buttons")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 20) {
                        FaceButtonView(symbol: "×", color: .green, isPressed: true)
                        FaceButtonView(symbol: "○", color: .orange, isPressed: false)
                        FaceButtonView(symbol: "□", color: .blue, isPressed: false)
                        FaceButtonView(symbol: "△", color: .purple, isPressed: true)
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var lightBarControlView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Light Bar Control (Demo)")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                ForEach(rainbowColors, id: \.name) { colorItem in
                    Button {
                        // UI only - no functionality
                    } label: {
                        Circle()
                            .fill(colorItem.color)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .strokeBorder(.white.opacity(0.8), lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Demo: Set light bar to \(colorItem.name)")
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var enhancedTerminalFunctionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Terminal Functions Guide (UI Demo)")
                .font(.subheadline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                // Button function items - with real-time status display
                enhancedFunctionItem("Cross (×)", "Execute command", .green, isPressed: true)
                enhancedFunctionItem("Circle (○)", "Delete", .orange, isPressed: false)
                enhancedFunctionItem("Square (□)", "Backspace", .blue, isPressed: false)
                enhancedFunctionItem("Triangle (△)", "Quick commands", .purple, isPressed: true)
                enhancedFunctionItem("L1", "Previous word", .cyan, isPressed: false)
                enhancedFunctionItem("R1", "Next word", .cyan, isPressed: false)

                // Trigger function items - with pressure value display
                enhancedTriggerItem(trigger: "L2", function: "Scroll up", color: .yellow, triggerValue: 0.3)
                enhancedTriggerItem(trigger: "R2", function: "Scroll down", color: .yellow, triggerValue: 0.7)

                // D-pad function items - with status display
                enhancedDPadItem(dpad: "D-Pad ↑↓", function: "Command history", color: .pink, isActive: true)
                enhancedDPadItem(dpad: "D-Pad ←→", function: "Move cursor", color: .pink, isActive: false)

                // Joystick function items - with position display
                enhancedStickItem(stick: "Left Stick", function: "Cursor control", color: .mint, position: "(-0.3, 0.2)")
                enhancedStickItem(stick: "Right Stick", function: "Scroll terminal", color: .mint, position: "(0.5, -0.3)")
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var advancedFeaturesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced Features (UI Demo)")
                .font(.subheadline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                FeatureCard(
                    title: "Haptic Feedback",
                    description: "Adaptive trigger resistance",
                    icon: "waveform.path",
                    color: .purple,
                    isEnabled: true
                )

                FeatureCard(
                    title: "Motion Sensor",
                    description: "Gyroscope and accelerometer",
                    icon: "gyroscope",
                    color: .orange,
                    isEnabled: false
                )

                FeatureCard(
                    title: "Touchpad",
                    description: "Multi-touch surface",
                    icon: "hand.tap.fill",
                    color: .blue,
                    isEnabled: true
                )

                FeatureCard(
                    title: "Speaker",
                    description: "Built-in audio feedback",
                    icon: "speaker.wave.2.fill",
                    color: .green,
                    isEnabled: true
                )
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct FaceButtonView: View {
    let symbol: String
    let color: Color
    let isPressed: Bool

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isPressed ? color : .gray.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(symbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isPressed ? .white : .gray)
                )

            Text(symbol)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct enhancedFunctionItem: View {
    let button: String
    let function: String
    let color: Color
    let isPressed: Bool

    init(_ button: String, _ function: String, _ color: Color, isPressed: Bool = false) {
        self.button = button
        self.function = function
        self.color = color
        self.isPressed = isPressed
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Circle()
                    .fill(isPressed ? color : .gray.opacity(0.3))
                    .frame(width: 8, height: 8)

                Text(button)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isPressed ? color : .secondary)
            }

            Text(function)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct enhancedTriggerItem: View {
    let trigger: String
    let function: String
    let color: Color
    let triggerValue: Float

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text(trigger)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)

                ProgressView(value: triggerValue)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .frame(width: 30)
            }

            Text(function)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("\(Int(triggerValue * 100))%")
                .font(.caption2)
                .foregroundColor(color)
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct enhancedDPadItem: View {
    let dpad: String
    let function: String
    let color: Color
    let isActive: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "dpad.fill")
                    .font(.caption)
                    .foregroundColor(isActive ? color : .gray)

                Text(dpad)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isActive ? color : .secondary)
            }

            Text(function)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct enhancedStickItem: View {
    let stick: String
    let function: String
    let color: Color
    let position: String

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "circle.circle")
                    .font(.caption)
                    .foregroundColor(color)

                Text(stick)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }

            Text(function)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text(position)
                .font(.caption2)
                .foregroundColor(color)
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct FeatureCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isEnabled: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isEnabled ? color : .gray)

                Spacer()

                Circle()
                    .fill(isEnabled ? .green : .red)
                    .frame(width: 8, height: 8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ControllerDebugView()
        .frame(width: 800, height: 600)
}
