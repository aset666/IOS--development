let fleetData: [(kind: String, id: String, charge: Int)] = [
    (kind: "welder",  id: "W-1", charge: 80),
    (kind: "scanner", id: "S-1", charge: 45),
    (kind: "cargo",   id: "C-1", charge: 100),
    (kind: "welder",  id: "W-2", charge: 15),
    (kind: "scanner", id: "S-2", charge: 60),
    (kind: "tug",     id: "T-1", charge: 50)
]

let sensorData: [(id: String, charge: Int)] = [
    (id: "hull-cam", charge: 12),
    (id: "thermal",  charge: 77)
]

struct LegacyBeacon {
    let name: String
    let signalStrength: Int
}

let beacon = LegacyBeacon(name: "ALMA-BEACON", signalStrength: 8)
print("Fleet registry online: \(fleetData.count) drone records, \(sensorData.count) sensors, beacon \(beacon.name).")

final class PowerCell {
    private var charge: Int
    
    init(charge: Int) {
        if charge < 0 { self.charge = 0 }
        else if charge > 100 { self.charge = 100 }
        else { self.charge = charge }
    }
    
    func level() -> Int {
        return charge
    }
    
    func spend(_ amount: Int) -> Bool {
        if amount <= 0 { return false }
        if charge < amount { return false }
        charge -= amount
        return true
    }
    
    func recharge(by amount: Int) {
        if amount <= 0 { return }
        charge += amount
        if charge > 100 { charge = 100 }
    }
}

class Drone {
    let id: String
    let cell: PowerCell
    
    init(id: String, cell: PowerCell) {
        self.id = id
        self.cell = cell
    }
    
    var powerCost: Int { 10 }
    
    var statusLine: String {
        return "\(id): \(cell.level())% \(cell.level().powerBar)"
    }
    
    func performTask() -> Int {
        return 0
    }
    
    final func runOnce() -> Int {
        if !cell.spend(powerCost) {
            return 0
        }
        return performTask()
    }
}

final class WelderDrone: Drone {
    override var powerCost: Int { 25 }
    
    override func performTask() -> Int {
        return 40
    }
    
    func weldSeam() -> String {
        return "Welded seam on \(id)"
    }
}

class ScannerDrone: Drone {
    override var powerCost: Int { 10 }
    
    override func performTask() -> Int {
        return 15
    }
    
    override var statusLine: String {
        return super.statusLine + " [scanner]"
    }
}

final class CargoDrone: Drone {
    override var powerCost: Int { 20 }
    
    override func performTask() -> Int {
        return 25
    }
}

func makeDrone(kind: String, id: String, charge: Int) -> Drone? {
    let cell = PowerCell(charge: charge)
    switch kind {
    case "welder":
        return WelderDrone(id: id, cell: cell)
    case "scanner":
        return ScannerDrone(id: id, cell: cell)
    case "cargo":
        return CargoDrone(id: id, cell: cell)
    default:
        return nil
    }
}

var fleet: [Drone] = []
for record in fleetData {
    if let drone = makeDrone(kind: record.kind, id: record.id, charge: record.charge) {
        fleet.append(drone)
    } else {
        print("WARNING: Unknown drone kind '\(record.kind)' for id \(record.id). Skipping.")
    }
}

print("\n--- FLEET BUILT ---")
for drone in fleet {
    print(drone.statusLine)
}

func runShift(_ fleet: [Drone], rounds: Int) -> Int {
    var totalWork = 0
    for _ in 0..<rounds {
        for drone in fleet {
            totalWork += drone.runOnce()
        }
    }
    return totalWork
}

let A = runShift(fleet, rounds: 3)

var B = 0
for drone in fleet {
    B += drone.cell.level()
}

var C = 0
for drone in fleet {
    if drone.cell.level() >= drone.powerCost {
        C += 1
    }
}

print("\n--- SHIFT RESULTS ---")
for drone in fleet {
    print(drone.statusLine)
}
print("Total work units (A): \(A)")
print("Total remaining charge (B): \(B)")
print("Drones that could run one more task (C): \(C)")

protocol Diagnosable {
    var componentID: String { get }
    var statusCode: Int { get }
    func diagnose() -> String
}

protocol Rechargeable {
    mutating func recharge(by amount: Int)
}

extension Drone: Rechargeable {
    func recharge(by amount: Int) {
        cell.recharge(by: amount)
    }
}

extension Drone: Diagnosable {
    var componentID: String { id }
    var statusCode: Int {
        return statusCode(forCharge: cell.level())
    }
}

struct SensorModule: Diagnosable, Rechargeable {
    let componentID: String
    var chargeLevel: Int
    
    var statusCode: Int {
        return statusCode(forCharge: chargeLevel)
    }
    
    mutating func recharge(by amount: Int) {
        if amount <= 0 { return }
        chargeLevel += amount
        if chargeLevel > 100 { chargeLevel = 100 }
    }
}

var sensors: [SensorModule] = []
for record in sensorData {
    let sensor = SensorModule(componentID: record.id, chargeLevel: record.charge)
    sensors.append(sensor)
}

func diagnosticsReport(_ components: [Diagnosable]) -> String {
    var result = "--- DIAGNOSTICS REPORT ---\n"
    for component in components {
        result += component.diagnose() + "\n"
    }
    result += "--- END REPORT ---"
    return result
}

var allComponents: [Diagnosable] = []
for drone in fleet {
    allComponents.append(drone)
}
for sensor in sensors {
    allComponents.append(sensor)
}

print("\n" + diagnosticsReport(allComponents))

extension Diagnosable {
    func diagnose() -> String {
        return "\(componentID): code \(statusCode)"
    }
    
    func statusCode(forCharge charge: Int) -> Int {
        if charge < 20 { return 2 }
        if charge < 50 { return 1 }
        return 0
    }
}

extension LegacyBeacon: Diagnosable {
    var componentID: String { name }
    var statusCode: Int {
        return statusCode(forCharge: signalStrength)
    }
    
    func diagnose() -> String {
        return "[LEGACY] \(componentID): signal \(signalStrength), code \(statusCode)"
    }
}

allComponents.append(beacon)
print("\n" + diagnosticsReport(allComponents))

var D = 0
for component in allComponents {
    D += component.statusCode
}
print("Sum of all status codes (D): \(D)")

extension Int {
    var powerBar: String {
        let clamped = self < 0 ? 0 : (self > 100 ? 100 : self)
        let filled = clamped / 10
        var bar = ""
        for _ in 0..<filled {
            bar += "#"
        }
        for _ in 0..<(10 - filled) {
            bar += "."
        }
        return bar
    }
}

print("\nPower bar examples:")
print("42 -> \(42.powerBar)")
print("-5 -> \((-5).powerBar)")
print("250 -> \(250.powerBar)")

class PatchDrone: Drone {
    override func performTask() -> Int {
        return 30
    }
}

let reportFleet: [Drone] = [WelderDrone(id: "W-9", cell: PowerCell(charge: 100))]
let first = reportFleet[0]
if let welder = first as? WelderDrone {
    print(welder.weldSeam())
}

protocol Labelled {
    var componentID: String { get }
    func label() -> String
}

extension Labelled {
    func label() -> String { "generic component" }
}

struct Thruster: Labelled {
    let componentID: String
    func label() -> String { "thruster \(componentID)" }
}

let parts: [Labelled] = [Thruster(componentID: "T-1")]
print(parts[0].label())

let missionCode = "\(A)-\(B)-\(C)-\(D)"
print("\nMISSION CODE: \(missionCode)")

// MARK: - ================= DEFENSE QUESTIONS =================
/*
 1. Why does a class satisfy a `mutating` protocol requirement without the keyword, while a struct must write it?
    Classes are reference types, so their methods always operate on the shared instance and can mutate it directly.
    Structs are value types, so methods operate on copies by default; the `mutating` keyword tells Swift that
    the method should modify the original instance, not a copy.

 2. One thing inheritance does that protocols cannot, and one thing protocols do that inheritance cannot:
    Inheritance: Provides shared implementation through a base class, allowing subclasses to reuse code
    and override behavior while maintaining a type hierarchy.
    Protocols: Allow unrelated types (classes, structs, enums) to conform to the same interface, enabling
    polymorphism across different type hierarchies without forcing them into an inheritance chain.

 3. What does `final` prevent, and what did it protect in runOnce()?
    `final` on a class prevents it from being subclassed. `final` on a method prevents it from being overridden.
    Making runOnce() final protected the shift ritual (spend-then-perform) from being changed by subclasses,
    ensuring that power accounting is always consistent and subclasses can only customize performTask(),
    not the ritual itself.

 4. In Report 4, why did the protocol extension's method win?
    When a method is called through a protocol type (like [Labelled]), Swift uses static dispatch and calls
    the protocol extension's implementation at compile time. The conforming type's method is only called
    if the method is part of the protocol's requirements (dynamic dispatch). Since label() was only in the
    extension, not in the protocol requirements, the extension's version was used.
 */

// MARK: - ================= BONUS =================
/*
 1. Two ways to forbid using Drone directly:
    a) Runtime failure: Add a check in init that crashes if called directly.
       init(id: String, cell: PowerCell) {
           if type(of: self) == Drone.self {
               fatalError("Drone is abstract and cannot be instantiated directly")
           }
           self.id = id
           self.cell = cell
       }
    b) Compile-time failure: Make the initializer private or internal, and provide factory methods only.
 
 2. Protocol-based redesign:
    protocol DroneProtocol {
        var id: String { get }
        var cell: PowerCell { get }
        var powerCost: Int { get }
        func performTask() -> Int
    }
    extension DroneProtocol {
        func runOnce() -> Int {
            if !cell.spend(powerCost) { return 0 }
            return performTask()
        }
    }
    struct WelderDrone: DroneProtocol {
        let id: String
        let cell: PowerCell
        var powerCost: Int { 25 }
        func performTask() -> Int { 40 }
    }
 
 3. Comparison:
    The class-based design provides shared implementation through inheritance and allows reference semantics 
    for shared state (like the PowerCell). The protocol-based design is more flexible and allows value types, 
    but requires each conforming type to implement all requirements. For this station, the class-based design 
    is better because drones need to share mutable state (the battery), and inheritance provides a clear 
    hierarchy with shared behavior.
 */
