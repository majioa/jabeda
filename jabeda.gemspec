
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jabeda/version"

Gem::Specification.new do |spec|
  spec.name          = "jabeda"
  spec.version       = Jabeda::VERSION
  spec.authors       = ["Konstantin Pavlov", "Michael Shigorin", "Malo Skrylevo"]
  spec.email         = ["thresh@altlinux.org", "mike@altlinux.org", "majioa@yandex.ru"]

  spec.summary       = %q{Jabeda OVZ complainer}
  spec.description   = <<-DESC
     Jabeda (formerly Yabeda) is an OpenVZ failcnt complainer which tends to be lightweight, flexible and easily extendable. Should be used on host machines (via some cron-job) to generate alerts when failcnt gets increased. Failcnt is the counter used in OpenVZ kernels to tell whether the needed parameter reached its limit.

     these gems will allow you to use additional functions:
      - mysql, dbi, and dbd-mysql for mysql support
      - tmail for email support
      - xmpp4r for jabber support
     DESC
  spec.homepage      = "https://github.com/majioa/jabeda"
  spec.license       = "GPLv3"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "http://rubygems.org"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/majioa/jabeda"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sqlite3", "~> 1.4"
  spec.add_dependency "mail", "~> 2.7"
  spec.add_dependency "xmpp4r", "~> 0.5.6"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 12.0", '>= 12.3.3'
  spec.add_development_dependency "rspec", "~> 3.0"
end
