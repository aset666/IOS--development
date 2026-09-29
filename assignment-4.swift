// =============================================================
//  Station ALMA-7, Part II: The Teleporter Incident
//  iOS Mobile Development · Module 4 · Lab Assignment
// =============================================================
// MARK: - =================== STARTER DATA ===================
// MARK: - Do not modify anything in this section
func fields(_ line: String, separatedBy separator: Character = ": ") -> [String] {
    var result: [String] = []
    var current = ""
    for character in line {
        if character == separator {
            result.append(current)
            current = ""
        } else {
            current.append(character)
        }
    }
    result.append(current)
    return result
}

let rawManifest = [
    "crate:101:120 ",
    "container:KZ-ALM-7:340 ",
    "livestock:lab mice:12:2 ",
    "???-corrupted-line ",
    "crate:102:75 ",
    "container:KZ-ALM-9:410 ",
    "livestock:ficus:3:5 ",
    "crate:103:260 ",
    "crate:104:abc ",
    ""
]

let deckReadings: [(deck: String, oxygen: Int)] = [
    (deck: "bridge",     oxygen: 78),
    (deck: "lab",        oxygen: 64),
    (deck: "greenhouse", oxygen: 55),
    (deck: "cargo",      oxygen: 12),
    (deck: "medbay",     oxygen: 90),
    (deck: "engine",     oxygen: 41)
]

let crewData: [(name: String, deck: String, oxygen: Int)] = [
    (name: "Timur ",   deck: "engine ", oxygen: 62),
    (name: "Dana ",    deck: "lab ",    oxygen: 48),
    (name: "Aigerim ", deck: "bridge ", oxygen: 91),
    (name: "Nurlan ",  deck: "cargo ",  oxygen: 17)
]

print("ALMA-7 recorder online: \(rawManifest.count) manifest lines, \(deckReadings.count) readings, \(crewData.count) crew records.")
// MARK: - ================= END OF STARTER DATA =================

// MARK: - =================== YOUR SOLUTION ===================

// MARK: Level 1 · The Deck Register

enum Deck: String, CaseIterable {
    case bridge, lab, cargo, medbay, engine
    
    var evacuationPriority: Int {
        switch self {
        case .bridge: return 1
        case .medbay: return 2
        case .lab:    return 3
        case .engine: return 4
        case .cargo:  return 5
        }
    }
}

print("--- DECK REGISTER ---")
for deck in Deck.allCases {
    print("\(deck.rawValue): priority \(deck.evacuationPriority)")
}

enum AlarmLevel: Int {
    case green = 0, yellow, orange, red
    
    static func level(forTotalMass mass: Int) -> AlarmLevel {
        if mass >= 1500 { return .red }
        let steps = mass / 500
        return AlarmLevel(rawValue: steps) ?? .red
    }
}

print("Alarm 0kg: \(AlarmLevel.level(forTotalMass: 0))")
print("Alarm 940kg: \(AlarmLevel.level(forTotalMass: 940))")
print("Alarm 4000kg: \(AlarmLevel.level(forTotalMass: 4000))")


// MARK: Level 2 · The Manifest

enum ManifestEntry {
    case crate(id: Int, massKg: Int)
    case container(code: String, massKg: Int)
    case livestock(species: String, count: Int, massPerUnitKg: Int)
    case unknown(raw: String)
}

func parseEntry(_ line: String) -> ManifestEntry {
    let parts = fields(line)
    guard !parts.isEmpty else { return .unknown(raw: line) }
    let tag = parts[0]
    
    switch tag {
    case "crate":
        guard parts.count == 3,
              let id = Int(parts[1]),
              let mass = Int(parts[2]) else {
            return .unknown(raw: line)
        }
        return .crate(id: id, massKg: mass)
        
    case "container":
        guard parts.count == 3,
              let mass = Int(parts[2]) else {
            return .unknown(raw: line)
        }
        return .container(code: parts[1], massKg: mass)
        
    case "livestock":
        guard parts.count == 4,
              let count = Int(parts[2]),
              let massPer = Int(parts[3]) else {
            return .unknown(raw: line)
        }
        return .livestock(species: parts[1], count: count, massPerUnitKg: massPer)
        
    default:
        return .unknown(raw: line)
    }
}

func mass(of entry: ManifestEntry) -> Int {
    switch entry {
    case .crate(_, let massKg):
        return massKg
    case .container(_, let massKg):
        return massKg
    case .livestock(_, let count, let massPerUnitKg):
        return count * massPerUnitKg
    case .unknown:
        return 0
    }
}

var totalMass = 0
var unknownCount = 0
var parsedManifest: [ManifestEntry] = []

for line in rawManifest {
    let entry = parseEntry(line)
    parsedManifest.append(entry)
    totalMass += mass(of: entry)
    if case .unknown = entry {
        unknownCount += 1
    }
}

print("\n--- MANIFEST ANALYSIS ---")
print("Total mass: \(totalMass) kg")
print("Unknown entries: \(unknownCount)")
print("Sample entry: \(parsedManifest[0])")

let A = totalMass


// MARK: Level 3 · Crew Snapshots

struct CrewSnapshot {
    let name: String
    var deck: Deck
    var oxygen: Int
    
    mutating func breathe(_ amount: Int) {
        oxygen -= amount
        if oxygen < 0 { oxygen = 0 }
    }
    
    mutating func move(to newDeck: Deck) {
        deck = newDeck
    }
    
    mutating func reviveInMedbay() {
        self = CrewSnapshot(name: name, deck: .medbay, oxygen: 100)
    }
    
    static func rookie(named name: String) -> CrewSnapshot {
        return CrewSnapshot(name: name, deck: .bridge, oxygen: 100)
    }
}

var crewRoster: [CrewSnapshot] = []

for record in crewData {
    if let deck = Deck(rawValue: record.deck) {
        let snapshot = CrewSnapshot(name: record.name, deck: deck, oxygen: record.oxygen)
        crewRoster.append(snapshot)
    } else {
        print("WARNING: Unknown deck '\(record.deck)' for \(record.name). Skipping.")
    }
}

print("\n--- CREW ROSTER ---")
for member in crewRoster {
    print("\(member.name) on \(member.deck.rawValue) with O2: \(member.oxygen)%")
}

print("\n--- VALUE SEMANTICS DEMO ---")

var originalSnap = CrewSnapshot.rookie(named: "TestCopy")
var copySnap = originalSnap
copySnap.oxygen = 10
print("1. Copy modified: Original O2=\(originalSnap.oxygen), Copy O2=\(copySnap.oxygen)")

func modifyPlain(var s: CrewSnapshot) {
    s.oxygen = 5
}
var plainSnap = CrewSnapshot.rookie(named: "TestPlain")
modifyPlain(var: plainSnap)
print("2. Plain param: After func call Original O2=\(plainSnap.oxygen) (should be 100)")

func modifyInout(s: inout CrewSnapshot) {
    s.oxygen = 5
}
var inoutSnap = CrewSnapshot.rookie(named: "TestInout")
modifyInout(s: &inoutSnap)
print("3. Inout param: After func call Original O2=\(inoutSnap.oxygen) (should be 5)")


// MARK: Level 4 · The Teleport Pod

final class TeleportPod {
    let id: String
    var chargeLevel: Int
    var occupant: CrewSnapshot?
    
    init(id: String, chargeLevel: Int) {
        self.id = id
        self.chargeLevel = chargeLevel
        self.occupant = nil
    }
    
    func load(_ crew: CrewSnapshot) -> Bool {
        if occupant != nil || chargeLevel < 20 {
            return false
        }
        occupant = crew
        return true
    }
    
    func fire() -> CrewSnapshot? {
        guard let person = occupant else {
            return nil
        }
        if chargeLevel < 20 {
            return nil
        }
        chargeLevel -= 20
        occupant = nil
        return person
    }
    
    deinit {
        print("Pod \(id) deinitialized.")
    }
}

print("\n--- TELEPORT POD LEDGER ---")
let pod = TeleportPod(id: "P-1", chargeLevel: 100)

func findCrew(named name: String) -> CrewSnapshot? {
    for m in crewRoster {
        if m.name == name { return m }
    }
    return nil
}

if let timur = findCrew(named: "Timur") {
    _ = pod.load(timur)
    _ = pod.fire()
}
print("After Timur: Charge = \(pod.chargeLevel)")

if let dana = findCrew(named: "Dana") {
    _ = pod.load(dana)
    _ = pod.fire()
}
print("After Dana: Charge = \(pod.chargeLevel)")

if let nurlan = findCrew(named: "Nurlan") {
    _ = pod.load(nurlan)
    _ = pod.fire()
}
print("After Nurlan: Charge = \(pod.chargeLevel)")

_ = pod.fire()
print("After empty fire: Charge = \(pod.chargeLevel)")

let C = pod.chargeLevel

print("\n--- REFERENCE SEMANTICS DEMO ---")
let refPodA = TeleportPod(id: "Ref-A", chargeLevel: 100)
let refPodB = refPodA
refPodB.chargeLevel = 0
print("Pod Ref-A charge after changing Ref-B: \(refPodA.chargeLevel) (should be 0)")

var valSnapA = CrewSnapshot.rookie(named: "RefTest")
var valSnapB = valSnapA
valSnapB.oxygen = 0
print("Snap RefTest oxygen after changing copy: \(valSnapA.oxygen) (should be 100)")
// Rule: Classes are reference types (assignment shares instance), Structs are value types (assignment copies data).


// MARK: Level 5 · Station Systems

final class Station {
    let callSign: String
    
    var hullIntegrity: Int {
        willSet {
            print("Hull integrity changing from \(hullIntegrity) to \(newValue)")
        }
        didSet {
            if hullIntegrity > 100 { hullIntegrity = 100 }
            if hullIntegrity < 0 { hullIntegrity = 0 }
        }
    }
    
    lazy var fullDiagnostics: String = {
        print("Running full scan...")
        return "Systems nominal. CallSign: \(self.callSign)"
    }()
    
    private var oxygenByDeck: [Deck: Int] = [:]
    
    init(callSign: String) {
        self.callSign = callSign
        self.hullIntegrity = 100
        
        for reading in deckReadings {
            if let validDeck = Deck(rawValue: reading.deck) {
                oxygenByDeck[validDeck] = reading.oxygen
            }
        }
    }
    
    var totalOxygen: Int {
        var sum = 0
        for (_, val) in oxygenByDeck {
            sum += val
        }
        return sum
    }
    
    var averageOxygen: Int {
        get {
            let count = oxygenByDeck.count
            if count == 0 { return 0 }
            return totalOxygen / count
        }
        set {
            for key in oxygenByDeck.keys {
                oxygenByDeck[key] = newValue
            }
        }
    }
}

let B: Int
do {
    let station = Station(callSign: "ALMA-7")
    B = station.averageOxygen
    print("\n--- STATION SYSTEMS ---")
    print("Initial Average Oxygen: \(B)")
    
    print("Accessing diagnostics first time:")
    _ = station.fullDiagnostics
    print("Accessing diagnostics second time:")
    _ = station.fullDiagnostics
    
    print("\n--- CLAMP TRAP ---")
    station.hullIntegrity = 130
    print("Set to 130 -> Actual: \(station.hullIntegrity)")
    
    station.hullIntegrity = -40
    print("Set to -40 -> Actual: \(station.hullIntegrity)")
    
    station.hullIntegrity = 55
    print("Set to 55 -> Actual: \(station.hullIntegrity)")
    // didSet clamp не вызывает бесконечную рекурсию, потому что Swift обнаруживает
    // присвоение внутри собственного наблюдателя и предотвращает рекурсивный вызов willSet/didSet.
}


// MARK: Level 6 · Incident Reports

var fixedRoster = crewRoster
for i in 0..<fixedRoster.count {
    fixedRoster[i].oxygen -= 10
}
print("\nReport 1 Fixed: First member O2 is now \(fixedRoster[0].oxygen)")

let fixedPodA = TeleportPod(id: "Fix-A", chargeLevel: 100)
let fixedPodB = TeleportPod(id: "Fix-B", chargeLevel: fixedPodA.chargeLevel)
fixedPodB.chargeLevel = 0
print("Report 2 Fixed: PodA charge is \(fixedPodA.chargeLevel)")

struct FixedLogbook {
    var entries: [String] = []
    mutating func add(_ entry: String) {
        entries.append(entry)
    }
}

var fixedSnapshot = CrewSnapshot.rookie(named: "Dana")
fixedSnapshot.oxygen = 40
let fixedPod = TeleportPod(id: "Fix-D", chargeLevel: 50)
fixedPod.chargeLevel = 10


// MARK: Level 7 · Sealing the Black Box

final class FlightRecorder {
    private var _entries: [String] = []
    private(set) var isSealed = false
    
    fileprivate var rawTranscript: String {
        var result = ""
        for e in _entries { result += "\(e)\n" }
        return result
    }
    
    var entryCount: Int { _entries.count }
    
    func add(_ entry: String) {
        guard !isSealed else { return }
        _entries.append(entry)
    }
    
    func seal() {
        isSealed = true
    }
}

func auditTranscript(of recorder: FlightRecorder) -> String {
    return "--- AUDIT ---\n\(recorder.rawTranscript)--- END ---"
}

let blackBox = FlightRecorder()
blackBox.add("System start")
blackBox.seal()
blackBox.add("This should not appear")
print("\n--- BLACK BOX ---")
print(auditTranscript(of: blackBox))

// MARK: Finale · Integrity Code

let D = AlarmLevel.level(forTotalMass: A).rawValue
let integrityCode = "\(A)-\(B)-\(C)-\(D)"
print("\nINTEGRITY CODE: \(integrityCode)")


// MARK: Bonus

func areSamePod(_ p1: TeleportPod?, _ p2: TeleportPod?) -> Bool {
    return p1 === p2
}

print("\n--- BONUS LIFETIME ---")
do {
    let tempPod = TeleportPod(id: "Temp-Pod", chargeLevel: 50)
    let aliasPod = tempPod
    print("Inside do block")
}
print("Outside do block")


// MARK: - ================= DEFENSE QUESTIONS =================
/*
1. Why did CrewSnapshot get an initializer for free and TeleportPod did not?
   Structs automatically receive a memberwise initializer if they don't define custom ones.
   Classes do not, because class initialization involves inheritance chains, two-phase safety checks,
   and potential overrides, making automatic generation unsafe or ambiguous.

2. What does `mutating` do to self, and why do classes never need it?
   `mutating` allows a struct method to replace `self` or modify stored properties.
   Since structs are value types, methods operate on copies by default.
   Classes are reference types; methods always modify the shared instance directly, so no keyword is needed.

3. In Report 4 both values are `let`. What exactly does `let` freeze for a struct, and what does it freeze for a class?
   For a struct: `let` freezes the entire value. No property can change.
   For a class: `let` freezes only the reference (the pointer). The object's internal `var` properties remain mutable.

4. Why must a lazy property be var? When does lazy change behaviour, not just performance?
   It must be `var` because its initial value is set AFTER initialization completes (mutation).
   Behaviour change: If the lazy property has side effects (e.g., printing, network calls) or depends on
   other properties that change post-init, making it lazy ensures those side effects happen on first access,
   not during init. Without lazy, the side effect happens immediately during construction.

5. private vs fileprivate: where in your FlightRecorder would private be too strict?
   `rawTranscript` needs to be `fileprivate`. If it were `private`, the free function
   `auditTranscript(of:)` could not access it, even though it's in the same file.
   `private` restricts access to the enclosing declaration only.

Bonus. On which line does deinit fire, and why can't === be used on CrewSnapshot?
   `deinit` fires at the closing brace of the `do` block, because that is when the last strong reference
   (`aliasPod`) goes out of scope and the reference count drops to zero.
   `===` compares memory addresses of class instances. Structs have no stable memory address as they are
   copied by value, so identity comparison is meaningless.
*/
