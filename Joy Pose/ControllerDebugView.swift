//
//  ControllerDebugView.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI
import GameController

// MARK: - Controller Debug View with Real-time Display

struct ControllerDebugView: View {
    var onClose: (() -> Void)? = nil
    
    // Controller state management
    @State private var isControllerConnected = false
    @State private var controllerName = ""
    @State private var batteryLevel: Float = 0.0
    @State private var buttonStates = ButtonStates()
    @State private var triggerValues = TriggerValues()
    @State private var stickValues = StickValues()
    

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                headerView

                // Enhanced terminal functions guide with integrated controller status
                enhancedTerminalFunctionsView

                // Advanced features
                advancedFeaturesView
            }
            .padding(24)
        }
        .frame(minWidth: 700, maxWidth: 900, minHeight: 500, maxHeight: 800)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            setupControllerObservation()
        }
        .onDisappear {
            removeControllerObservation()
        }
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            // Top row with status and close button
            HStack {
                // Connection status with animated indicators
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(isControllerConnected ? .green.opacity(0.2) : .red.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "gamecontroller.fill")
                            .font(.title2)
                            .foregroundColor(isControllerConnected ? .green : .red)
                            .symbolEffect(.pulse, isActive: isControllerConnected)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Controller Status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        Text(isControllerConnected ? "Connected" : "Disconnected")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(isControllerConnected ? .green : .red)
                    }
                }
                
                Spacer()
                
                // Close button with enhanced styling
                Button(action: { onClose?() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .hoverEffect(.lift)
            }
            
            // Controller information section
            if isControllerConnected {
                HStack(spacing: 20) {
                    // Controller icon with branding
                    VStack(spacing: 8) {
                        Image(systemName: "playstation.logo")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                            .symbolEffect(.variableColor.iterative, isActive: true)
                        
                        Text("DualSense")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .frame(height: 40)
                    
                    // Device details
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Device:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(controllerName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        if batteryLevel > 0 {
                            HStack {
                                Text("Battery:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: batteryLevel > 0.2 ? "battery.100" : "battery.25")
                                        .font(.caption)
                                        .foregroundColor(batteryLevel > 0.2 ? .green : .orange)
                                    
                                    Text("\(Int(batteryLevel * 100))%")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(batteryLevel > 0.2 ? .green : .orange)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Real-time status indicator
                    VStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                            .symbolEffect(.pulse, isActive: true)
                        
                        Text("LIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .tracking(1)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 1)
        )
    }




    private var enhancedTerminalFunctionsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Enhanced section header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.blue.gradient.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "gamecontroller.fill")
                        .foregroundStyle(.blue.gradient)
                        .font(.title2)
                        .symbolEffect(.variableColor.iterative, isActive: isControllerConnected)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("DualSense Terminal Functions")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("Real-time controller input mapping with status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Controller status with battery info
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isControllerConnected ? .green : .red)
                            .frame(width: 8, height: 8)
                            .scaleEffect(isControllerConnected ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), 
                                     value: isControllerConnected)
                        
                        Text(isControllerConnected ? "CONNECTED" : "DISCONNECTED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(isControllerConnected ? .green : .red)
                            .textCase(.uppercase)
                            .tracking(0.8)
                    }
                    
                    if isControllerConnected {
                        HStack(spacing: 4) {
                            Image(systemName: "battery.75percent")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text("75%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Unified 3x4 grid layout with integrated controller status
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Row 1: Face buttons
                enhancedControllerFunctionItem(
                    icon: "cross.circle.fill",
                    title: "Cross (×)",
                    function: "Execute Command",
                    color: .green,
                    isPressed: buttonStates.buttonA,
                    statusValue: nil
                )
                enhancedControllerFunctionItem(
                    icon: "circle.circle.fill",
                    title: "Circle (○)",
                    function: "Cancel/Delete",
                    color: .orange,
                    isPressed: buttonStates.buttonB,
                    statusValue: nil
                )
                enhancedControllerFunctionItem(
                    icon: "square.fill",
                    title: "Square (□)",
                    function: "Backspace",
                    color: .blue,
                    isPressed: buttonStates.buttonX,
                    statusValue: nil
                )
                enhancedControllerFunctionItem(
                    icon: "triangle.fill",
                    title: "Triangle (△)",
                    function: "Menu/Options",
                    color: .red,
                    isPressed: buttonStates.buttonY,
                    statusValue: nil
                )
                
                // Row 2: Triggers and shoulders
                enhancedControllerFunctionItem(
                    icon: "l2.rectangle.roundedbottom",
                    title: "L2 Trigger",
                    function: "Volume Down",
                    color: .purple,
                    isPressed: triggerValues.leftTrigger > 0.1,
                    statusValue: triggerValues.leftTrigger
                )
                enhancedControllerFunctionItem(
                    icon: "r2.rectangle.roundedbottom",
                    title: "R2 Trigger",
                    function: "Volume Up",
                    color: .purple,
                    isPressed: triggerValues.rightTrigger > 0.1,
                    statusValue: triggerValues.rightTrigger
                )
                enhancedControllerFunctionItem(
                    icon: "l1.rectangle.roundedtop",
                    title: "L1 Shoulder",
                    function: "Previous Track",
                    color: .cyan,
                    isPressed: buttonStates.leftShoulder,
                    statusValue: nil
                )
                enhancedControllerFunctionItem(
                    icon: "r1.rectangle.roundedtop",
                    title: "R1 Shoulder",
                    function: "Next Track",
                    color: .cyan,
                    isPressed: buttonStates.rightShoulder,
                    statusValue: nil
                )
                
                // Row 3: D-Pad and thumbsticks
                enhancedControllerFunctionItem(
                    icon: "dpad.fill",
                    title: "D-Pad",
                    function: "Navigation",
                    color: .pink,
                    isPressed: buttonStates.dpadUp || buttonStates.dpadDown || buttonStates.dpadLeft || buttonStates.dpadRight,
                    statusValue: nil
                )
                enhancedControllerFunctionItem(
                    icon: "l.joystick",
                    title: "Left Stick",
                    function: "Cursor Control",
                    color: .mint,
                    isPressed: abs(stickValues.leftStickX) > 0.1 || abs(stickValues.leftStickY) > 0.1,
                    statusValue: sqrt(stickValues.leftStickX * stickValues.leftStickX + stickValues.leftStickY * stickValues.leftStickY)
                )
                enhancedControllerFunctionItem(
                    icon: "r.joystick",
                    title: "Right Stick",
                    function: "Scroll Terminal",
                    color: .mint,
                    isPressed: abs(stickValues.rightStickX) > 0.1 || abs(stickValues.rightStickY) > 0.1,
                    statusValue: sqrt(stickValues.rightStickX * stickValues.rightStickX + stickValues.rightStickY * stickValues.rightStickY)
                )
                enhancedControllerFunctionItem(
                    icon: "touchpad",
                    title: "Touchpad",
                    function: "Mouse Control",
                    color: .indigo,
                    isPressed: false, // TODO: Add touchpad support
                    statusValue: nil
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .stroke(.secondary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var advancedFeaturesView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Enhanced section header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.purple.gradient.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "gearshape.2.fill")
                        .foregroundStyle(.purple.gradient)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Advanced Features")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("Hardware capabilities and status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Feature count indicator
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("3/4")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
            
            // Enhanced feature grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                EnhancedFeatureCard(
                    title: "Haptic Feedback",
                    description: "Adaptive trigger resistance with precision force feedback",
                    icon: "waveform.path",
                    color: .purple,
                    isEnabled: isControllerConnected,
                    statusText: isControllerConnected ? "Active" : "Unavailable"
                )

                EnhancedFeatureCard(
                    title: "Motion Sensor",
                    description: "6-axis gyroscope and accelerometer for spatial tracking",
                    icon: "gyroscope",
                    color: .orange,
                    isEnabled: false,
                    statusText: "Not Supported"
                )

                EnhancedFeatureCard(
                    title: "Touchpad",
                    description: "Multi-touch capacitive surface with click detection",
                    icon: "hand.tap.fill",
                    color: .blue,
                    isEnabled: isControllerConnected,
                    statusText: isControllerConnected ? "Ready" : "Disconnected"
                )

                EnhancedFeatureCard(
                    title: "Audio Output",
                    description: "Built-in speaker with 3D spatial audio support",
                    icon: "speaker.wave.3.fill",
                    color: .green,
                    isEnabled: isControllerConnected,
                    statusText: isControllerConnected ? "Enabled" : "Muted"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .stroke(.secondary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
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

// MARK: - Controller State Management

struct ButtonStates {
    var buttonA = false
    var buttonB = false  
    var buttonX = false
    var buttonY = false
    var leftShoulder = false
    var rightShoulder = false
    var dpadUp = false
    var dpadDown = false
    var dpadLeft = false
    var dpadRight = false
}

struct TriggerValues {
    var leftTrigger: Float = 0.0
    var rightTrigger: Float = 0.0
}

struct StickValues {
    var leftStickX: Float = 0.0
    var leftStickY: Float = 0.0
    var rightStickX: Float = 0.0
    var rightStickY: Float = 0.0
}

// MARK: - Controller Management Extension

extension ControllerDebugView {
    
    func setupControllerObservation() {
        // Setup notifications for controller connections
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { _ in
            updateControllerState()
        }
        
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { _ in
            updateControllerState()
        }
        
        // Check for existing controllers
        updateControllerState()
    }
    
    func removeControllerObservation() {
        NotificationCenter.default.removeObserver(self, name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.removeObserver(self, name: .GCControllerDidDisconnect, object: nil)
    }
    
    func updateControllerState() {
        guard let controller = GCController.controllers().first else {
            isControllerConnected = false
            controllerName = ""
            batteryLevel = 0.0
            resetControllerValues()
            return
        }
        
        isControllerConnected = true
        controllerName = controller.vendorName ?? "Unknown Controller"
        
        // Get battery level if available
        if let battery = controller.battery {
            batteryLevel = battery.batteryLevel
        }
        
        // Setup input handlers
        setupInputHandlers(for: controller)
    }
    
    func setupInputHandlers(for controller: GCController) {
        // Extended gamepad (most modern controllers)
        if let extendedGamepad = controller.extendedGamepad {
            // Button inputs
            extendedGamepad.buttonA.valueChangedHandler = { _, _, pressed in
                buttonStates.buttonA = pressed
            }
            extendedGamepad.buttonB.valueChangedHandler = { _, _, pressed in
                buttonStates.buttonB = pressed
            }
            extendedGamepad.buttonX.valueChangedHandler = { _, _, pressed in
                buttonStates.buttonX = pressed
            }
            extendedGamepad.buttonY.valueChangedHandler = { _, _, pressed in
                buttonStates.buttonY = pressed
            }
            
            // Shoulder buttons
            extendedGamepad.leftShoulder.valueChangedHandler = { _, _, pressed in
                buttonStates.leftShoulder = pressed
            }
            extendedGamepad.rightShoulder.valueChangedHandler = { _, _, pressed in
                buttonStates.rightShoulder = pressed
            }
            
            // Triggers
            extendedGamepad.leftTrigger.valueChangedHandler = { _, value, _ in
                triggerValues.leftTrigger = value
            }
            extendedGamepad.rightTrigger.valueChangedHandler = { _, value, _ in
                triggerValues.rightTrigger = value
            }
            
            // D-Pad
            extendedGamepad.dpad.up.valueChangedHandler = { _, _, pressed in
                buttonStates.dpadUp = pressed
            }
            extendedGamepad.dpad.down.valueChangedHandler = { _, _, pressed in
                buttonStates.dpadDown = pressed
            }
            extendedGamepad.dpad.left.valueChangedHandler = { _, _, pressed in
                buttonStates.dpadLeft = pressed
            }
            extendedGamepad.dpad.right.valueChangedHandler = { _, _, pressed in
                buttonStates.dpadRight = pressed
            }
            
            // Thumbsticks
            extendedGamepad.leftThumbstick.valueChangedHandler = { _, xValue, yValue in
                stickValues.leftStickX = xValue
                stickValues.leftStickY = yValue
            }
            extendedGamepad.rightThumbstick.valueChangedHandler = { _, xValue, yValue in
                stickValues.rightStickX = xValue
                stickValues.rightStickY = yValue
            }
        }
    }
    
    func resetControllerValues() {
        buttonStates = ButtonStates()
        triggerValues = TriggerValues()
        stickValues = StickValues()
    }
}

// MARK: - Enhanced Feature Card Component

struct EnhancedFeatureCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    let statusText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            descriptionSection
            if isEnabled {
                progressSection
            }
        }
        .padding(16)
        .background(backgroundStyle)
        .overlay(alignment: .topTrailing) {
            checkmarkOverlay
        }
        .scaleEffect(isEnabled ? 1.0 : 0.98)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            iconView
            titleAndStatusView
            Spacer()
        }
    }
    
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(isEnabled ? AnyShapeStyle(color.gradient.opacity(0.2)) : AnyShapeStyle(Color.gray.opacity(0.1)))
                .frame(width: 44, height: 44)
            
            Image(systemName: icon)
                .foregroundStyle(isEnabled ? color.gradient : Color.gray.gradient)
                .font(.title2)
        }
    }
    
    private var titleAndStatusView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            statusIndicator
        }
    }
    
    private var statusIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isEnabled ? .green : .gray)
                .frame(width: 6, height: 6)
            
            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isEnabled ? .green : .gray)
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }
    
    private var descriptionSection: some View {
        Text(description)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
    }
    
    private var progressSection: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < 3 ? color.opacity(0.8) : color.opacity(0.2))
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.1), value: isEnabled)
            }
        }
    }
    
    private var backgroundStyle: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isEnabled ? color.opacity(0.05) : Color.gray.opacity(0.02))
            .stroke(isEnabled ? color.opacity(0.2) : Color.gray.opacity(0.1), lineWidth: 1)
    }
    
    @ViewBuilder
    private var checkmarkOverlay: some View {
        if isEnabled {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
                .offset(x: -8, y: 8)
        }
    }
}

// MARK: - Enhanced Controller Function Item Component

struct enhancedControllerFunctionItem: View {
    let icon: String
    let title: String
    let function: String
    let color: Color
    let isPressed: Bool
    let statusValue: Float?
    
    var body: some View {
        VStack(spacing: 8) {
            iconView
            titleAndFunctionView
            statusIndicatorView
        }
        .padding(12)
        .background(backgroundView)
        .hoverEffect(.lift)
        .animation(.easeInOut(duration: 0.3), value: isPressed)
    }
    
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(isPressed ? AnyShapeStyle(color.gradient.opacity(0.3)) : AnyShapeStyle(Color.gray.opacity(0.1)))
                .frame(width: 32, height: 32)
                .scaleEffect(isPressed ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isPressed)
            
            Image(systemName: icon)
                .foregroundStyle(isPressed ? color.gradient : Color.gray.gradient)
                .font(.title3)
                .symbolEffect(.bounce, value: isPressed)
        }
    }
    
    private var titleAndFunctionView: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isPressed ? color : .primary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
            
            Text(function)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
    
    @ViewBuilder
    private var statusIndicatorView: some View {
        if let statusValue = statusValue {
            progressView(statusValue)
        } else {
            buttonStatusView
        }
    }
    
    private func progressView(_ value: Float) -> some View {
        HStack(spacing: 2) {
            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 2)
            
            Text("\(Int(value * 100))%")
                .font(.caption2)
                .foregroundColor(color)
                .frame(width: 25)
        }
    }
    
    private var buttonStatusView: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(isPressed ? color : Color.gray.opacity(0.3))
                .frame(width: 4, height: 4)
            
            Text(isPressed ? "ACTIVE" : "IDLE")
                .font(.caption2)
                .foregroundColor(isPressed ? color : .secondary)
                .fontWeight(.medium)
                .textCase(.uppercase)
                .tracking(0.3)
        }
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .stroke(isPressed ? color.opacity(0.4) : Color.gray.opacity(0.2), lineWidth: 1)
    }
}

// MARK: - Enhanced Info Card Component

struct EnhancedInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color.gradient)
                    .font(.title3)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 6, height: 6)
                .offset(x: -8, y: 8)
        }
    }
}

#Preview {
    ControllerDebugView()
        .frame(width: 800, height: 600)
}
