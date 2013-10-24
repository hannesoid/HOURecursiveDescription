//
//  RootViewController.m
//  RecursiveDescriptionExample
//
//  Created by Hannes Oud on 04.05.13.
//  Copyright (c) 2013 Hannes Oud. All rights reserved.
//

#import "RootViewController.h"
#import <HOURecursiveDescription/HOURecursiveDescription.h>
@interface RootViewController ()

@property (weak, nonatomic) IBOutlet UIView *subview1;
@property (weak, nonatomic) IBOutlet UIButton *myButton;
@property (weak, nonatomic) IBOutlet UIButton *myButton2;
@property (weak, nonatomic) IBOutlet UIView *greyBlob;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation RootViewController

- (IBAction)buttonPressed:(id)sender {
#if DEBUG
    __unused NSString *descr = [self.view recursiveDescription2];
    // a breakpoint here outputs descr
#endif
}

@end
