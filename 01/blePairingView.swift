//
//  blePairingView.swift
//  01
//
//  Created by 李恩亞 on 2025/5/2.
//

import SwiftUI
import Inject
import CoreBluetooth


class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    @Published var isBluetoothEnabled = false
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var connectedDevice: CBPeripheral?
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var isCorrectDevice = false
    @Published var currentCount: Int = 0
    var actionTypeCharacteristic: CBCharacteristic?
    var receiveCharacteristic: CBCharacteristic?
    
    // 目標裝置名稱關鍵字
    private let targetDeviceName = "micro:bit"
    private let targetCount: Int = 10 // 目標次數
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case failed
        case wrongDevice
    }
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            isBluetoothEnabled = true
            // 當藍牙開啟時，檢查已連接的裝置
            checkConnectedDevices()
            startScanning()
        case .poweredOff:
            isBluetoothEnabled = false
            connectionStatus = .disconnected
        case .unauthorized:
            isBluetoothEnabled = false
            connectionStatus = .disconnected
        case .unsupported:
            isBluetoothEnabled = false
            connectionStatus = .disconnected
        case .resetting:
            isBluetoothEnabled = false
            connectionStatus = .disconnected
        case .unknown:
            isBluetoothEnabled = false
            connectionStatus = .disconnected
        @unknown default:
            isBluetoothEnabled = false
            connectionStatus = .disconnected
        }
    }
    
    // 新增：檢查已連接的裝置
    func checkConnectedDevices() {
        let connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")])
        
        for peripheral in connectedPeripherals {
            print("發現已連接的裝置: \(peripheral.name ?? "Unknown")")
            if let deviceName = peripheral.name, deviceName.contains(targetDeviceName) {
                print("找到目標裝置，嘗試連接")
                connect(to: peripheral)
            }
        }
    }

    
    func startScanning() {
        if isBluetoothEnabled {
            let serviceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
            centralManager.scanForPeripherals(withServices: [serviceUUID])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("發現裝置: \(peripheral.name ?? "Unknown")")
        print("裝置 UUID: \(peripheral.identifier.uuidString)")
        
        // 如果發現目標裝置，立即嘗試連接
        if let deviceName = peripheral.name, deviceName.contains(targetDeviceName) {
            print("找到目標裝置，嘗試連接")
            connect(to: peripheral)
        }
        
        if !discoveredDevices.contains(peripheral) {
            discoveredDevices.append(peripheral)
        }
    }
    

    func connect(to peripheral: CBPeripheral) {
        print("開始連接裝置: \(peripheral.name ?? "Unknown")")
        connectionStatus = .connecting

        peripheral.delegate = self
        connectedDevice = peripheral // 保留 reference，避免系統釋放

        centralManager.connect(peripheral, options: nil)
    }

    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("已連接到裝置: \(peripheral.name ?? "Unknown")")
        print("裝置 UUID: \(peripheral.identifier.uuidString)")
        
        // 檢查是否為正確的裝置
        if let deviceName = peripheral.name, deviceName.contains(targetDeviceName) {
            print("確認是目標裝置")
            isCorrectDevice = true
            connectedDevice = peripheral
            connectionStatus = .connected
            // 停止掃描
            centralManager.stopScan()
            // 開始發現服務
            peripheral.discoverServices(nil)
        } else {
            print("不是目標裝置")
            isCorrectDevice = false
            connectionStatus = .wrongDevice
            // 斷開錯誤的裝置
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionStatus = .failed
        print("連接失敗: \(error?.localizedDescription ?? "未知錯誤")")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionStatus = .disconnected
        connectedDevice = nil
        isCorrectDevice = false
        // 重新開始掃描
        startScanning()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("❌ 發現服務失敗: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            print("❌ 沒有找到服務")
            return
        }
        
        print("📱 發現 \(services.count) 個服務")
        
        for service in services {
            print("🔍 服務 UUID: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("❌ 發現特徵失敗: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            print("❌ 沒有找到特徵")
            return
        }
        
        print("📱 發現 \(characteristics.count) 個特徵")
        
        for characteristic in characteristics {
            // 印出 characteristic 詳細資訊
            print("🔍 特徵 UUID: \(characteristic.uuid)")
            print("📊 特徵屬性: \(characteristic.properties)")
            print("📊 是否可通知: \(characteristic.properties.contains(.notify))")
            print("📊 是否可指示: \(characteristic.properties.contains(.indicate))")
            print("📊 是否可讀: \(characteristic.properties.contains(.read))")
            print("📊 是否可寫: \(characteristic.properties.contains(.write))")
            
            // 根據 UUID 判斷是哪一個 Characteristic
            if characteristic.uuid == CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") {
                actionTypeCharacteristic = characteristic
                print("✅ ActionType characteristic set.")
            } else if characteristic.uuid == CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") {
                receiveCharacteristic = characteristic
                print("✅ Receive characteristic set.")
                // 訂閱 indicate 特徵
                print("📡 嘗試訂閱通知...")
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            // 確保在主線程更新 UI
            DispatchQueue.main.async {
                self.isCorrectDevice = true
                self.connectionStatus = .connected
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ 接收數據錯誤: \(error.localizedDescription)")
            return
        }
        
        if characteristic == receiveCharacteristic {
            guard let data = characteristic.value else {
                print("❌ 接收到的數據為空")
                return
            }
            
            print("📥 收到原始數據: \(data as NSData)")
            print("📥 數據長度: \(data.count) bytes")
            
            // 解析單一 byte 的數據
            if data.count == 1 {
                let byte = data.first!
                let count = Int(byte) - 48  // 將 ASCII 轉換為數字 (0x30 = '0' 的 ASCII 碼)
                DispatchQueue.main.async {
                    self.currentCount = count
                    print("📊 解析後的次數: \(self.currentCount)")
                }
            } else {
                print("⚠️ 數據格式不正確")
            }
        }
    }
    
    // 添加 indicate 確認回調
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ 設置通知狀態失敗: \(error.localizedDescription)")
            return
        }
        
        if characteristic == receiveCharacteristic {
            print("✅ 成功設置通知狀態")
            print("📊 通知是否啟用: \(characteristic.isNotifying)")
        }
    }
    
    func sendActionType(_ action: String, count: UInt32) {
        guard let peripheral = connectedDevice else {
            print("❌ 尚未連接到裝置 (connectedDevice 為 nil)")
            return
        }

        guard let characteristic = actionTypeCharacteristic else {
            print("❌ 尚未找到 characteristic (actionTypeCharacteristic 為 nil)")
            return
        }

        guard let actionData = action.data(using: .utf8) else {
            print("❌ 無法將 action 字串轉換為資料 (actionData 為 nil)")
            return
        }
    
        var countValue = count.littleEndian
        let countData = Data(bytes: &countValue, count: MemoryLayout<UInt32>.size)
    
        let combinedData = actionData + countData
        peripheral.writeValue(combinedData, for: characteristic, type: .withResponse)
        
        print("📤 傳送動作類型'\(action)'成功")
    }
}

struct blePairingView: View {
    @Binding var path: [PlanRoute]
    let plan: WorkoutPlan
    @EnvironmentObject var bluetoothManager: BluetoothManager

    var body: some View {
        VStack {
            if bluetoothManager.connectionStatus == .connected && bluetoothManager.isCorrectDevice {
                // 連接成功後自動跳轉
                WaitingView(path: $path, plan: plan)
                    .environmentObject(bluetoothManager)
            } else {
                Text("請先開啟藍芽連接手環")
                    .font(.title3)
                    .foregroundStyle(Color(.darkBackground))
                    .padding()
                    .overlay(
                            RoundedRectangle(cornerRadius: 20)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundStyle(Color(.darkBackground))
                    )
                
                    Image("chicken_strong")
                        .resizable()
                        .frame(width: 250, height: 300)
                    .padding()
                
                Button(action: {
                        if let url = URL(string: "App-Prefs:root=Bluetooth") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "applewatch.radiowaves.left.and.right")
                                .foregroundStyle(Color(.darkBackground))
                            Text("前往設定開啟藍牙")
                                .font(.headline)
                                .foregroundColor(Color(.darkBackground))
                        }
                    }
                    .padding()
                    .frame(width: 300, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(lineWidth: 2)
                            .foregroundStyle(Color(.darkBackground))
                    )
                    .background(Color(.mint))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    if bluetoothManager.connectionStatus == .connecting {
                        Text("正在連接...")
                            .font(.headline)
                            .foregroundColor(Color(.darkBackground))
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundStyle(Color(.darkBackground))
                            )
                    } else if bluetoothManager.connectionStatus == .failed {
                        Text("連接失敗")
                            .font(.headline)
                            .foregroundColor(Color(.darkBackground))
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundStyle(Color(.darkBackground))
                            )
                    } else if bluetoothManager.connectionStatus == .wrongDevice {
                        Text("請連接正確的裝置")
                            .font(.headline)
                            .foregroundColor(Color(.darkBackground))
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundStyle(Color(.darkBackground))
                            )
                    }
                }
            }
            .onChange(of: bluetoothManager.connectionStatus) { newStatus in
                if newStatus == .connected && bluetoothManager.isCorrectDevice {
                        path.append(.workout(plan: plan, exerciseIndex: 0, setIndex: 0))
                }
            }
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.background))
        
    }
}

struct WaitingView: View {
    @State private var timeRemaining = 3
    @State private var hasSentAction = false
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Binding var path: [PlanRoute]
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let plan: WorkoutPlan
    
    var body: some View {
        VStack {
            Text("請站穩並保持靜止")
                .font(.title3)
                .foregroundStyle(Color(.darkBackground))
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius:20)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(Color(.darkBackground))
                )
            Image("chicken_strong").resizable()
                .frame(width:250,height:300)
                .padding()
            Text("\(timeRemaining)秒後開始運動")
                .font(.headline)
                .foregroundColor(Color(.darkBackground))
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(Color(.darkBackground))
                )
        }
        .ignoresSafeArea()
        .frame(maxWidth:.infinity,maxHeight: .infinity)
        .background(Color.brown)
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else if !hasSentAction {
                bluetoothManager.sendActionType("1", count: 10)
                hasSentAction = true
                path.append(.workout(plan: plan, exerciseIndex: 0, setIndex: 0))
            }
        }
    }
}



//#Preview {
//    blePairingView(path: .constant([]))
//        .environmentObject(BluetoothManager())
//}


