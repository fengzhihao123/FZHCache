#
#  Be sure to run `pod spec lint FZHCache.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name         = "FZHCache"
  spec.version      = "0.0.1"
  spec.summary      = "An easy way to cache."

  spec.description  = <<-DESC
                    FZHCache is a powerful and pure Swift implemented library for cacheing data to memory or disk.
                   DESC

  spec.homepage     = "https://github.com/fengzhihao123/FZHCache"

  spec.license      = "MIT"

  spec.author    = "FengZhiHao"
  
  spec.platform     = :ios, "10.0"

  spec.source       = { :git => "https://github.com/fengzhihao123/FZHCache.git", :tag => "#{spec.version}" }

  spec.source_files  = "FZHCache", "Source/*.{swift}"

end
