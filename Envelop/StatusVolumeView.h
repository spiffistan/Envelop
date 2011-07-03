//
//  StatusVolumeView.h
//  Envelop
//
//  Created by Anders on 6/27/11.
//  Copyright 2011 Capasit. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface StatusVolumeView : NSViewController {
@private
    IBOutlet NSSlider *volumeSlider;
}

@property (assign, readwrite) IBOutlet NSSlider *volumeSlider;

@end
