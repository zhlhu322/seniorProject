//
//  PostureAnalyzer.swift
//  01
//
//  Created on 2025/11/12.
//

import Foundation
import Vision
import UIKit

// MARK: - 錯誤處理
enum PoseAnalysisError: Error {
    case imageConversionFailed
    case noPersonDetected
    case visionRequestFailed(Error)
    case insufficientKeypoints
    
    var localizedDescription: String {
        switch self {
        case .imageConversionFailed:
            return "無法轉換圖片格式"
        case .noPersonDetected:
            return "未檢測到人體姿勢"
        case .visionRequestFailed(let error):
            return "Vision 分析失敗：\(error.localizedDescription)"
        case .insufficientKeypoints:
            return "檢測到的關鍵點不足"
        }
    }
}

// MARK: - 姿勢關鍵點結構
struct PoseKeypoints {
    let neck: CGPoint?
    let leftShoulder: CGPoint?
    let rightShoulder: CGPoint?
    let leftHip: CGPoint?
    let rightHip: CGPoint?
    
    // 額外資訊
    let confidence: Float // 整體置信度
    let detectedPointsCount: Int // 檢測到的點數
    
    init(neck: CGPoint?, leftShoulder: CGPoint?, rightShoulder: CGPoint?, 
         leftHip: CGPoint?, rightHip: CGPoint?, confidence: Float = 0.0) {
        self.neck = neck
        self.leftShoulder = leftShoulder
        self.rightShoulder = rightShoulder
        self.leftHip = leftHip
        self.rightHip = rightHip
        self.confidence = confidence
        
        // 計算有效點數
        var count = 0
        if neck != nil { count += 1 }
        if leftShoulder != nil { count += 1 }
        if rightShoulder != nil { count += 1 }
        if leftHip != nil { count += 1 }
        if rightHip != nil { count += 1 }
        self.detectedPointsCount = count
    }
    
    // 檢查是否有足夠的關鍵點
    var isValid: Bool {
        return detectedPointsCount >= 3
    }
}

// MARK: - 姿勢分析器
class PostureAnalyzer {
    
    // 最小置信度閾值
    private let minimumConfidence: Float = 0.1
    
    /// 分析圖片中的人體姿勢
    /// - Parameter image: 要分析的 UIImage
    /// - Returns: Result 包含 PoseKeypoints 或 Error
    func analyzePosture(image: UIImage, completion: @escaping (Result<PoseKeypoints, Error>) -> Void) {
        // 將 UIImage 轉換為 CIImage
        guard let ciImage = convertToCIImage(from: image) else {
            completion(.failure(PoseAnalysisError.imageConversionFailed))
            return
        }
        
        // 建立 Vision 請求
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(PoseAnalysisError.visionRequestFailed(error)))
                return
            }
            
            // 處理結果
            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let firstPerson = observations.first else {
                completion(.failure(PoseAnalysisError.noPersonDetected))
                return
            }
            
            // 提取關鍵點
            do {
                let keypoints = try self.extractKeypoints(from: firstPerson)
                
                if keypoints.isValid {
                    completion(.success(keypoints))
                } else {
                    completion(.failure(PoseAnalysisError.insufficientKeypoints))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        // 執行請求
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(.failure(PoseAnalysisError.visionRequestFailed(error)))
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 將 UIImage 轉換為 CIImage
    private func convertToCIImage(from uiImage: UIImage) -> CIImage? {
        if let ciImage = uiImage.ciImage {
            return ciImage
        } else if let cgImage = uiImage.cgImage {
            return CIImage(cgImage: cgImage)
        }
        return nil
    }
    
    /// 從 VNHumanBodyPoseObservation 提取指定的關鍵點
    private func extractKeypoints(from observation: VNHumanBodyPoseObservation) throws -> PoseKeypoints {
        // 提取頸部（頸部在 Vision 中是通過鼻子和中心點推算的）
        let neck = try? getPoint(for: .neck, from: observation)
        
        // 提取肩膀
        let leftShoulder = try? getPoint(for: .leftShoulder, from: observation)
        let rightShoulder = try? getPoint(for: .rightShoulder, from: observation)
        
        // 提取髖部
        let leftHip = try? getPoint(for: .leftHip, from: observation)
        let rightHip = try? getPoint(for: .rightHip, from: observation)
        
        // 計算平均置信度
        var confidenceSum: Float = 0.0
        var validPointsCount = 0
        
        if let neckPoint = try? observation.recognizedPoint(.neck), neckPoint.confidence > minimumConfidence {
            confidenceSum += neckPoint.confidence
            validPointsCount += 1
        }
        if let leftShoulderPoint = try? observation.recognizedPoint(.leftShoulder), leftShoulderPoint.confidence > minimumConfidence {
            confidenceSum += leftShoulderPoint.confidence
            validPointsCount += 1
        }
        if let rightShoulderPoint = try? observation.recognizedPoint(.rightShoulder), rightShoulderPoint.confidence > minimumConfidence {
            confidenceSum += rightShoulderPoint.confidence
            validPointsCount += 1
        }
        if let leftHipPoint = try? observation.recognizedPoint(.leftHip), leftHipPoint.confidence > minimumConfidence {
            confidenceSum += leftHipPoint.confidence
            validPointsCount += 1
        }
        if let rightHipPoint = try? observation.recognizedPoint(.rightHip), rightHipPoint.confidence > minimumConfidence {
            confidenceSum += rightHipPoint.confidence
            validPointsCount += 1
        }
        
        let averageConfidence = validPointsCount > 0 ? confidenceSum / Float(validPointsCount) : 0.0
        
        return PoseKeypoints(
            neck: neck,
            leftShoulder: leftShoulder,
            rightShoulder: rightShoulder,
            leftHip: leftHip,
            rightHip: rightHip,
            confidence: averageConfidence
        )
    }
    
    /// 獲取指定關節點的座標（轉換為左上角原點）
    private func getPoint(for jointName: VNHumanBodyPoseObservation.JointName, 
                         from observation: VNHumanBodyPoseObservation) throws -> CGPoint? {
        let recognizedPoint = try observation.recognizedPoint(jointName)
        
        // 檢查置信度
        guard recognizedPoint.confidence > minimumConfidence else {
            return nil
        }
        
        // Vision 的座標系統：左下角為原點 (0,0)
        // 轉換為左上角原點：Y_new = 1 - Y_old
        let x = recognizedPoint.location.x
        let y = 1.0 - recognizedPoint.location.y
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - 姿勢分析結果
struct PostureAnalysisResult {
    let keypoints: PoseKeypoints
    let issues: [PostureIssue]
    let recommendations: [String]
    let overallScore: Int // 0-100 分
    
    init(keypoints: PoseKeypoints) {
        self.keypoints = keypoints
        self.issues = PostureAnalyzer.detectIssues(from: keypoints)
        self.recommendations = PostureAnalyzer.generateRecommendations(for: self.issues)
        self.overallScore = PostureAnalyzer.calculateScore(issues: self.issues, keypoints: keypoints)
    }
}

// MARK: - 姿勢問題類型
enum PostureIssue {
    case forwardHead // 頭前傾
    case roundedShoulders // 圓肩/駝背
    case shoulderImbalance // 高低肩
    case pelvicTilt // 骨盆傾斜
    
    var description: String {
        switch self {
        case .forwardHead:
            return "頭部前傾"
        case .roundedShoulders:
            return "圓肩（駝背傾向）"
        case .shoulderImbalance:
            return "肩膀高低不平衡"
        case .pelvicTilt:
            return "骨盆傾斜"
        }
    }
    
    var severity: String {
        return "需要注意"
    }
}

// MARK: - PostureAnalyzer 擴展：問題檢測
extension PostureAnalyzer {
    
    /// 檢測姿勢問題
    static func detectIssues(from keypoints: PoseKeypoints) -> [PostureIssue] {
        var issues: [PostureIssue] = []
        
        // 檢測高低肩
        if let leftShoulder = keypoints.leftShoulder,
           let rightShoulder = keypoints.rightShoulder {
            let shoulderDiff = abs(leftShoulder.y - rightShoulder.y)
            if shoulderDiff > 0.05 { // 5% 的高度差異
                issues.append(.shoulderImbalance)
            }
        }
        
        // 檢測圓肩（通過肩膀與頸部的相對位置）
        if let neck = keypoints.neck,
           let leftShoulder = keypoints.leftShoulder,
           let rightShoulder = keypoints.rightShoulder {
            let shoulderCenterX = (leftShoulder.x + rightShoulder.x) / 2
            let shoulderCenterY = (leftShoulder.y + rightShoulder.y) / 2
            
            // 如果肩膀中心在頸部前方較多，可能是圓肩
            if shoulderCenterY > neck.y + 0.1 {
                issues.append(.roundedShoulders)
            }
        }
        
        // 檢測骨盆傾斜
        if let leftHip = keypoints.leftHip,
           let rightHip = keypoints.rightHip {
            let hipDiff = abs(leftHip.y - rightHip.y)
            if hipDiff > 0.05 { // 5% 的高度差異
                issues.append(.pelvicTilt)
            }
        }
        
        return issues
    }
    
    /// 生成改善建議
    static func generateRecommendations(for issues: [PostureIssue]) -> [String] {
        var recommendations: [String] = []
        
        if issues.isEmpty {
            recommendations.append("✨ 你的體態良好！繼續保持！")
            recommendations.append("💪 建議定期運動以維持良好姿勢")
            return recommendations
        }
        
        for issue in issues {
            switch issue {
            case .forwardHead:
                recommendations.append("🔹 頭部前傾改善：\n   • 注意手機使用姿勢\n   • 進行頸部伸展運動\n   • 加強頸部後側肌群")
            case .roundedShoulders:
                recommendations.append("🔹 圓肩改善：\n   • 多做擴胸運動\n   • 加強背部肌群訓練\n   • 避免長時間彎腰駝背")
            case .shoulderImbalance:
                recommendations.append("🔹 肩膀平衡改善：\n   • 注意日常姿勢對稱性\n   • 進行單側肩部訓練\n   • 避免單肩背包")
            case .pelvicTilt:
                recommendations.append("🔹 骨盆平衡改善：\n   • 加強核心肌群訓練\n   • 進行骨盆穩定運動\n   • 注意站姿重心分配")
            }
        }
        
        recommendations.append("\n💡 建議持續記錄體態變化，追蹤改善效果！")
        
        return recommendations
    }
    
    /// 計算體態評分
    static func calculateScore(issues: [PostureIssue], keypoints: PoseKeypoints) -> Int {
        var score = 100
        
        // 根據問題數量扣分
        score -= issues.count * 15
        
        // 根據關鍵點置信度調整
        let confidenceBonus = Int(keypoints.confidence * 10)
        score = min(100, score + confidenceBonus)
        
        // 根據檢測到的點數調整
        if keypoints.detectedPointsCount < 4 {
            score -= 10
        }
        
        return max(0, score)
    }
}
