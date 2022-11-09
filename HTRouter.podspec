Pod::Spec.new do |s|
  s.name         = 'HTRouter'
  s.version          = '0.2.3'
  s.summary          = 'HTRouter is a routing framework for ios applications.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
HTRouter is a routing framework for ios applications. Have a try.
                       DESC

  s.homepage         = 'https://github.com/nscribble/HTRouter'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'nscribble' => 'jasonchan.sysu@gmail.com' }
  s.source           = { :git => 'https://github.com/nscribble/HTRouter.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'
  
  s.requires_arc = true
  s.source_files = 'HTRouter/**/*.{h,m}'
  s.public_header_files = 'HTRouter/*.{h}'
  
  s.frameworks = 'Foundation'
end
