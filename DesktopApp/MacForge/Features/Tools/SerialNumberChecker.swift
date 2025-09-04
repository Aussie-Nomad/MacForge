//
//  SerialNumberChecker.swift
//  MacForge
//
//  Serial Number Checker tool for looking up Mac device information,
//  warranty status, and estimated value based on serial numbers.
//

import SwiftUI

// MARK: - Apple Warranty Response
struct AppleWarrantyResponse: Codable {
    let serialNumber: String
    let productName: String?
    let warrantyStatus: String?
    let warrantyExpirationDate: String?
    let isEligibleForPurchase: Bool?
    let isEligibleForCoverage: Bool?
    let coverageType: String?
    
    var isCovered: Bool {
        return isEligibleForCoverage ?? false
    }
    
    var isExpired: Bool {
        guard let expirationDate = warrantyExpirationDate else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: expirationDate) {
            return date < Date()
        }
        return false
    }
}

// MARK: - Device Models
struct DeviceInfo: Codable, Identifiable {
    var id = UUID()
    let serialNumber: String
    let model: String
    let modelIdentifier: String
    let purchaseDate: Date?
    let purchasePrice: Double?
    let warrantyStatus: WarrantyStatus
    let estimatedValue: Double?
    let specifications: DeviceSpecifications?
    let condition: DeviceCondition?
    let currency: Currency?
    let tradeInValues: TradeInValues?
    let suggestedPrice: Double?
    
    enum WarrantyStatus: String, Codable, CaseIterable {
        case active = "Active"
        case expired = "Expired"
        case unknown = "Unknown"
        case appleCarePlus = "AppleCare+"
        case limitedWarranty = "Limited Warranty"
        case notCovered = "Not Covered"
        
        var color: Color {
            switch self {
            case .active, .appleCarePlus:
                return .green
            case .expired:
                return .red
            case .limitedWarranty:
                return .orange
            case .notCovered:
                return .red
            case .unknown:
                return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .active, .appleCarePlus:
                return "checkmark.shield.fill"
            case .expired:
                return "xmark.shield"
            case .limitedWarranty:
                return "exclamationmark.shield"
            case .notCovered:
                return "xmark.shield"
            case .unknown:
                return "questionmark.shield"
            }
        }
    }
}

struct DeviceSpecifications: Codable {
    let processor: String?
    let memory: String?
    let storage: String?
    let graphics: String?
    let display: String?
    let year: Int?
    let generation: String?
}

enum DeviceCondition: String, CaseIterable, Codable {
    case new = "✨ New, < 1 Year"
    case good = "👌 Good, 2 - 3 Year"
    case fair = "🎡 FAIR, 4+ Years"
    case needsRepair = "🔧 NEEDS REPAIR"
    
    var multiplier: Double {
        switch self {
        case .new: return 1.0      // 100%
        case .good: return 0.85   // 85%
        case .fair: return 0.70   // 70%
        case .needsRepair: return 0.55 // 55%
        }
    }
}

enum Currency: String, CaseIterable, Codable {
    case uk = "UK"
    case sing = "SING"
    case sa = "SA"
    case us = "US"
    
    var symbol: String {
        switch self {
        case .uk: return "£"
        case .sing: return "S$"
        case .sa: return "R"
        case .us: return "$"
        }
    }
}

struct TradeInValues: Codable {
    let musicMagpie: Double
    let iStoreTradeIn: Double
    let appleTradeIn: Double
    let currency: Currency
    
    var average: Double {
        return (musicMagpie + iStoreTradeIn + appleTradeIn) / 3.0
    }
}

// MARK: - Serial Number Service
@MainActor
class SerialNumberService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Apple's public warranty API endpoint
    private let appleWarrantyURL = "https://checkcoverage.apple.com/api/v1/coverage"
    
    func getDeviceInfoFromSerial(_ serialNumber: String, purchaseDate: Date?, purchasePrice: Double?, condition: DeviceCondition?, currency: Currency?) async -> DeviceInfo? {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // Try to get warranty info from Apple's public API
        if let warrantyResponse = await getAppleWarrantyInfo(serialNumber) {
            // Successfully got warranty info
            let deviceInfo = DeviceInfo(
                serialNumber: serialNumber,
                model: warrantyResponse.productName ?? "Mac",
                modelIdentifier: "Mac14,2", // Would parse from serial number
                purchaseDate: purchaseDate,
                purchasePrice: purchasePrice,
                warrantyStatus: determineWarrantyStatus(from: warrantyResponse),
                estimatedValue: nil,
                specifications: DeviceSpecifications(
                    processor: "Apple M2", // Would get from database
                    memory: "16GB Unified Memory",
                    storage: "512GB SSD",
                    graphics: "Integrated Apple M2",
                    display: "13-inch Liquid Retina display",
                    year: 2022,
                    generation: "M2"
                ),
                condition: condition,
                currency: currency,
                tradeInValues: nil,
                suggestedPrice: nil
            )
            
            return deviceInfo
        } else {
            // Apple API failed, provide helpful error message
            errorMessage = "Unable to verify warranty status with Apple. This could be due to:\n• Invalid serial number\n• Apple's service being temporarily unavailable\n• Network connectivity issues\n\nShowing estimated device information instead."
            
            // Enhanced fallback: Parse serial number for device identification
            let deviceInfo = createDeviceInfoFromSerial(serialNumber, purchaseDate: purchaseDate, purchasePrice: purchasePrice, condition: condition, currency: currency)
            
            return deviceInfo
        }
    }
    
    private func createDeviceInfoFromSerial(_ serialNumber: String, purchaseDate: Date?, purchasePrice: Double?, condition: DeviceCondition?, currency: Currency?) -> DeviceInfo {
        // Try to find device in our comprehensive database first
        if let appleDevice = AppleDeviceDatabase.findDevice(by: serialNumber) {
            return DeviceInfo(
                serialNumber: serialNumber,
                model: appleDevice.modelName,
                modelIdentifier: appleDevice.modelIdentifier,
                purchaseDate: purchaseDate,
                purchasePrice: purchasePrice,
                warrantyStatus: .unknown,
                estimatedValue: nil,
                specifications: appleDevice.specifications,
                condition: condition,
                currency: currency,
                tradeInValues: nil,
                suggestedPrice: nil
            )
        }
        
        // Fallback to parsing serial number manually
        let deviceSpecs = parseSerialNumberForDevice(serialNumber)
        
        return DeviceInfo(
            serialNumber: serialNumber,
            model: deviceSpecs.model,
            modelIdentifier: deviceSpecs.modelIdentifier,
            purchaseDate: purchaseDate,
            purchasePrice: purchasePrice,
            warrantyStatus: .unknown,
            estimatedValue: nil,
            specifications: deviceSpecs.specifications,
            condition: condition,
            currency: currency,
            tradeInValues: nil,
            suggestedPrice: nil
        )
    }
    
    private func parseSerialNumberForDevice(_ serial: String) -> (model: String, modelIdentifier: String, specifications: DeviceSpecifications) {
        // Apple's serial number format: AABCCDDDEEF
        // AA = Factory code, B = Year, CC = Week, DDD = Unique ID, EE = Model, F = Color
        
        guard serial.count >= 11 else {
            return ("Unknown Mac", "Unknown", DeviceSpecifications(
                processor: "Unknown",
                memory: "Unknown",
                storage: "Unknown",
                graphics: "Unknown",
                display: "Unknown",
                year: Calendar.current.component(.year, from: Date()),
                generation: "Unknown"
            ))
        }
        
        let yearChar = String(serial[serial.index(serial.startIndex, offsetBy: 2)])
        let year = parseYearFromSerial(yearChar)
        
        // Extract model identifier from serial pattern
        let modelCode = String(serial[serial.index(serial.startIndex, offsetBy: 8)..<serial.index(serial.startIndex, offsetBy: 10)])
        let modelIdentifier = getModelIdentifier(from: modelCode, year: year)
        
        // Get device specifications based on year and model
        let specs = getDeviceSpecsForYearAndModel(year: year, modelCode: modelCode)
        
        return (specs.model, modelIdentifier, specs.specifications)
    }
    
    private func parseYearFromSerial(_ yearChar: String) -> Int {
        // Apple's year encoding in serial numbers
        let currentYear = Calendar.current.component(.year, from: Date())
        let yearMapping: [String: Int] = [
            "C": 2010, "D": 2011, "F": 2012, "G": 2013,
            "H": 2014, "J": 2015, "K": 2016, "L": 2017,
            "M": 2018, "N": 2019, "P": 2020, "Q": 2021,
            "R": 2022, "S": 2023, "T": 2024, "V": 2025
        ]
        
        return yearMapping[yearChar] ?? currentYear
    }
    
    private func getModelIdentifier(from modelCode: String, year: Int) -> String {
        // Map model codes to Apple's public model identifiers
        let modelMapping: [String: String] = [
            "1C": "MacBookPro18,1", // M1 Pro 14"
            "1D": "MacBookPro18,2", // M1 Max 14"
            "1E": "MacBookPro18,3", // M1 Pro 16"
            "1F": "MacBookPro18,4", // M1 Max 16"
            "2A": "MacBookPro19,1", // M2 Pro 13"
            "2B": "MacBookPro19,2", // M2 13"
            "3A": "MacBookPro20,1", // M2 Pro 14"
            "3B": "MacBookPro20,2", // M2 Max 14"
            "3C": "MacBookPro20,3", // M2 Pro 16"
            "3D": "MacBookPro20,4"  // M2 Max 16"
        ]
        
        return modelMapping[modelCode] ?? "MacBookPro\(year),1"
    }
    
    private func getDeviceSpecsForYearAndModel(year: Int, modelCode: String) -> (model: String, specifications: DeviceSpecifications) {
        // Determine device specifications based on year and model code
        if year >= 2022 {
            if modelCode.hasPrefix("3") {
                // M2 Pro/Max models
                return ("MacBook Pro (14-inch, M2 Pro, \(year))", DeviceSpecifications(
                    processor: "Apple M2 Pro",
                    memory: "16GB Unified Memory",
                    storage: "512GB SSD",
                    graphics: "Integrated Apple M2 Pro",
                    display: "14-inch Liquid Retina XDR display",
                    year: year,
                    generation: "M2"
                ))
            } else if modelCode.hasPrefix("2") {
                // M2 models
                return ("MacBook Pro (13-inch, M2, \(year))", DeviceSpecifications(
                    processor: "Apple M2",
                    memory: "16GB Unified Memory",
                    storage: "512GB SSD",
                    graphics: "Integrated Apple M2",
                    display: "13-inch Liquid Retina display",
                    year: year,
                    generation: "M2"
                ))
            }
        } else if year >= 2021 {
            if modelCode.hasPrefix("1") {
                // M1 Pro/Max models
                return ("MacBook Pro (14-inch, M1 Pro, \(year))", DeviceSpecifications(
                    processor: "Apple M1 Pro",
                    memory: "16GB Unified Memory",
                    storage: "512GB SSD",
                    graphics: "Integrated Apple M1 Pro",
                    display: "14-inch Liquid Retina XDR display",
                    year: year,
                    generation: "M1"
                ))
            }
        }
        
        // Fallback for older models
        return ("MacBook Pro (\(year))", DeviceSpecifications(
            processor: "Intel Core i5",
            memory: "16GB LPDDR3",
            storage: "512GB SSD",
            graphics: "Intel Iris Plus Graphics",
            display: "13-inch Retina display",
            year: year,
            generation: "Intel"
        ))
    }
    
    private func getAppleWarrantyInfo(_ serialNumber: String) async -> AppleWarrantyResponse? {
        let requestBody = [
            "serialNumber": serialNumber,
            "countryCode": "US" // Default to US, could be made configurable
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Failed to create JSON data")
            return nil
        }
        
        var request = URLRequest(url: URL(string: appleWarrantyURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response type")
                return nil
            }
            
            print("Apple API response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Apple API success response: \(responseString)")
                }
                
                do {
                    let warrantyResponse = try JSONDecoder().decode(AppleWarrantyResponse.self, from: data)
                    return warrantyResponse
                } catch {
                    print("JSON decode error: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Raw response: \(responseString)")
                    }
                    return nil
                }
            } else if httpResponse.statusCode == 404 {
                // Device not found - this is normal for invalid serials
                print("Device not found (404)")
                return nil
            } else {
                // Log the error for debugging
                print("Apple API error: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Error response: \(responseString)")
                }
                return nil
            }
        } catch {
            // Log the error for debugging
            print("Apple API request failed: \(error)")
            return nil
        }
    }
    
    private func determineWarrantyStatus(from response: AppleWarrantyResponse) -> DeviceInfo.WarrantyStatus {
        if response.isCovered {
            if response.isExpired {
                return .expired
            } else {
                return .active
            }
        } else {
            return .notCovered
        }
    }
    
    func calculateSuggestedPrice(
        purchaseDate: Date,
        purchasePrice: Double,
        tradeInValues: TradeInValues,
        condition: DeviceCondition,
        currency: Currency
    ) -> Double {
        // Calculate depreciation (5-year 20% loss)
        let currentDate = Date()
        let daysSincePurchase = Calendar.current.dateComponents([.day], from: purchaseDate, to: currentDate).day ?? 0
        let maxDays = 5 * 365
        let maxDepreciation = purchasePrice * 0.20
        
        let depreciation = daysSincePurchase >= maxDays ? maxDepreciation : (maxDepreciation * Double(daysSincePurchase) / Double(maxDays))
        
        // Calculate base value: (trade-in + depreciation / 4)
        let baseValue = (tradeInValues.average + depreciation / 4.0)
        
        // Apply condition multiplier
        let suggestedPrice = baseValue * condition.multiplier
        
        return suggestedPrice
    }
    
    func getTradeInValues(for model: String, currency: Currency) -> TradeInValues {
        // This would integrate with actual trade-in services
        // For now, return estimated values based on model and currency
        let baseValue: Double
        switch currency {
        case .uk: baseValue = 800.0
        case .sing: baseValue = 1400.0
        case .sa: baseValue = 15000.0
        case .us: baseValue = 1000.0
        }
        
        return TradeInValues(
            musicMagpie: baseValue * 0.8,
            iStoreTradeIn: baseValue * 0.9,
            appleTradeIn: baseValue * 0.85,
            currency: currency
        )
    }
    
    func getCurrentDeviceSerial() -> String? {
        #if os(macOS)
        let task = Process()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPHardwareDataType", "-xml"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
               let hardware = plist["SPHardwareDataType"] as? [[String: Any]],
               let firstItem = hardware.first,
               let serial = firstItem["serial_number"] as? String {
                return serial
            }
        } catch {
            return nil
        }
        #endif
        return nil
    }
}

// MARK: - Serial Number Checker View
struct SerialNumberCheckerView: View {
    @StateObject private var serialNumberService = SerialNumberService()
    
    @State private var serialNumber = ""
    @State private var purchaseDate = Date()
    @State private var purchasePrice = ""
    @State private var selectedCondition = DeviceCondition.good
    @State private var selectedCurrency = Currency.us
    @State private var musicMagpieValue = ""
    @State private var iStoreValue = ""
    @State private var appleValue = ""
    @State private var deviceInfo: DeviceInfo?
    @State private var valuationDeviceInfo: DeviceInfo?
    @State private var showingValuationResults = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Device Foundry Lookup")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("Look up device information and calculate valuations")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Serial Number Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Serial Number")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        TextField("Enter serial number", text: $serialNumber)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                        
                        Button("Current Device") {
                            if let currentSerial = getCurrentDeviceSerial() {
                                serialNumber = currentSerial
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                    }
                    
                    Text("Enter a Mac serial number to look up device information")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Purchase Information
                VStack(alignment: .leading, spacing: 12) {
                    Text("Purchase Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Purchase Date")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Purchase Price")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $purchasePrice)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                
                // Device Condition and Currency
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Device Condition")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Condition", selection: $selectedCondition) {
                            ForEach(DeviceCondition.allCases, id: \.self) { condition in
                                Text(condition.rawValue).tag(condition)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Currency")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Currency", selection: $selectedCurrency) {
                            ForEach(Currency.allCases, id: \.self) { currency in
                                Text("\(currency.symbol) \(currency.rawValue)").tag(currency)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                // Trade-in Values
                VStack(alignment: .leading, spacing: 12) {
                    Text("Trade-in Values")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Enter the trade-in values from each site:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Music Magpie")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $musicMagpieValue)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("iStore Trade In")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $iStoreValue)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Apple Trade In")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $appleValue)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Look Up Device") {
                        Task {
                            await lookUpDevice()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(serialNumber.isEmpty)
                    
                    if deviceInfo != nil {
                        Button("Calculate Valuation") {
                            calculateValuation(for: deviceInfo!)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .disabled(musicMagpieValue.isEmpty && iStoreValue.isEmpty && appleValue.isEmpty)
                    }
                }
                
                // Device Information Display
                if let deviceInfo = deviceInfo {
                    DeviceInfoView(deviceInfo: deviceInfo)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Loading and Error States
                if serialNumberService.isLoading {
                    ProgressView("Looking up device...")
                        .padding()
                }
                
                if let errorMessage = serialNumberService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingValuationResults) {
            if let valuationDeviceInfo = valuationDeviceInfo {
                ValuationResultsSheet(deviceInfo: valuationDeviceInfo)
            }
        }
    }
    
    // MARK: - Actions
    
    private func lookUpDevice() async {
        let price = Double(purchasePrice) ?? 0.0
        
        deviceInfo = await serialNumberService.getDeviceInfoFromSerial(
            serialNumber,
            purchaseDate: purchaseDate,
            purchasePrice: price > 0 ? price : nil,
            condition: selectedCondition,
            currency: selectedCurrency
        )
    }
    
    private func calculateValuation(for deviceInfo: DeviceInfo) {
        guard let musicMagpie = Double(musicMagpieValue),
              let iStore = Double(iStoreValue),
              let apple = Double(appleValue),
              let purchaseDate = deviceInfo.purchaseDate,
              let purchasePrice = deviceInfo.purchasePrice else {
            return
        }
        
        let tradeInValues = TradeInValues(
            musicMagpie: musicMagpie,
            iStoreTradeIn: iStore,
            appleTradeIn: apple,
            currency: selectedCurrency
        )
        
        let suggestedPrice = serialNumberService.calculateSuggestedPrice(
            purchaseDate: purchaseDate,
            purchasePrice: purchasePrice,
            tradeInValues: tradeInValues,
            condition: selectedCondition,
            currency: selectedCurrency
        )
        
        // Create valuation device info
        let valuationInfo = DeviceInfo(
            serialNumber: deviceInfo.serialNumber,
            model: deviceInfo.model,
            modelIdentifier: deviceInfo.modelIdentifier,
            purchaseDate: deviceInfo.purchaseDate,
            purchasePrice: deviceInfo.purchasePrice,
            warrantyStatus: deviceInfo.warrantyStatus,
            estimatedValue: deviceInfo.estimatedValue,
            specifications: deviceInfo.specifications,
            condition: deviceInfo.condition,
            currency: deviceInfo.currency,
            tradeInValues: tradeInValues,
            suggestedPrice: suggestedPrice
        )
        
        valuationDeviceInfo = valuationInfo
        showingValuationResults = true
    }
    
    private func getCurrentDeviceSerial() -> String? {
        #if os(macOS)
        let task = Process()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPHardwareDataType", "-xml"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
               let hardware = plist["SPHardwareDataType"] as? [[String: Any]],
               let firstItem = hardware.first,
               let serial = firstItem["serial_number"] as? String {
                return serial
            }
        } catch {
            return nil
        }
        #endif
        return nil
    }
}

// MARK: - Device Info View

struct DeviceInfoView: View {
    let deviceInfo: DeviceInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Device Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Model", value: deviceInfo.model)
                InfoRow(label: "Serial Number", value: deviceInfo.serialNumber)
                InfoRow(label: "Model ID", value: deviceInfo.modelIdentifier)
                
                if let purchaseDate = deviceInfo.purchaseDate {
                    InfoRow(label: "Purchase Date", value: purchaseDate.formatted(date: .abbreviated, time: .omitted))
                }
                
                if let purchasePrice = deviceInfo.purchasePrice {
                    InfoRow(label: "Purchase Price", value: String(format: "%.2f", purchasePrice))
                }
                
                InfoRow(label: "Warranty", value: deviceInfo.warrantyStatus.rawValue)
                    .foregroundColor(deviceInfo.warrantyStatus.color)
                
                if let specs = deviceInfo.specifications {
                    if let processor = specs.processor {
                        InfoRow(label: "Processor", value: processor)
                    }
                    if let memory = specs.memory {
                        InfoRow(label: "Memory", value: memory)
                    }
                    if let storage = specs.storage {
                        InfoRow(label: "Storage", value: storage)
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Valuation Results Sheet

struct ValuationResultsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let deviceInfo: DeviceInfo
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Valuation Results")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Device: \(deviceInfo.model)")
                    .font(.headline)
                
                if let purchaseDate = deviceInfo.purchaseDate {
                    Text("Purchase Date: \(purchaseDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                }
                
                if let purchasePrice = deviceInfo.purchasePrice {
                    Text("Original Price: \(deviceInfo.currency?.symbol ?? "$")\(String(format: "%.2f", purchasePrice))")
                        .font(.subheadline)
                }
                
                if let condition = deviceInfo.condition {
                    Text("Condition: \(condition.rawValue)")
                        .font(.subheadline)
                }
                
                if let tradeInValues = deviceInfo.tradeInValues {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Trade-in Values:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Music Magpie: \(tradeInValues.currency.symbol)\(String(format: "%.2f", tradeInValues.musicMagpie))")
                        Text("iStore Trade In: \(tradeInValues.currency.symbol)\(String(format: "%.2f", tradeInValues.iStoreTradeIn))")
                        Text("Apple Trade In: \(tradeInValues.currency.symbol)\(String(format: "%.2f", tradeInValues.appleTradeIn))")
                        Text("Average: \(tradeInValues.currency.symbol)\(String(format: "%.2f", tradeInValues.average))")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                if let purchaseDate = deviceInfo.purchaseDate,
                   let purchasePrice = deviceInfo.purchasePrice {
                    let daysSincePurchase = Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0
                    let maxDays = 5 * 365
                    let maxDepreciation = purchasePrice * 0.20
                    let depreciation = daysSincePurchase >= maxDays ? maxDepreciation : (maxDepreciation * Double(daysSincePurchase) / Double(maxDays))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Depreciation (5-year 20% loss):")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Days since purchase: \(daysSincePurchase)")
                            .font(.caption)
                        Text("Depreciation: \(deviceInfo.currency?.symbol ?? "$")\(String(format: "%.2f", depreciation))")
                            .font(.caption)
                        Text("Remaining value: \(deviceInfo.currency?.symbol ?? "$")\(String(format: "%.2f", purchasePrice - depreciation))")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                if let suggestedPrice = deviceInfo.suggestedPrice {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggested Price:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(deviceInfo.currency?.symbol ?? "$")\(String(format: "%.2f", suggestedPrice))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
        .frame(width: 450, height: 500)
    }
}

#Preview {
    SerialNumberCheckerView()
}
