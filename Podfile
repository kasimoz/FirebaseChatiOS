# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'FirebaseChat' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'Firebase/Analytics'
  pod 'Firebase/Auth'
  pod 'Firebase/Database'
  pod 'Firebase/Storage'
  pod 'Firebase/Messaging'
  pod 'ObjectMapper', '~> 3.5'
  pod 'FirebaseUI/Storage'
  pod 'ReachabilitySwift'


target 'notification' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

   pod 'FirebaseUI/Storage'
   pod 'Firebase/Storage'
end

target 'share' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  pod 'Firebase/Auth'
  pod 'Firebase/Storage'
  pod 'FirebaseUI/Storage'
  pod 'Firebase/Database'
  pod 'ObjectMapper', '~> 3.5'
end

end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    puts target.name
  end
end
