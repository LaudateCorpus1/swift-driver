public struct OptionParser {
  /// Generates an option given an appropriate set of arguments.
  enum Generator {
    case input
    case flag(() -> Option)
    case joined((String) -> Option)
    case separate((String) -> Option)
    case remaining(([String]) -> Option)
    case commaJoined(([String]) -> Option)
    case joinedOrSeparate((String) -> Option)
  }

  private struct StoredOption {
    /// The spelling of the option, including its prefix, e.g.,
    /// "-help"
    let spelling: String

    /// The generator that produces the option value given the
    /// appropriate arguments.
    let generator: Generator

    /// Whether this option is an alias, and therefore need not be
    /// printed.
    let isAlias: Bool

    /// Whether this option is hidden.
    let isHidden: Bool
    
    /// The meta-variable name, if there is one.
    let metaVar: String?

    /// The help text, if there is one
    let helpText: String?    
  }

  private var options: [StoredOption] = []
  
  mutating func addOption(
    spelling: String, generator: Generator, isHidden: Bool = false,
    metaVar: String? = nil, helpText: String? = nil
  ) {
    options.append(
      StoredOption(spelling: spelling, generator: generator, isAlias: false,
        isHidden: isHidden, metaVar: metaVar, helpText: helpText))
  }

  mutating func addAlias(
    spelling: String, generator: Generator, isHidden: Bool = false
  ) {
    options.append(
      StoredOption(spelling: spelling, generator: generator, isAlias: true,
        isHidden: isHidden, metaVar: nil, helpText: nil))
  }
}

extension String {
  fileprivate func canonicalizedForArgName() -> String {
    var result = self
    while result.first != nil && result.first! == "-" {
      result = String(result.dropFirst())
    }
    return result.lowercased()
  }
}

extension OptionParser {

  /// Print help information to the terminal.
  func printHelp(includeHidden: Bool) {
    print("""
      OVERVIEW: Swift compiler

      USAGE: swift

      OPTIONS:
      """)

    let sortedOptions = options.sorted { x, y in
      x.spelling.canonicalizedForArgName() < y.spelling.canonicalizedForArgName()
    }
    for option in sortedOptions {
      if option.isAlias { continue }
      if option.isHidden && !includeHidden { continue }
      if option.helpText == nil { continue }
      
      let maxDisplayNameLength = 22

      // Figure out the display name, with metavariable if given
      var displayName = option.spelling
      switch option.generator {
        case .input:
          continue
        
        case .flag:
          break

        case .joined, .commaJoined:
          displayName += option.metaVar ?? "<value>"

        case .separate, .remaining, .joinedOrSeparate:
          displayName += " " + (option.metaVar ?? "<value>")
      }
      if displayName.count <= maxDisplayNameLength {
        let rightPadding = String(
          repeating: " ",
          count: maxDisplayNameLength - displayName.count)
        
        print("  \(displayName)\(rightPadding) \(option.helpText!)")
      } else {
        print("  \(displayName)")
        let leftPadding = String(
          repeating: " ", count: maxDisplayNameLength)
        print("  \(leftPadding) \(option.helpText!)")
      }
    }
  }
}
