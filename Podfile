# Uncomment the next line to define a global platform for your project
platform :ios, '14.0'

def shared_pods
  use_frameworks!
  
  pod 'Alamofire'
  pod 'Kingfisher/SwiftUI'
  pod 'AnyCodable-FlightSchool', '~> 0.4.0'
end

target 'Apphud' do
  shared_pods
  
  pod 'SwiftUIRefresh'
#  pod 'Firebase/Analytics'
#  pod 'Firebase/Crashlytics'
#  pod 'Firebase/RemoteConfig'
end

target 'WidgetsExtension' do
  shared_pods
end

target 'ApphudIntentHandler' do
  shared_pods
end
