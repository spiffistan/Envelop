//
//  EnvelopAppDelegate.h
//  Envelop
//
//  Created by Anders on 6/20/11.
//  Copyright 2011 Capasit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define BUFFERS 3

@interface EnvelopAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
    IBOutlet NSSlider *pitchSlider, *gainSlider, *filterSlider;
    IBOutlet NSMenu *statusMenu;
    IBOutlet NSMenuItem *playItem;
    IBOutlet NSButton *playButton, *generateButton;
    IBOutlet NSTextField *hzLabel;
    IBOutlet NSButton *pitchButton, *gainButton, *filterButton;
    IBOutlet NSProgressIndicator *spinner;
    IBOutlet NSButton *showAdvancedButton;
    IBOutlet NSBox *advancedBox;
    NSStatusItem *statusItem;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton *playButton, *showAdvancedButton;
@property (assign) IBOutlet NSMenuItem *playItem;
@property (assign) IBOutlet NSSlider *pitchSlider, *gainSlider, *filterSlider;
@property (assign) IBOutlet NSBox *advancedBox;

- (IBAction) changePitch:(id) sender;
- (IBAction) startStopOscillatePitch:(id) sender;
- (IBAction) changeGain:(id) sender;
- (IBAction) startStopOscillateGain:(id) sender;
- (IBAction) generateNoise:(id) sender;
- (IBAction) playPause:(id) sender;
- (IBAction) changeCutoff:(id) sender;

@end
