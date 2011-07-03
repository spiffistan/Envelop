//
//  EnvelopAppDelegate.m
//  Envelop
//
//  Created by Anders on 6/20/11.
//  Copyright 2011 Capasit. All rights reserved.
//

#import "EnvelopAppDelegate.h"
#import "StatusVolumeView.h"

#include "AudioController.h"
#include "NoiseUtils.h"

Float32 cutoff = 300.0f;
Float32 volume = 0.5f;
BOOL generateWhite = NO;

@implementation EnvelopAppDelegate

@synthesize window;
@synthesize statusMenu, playItem, volumeItem;
@synthesize showAdvancedButton, advancedBox;
@synthesize volumeSlider, filterSlider, filterButton;
@synthesize closePrefsButton;
@synthesize hzLabel;

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
    kOscillateSlow,
    kOscillateNormal,
    kOscillateFast 
};

enum {
    kOscillateLow, 
    kOscillateMiddle,
    kOscillateHigh
};

enum {
    kOscillateShort, 
    kOscillateMedium,
    kOscillateLong
};

////////////////////////////////////////////////////////////////////////////////
/// Overrides
////////////////////////////////////////////////////////////////////////////////

- (void) applicationDidFinishLaunching:(NSNotification *) aNotification
{    
    StatusVolumeView *controller = [[StatusVolumeView alloc] initWithNibName:@"StatusVolumeView" bundle:nil];
    
    [volumeItem setView:[controller view]];
    
    statusMenuVolumeSlider = [controller volumeSlider];
    
    [controller release];
    
    isPlaying = YES;
    isOscillating = NO;
    oscillateSpeed = 10000;
        
    audioThread = [[NSThread alloc] initWithTarget:self selector:@selector(startAudio:) object:nil];

    [audioThread start];
    

}

- (void) awakeFromNib
{
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    NSImage * image = [NSImage imageNamed:@"envelop-icon-status.png"];
    
    [statusItem setImage:image];
    [statusItem setMenu:statusMenu];
    [statusItem setHighlightMode:YES];
}

////////////////////////////////////////////////////////////////////////////////

- (void) startAudio:(id) sender
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
    CreateAU();
	StartAU();
    
    [pool drain];
}

- (void) changeCutoff:(id) sender
{
    [hzLabel setStringValue:[NSString stringWithFormat:@"%d Hz", [filterSlider intValue]]];
    
    cutoff = [filterSlider floatValue];
}

- (void) changePresetCutoff:(id) sender 
{
    BOOL enableFilterSlider = NO;
    
    switch ([sender tag]) 
    {
        case kFilterBreeze: 
            cutoff = 100.0f;
            break;
    
        case kFilterRainstorm:
            cutoff = 300.0f;
            break;
        
        case kFilterAirplane:
            cutoff = 400.0f;
            break;
        
        case kFilterConcorde:
            cutoff = 550.0f;
            break;
        
        case kFilterWaterfallFar:
            cutoff = 650.0f;
            break;
        
        case kFilterWaterfallNear:
            cutoff = 1200.0f;
            break;
            
        case kFilterWaterfallUnder:
            cutoff = 1700.0f;
            break;
        
        case kFilterSR71Blackbird:
            cutoff = 2800.0f;
            break;
            
        case kFilterCustom:
            enableFilterSlider = YES;
            break;
            
        default:
            break;
    }
    
    [hzLabel setStringValue:[NSString stringWithFormat:@"%d Hz", ((int) cutoff)]];
    [filterSlider setEnabled:enableFilterSlider];
    [filterSlider setFloatValue:cutoff];
}

- (IBAction) changeNoiseType:(id) sender
{
    switch ([sender tag]) {
        case kNoiseTypeWhite:
            generateWhite = YES;
            break;
            
        case kNoiseTypeBrown:
            generateWhite = NO;
            break;
            
        default:
            break;
    }
}

// TODO 

Float64 b = 0.2, c = 0.3, d = 1.3, t = 0;

- (IBAction) oscillateVolume:(id) sender
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
    int i = 0;
            
    while(isOscillating)
    {
        usleep(oscillateSpeed);
        
        double x = -c/2 * (cos((M_PI * t) / d) - 1) + b;
        
        if(i < 10) 
            i++;
        else 
        {
            i = 0;
            [volumeSlider setDoubleValue:x];
            [statusMenuVolumeSlider setDoubleValue:x];
        }
        
        t += 0.001;
                
        SetAUVolume((float) x);
        
    }
    
    [pool drain];
} 

- (IBAction) changeOscillateSpeed:(id)sender
{
    switch ([sender tag]) {
        case kOscillateFast:
            oscillateSpeed = 1000;
            break;
        case kOscillateNormal:
            oscillateSpeed = 3000;
            break;
        case kOscillateSlow:
            oscillateSpeed = 10000;
            break;
        default:
            break;
    }
}

- (IBAction) changeVolume:(id) sender
{
    volume = [volumeSlider floatValue];
    
    SetAUVolume(volume);
}

- (IBAction) startStopOscillateVolume:(id) sender
{
    if(!isOscillating)
    {
        isOscillating = YES;
        [volumeSlider setEnabled:NO];
        [statusMenuVolumeSlider setEnabled:NO];
        oscillateVolumeThread = [[NSThread alloc] initWithTarget:self selector:@selector(oscillateVolume:) object:nil];
        [oscillateVolumeThread start];
    }
    else
    {
        isOscillating = NO;
        [volumeSlider setEnabled:YES];
        [statusMenuVolumeSlider setEnabled:YES];
        [oscillateVolumeThread cancel];
    }
}
/*
- (IBAction) changeOscillationSpeed:(id) sender 
{
    if ([sender tag] == 1) {
        oscillateGainSpeed = 1000;
    } else if([sender tag] == 2) {
        oscillateGainSpeed = 500;
    } else if([sender tag] == 3) {
        oscillateGainSpeed = 100;
    }
}

// TODO constants

- (IBAction) changeOscillationRange:(id) sender 
{
    if ([sender tag] == 1) {
        b = 0.2, c = 0.3, d = 1.3, t = 0;
    } else if([sender tag] == 2) {
        b = 0.4, c = 0.3, d = 1.3, t = 0;
    } else if([sender tag] == 3) {
        b = 0.6, c = 0.3, d = 1.3, t = 0;
    }
}*/

- (IBAction) playPause:(id) sender
{
    if(isPlaying)
    {

        [statusItem setImage:[NSImage imageNamed:@"envelop-icon-status.png"]];
        [playItem setTitle:@"Play"];
        StopAU();
    }
    else
    {
        [statusItem setImage:[NSImage imageNamed:@"envelop-icon-status-active.png"]];
        [playItem setTitle:@"Pause"];
        StartAU();
    }
}

- (IBAction) showPrefsWindow:(id) sender
{
    [window setIsVisible:YES];
}

- (IBAction) showHideAdvancedPanel:(id) sender
{
    NSRect advancedBoxFrame = [advancedBox frame];
    NSRect windowFrame = [window frame];
    
    UInt16 sizeDiff = 232; // Pixels
        
    switch ([sender state]) 
    {
        case NSOnState:
            
            advancedBoxFrame.size.height += sizeDiff;
            windowFrame.size.height += sizeDiff;
            windowFrame.origin.y -= sizeDiff;
            break;
            
        case NSOffState:
            
            advancedBoxFrame.size.height -= sizeDiff;
            windowFrame.size.height -= sizeDiff;
            windowFrame.origin.y += sizeDiff;
            break;
    }
    
    [window setFrame:windowFrame display:YES animate:YES];
    [advancedBox setFrame:advancedBoxFrame];

}

@end
