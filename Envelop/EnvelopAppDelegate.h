//
//  EnvelopAppDelegate.h
//  Envelop
//
//  Created by Anders on 6/20/11.
//  Copyright 2011 Capasit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMDoubleSlider.h"

#ifdef DEBUG
#	define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#	define DLog(...)
#endif

@interface EnvelopAppDelegate : NSObject <NSApplicationDelegate> {
@private
    
    Float32 oscillateSpeed;
    Float64 b, c, d, t;
    
    double (*easer)(double, double, double, double);
    
    BOOL isPlaying, isOscillating;
    NSWindow *window;
    NSThread *oscillateVolumeThread, *audioThreadOut, *audioThreadIn;
    NSStatusItem *statusItem;
    //NSUserDefaults *preferences;
    
    IBOutlet BOOL showDockIcon;
    
    IBOutlet NSView *audioTabSubView;
    
    IBOutlet SMDoubleSlider *rangeSlider;

    IBOutlet NSSlider *volumeSlider, *filterSlider, *statusMenuVolumeSlider, *oscillateSpeedSlider;
    IBOutlet NSMenu *statusMenu;
    IBOutlet NSMenuItem *playItem;
    IBOutlet NSTextField *hzLabel;
    IBOutlet NSButton *filterButton, *closePrefsButton, *showDockIconButton, *oscillationButton, *startStopButton;
    IBOutlet NSButton *showAdvancedButton;
    IBOutlet NSBox *advancedBox;
    IBOutlet NSMenuItem *volumeItem;
    IBOutlet NSPopUpButton *noiseTypePopUp, *oscillationRangePopUp, *oscillationSpeedPopUp, *oscillationStartPopUp, *oscillationTypePopUp, *filterPopUp;
}

@property (assign) IBOutlet NSView *audioTabSubView;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton *showAdvancedButton, *closePrefsButton, *filterButton, *oscillationButton, *startStopButton;
@property (assign) IBOutlet NSMenu *statusMenu;
@property (assign) IBOutlet NSMenuItem *playItem;
@property (assign) IBOutlet NSSlider *volumeSlider, *filterSlider, *oscillateSpeedSlider;
@property (assign) IBOutlet NSBox *advancedBox;
@property (assign) IBOutlet NSMenuItem *volumeItem;
@property (assign) IBOutlet NSTextField *hzLabel;
@property (assign) IBOutlet NSPopUpButton *noiseTypePopUp, *oscillationRangePopUp, *oscillationSpeedPopUp, *oscillationStartPopUp, *oscillationTypePopUp, *filterPopUp;
@property (assign) IBOutlet SMDoubleSlider *rangeSlider;

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
- (IBAction) startStopFilter:(id)sender;
- (IBAction) changeEasing:(id)sender;


- (void) changeFilter:(NSInteger)tag;
- (void) savePrefs;
- (void) loadPrefs;
- (void) oscillate:(BOOL)start;
- (void) oscillateVolume;

@end

double easeInOutQuad   (double t, double b, double c, double d);
double easeInOutCubic  (double t, double b, double c, double d);
double easeInOutExpo   (double t, double b, double c, double d);
double easeInOutSine   (double t, double b, double c, double d);


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
    kEasingQuad,
    kEasingCubic,
    kEasingSine,
    kEasingExpo
};

enum {
    kOscillateSpeedSlow,
    kOscillateSpeedNormal,
    kOscillateSpeedFast,
    kOscillateSpeedCustom = 99,
    kOscillateSpeedSlider
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
