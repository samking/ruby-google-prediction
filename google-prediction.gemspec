Gem::Specification.new do |s|
  s.name = %q{google-prediction}
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sam King"]
  s.email = %q{samking@cs.stanford.edu}
  s.date = %q{2010-08-18}
  s.summary = %q{Google Prediction API interface for Ruby.}
  s.description = %q{Generates an auth token from a google account
Trains using the auth token and data uploaded to Google Storage for Developers
Checks the training status
Predicts outputs when given new input}
  s.homepage = %q{http://code.google.com/p/ruby-google-prediction/}
  s.require_paths = ["lib"]
  s.files = [
    "lib/google-prediction.rb",
  ]
  s.add_dependency('curb', '>= 0.7.7.1')
  s.add_dependency('json', '>= 1.4.3')

  s.has_rdoc = true
  s.rdoc_options << '-SNm' << 'GooglePrediction'

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3
  end
end

