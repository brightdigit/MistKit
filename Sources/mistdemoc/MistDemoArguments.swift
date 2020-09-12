import ArgumentParser
import MistKit

struct MistDemoArguments: ParsableArguments {
  @Option()
  var apiKey = "c2b958e56ab5a41aa25d673f479bbac1379f1247d83199ccd94e38bb6ae715e2"

  @Option()
  var container = "iCloud.com.brightdigit.MistDemo"

  @Option()
  var environment = MKEnvironment.development

  @Option()
  var token: String?
}
