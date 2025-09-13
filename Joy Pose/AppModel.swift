//
//  AppModel.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

@MainActor @Observable
class AppModel {
    let rooCodeConnectionManager = RooCodeConnectionManager.shared
    
    init() {
        print("🎯 JoyPose AppModel initialized")
        
        // 现代化启动：延迟启动服务发现以优化启动性能
        Task { @MainActor in
            // 给 UI 一点时间完成初始化
            try? await Task.sleep(for: .milliseconds(500))
            logger.info("🔍 [DEBUG] AppModel starting Roo Code service discovery", category: .connection)
            rooCodeConnectionManager.startScanning()
        }
    }
}