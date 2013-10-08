Pod::Spec.new do |s|

  s.name         = "HOURecursiveDescription"
  s.version      = "0.1.0"
  s.summary      = "Adds ivar names to views recursiveDescription via [UIView recursiveDescription2]."

  s.description  = <<-DESC
Adds `recursiveDescription2` method to UIView. In addition to UIView's (private) recursiveDescription, this shows:
- names of views, if they are instance variables of UIView or UIViewController subclass objects, if part of the inspected hierarchy

Improves `description` methods of UIView, UIImage, UIImageView, adds
- UIViewController classes if they associated with a view - adapted a swizzled [UIView description] from Peter Steinberger
- UIImage and UIImageView get sth. like <UIImage:0x8b612f0 size:{768, 1001} scale:1 imageOrientation:0> (also from Peter)
- Because `description` is used to compose `recursiveDescription`, these improvements also appear when calling `recursiveDescription2`
                   DESC

  s.homepage     = "https://github.com/hannesoid/HOURecursiveDescription"
  s.license      = s.license = {
    :type => 'MIT',
    :file => 'LICENSE'
  }
  s.author       = { "Hannes Oud" => "hannes.oud.dev@gmail.com" }
  s.platform     = :ios, '5.0'
  s.source       = { :git => "git@github.com:hannesoid/HOURecursiveDescription.git", :tag => s.version.to_s }
  s.source_files  = 'HOURecursiveDescription'
  s.framework  = 'UIKit'  
  s.requires_arc = true
  
end
