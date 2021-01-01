#
#  Be sure to run `pod spec lint NoMAD-ADAuth.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
Pod::Spec.new do |s|
  s.name         = "NoMAD-ADAuth"
  s.version      = "1.0.1"
  s.summary      = "NoMAD AD Authentication Framework"
  s.description  = <<-DESC
The NoMAD AD Authentication Framework allows you to present a username and password to the Framework 
and have it get tickets for the user and then lookup the user's information in AD. 

In addition the framework is:

- site aware
- able to change passwords
- able to use SSL for AD lookups
- can have the site forced or ignored
- is aware of network changes, and will mark sites to be re-discovered on changes
- perform recursive group lookups
DESC

  s.homepage     = "https://nomad.menu/"
  s.license      = { :type => "Orchard & Grove Everything but Commercial License", :file => "LICENSE" }
  s.authors      = { "Josh Wisenbaker" => "josh@orchardandgrove.com", "Joel Rennich" => "joel@orchardandgrove.com" }
  s.platform     = :osx, "10.10"
  s.source       = { :git => "https://gitlab.com/Mactroll/NoMAD-ADAuth", :tag => "#{s.version}" }
  s.source_files  = "NoMAD-ADAuth", "NoMAD-ADAuth/**/*.{h,m}"
  s.exclude_files = "docs"

  # s.public_header_files = "Classes/**/*.h"
  # s.framework  = "SomeFramework"
  s.frameworks = "Security", "GSS", "Kerberos"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"
end
