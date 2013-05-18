//
//  HOURecursiveDescription.m
//  HOURecursiveDescription
//
//  Created by Hannes Oud on 04.05.13.
//  Copyright (c) 2013 Hannes Oud. All rights reserved.
//

#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#if DEBUG

#pragma mark - Adding [UIView recursiveDescription2]

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

            NSNumber *key = [NSString stringWithFormat:@"%p", varValue];  // sth like "0x756e460"
            
            if (!dict[key]) dict[key] = [[NSMutableArray alloc] init];
            [((NSMutableArray *) dict[key]) addObject: [NSString stringWithCString:name encoding:NSASCIIStringEncoding]];
            
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

/**
 * Adds the method [recursiveDescription2] to UIView.
 * recursiveDescription2 augments each view with its corresponding ivar name(s)
 */
__attribute__((constructor)) static void HOUDAddRecursiveDescription2(void) {
    @autoreleasepool {
        
        SEL recursiveDescription2SEL = @selector(recursiveDescription2);
        IMP recursiveDescription2IMP = imp_implementationWithBlock(^(id _self) {
            UIView *view = _self;
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            SEL recDescSEL = NSSelectorFromString([NSString stringWithFormat:@"%@Description",@"recursive"]);
            NSMutableString *description = [view performSelector:recDescSEL];
#pragma clang diagnostic pop
            
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
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
        });
        
        class_addMethod(UIView.class, recursiveDescription2SEL, recursiveDescription2IMP, "@@:");
        
    }
}

#pragma mark - Pimping [UIView description]

void HOUswizzle(Class c, SEL orig, SEL new) { // same as pspdf_swizzle
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    }else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}


static BOOL HOUIsVisibleView(UIView *view) { // same as PSPDFKitIsVisibleView
    BOOL isViewHidden = view.isHidden || view.alpha == 0 || CGRectIsEmpty(view.frame);
    return !view || (HOUIsVisibleView(view.superview) && !isViewHidden);
}



// Following code patches UIView's description to show the classname of an an view controller, if one is attached.
// Will only get compiled for debugging. Use 'po [[UIWindow keyWindow] recursiveDescription]' to invoke.
__attribute__((constructor)) static void HOUImproveUIViewDescription(void) { // almost same as PSPDFKitImproveRecursiveDescription
    @autoreleasepool {
        
        SEL customViewDescriptionSEL = NSSelectorFromString(@"pspdf_customViewDescription");
        IMP customViewDescriptionIMP = imp_implementationWithBlock(^(id _self) {
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            NSMutableString *description = [_self performSelector:customViewDescriptionSEL];
#pragma clang diagnostic pop
            
            id nextResponder = [(UIView *)_self nextResponder]; // @steipete - replaced private api call to _viewDelegate by nextResponder check
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
            if (!HOUIsVisibleView(_self)) {
                description = [NSMutableString stringWithFormat:@"XX (%@)", description];
            }
            
            return description;
        });
        class_addMethod([UIView class], customViewDescriptionSEL, customViewDescriptionIMP, "@@:");
        HOUswizzle([UIView class], @selector(description), customViewDescriptionSEL);
    }
}
#endif