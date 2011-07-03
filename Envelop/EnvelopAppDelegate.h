//
//  EnvelopAppDelegate.h
//  Envelop
//
//  Created by Anders on 6/20/11.
//  Copyright 2011 Capasit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AudioController.h"

@interface EnvelopAppDelegate : NSObject <NSApplicationDelegate> {
@private
    
    Float32 oscillateSpeed;
    
    BOOL isPlaying, isOscillating;
    NSWindow *window;
    NSThread *oscillateVolumeThread, *audioThread;
    
    IBOutlet NSSlider *volumeSlider, *filterSlider, *statusMenuVolumeSlider;
    IBOutlet NSMenu *statusMenu;
    IBOutlet NSMenuItem *playItem;
    IBOutlet NSTextField *hzLabel;
    IBOutlet NSButton *filterButton, *closePrefsButton;
    IBOutlet NSButton *showAdvancedButton;
    IBOutlet NSBox *advancedBox;
    IBOutlet NSStatusItem *statusItem;
    IBOutlet NSMenuItem *volumeItem;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton *showAdvancedButton, *closePrefsButton, *filterButton;
@property (assign) IBOutlet NSMenu *statusMenu;
@property (assign) IBOutlet NSMenuItem *playItem;
@property (assign) IBOutlet NSSlider *volumeSlider, *filterSlider;
@property (assign) IBOutlet NSBox *advancedBox;
@property (assign) IBOutlet NSMenuItem *volumeItem;
@property (assign) IBOutlet NSTextField *hzLabel;

- (IBAction) changeVolume:(id) sender;
- (IBAction) changeNoiseType:(id) sender;
- (IBAction) playPause:(id) sender;
- (IBAction) changeCutoff:(id) sender;
- (IBAction) changePresetCutoff:(id) sender;
- (IBAction) startStopOscillateVolume:(id) sender;
- (IBAction) changeOscillateSpeed:(id)sender;

@end
