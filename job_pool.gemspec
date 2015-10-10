lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'job_pool/version'

Gem::Specification.new do |spec|
  spec.name          = "job_pool"
  spec.version       = JobPool::VERSION
  spec.authors       = ["Scott Bronson"]
  spec.email         = ["brons_jobpo@rinspin.com"]
  spec.summary       = "Runs jobs in child processes."
  spec.description   = "Makes it easy to launch, kill, communicate with, and watch child processes."
  spec.homepage      = "http://github.com/bronson/job_pool"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
