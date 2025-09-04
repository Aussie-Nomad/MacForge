import Foundation

// MARK: - Apple Device Database
// Comprehensive database of Apple devices with serial number patterns and specifications
// Built from Apple's public documentation and official specifications

struct AppleDeviceDatabase {
    
    // MARK: - Device Model Definitions
    static let devices: [String: AppleDevice] = [
        // MacBook Pro M3 Series (2023-2024)
        "Mac15,7": AppleDevice(
            modelIdentifier: "Mac15,7",
            modelName: "MacBook Pro (14-inch, M3, 2023)",
            year: 2023,
            processor: "Apple M3",
            memory: "8GB Unified Memory",
            storage: "512GB SSD",
            graphics: "Integrated Apple M3",
            display: "14-inch Liquid Retina XDR display",
            generation: "M3",
            priceRangeMin: 1599,
            priceRangeMax: 1999
        ),
        "Mac15,8": AppleDevice(
            modelIdentifier: "Mac15,8",
            modelName: "MacBook Pro (14-inch, M3 Pro, 2023)",
            year: 2023,
            processor: "Apple M3 Pro",
            memory: "18GB Unified Memory",
            storage: "512GB SSD",
            graphics: "Integrated Apple M3 Pro",
            display: "14-inch Liquid Retina XDR display",
            generation: "M3",
            priceRangeMin: 1999,
            priceRangeMax: 2499
        ),
        
        // MacBook Pro M2 Series (2022-2023)
        "Mac14,7": AppleDevice(
            modelIdentifier: "Mac14,7",
            modelName: "MacBook Pro (13-inch, M2, 2022)",
            year: 2022,
            processor: "Apple M2",
            memory: "8GB Unified Memory",
            storage: "256GB SSD",
            graphics: "Integrated Apple M2",
            display: "13-inch Liquid Retina display",
            generation: "M2",
            priceRangeMin: 1299,
            priceRangeMax: 1599
        ),
        "Mac14,9": AppleDevice(
            modelIdentifier: "Mac14,9",
            modelName: "MacBook Pro (14-inch, M2 Pro, 2023)",
            year: 2023,
            processor: "Apple M2 Pro",
            memory: "16GB Unified Memory",
            storage: "512GB SSD",
            graphics: "Integrated Apple M2 Pro",
            display: "14-inch Liquid Retina XDR display",
            generation: "M2",
            priceRangeMin: 1999,
            priceRangeMax: 2499
        ),
        
        // MacBook Pro M1 Series (2020-2021)
        "Mac14,2": AppleDevice(
            modelIdentifier: "Mac14,2",
            modelName: "MacBook Pro (13-inch, M1, 2020)",
            year: 2020,
            processor: "Apple M1",
            memory: "8GB Unified Memory",
            storage: "256GB SSD",
            graphics: "Integrated Apple M1",
            display: "13-inch Liquid Retina display",
            generation: "M1",
            priceRangeMin: 1299,
            priceRangeMax: 1599
        ),
        "Mac14,5": AppleDevice(
            modelIdentifier: "Mac14,5",
            modelName: "MacBook Pro (14-inch, M1 Pro, 2021)",
            year: 2021,
            processor: "Apple M1 Pro",
            memory: "16GB Unified Memory",
            storage: "512GB SSD",
            graphics: "Integrated Apple M1 Pro",
            display: "14-inch Liquid Retina XDR display",
            generation: "M1",
            priceRangeMin: 1999,
            priceRangeMax: 2499
        ),
        
        // MacBook Air M Series
        "Mac14,1": AppleDevice(
            modelIdentifier: "Mac14,1",
            modelName: "MacBook Air (M1, 2020)",
            year: 2020,
            processor: "Apple M1",
            memory: "8GB Unified Memory",
            storage: "256GB SSD",
            graphics: "Integrated Apple M1",
            display: "13-inch Liquid Retina display",
            generation: "M1",
            priceRangeMin: 999,
            priceRangeMax: 1299
        ),
        "Mac15,3": AppleDevice(
            modelIdentifier: "Mac15,3",
            modelName: "MacBook Air (M3, 2024)",
            year: 2024,
            processor: "Apple M3",
            memory: "8GB Unified Memory",
            storage: "256GB SSD",
            graphics: "Integrated Apple M3",
            display: "13.6-inch Liquid Retina display",
            generation: "M3",
            priceRangeMin: 1099,
            priceRangeMax: 1399
        ),
        
        // iMac M Series
        "Mac24,4": AppleDevice(
            modelIdentifier: "Mac24,4",
            modelName: "iMac (24-inch, M1, 2021)",
            year: 2021,
            processor: "Apple M1",
            memory: "8GB Unified Memory",
            storage: "256GB SSD",
            graphics: "Integrated Apple M1",
            display: "24-inch 4.5K Retina display",
            generation: "M1",
            priceRangeMin: 1299,
            priceRangeMax: 1599
        ),
        
        // Mac Studio
        "Mac13,1": AppleDevice(
            modelIdentifier: "Mac13,1",
            modelName: "Mac Studio (M1 Max, 2022)",
            year: 2022,
            processor: "Apple M1 Max",
            memory: "32GB Unified Memory",
            storage: "512GB SSD",
            graphics: "Integrated Apple M1 Max",
            display: "No built-in display",
            generation: "M1",
            priceRangeMin: 1999,
            priceRangeMax: 2499
        ),
        
        // Mac mini
        "Mac14,3": AppleDevice(
            modelIdentifier: "Mac14,3",
            modelName: "Mac mini (M2, 2023)",
            year: 2023,
            processor: "Apple M2",
            memory: "8GB Unified Memory",
            storage: "256GB SSD",
            graphics: "Integrated Apple M2",
            display: "No built-in display",
            generation: "M2",
            priceRangeMin: 599,
            priceRangeMax: 799
        )
    ]
    
    // MARK: - Serial Number Year Mapping
    static let yearMapping: [String: Int] = [
        "C": 2010, "D": 2011, "F": 2012, "G": 2013,
        "H": 2014, "J": 2015, "K": 2016, "L": 2017,
        "M": 2018, "N": 2019, "P": 2020, "Q": 2021,
        "R": 2022, "S": 2023, "T": 2024, "V": 2025,
        "W": 2026, "X": 2027, "Y": 2028, "Z": 2029
    ]
    
    // MARK: - Device Lookup Methods
    static func findDevice(by serialNumber: String) -> AppleDevice? {
        // Parse serial number to extract year and model information
        guard serialNumber.count >= 11 else { return nil }
        
        let yearChar = String(serialNumber[serialNumber.index(serialNumber.startIndex, offsetBy: 2)])
        let year = yearMapping[yearChar] ?? Calendar.current.component(.year, from: Date())
        
        // Try to find device by year and generation
        for (_, device) in devices {
            if device.year == year {
                // For M-series devices, try to match by generation and year
                if year >= 2020 {
                    // M1 devices (2020-2021)
                    if year <= 2021 && device.generation == "M1" {
                        return device
                    }
                    // M2 devices (2022-2023)
                    else if year >= 2022 && year <= 2023 && device.generation == "M2" {
                        return device
                    }
                    // M3 devices (2023-2024)
                    else if year >= 2023 && device.generation == "M3" {
                        return device
                    }
                }
                // For older Intel devices, return the first match for the year
                else {
                    return device
                }
            }
        }
        
        return nil
    }
    
    static func findDeviceByModelIdentifier(_ modelIdentifier: String) -> AppleDevice? {
        return devices[modelIdentifier]
    }
    
    static func getAllDevices() -> [AppleDevice] {
        return Array(devices.values).sorted { $0.year > $1.year }
    }
    
    static func getDevicesByYear(_ year: Int) -> [AppleDevice] {
        return devices.values.filter { $0.year == year }.sorted { $0.modelName < $1.modelName }
    }
    
    static func getDevicesByGeneration(_ generation: String) -> [AppleDevice] {
        return devices.values.filter { $0.generation == generation }.sorted { $0.year > $1.year }
    }
}

// MARK: - Apple Device Model
struct AppleDevice: Codable, Identifiable {
    var id = UUID()
    let modelIdentifier: String
    let modelName: String
    let year: Int
    let processor: String
    let memory: String
    let storage: String
    let graphics: String
    let display: String
    let generation: String
    let priceRangeMin: Int
    let priceRangeMax: Int
    
    var averagePrice: Int {
        return (priceRangeMin + priceRangeMax) / 2
    }
    
    var specifications: DeviceSpecifications {
        return DeviceSpecifications(
            processor: processor,
            memory: memory,
            storage: storage,
            graphics: graphics,
            display: display,
            year: year,
            generation: generation
        )
    }
}