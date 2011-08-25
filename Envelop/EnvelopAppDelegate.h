//
//  EnvelopAppDelegate.h
//  Envelop
//
//  Created by Anders on 6/20/11.
//  Copyright 2011 Capasit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EnvelopAppDelegate : NSObject <NSApplicationDelegate> {
@private
    
    Float32 oscillateSpeed;
    
    BOOL isPlaying, isOscillating;
    NSWindow *window;
    NSThread *oscillateVolumeThread, *audioThread;
    NSStatusItem *statusItem;
    NSUserDefaults *preferences;
    
    IBOutlet BOOL showDockIcon;
    
    IBOutlet NSView *audioTabSubView;

    IBOutlet NSSlider *volumeSlider, *filterSlider, *statusMenuVolumeSlider;
    IBOutlet NSMenu *statusMenu;
    IBOutlet NSMenuItem *playItem;
    IBOutlet NSTextField *hzLabel;
    IBOutlet NSButton *filterButton, *closePrefsButton, *showDockIconButton;
    IBOutlet NSButton *showAdvancedButton;
    IBOutlet NSBox *advancedBox;
    IBOutlet NSMenuItem *volumeItem;
    IBOutlet NSPopUpButton *noiseTypePopUp, *oscillationRangePopUp, *oscillationSpeedPopUp, *oscillationStartPopUp, *oscillationTypePopUp, *filterPopUp;
}

@property (assign) IBOutlet NSView *audioTabSubView;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton *showAdvancedButton, *closePrefsButton, *filterButton;
@property (assign) IBOutlet NSMenu *statusMenu;
@property (assign) IBOutlet NSMenuItem *playItem;
@property (assign) IBOutlet NSSlider *volumeSlider, *filterSlider;
@property (assign) IBOutlet NSBox *advancedBox;
@property (assign) IBOutlet NSMenuItem *volumeItem;
@property (assign) IBOutlet NSTextField *hzLabel;
@property (assign) IBOutlet NSPopUpButton *noiseTypePopUp, *oscillationRangePopUp, *oscillationSpeedPopUp, *oscillationStartPopUp, *oscillationTypePopUp, *filterPopUp;

- (IBAction) changeVolume:(id) sender;
- (IBAction) changeNoiseType:(id) sender;
- (IBAction) playPause:(id) sender;
- (IBAction) changeCutoff:(id) sender;
- (IBAction) changePresetCutoff:(id) sender;
- (IBAction) startStopOscillateVolume:(id) sender;
- (IBAction) changeOscillateRange:(id)sender;
- (IBAction) changeOscillateSpeed:(id)sender;
- (IBAction) changeOscillateStart:(id)sender;
- (IBAction) showHideDockIcon:(id)sender;

@end

enum {
    kFilterBreeze,
    kFilterRainstorm,
    kFilterAirplane,
    kFilterConcorde,
    kFilterWaterfallFar,
    kFilterWaterfallNear,
    kFilterWaterfallUnder,
    kFilterSR71Blackbird,
    kFilterCustom = 99
};

enum {
    kNoiseTypeWhite,
    kNoiseTypeBrown,
    kNoiseTypePink
};

enum {
    kOscillateSpeedSlow,
    kOscillateSpeedNormal,
    kOscillateSpeedFast 
};

enum {
    kOscillateStartLow, 
    kOscillateStartMiddle,
    kOscillateStartHigh
};

enum {
    kOscillateRangeShort, 
    kOscillateRangeMedium,
    kOscillateRangeLong
};
