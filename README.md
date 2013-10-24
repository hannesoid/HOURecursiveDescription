HOURecursiveDescription
=======================

Adds `recursiveDescription2` method to UIView, UIViewController, UIAppilcation. In addition to UIView's (private) recursiveDescription, this shows:
- names of views, if they are instance variables of UIView or UIViewController subclass objects, if part of the inspected hierarchy

Improves `description` methods of UIView, UIImage, UIImageView, adds
- UIViewController classes if they associated with a view - adapted a swizzled [UIView description] from Peter Steinberger: http://petersteinberger.com/blog/2012/pimping-recursivedescription/
- UIImage and UIImageView get sth. like <UIImage:0x8b612f0 size:{768, 1001} scale:1 imageOrientation:0> (also from Peter)
- Because `description` is used to compose `recursiveDescription`, these improvements also appear when calling `recursiveDescription2`

Call it in debugger on a view:

    po [someView recursiveDescription2]
    
Example output:

    0x08c5d730 'RootViewController:0x757a0b0' <UIView: 0x719ffd0; frame = (0 20; 320 460); autoresize = RM+BM; layer = <CALayer: 0x71a0030>>
    | _subview1 <UIView: 0x719fe90; frame = (96 20; 128 27); autoresize = W+H; layer = <CALayer: 0x719fef0>>
    | _myButton <UIRoundedRectButton: 0x719ba40; frame = (46 295; 204 44); opaque = NO; autoresize = RM+BM; layer = <CALayer: 0x719bb60>>
    |    | _tableViewStyleBackground <UIGroupTableViewCellBackground: 0x719c320; frame = (0 0; 204 44); userInteractionEnabled = NO; layer = <CALayer: 0x719c3f0>>
    |    | _shadowView <UIImageView: 0x719d8f0; frame = (1 1; 202 43); opaque = NO; userInteractionEnabled = NO; layer = <CALayer: 0x719dbd0>> - (null)
    |    | _titleView <UIButtonLabel: 0x719cfa0; frame = (90 12; 23 19); text = 'log'; clipsToBounds = YES; opaque = NO; userInteractionEnabled = NO; layer = <CALayer: 0x719d090>>
    | _greyBlob <UIView: 0x719ebe0; frame = (46 96; 227 136); autoresize = RM+BM; layer = <CALayer: 0x719aec0>>
    |    | _myButton2 <UIRoundedRectButton: 0x719ed60; frame = (20 73; 73 44); opaque = NO; autoresize = RM+BM; layer = <CALayer: 0x719ee30>>
    |    |    | _tableViewStyleBackground <UIGroupTableViewCellBackground: 0x719ee60; frame = (0 0; 73 44); userInteractionEnabled = NO; layer = <CALayer: 0x719eee0>>
    |    |    | _shadowView <UIImageView: 0x719ef50; frame = (1 1; 71 43); opaque = NO; userInteractionEnabled = NO; layer = <CALayer: 0x719efb0>> - (null)
    |    |    | _titleView <UIButtonLabel: 0x719f100; frame = (12 12; 49 19); text = 'Button'; clipsToBounds = YES; opaque = NO; userInteractionEnabled = NO; layer = <CALayer: 0x719f1f0>>
    |    | _imageView <UIImageView: 0x8c81490; frame = (101 9; 106 60); autoresize = RM+BM; userInteractionEnabled = NO; layer = <CALayer: 0x8c81560>>-><UIImage: 0x8c827a0 size:{171, 68}>

Call in debugger on the application:

    po [UIApplication recursiveDescription2]
    
Example output:

<UIWindow: 0xde15700; frame = (0 0; 320 568); gestureRecognizers = <NSArray: 0xde17dc0>; layer = <UIWindowLayer: 0xde18620>>
   | 'RootViewController:0xde189b0' <UIView: 0x8a23390; frame = (0 0; 320 568); autoresize = RM+BM; layer = <CALayer: 0x8a233f0>>
   |    | _subview1 <UIView: 0x8a23220; frame = (96 20; 128 135); autoresize = W+H; layer = <CALayer: 0x8a23280>>
   |    | _myButton, _button <UIButton: 0x8a1f6f0; frame = (46 295; 246 44); opaque = NO; autoresize = RM+BM; layer = <CALayer: 0x8a1f820>>
   |    |    | _titleView <UIButtonLabel: 0x8a258b0; frame = (33 13; 179 18); text = 'log recursiveDescription2'; clipsToBounds = YES; opaque = NO; userInteractionEnabled = NO; layer = <CALayer: 0x8a25960>>
   |    | _greyBlob <UIView: 0x8a21630; frame = (46 96; 227 136); autoresize = RM+BM; layer = <CALayer: 0x8a21690>>
   |    |    | _myButton2, _button <UIButton: 0x8a1ea20; frame = (20 73; 73 44); opaque = NO; autoresize = RM+BM; layer = <CALayer: 0x8a16750>>
   |    |    |    | _titleView <UIButtonLabel: 0x8a21c50; frame = (12 13; 48 18); text = 'Button'; clipsToBounds = YES; opaque = NO; userInteractionEnabled = NO; layer = <CALayer: 0x8a21d80>>
   |    |    | _imageView <UIImageView: 0x8a184c0; frame = (101 9; 106 60); autoresize = RM+BM; userInteractionEnabled = NO; layer = <CALayer: 0x8a18990>>-><UIImage: 0x8a22350 size:{171, 68}> - (null)

Installation
------------
- Drop the *HOURecursiveDescripion.m* in your Xcode project and add it to your target. It is only compiled in DEBUG builds. HOURecursiveDescripion.h is optional if you want to call from code.
or with CocoaPods
    pod 'HOURecursiveDescription'

How it works
------------
- `nextResponder` is used to find an associated UIViewController for a UIView.
- Ivar names and instance pointer adresses are traversed by inspecting the involved objects class using objc runtime methods
- the return of the original `recursiveDescription` is then manipulated using a regex
