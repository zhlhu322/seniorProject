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
    @Published var isDeviceReady = false  // 新增：裝置是否準備好
    
    var actionTypeCharacteristic: CBCharacteristic?
    var receiveCharacteristic: CBCharacteristic?
    
    // 目標裝置名稱關鍵字
    private let targetDeviceName = "micro:bit"
    private let targetCount: Int = 10 // 目標次數
    
    // 定義 Service 和 Characteristic UUIDs
    private let serviceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    private let rxCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")  // 接收
    private let txCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")  // 傳送
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case failed
        case wrongDevice
    }
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)  // 使用主線程
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            switch central.state {
            case .poweredOn:
                self.isBluetoothEnabled = true
                self.checkConnectedDevices()
                self.startScanning()
            case .poweredOff, .unauthorized, .unsupported, .resetting, .unknown:
                self.isBluetoothEnabled = false
                self.connectionStatus = .disconnected
                self.isDeviceReady = false
            @unknown default:
                self.isBluetoothEnabled = false
                self.connectionStatus = .disconnected
                self.isDeviceReady = false
            }
        }
    }
    
    func checkConnectedDevices() {
        let connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [serviceUUID])
        
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
            print("🔍 開始掃描裝置...")
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("發現裝置: \(peripheral.name ?? "Unknown")")
        print("裝置 UUID: \(peripheral.identifier.uuidString)")
        print("RSSI: \(RSSI)")
        
        // 如果發現目標裝置，立即嘗試連接
        if let deviceName = peripheral.name, deviceName.contains(targetDeviceName) {
            print("找到目標裝置，嘗試連接")
            centralManager.stopScan()  // 停止掃描
            connect(to: peripheral)
        }
        
        if !discoveredDevices.contains(peripheral) {
            discoveredDevices.append(peripheral)
        }
    }
    
    func connect(to peripheral: CBPeripheral) {
        print("開始連接裝置: \(peripheral.name ?? "Unknown")")
        connectionStatus = .connecting
        isDeviceReady = false
        
        peripheral.delegate = self
        connectedDevice = peripheral
        
        centralManager.connect(peripheral, options: [
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
        ])
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("已連接到裝置: \(peripheral.name ?? "Unknown")")
        print("裝置 UUID: \(peripheral.identifier.uuidString)")
        
        DispatchQueue.main.async {
            if let deviceName = peripheral.name, deviceName.contains(self.targetDeviceName) {
                print("確認是目標裝置")
                self.isCorrectDevice = true
                self.connectedDevice = peripheral
                self.connectionStatus = .connected
                
                // 開始發現服務
                peripheral.discoverServices([self.serviceUUID])
            } else {
                print("不是目標裝置")
                self.isCorrectDevice = false
                self.connectionStatus = .wrongDevice
                central.cancelPeripheralConnection(peripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.connectionStatus = .failed
            self.isDeviceReady = false
            print("連接失敗: \(error?.localizedDescription ?? "未知錯誤")")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.connectionStatus = .disconnected
            self.connectedDevice = nil
            self.isCorrectDevice = false
            self.isDeviceReady = false
            
            if let error = error {
                print("裝置斷開連接，錯誤: \(error.localizedDescription)")
            } else {
                print("裝置正常斷開連接")
            }
            
            // 重新開始掃描
            self.startScanning()
        }
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
            if service.uuid == serviceUUID {
                print("✅ 找到目標服務，開始發現特徵...")
                peripheral.discoverCharacteristics([rxCharacteristicUUID, txCharacteristicUUID], for: service)
            }
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
        
        print("📱 在服務 \(service.uuid) 中發現 \(characteristics.count) 個特徵")
        
        var foundRx = false
        var foundTx = false
        
        for characteristic in characteristics {
            print("🔍 特徵 UUID: \(characteristic.uuid)")
            print("📊 特徵屬性: \(characteristic.properties.rawValue)")
            
            if characteristic.uuid == rxCharacteristicUUID {
                receiveCharacteristic = characteristic
                print("✅ 找到接收特徵 (RX)")
                
                if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                    print("📡 嘗試訂閱通知...")
                    peripheral.setNotifyValue(true, for: characteristic)
                    foundRx = true
                } else {
                    print("⚠️ 接收特徵不支援通知")
                }
                
            } else if characteristic.uuid == txCharacteristicUUID {
                actionTypeCharacteristic = characteristic
                print("✅ 找到傳送特徵 (TX)")
                foundTx = true
            }
        }
        
        // 當兩個特徵都找到時，標記裝置準備好
        if foundRx && foundTx {
            DispatchQueue.main.async {
                print("🎉 所有特徵都已設置完成")
                // 先不要立即設為 ready，等收到通知訂閱確認
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("⚠️ 設置通知狀態失敗: \(error.localizedDescription)")
            return
        }
        
        if characteristic.uuid == rxCharacteristicUUID {
            DispatchQueue.main.async {
                if characteristic.isNotifying {
                    print("✅ 成功訂閱通知，裝置準備完成")
                    self.isDeviceReady = true
                    
                    // 可選：發送一個測試訊息確認連接
                    self.sendConnectionTest()
                } else {
                    print("❌ 通知訂閱失敗")
                    self.isDeviceReady = false
                }
            }
        }
    }
    
    // 新增：發送連接測試
    func sendConnectionTest() {
        print("📤 發送連接測試訊息")
        let testMessage = "ping".data(using: .utf8)!
        //sendData(testMessage)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("⚠️ 接收資料錯誤: \(error.localizedDescription)")
            return
        }
        
        print("📱 收到資料的 Characteristic UUID: \(characteristic.uuid)")
        
        guard characteristic.uuid == rxCharacteristicUUID else {
            print("⚠️ 不是預期的 characteristic，忽略")
            return
        }
        
        guard let data = characteristic.value else {
            print("⚠️ 接收到的資料為空")
            return
        }
        
        print("📥 收到原始資料: \(data as NSData)")
        print("📥 資料長度: \(data.count) bytes")
        print("📥 十六進制: \(data.map { String(format: "%02X", $0) }.joined(separator: " "))")
        
        // 嘗試多種編碼方式解析字串
        var receivedString: String?
        
        // 1. 嘗試 UTF-8
        if let utf8String = String(data: data, encoding: .utf8) {
            receivedString = utf8String.trimmingCharacters(in: .whitespacesAndNewlines)
            print("📥 UTF-8 解析: '\(receivedString!)'")
        }
        // 2. 嘗試 ASCII
        else if let asciiString = String(data: data, encoding: .ascii) {
            receivedString = asciiString.trimmingCharacters(in: .whitespacesAndNewlines)
            print("📥 ASCII 解析: '\(receivedString!)'")
        }
        // 3. 嘗試 ISO Latin 1
        else if let latin1String = String(data: data, encoding: .isoLatin1) {
            receivedString = latin1String.trimmingCharacters(in: .whitespacesAndNewlines)
            print("📥 ISO Latin 1 解析: '\(receivedString!)'")
        }
        
        if let message = receivedString {
            handleReceivedMessage(message)
        } else {
            // 如果無法解析為字串，檢查是否為數字
            handleReceivedData(data)
        }
    }
    
    // 處理接收到的文字訊息
    private func handleReceivedMessage(_ message: String) {
        print("📨 處理訊息: '\(message)'")
        
        DispatchQueue.main.async {
            switch message.lowercased() {
            case "connected":
                print("✅ 收到連接確認")
                self.isDeviceReady = true
                
            case "end":
                print("✅ 收到結束確認")
                // 處理結束邏輯
                
            default:
                print("📥 收到未知訊息: '\(message)'")
                
                // 檢查是否為數字字串
                if let count = Int(message) {
                    self.currentCount = count
                    print("📊 更新計數: \(count)")
                }
            }
        }
    }
    
    // 處理接收到的原始資料
    private func handleReceivedData(_ data: Data) {
        print("🔍 處理原始資料")
        
        if data.count == 1 {
            let byte = data.first!
            print("📊 收到單一 byte: \(byte) (0x\(String(byte, radix: 16)))")
            
            // 檢查是否為 ASCII 數字
            if byte >= 48 && byte <= 57 {
                let count = Int(byte) - 48
                DispatchQueue.main.async {
                    self.currentCount = count
                    print("📊 解析後的計數: \(self.currentCount)")
                }
            }
        }
    }
    
    // 發送資料的通用方法
    func sendData(_ dataa: Data) {
        guard let peripheral = connectedDevice,
              let characteristic = actionTypeCharacteristic else {
            print("⚠️ 裝置或特徵未準備好")
            return
        }
        
        let bytes: [UInt8] = [0x31, 0x0A]
        let data = Data(bytes)
        print("📤 發送資料 (\(bytes.count) bytes): \(bytes.map { String(format: "%02X", $0) }.joined(separator: " "))")
        print("dataa count: \(dataa.count)")
        print("dataa hex: \(dataa.map { String(format: "%02X", $0) }.joined(separator: " "))")
        print("data count: \(data.count)")
        print("data hex: \(data.map { String(format: "%02X", $0) }.joined(separator: " "))")
        peripheral.writeValue(dataa, for: characteristic, type: .withResponse)
    }
    
    func sendActionType(_ str: String) {
        guard isDeviceReady else {
            print("⚠️ 裝置尚未準備好，無法發送")
            return
        }
        
        var transformed: [UInt8] = []
        for s in str.utf8 {   // 直接拿 UTF8 編碼值
            transformed.append(s)
        }
        transformed.append(0x0A)  // 加上換行符號
        
        let data = Data(transformed)
        sendData(data)
        
        print("📤 發送動作類型(轉換後): \(transformed.map { String(format: "%02X", $0) }.joined(separator: " "))")
    }



    
    // 發送字串訊息
    func sendMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else {
            print("⚠️ 無法將訊息轉換為資料")
            return
        }
        sendData(data)
        print("📤 發送訊息: '\(message)'")
    }
}

struct blePairingView: View {
    @Binding var path: [PlanRoute]
    let plan: WorkoutPlan
    @EnvironmentObject var bluetoothManager: BluetoothManager
    

    init(path: Binding<[PlanRoute]>, plan: WorkoutPlan) {
            self._path = path
            self.plan = plan
            print("workoutPlan: \(plan)")
    }
    
    var body: some View {
        VStack {
            if bluetoothManager.connectionStatus == .connected && bluetoothManager.isCorrectDevice &&
                bluetoothManager.isDeviceReady{
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
                    .background(Color(.myMint))
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
        .onAppear {
            let idString = plan.details[0].id   // "1"
            bluetoothManager.sendActionType(idString)
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else if !hasSentAction {
                let idString = plan.details[0].id   // "1"
                if let idInt = Int(idString) {
                    print("sending\(Int(idString))")
                    path.append(.workout(plan: plan, exerciseIndex: 0, setIndex: 0))
                }
                hasSentAction = true
            }
        }
    }
}



//#Preview {
//    blePairingView(path: .constant([]))
//        .environmentObject(BluetoothManager())
//}

