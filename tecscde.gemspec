lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "tecscde/version"

Gem::Specification.new do |spec|
  spec.name          = "tecscde"
  spec.version       = Tecscde::VERSION
  spec.authors       = ["Hiroshi OYAMA", "Kenji Okimoto"]
  spec.email         = ["hiro22022@gmail.com", "okimoto@clear-code.com"]

  spec.summary       = %q{TECSCDE - TECS Component Diagram Editor}
  spec.description   = %q{TECSCDE - TECS Component Diagram Editor}
  spec.homepage      = "https://www.toppers.jp/"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/hiro22022/TECSCDE"
    spec.metadata["changelog_uri"] = "https://github.com/hiro22022/TECSCDE/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject {|f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "gtk2", ">= 3.3.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "racc"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rubocop", "~> 0.61.1"
end
