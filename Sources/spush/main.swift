import Guaka

struct Help: HelpGenerator {
    let commandHelp: CommandHelp
    
    init(commandHelp: CommandHelp) {
        self.commandHelp = commandHelp
    }
    
    var commandDescriptionSection: String? {
        return "Spush - Push text via Pushbullet\n\n"
    }
    
    var usageSection: String? {
        return "usage: spush -t <Access token> [Title] [Body]\n\n"
    }
}

GuakaConfig.helpGenerator = Help.self

struct ApiKey: FlagValue {
    let value: String
    
    static func fromString(flagValue value: String) throws -> ApiKey {
        return ApiKey(value: value)
    }
    
    static var typeDescription: String {
        return "Pushbullet API key."
    }
    
}


let rootCommand = Command(usage: "main")  { flags, args in
    guard let apikey = flags.get(name: "token", type: ApiKey.self), !apikey.value.isEmpty else {
        print("Spush error: Pushbullet Api key is empty!\n")
        return
    }
    
    guard args.count == 2 else {
        print("Spush error: Spush needs 2 arguments but passed \(args.count)!\n")
        return
    }
    
    let title = args[0]
    let text = args[1]
    
    guard !title.isEmpty else {
        print("Spush error: Title is empty!\n")
        return
    }
    
    guard !text.isEmpty else {
        print("Spush error: Text is empty!\n")
        return
    }

    let pb = Pushbullet(apikey: apikey.value)
    pb.push(title: title, body: text) { (result) in
        switch result {
        case .success:
            print("Spush success")
        case .failure(let error):
            print("error", error)
        }
    }
}

let apiKey = Flag(shortName: "t", longName: "token", type: ApiKey.self, description: "Pushbullet API key.", required: true, inheritable: false)

rootCommand.add(flag: apiKey)
rootCommand.execute()
