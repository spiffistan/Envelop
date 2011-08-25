//
//  EnvelopAppDelegate.m
//  Envelop
//
//  Created by Anders on 6/20/11.
//  Copyright 2011 Capasit. All rights reserved.
//

#import "EnvelopAppDelegate.h"
#import "StatusVolumeView.h"
#import "AudioController.h"

Float32 cutoff = 300.0f;
Float32 volume = 0.5f;
BOOL generateWhite = NO;

@implementation EnvelopAppDelegate

@synthesize window;
@synthesize statusMenu, playItem, volumeItem;
@synthesize showAdvancedButton, advancedBox, audioTabSubView;
@synthesize volumeSlider, filterSlider, filterButton;
@synthesize closePrefsButton;
@synthesize hzLabel;
@synthesize noiseTypePopUp, oscillationRangePopUp, oscillationSpeedPopUp, oscillationStartPopUp, oscillationTypePopUp, filterPopUp;

////////////////////////////////////////////////////////////////////////////////
/// Overrides
////////////////////////////////////////////////////////////////////////////////

- (void) applicationDidFinishLaunching:(NSNotification *) aNotification
{    
    StatusVolumeView *controller = [[StatusVolumeView alloc] initWithNibName:@"StatusVolumeView" bundle:nil];
    
    volumeItem.view = controller.view;
    statusMenuVolumeSlider = controller.volumeSlider;
    
    [controller release];
    
    [noiseTypePopUp selectItemWithTag:kNoiseTypeBrown];
    [oscillationRangePopUp selectItemWithTag:kOscillateRangeMedium];
    [oscillationStartPopUp selectItemWithTag:kOscillateStartMiddle];
    [oscillationSpeedPopUp selectItemWithTag:kOscillateSpeedNormal];
    [filterPopUp selectItemWithTag:kFilterRainstorm];
    
    isPlaying = YES;
    isOscillating = NO;
    oscillateSpeed = 2500;
        
    audioThread = [[NSThread alloc] initWithTarget:self selector:@selector(startAudio:) object:nil];

    [audioThread start];
    

}

- (void) awakeFromNib
{
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    NSImage * image = [NSImage imageNamed:@"envelop-statusbar-active-new-20.png"];
    
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



////////////////////////////////////////////////////////////////////////////////

- (void) changeCutoff:(id) sender
{
    [hzLabel setStringValue:[NSString stringWithFormat:@"%d Hz", [filterSlider intValue]]];
    
    cutoff = [filterSlider floatValue];
}



////////////////////////////////////////////////////////////////////////////////

- (void) changePresetCutoff:(id) sender 
{
    BOOL enableFilterSlider = NO;
    
    switch ([sender tag]) 
    {
        case kFilterBreeze:         cutoff = 100.0f;    break;
        case kFilterRainstorm:      cutoff = 300.0f;    break;
        case kFilterAirplane:       cutoff = 400.0f;    break;
        case kFilterConcorde:       cutoff = 550.0f;    break;
        case kFilterWaterfallFar:   cutoff = 650.0f;    break;
        case kFilterWaterfallNear:  cutoff = 1200.0f;   break;
        case kFilterWaterfallUnder: cutoff = 1700.0f;   break;
        case kFilterSR71Blackbird:  cutoff = 2800.0f;   break;
            
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



////////////////////////////////////////////////////////////////////////////////

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



////////////////////////////////////////////////////////////////////////////////

Float64 b = 0.3, c = 0.3, d = 1, t = 0; // b: offset, c: range, d: divider, t: counter

- (IBAction) oscillateVolume:(id) sender
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
    int i = 0;
    double x;
            
    while(isOscillating)
    {
        usleep(oscillateSpeed);
         
        x = -c/2 * (cos((M_PI * t) / d) - 1) + b;
                
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



////////////////////////////////////////////////////////////////////////////////

- (IBAction) changeOscillateRange:(id)sender
{
    switch ([sender tag]) 
    {
        case kOscillateRangeLong:
            c = 0.4;
            break;
        case kOscillateRangeMedium:
            c = 0.3;
            break;
        case kOscillateRangeShort:
            c = 0.2;
            break;
        default:
            break;
    }
}



////////////////////////////////////////////////////////////////////////////////

- (IBAction) changeOscillateSpeed:(id)sender
{
    switch ([sender tag]) 
    {
        case kOscillateSpeedFast:
            oscillateSpeed = 1000;
            break;
        case kOscillateSpeedNormal:
            oscillateSpeed = 2500;
            break;
        case kOscillateSpeedSlow:
            oscillateSpeed = 7000;
            break;
        default:
            break;
    }
}



////////////////////////////////////////////////////////////////////////////////

- (IBAction) changeOscillateStart:(id)sender

{
    switch ([sender tag]) 
    {
        case kOscillateStartLow:
            b = 0.1;
            break;
        case kOscillateStartMiddle:
            b = 0.3;
            break;
        case kOscillateStartHigh:
            b = 0.6;
            break;
        default:
            break;
    }
}



////////////////////////////////////////////////////////////////////////////////

- (IBAction) changeVolume:(id) sender
{
    volume = [volumeSlider floatValue];
    
    SetAUVolume(volume);
}



////////////////////////////////////////////////////////////////////////////////

- (IBAction) startStopOscillateVolume:(id) sender
{
    if(!isOscillating)
    {
        isOscillating = YES;
        volumeSlider.enabled = NO;
        statusMenuVolumeSlider.enabled = NO;
        
        oscillateVolumeThread = [[NSThread alloc] initWithTarget:self selector:@selector(oscillateVolume:) object:nil];
        [oscillateVolumeThread start];
    }
    else
    {
        isOscillating = NO;
        volumeSlider.enabled = YES;
        statusMenuVolumeSlider.enabled = YES;
        
        [oscillateVolumeThread cancel];
    }
}



////////////////////////////////////////////////////////////////////////////////

- (IBAction) playPause:(id) sender
{
    if(isPlaying)
    {

        statusItem.image = [NSImage imageNamed:@"envelop-statusbar-active-new-20.png"];
        playItem.title = @"Play";
        
        isPlaying = NO;
        StopAU();
    }
    else
    {
        statusItem.image = [NSImage imageNamed:@"envelop-statusbar-inactive-new-20.png"];
        playItem.title = @"Pause";
        isPlaying = YES;
        StartAU();
    }
}



////////////////////////////////////////////////////////////////////////////////

- (IBAction) showPrefsWindow:(id) sender
{
    window.isVisible = YES;
}



////////////////////////////////////////////////////////////////////////////////

- (IBAction) showHideAdvancedPanel:(id) sender
{
    NSRect advancedBoxFrame = [advancedBox frame];
    NSRect audioTabSubViewFrame = [audioTabSubView frame];
    NSRect windowFrame = [window frame];
    
    UInt16 sizeDiff = 232; // Pixels
        
    switch ([sender state]) 
    {
        case NSOnState:
            
            advancedBoxFrame.size.height += sizeDiff;
            audioTabSubViewFrame.size.height += sizeDiff;
            windowFrame.size.height += sizeDiff;
            windowFrame.origin.y -= sizeDiff;
            break;
            
        case NSOffState:
            
            advancedBoxFrame.size.height -= sizeDiff;
            audioTabSubViewFrame.size.height -= sizeDiff;
            windowFrame.size.height -= sizeDiff;
            windowFrame.origin.y += sizeDiff;
            break;
    }
    
    [window setFrame:windowFrame display:YES animate:YES];
    [audioTabSubView setFrame:audioTabSubViewFrame];
    [advancedBox setFrame:advancedBoxFrame];

}

@end
