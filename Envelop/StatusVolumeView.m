//
//  StatusVolumeView.m
//  Envelop
//
//  Created by Anders on 6/27/11.
//  Copyright 2011 Capasit. All rights reserved.
//

#import "StatusVolumeView.h"


@implementation StatusVolumeView
@synthesize volumeSlider;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

@end
