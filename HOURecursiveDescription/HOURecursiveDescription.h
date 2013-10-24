//
//  HOURecursiveDescription.m
//  HOURecursiveDescription
//
//  Created by Hannes Oud on 04.05.13.
//  Copyright (c) 2013 Hannes Oud. All rights reserved.
//
//  HOURollOutDescriptionPimping is the entry point

#import <UIKit/UIKit.h>

#if DEBUG // private API [UIView recursiveDescription] is used throughout the code

@interface UIView (HOURecursiveDescription)

/**
 *  Compiles sth. like:
 *  0x08c5d730 'RootViewController:0x757a0b0' <UIView: 0x719ffd0; frame = (0 20; 320 460); autoresize = RM+BM; layer = <CALayer: 0x71a0030>>
 * | _subview1 <UIView: 0x719fe90; frame = (96 20; 128 27); autoresize = W+H; layer = <CALayer: 0x719fef0>>
 * | _myButton <UIRoundedRectButton: 0x719ba40; frame = (46 295; 204 44); opaque = NO; autoresize = RM+BM; layer = <CALayer: 0x719bb60>>
 * |    | _tableViewStyleBackground <UIGroupTableViewCellBackground: 0x719c320; frame = (0 0; 204 44); userInteractionEnabled = NO; layer = <CALayer: 0x719c3f0>>
 *
 *  @return A recursive description of the view's hierarchy with ivar-names, viewcontrollers and better image descriptions
 */
- (NSString *)recursiveDescription2;

@end

@interface UIApplication (HOURecursiveDescription)

/**
 *  Use po [UIApplication recursiveDescription2] in Debugger to get a complete trace of the view hierarchy
 *
 *  @return A recursive description with ivar-names, viewcontrollers and better image descriptions of the current UIApplication's keyWindow
 */
+ (NSString *)recursiveDescription2;

/**
 *  @return A recursive description with ivar-names, viewcontrollers and better image descriptions of the UIApplication's keyWindow
 */
- (NSString *)recursiveDescription2;

@end

@interface UIViewController (HOURecursiveDescription)

/**
 *  @return A recursive description with ivar-names, viewcontrollers and better image descriptions of the viewcontroller's view
 */
- (NSString *)recursiveDescription2;

@end

#endif