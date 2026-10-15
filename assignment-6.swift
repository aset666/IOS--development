import UIKit

// One favorite game
struct Game {
    let title: String
    let description: String
    let imageName: String
}

class ViewController: UIViewController {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!

    // 10 favorite games. Image names must match the names in Assets.xcassets
    let games: [Game] = [
        Game(title: "Elden Ring",
             description: "Open world action RPG from FromSoftware. Hard bosses and a huge map to explore.",
             imageName: "eldenring"),
        Game(title: "CS2",
             description: "Competitive team shooter. Terrorists against counter-terrorists, round by round.",
             imageName: "cs2"),
        Game(title: "Dota 2",
             description: "5v5 MOBA where you pick a hero and destroy the enemy ancient.",
             imageName: "dota2"),
        Game(title: "Warcraft",
             description: "Fantasy strategy series about the war between humans and orcs.",
             imageName: "warcraft"),
        Game(title: "Half-Life 2",
             description: "Story shooter with the gravity gun. Gordon Freeman fights the Combine.",
             imageName: "halflife2"),
        Game(title: "Grand Theft Auto V",
             description: "Open world crime game with three main characters in Los Santos.",
             imageName: "gta5"),
        Game(title: "Resident Evil",
             description: "Survival horror series with zombies, puzzles and very little ammo.",
             imageName: "residentevil"),
        Game(title: "Assassin's Creed",
             description: "Stealth action in historical worlds. Climb, hide and use the hidden blade.",
             imageName: "assassinscreed"),
        Game(title: "Metro 2033",
             description: "Post-apocalyptic shooter in the Moscow metro with a dark atmosphere.",
             imageName: "metro2033"),
        Game(title: "Far Cry 3",
             description: "Survival on a tropical island with the crazy villain Vaas.",
             imageName: "farcry3")
    ]

    // index of the game that is on the screen now (nil = nothing yet)
    var currentIndex: Int?

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.contentMode = .scaleAspectFit
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center

        showStartState()
    }

    // What the user sees when the app starts
    func showStartState() {
        imageView.image = UIImage(systemName: "gamecontroller")
        titleLabel.text = "Game Roulette"
        descriptionLabel.text = "Tap the button to get a random favorite game."
    }

    @IBAction func buttonTapped(_ sender: UIButton) {
        // all indexes except the one we already show
        var availableIndexes = Array(games.indices)
        if let current = currentIndex {
            availableIndexes.removeAll { $0 == current }
        }

        guard let newIndex = availableIndexes.randomElement() else {
            return
        }

        currentIndex = newIndex
        show(games[newIndex])
    }

    // image, title and description change together
    func show(_ game: Game) {
        imageView.image = UIImage(named: game.imageName)
        titleLabel.text = game.title
        descriptionLabel.text = game.description
    }
}
