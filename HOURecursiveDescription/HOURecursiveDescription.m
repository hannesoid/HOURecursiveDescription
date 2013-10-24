//
//  HOURecursiveDescription.m
//  HOURecursiveDescription
//
//  Created by Hannes Oud on 04.05.13.
//  Copyright (c) 2013 Hannes Oud. All rights reserved.
//
//  HOURollOutDescriptionPimping is the entry point

#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#if DEBUG

#import "HOURecursiveDescription.h"

#pragma mark - removing missing selector warnings
// by declaring here, what we will use in swizzeling

@interface UIView(HOUImprovedDescriptions_Internal)
- (NSString *)HOU_customViewDescription;
- (NSString *)pspdf_description;
- (NSString *)pspdf_customViewDescription;
- (NSString *)recursiveDescription;
- (NSString *)recursiveDescription2;
@end

@interface UIImageView(HOUImprovedDescriptions_Internal)
- (NSString *)HOU_description;
@end

@interface UIImage(HOUImprovedDescriptions_Internal)
- (NSString *)HOU_description;
@end

#pragma mark - Helpers for Swizzling

/**
 * A copy of pspdf_replaceMethodWithBlock
 * Swizzles the new method, using the block as implementation. 
 * Old implementation will be available under the newSEL selector.
 */
static BOOL HOUReplaceMethodWithBlock(Class c, SEL origSEL, SEL newSEL, id block) {
//    NSAssert(c && origSEL && newSEL && block, @"invalid parameters in block swizzle"); // todo replace NSAssert, as it requires self & _cmd
    Method origMethod = class_getInstanceMethod(c, origSEL);
    const char *encoding = method_getTypeEncoding(origMethod);
    
    // Add the new method.
    IMP impl = imp_implementationWithBlock(block);
    if (!class_addMethod(c, newSEL, impl, encoding)) {
        NSLog(@"Failed to add method: %@ on %@", NSStringFromSelector(newSEL), c);
        return NO;
    }else {
        // Ensure the new selector has the same parameters as the existing selector.
        Method newMethod = class_getInstanceMethod(c, newSEL);
        // NSAssert(strcmp(method_getTypeEncoding(origMethod), method_getTypeEncoding(newMethod)) == 0, @"Encoding must be the same."); // todo replace NSAssert, as it requires self & _cmd
        
        // If original doesn't implement the method we want to swizzle, create it.
        if (class_addMethod(c, origSEL, method_getImplementation(newMethod), encoding)) {
            class_replaceMethod(c, newSEL, method_getImplementation(origMethod), encoding);
        }else {
            method_exchangeImplementations(origMethod, newMethod);
        }
    }
    return YES;
}

#pragma mark - Helpers for adding [UIView recursiveDescription2]

static BOOL isUIViewOrUIViewControllerClass(const char *classname) {
    return (strcmp(classname, "UIView") == 0 || strcmp(classname, "UIViewController") == 0);
}

/**
 * Fills the provided mutable dictionary with entries of the form ivar_value_adress_string1 -> ivarname1[, ivarname2,..],
 * where the ivar_value_adress_strings are the formatted pointer-adress-string's of each ivar of obj, defined in obj.class,
 * and its superclasses up to those defined in UIView.class or UIViewController.class.
 *
 * ivars are only collected if they are UIView or subclass.
 *
 * Produces sth. like @{ @"0x7572b10": @[@"_subview1"], @"0x756e460" : @[@"_myButtonInView1", @"_myButtonAlsoInView2"]}.. 
 */
static void collectUIViewIvarPointerToNameDict(NSObject *obj, NSMutableDictionary *dict) {

    if (![obj isKindOfClass:UIView.class] && ![obj isKindOfClass:UIViewController.class]) return;
    
    unsigned int ivarCount = 0;
    
    Class class = obj.class;
    
    while (!isUIViewOrUIViewControllerClass(class_getName(class))) { // traverse class and superclasses up to UIView[Controller]
        
        Ivar *ivars = class_copyIvarList(class, &ivarCount);
        
        for (int i = 0; i < ivarCount; i++) {
            
            Ivar var = ivars[i];
            
            const char* name = ivar_getName(var);
            const char* typeEncoding = ivar_getTypeEncoding(var);

            if (strncmp(typeEncoding,"@",1) != 0) continue; // if it's not an object, ignore it
            
            id varValue = object_getIvar(obj, var);
            
            if (![varValue isKindOfClass:UIView.class]) continue;    // if it's not UIView or subclasses, ignore it

            NSString *key = [NSString stringWithFormat:@"%p", varValue];  // sth like "0x756e460"
            
            if (!dict[key]) dict[key] = [NSMutableArray array];
            [((NSMutableArray *) dict[key]) addObject: @(name)];
            
        }
        
        free(ivars);
        class = class_getSuperclass(class);
    }
    
}

static void recursivelyCollectIvarPointerToNamesDict(UIView *view, NSMutableDictionary *dict) {

    // collect ivars from associated viewcontroller, if applicable
    id nextResponder = [view nextResponder];
    if ([nextResponder isKindOfClass:UIViewController.class]) {
        collectUIViewIvarPointerToNameDict(nextResponder, dict);
    }

    // collect ivars from the view itself
    collectUIViewIvarPointerToNameDict(view, dict);
    
    // collect ivars from the view's subviews
    for (UIView *subview in view.subviews) {
        recursivelyCollectIvarPointerToNamesDict(subview, dict);
    }
    
}

#pragma mark - Pimping [UIView description] à la PST

static BOOL HOUIsVisibleView(UIView *view) { // same as PSPDFKitIsVisibleView
    BOOL isViewHidden = view.isHidden || view.alpha == 0 || CGRectIsEmpty(view.frame);
    return !view || (HOUIsVisibleView(view.superview) && !isViewHidden);
}

/**
 * Pretty much copy of PSPDFKitImproveRecursiveDescription
 *
 * Following code patches UIView's description to show the classname of an an view controller, if one is attached,
 * and adds XX for hidden views and warnings for wierd view frames.
 * Doesn't use any private API.
 */
static void HOUImproveUIViewDescription(void) {
    @autoreleasepool {
        
        SEL HOU_customViewDescription = @selector(HOU_customViewDescription);
        
        HOUReplaceMethodWithBlock(UIView.class, @selector(description), HOU_customViewDescription, ^(UIView *self) {
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            NSMutableString *description = [self performSelector:HOU_customViewDescription];
#pragma clang diagnostic pop
            
            id nextResponder = [(UIView *)self nextResponder]; // @steipete - replaced private api call to _viewDelegate by nextResponder check
            if ([nextResponder isKindOfClass:UIViewController.class]) {
                
                UIViewController *viewController = nextResponder;
                                
                NSString *viewControllerClassName = NSStringFromClass([viewController class]);
                
                if ([viewControllerClassName length]) {
                    NSString *children = @""; // iterate over childViewControllers
                    
                    if ([viewController respondsToSelector:@selector(childViewControllers)] && [viewController.childViewControllers count]) {
                        NSString *origDescription = description;
                        description = [NSMutableString stringWithFormat:@"%d child[", [viewController.childViewControllers count]];
                        for (UIViewController *childViewController in viewController.childViewControllers) {
                            [description appendFormat:@"%@:%p ", NSStringFromClass([childViewController class]), childViewController];
                        }
                        [description appendFormat:@"] %@", origDescription];
                    }
                    
                    // check if the frame of a childViewController is bigger than the one of a parentViewController. (usually this is a bug)
                    NSString *warnString = @"";
                    if (viewController && viewController.parentViewController && [viewController isViewLoaded] && [viewController.parentViewController isViewLoaded]) {
                        CGRect parentRect = viewController.parentViewController.view.bounds;
                        CGRect childRect = viewController.view.frame;
                        
                        if (parentRect.size.width < childRect.origin.x + childRect.size.width ||
                            parentRect.size.height < childRect.origin.y + childRect.size.height) {
                            warnString = @"* OVERLAP! ";
                        }else if(CGRectIsEmpty(childRect)) {
                            warnString = @"* ZERORECT! " ;
                        }
                    }
                    description = [NSMutableString stringWithFormat:@"%@'%@:%p'%@ %@", warnString, viewControllerClassName, viewController, children, description];
                }
            }
            
            // add marker if view is hidden.
            if (!HOUIsVisibleView(self)) {
                description = [NSMutableString stringWithFormat:@"XX (%@)", description];
            }
            
            return description;
        });
    }
}

#pragma mark - Pimping [UIImage description] and [UIImageView description] à la PST

/** 
 * A copy of PSPDFKitImproveImageDescription
 * Instead of "<UIImage: 0x8b612f0>" we want "<UIImage:0x8b612f0 size:{768, 1001} scale:1 imageOrientation:0>".
 * Doesn't use any private API.
 */
static void HOUImproveImageDescription() {
    @autoreleasepool {
        SEL descriptionSEL = @selector(HOU_description);
        HOUReplaceMethodWithBlock(UIImage.class, @selector(description), descriptionSEL, ^(UIImage *self) {
            NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p size:%@", self.class, self, NSStringFromCGSize(self.size)];
            if (self.scale > 1) {
                [description appendFormat:@" scale:%.0f", self.scale];
            }
            if ([self imageOrientation] != UIImageOrientationUp) {
                [description appendFormat:@" imageOrientation:%d", self.imageOrientation];
            }
            [description appendString:@">"];
            return [description copy];
        });
    }
}

/**
 * A copy of PSPDFKitImproveImageViewDescription
 * Instead of "<UIImage: 0x8b612f0>" we want "<UIImage:0x8b612f0 size:{768, 1001} scale:1 imageOrientation:0>".
 * Doesn't use any private API.
 */
static void HOUImproveImageViewDescription() {
    @autoreleasepool {
        SEL descriptionSEL = NSSelectorFromString(@"HOU_description");
        HOUReplaceMethodWithBlock(UIImageView.class, @selector(description), descriptionSEL, ^(UIImageView *self) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            return [NSString stringWithFormat:@"%@->%@", [self performSelector:descriptionSEL], [self.image description]];
#pragma clang diagnostic pop
        });
    }
}

#pragma mark - Rollout all wanted Pimp-functions on construction

__attribute__((constructor)) static void HOURollOutDescriptionPimping() {
    
    // make sure the PST implementation isn't duplicated here
    BOOL alreadyAddedByPST = (class_getInstanceMethod(UIView.class, @selector(pspdf_customViewDescription))) ||
                             (class_getInstanceMethod(UIView.class, @selector(pspdf_description)));
    
    if (!alreadyAddedByPST) {
        HOUImproveUIViewDescription();
        HOUImproveImageDescription();
        HOUImproveImageViewDescription();
    }
    
}

#pragma mark - Categories

@implementation UIView (HOURecursiveDescription)

/**
 * recursiveDescription2 augments each view with its corresponding ivar name(s)
 * Calls private API [UIView recursiveDescription]
 */
- (NSString *)recursiveDescription2 {
    UIView *view = self;
    
    NSMutableString *description = [[view recursiveDescription] mutableCopy]; //private, but ok, since only compiled in DEBUG
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    recursivelyCollectIvarPointerToNamesDict(view, dict);
    
    // regex matches UIView-like description formats e.g. "<UIView: 0x756e460;" in two groups
    // index 1 (<UIView: ), index 2 (0x756e460), index 0 is the entire match
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"(<[^:]+: )(0x[0-9a-z]+);" options:0 error:nil];
    
    NSArray *matches = [regex matchesInString:description options:0 range:NSMakeRange(0, description.length)];
    
    for (NSTextCheckingResult *match in [[matches reverseObjectEnumerator] allObjects]) {
        // traverse backwards, so the matched ranges stay accurate when inserting strings
        
        NSRange range = [match rangeAtIndex:2];
        if (range.length > 0) {
            NSString *addressString = [description substringWithRange:range];
            
            NSArray *names = dict[addressString];
            if (names.count > 0) {
                NSString *fullMatch = [description substringWithRange:[match rangeAtIndex:0]];
                
                [description replaceCharactersInRange:[match rangeAtIndex:0] withString:[NSString stringWithFormat:@"%@ %@", [names componentsJoinedByString:@", "] ,fullMatch]];
            }
            
        }
    }
    return description;
}

@end

@implementation UIApplication (HOURecursiveDescription)

- (NSString *)recursiveDescription2 {
    return [[self keyWindow] recursiveDescription2];
}

+ (NSString *)recursiveDescription2 {
    return [[[UIApplication sharedApplication] keyWindow] recursiveDescription2];
}

@end

@implementation UIViewController(HOURecursiveDescription)
- (NSString *)recursiveDescription2 {
    return [self.view recursiveDescription2];
}
@end

#endif

