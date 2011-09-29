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
BOOL enableFilter = YES;
int noiseType = 1;

@implementation EnvelopAppDelegate

@synthesize window;
@synthesize statusMenu, playItem, volumeItem;
@synthesize showAdvancedButton, advancedBox, audioTabSubView;
@synthesize volumeSlider, filterSlider, rangeSlider, oscillateSpeedSlider, filterButton, startStopButton;
@synthesize closePrefsButton, oscillationButton;
@synthesize hzLabel;
@synthesize noiseTypePopUp, oscillationRangePopUp, oscillationSpeedPopUp, oscillationStartPopUp, oscillationTypePopUp, filterPopUp;

////////////////////////////////////////////////////////////////////////////////
/// Overrides
////////////////////////////////////////////////////////////////////////////////

- (id)init
{
    b = 0.3f, c = 0.3f, d = 1, t = 0;    
    return (self);
}

- (void) applicationDidFinishLaunching:(NSNotification *) aNotification
{    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self
           selector:@selector(applicationWillTerminate:)
               name:NSApplicationWillTerminateNotification
             object:nil];
    
    NSUserDefaults *preferences = [[NSUserDefaults standardUserDefaults] retain];
    
    showDockIcon = ![[[[NSBundle mainBundle] infoDictionary] objectForKey:@"LSUIElement"] boolValue];
    
    StatusVolumeView *controller = [[StatusVolumeView alloc] initWithNibName:@"StatusVolumeView" bundle:nil];
    
    volumeItem.view = controller.view;
    statusMenuVolumeSlider = controller.volumeSlider;
    
    [controller release];
        
    [rangeSlider setMaxValue:1.0f];
    [rangeSlider setMinValue:0.0f];
    [rangeSlider setFloatHiValue:(b+c)];
    [rangeSlider setFloatLoValue:b];
    [rangeSlider setNumberOfTickMarks:25];
    [rangeSlider setContinuous:YES];
    [rangeSlider setAction:@selector(changeRange:)];
    [rangeSlider setTickMarkPosition:NSTickMarkAbove];
    [[rangeSlider cell] setControlSize:NSSmallControlSize];
    [rangeSlider setEnabled:NO];
    
    isPlaying = YES;
    isOscillating = NO;
    oscillateSpeed = 2500;
    easer = &easeInOutQuad;
    
    if([preferences integerForKey:@"appHasLaunched"])
    {
        [self loadPrefs];
    }
    else 
    {
        [preferences setInteger:1 forKey:@"appHasLaunched"];
        [noiseTypePopUp selectItemWithTag:kNoiseTypeBrown];
        [oscillationSpeedPopUp selectItemWithTag:kOscillateSpeedNormal];
        [filterPopUp selectItemWithTag:kFilterRainstorm];
    }
        
    audioThreadOut = [[NSThread alloc] initWithTarget:self selector:@selector(startAudio:) object:nil];

    [audioThreadOut start];
    
}

- (void) awakeFromNib
{
    [NSApp setDelegate: self]; 
    
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    NSImage * image = [NSImage imageNamed:@"statusbar-active.png"];
    
    [statusItem setImage:image];
    [statusItem setMenu:statusMenu];
    [statusItem setHighlightMode:YES];

}

- (void) applicationWillTerminate: (NSNotification *)notification
{
    [self savePrefs];
}

////////////////////////////////////////////////////////////////////////////////

- (void) startAudio:(id) sender
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
    CreateAU();
	StartAU();

    [pool drain];
}
/*
- (void) startMic:(id) sender
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    CreateMicrophoneAU();
	StartMicrophoneAU();
    
    [pool drain];
}
*/


////////////////////////////////////////////////////////////////////////////////

- (void) changeCutoff:(id) sender
{
    [hzLabel setStringValue:[NSString stringWithFormat:@"%d Hz", [filterSlider intValue]]];
    
    cutoff = [filterSlider floatValue];
}

- (void) changeRange:(SMDoubleSlider *) sender
{
    b = [sender doubleLoValue];
    c = [sender doubleHiValue] - b;
}



////////////////////////////////////////////////////////////////////////////////

- (IBAction) changePresetCutoff:(id) sender 
{
    [self changeFilter:[sender tag]];
}

- (void) changeFilter:(NSInteger) tag
{
    BOOL enableFilterSlider = NO;
    
    switch (tag) 
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
    }
    
    [hzLabel setStringValue:[NSString stringWithFormat:@"%d Hz", ((int) cutoff)]];
    [filterSlider setEnabled:enableFilterSlider];
    [filterSlider setFloatValue:cutoff];
}


////////////////////////////////////////////////////////////////////////////////

- (IBAction) changeNoiseType:(id) sender
{
    noiseType = (int) [sender tag];
}

double easeInOutQuad  (double t, double b, double c, double d) 
{
	if (t < d / 2) return 2 * c * t * t / (d * d) + b;
	double ts = t - d/2;
	return -2 * c * ts * ts / (d * d) + 2 * c * ts / d + c / 2 + b;
}

double easeInOutCubic  (double t, double b, double c, double d) 
{
    if ((t /= d / 2) < 1)
    return c / 2 * t * t * t + b;
    return c / 2 * ((t -= 2) * t * t + 2) + b;
}

double easeInOutSine (double t, double b, double c, double d) 
{
	return -c/2 * (cos(M_PI*t/d) - 1) + b;
}

double easeInOutExpo (double t, double b, double c, double d) 
{
    if (t == 0) return b;
    if (t == d) return b+c;
    if ((t /= d/2) < 1) return c/2 * pow(2, 10 * (t - 1)) + b;
    return c/2 * (-pow(2, -10 * --t) + 2) + b;
}


- (IBAction) changeEasing:(id)sender
{
    switch ([sender tag]) 
    {
        case kEasingQuad:
            easer = &easeInOutQuad;
            break;
        case kEasingCubic:
            easer = &easeInOutCubic;
            break;
        case kEasingSine: 
            easer = &easeInOutSine;
            break;
        case kEasingExpo:
            easer = &easeInOutExpo;
            break;
    }
}


////////////////////////////////////////////////////////////////////////////////


BOOL countUp = YES;

- (void) oscillateVolume
{    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
    int i = 0;
    double x;
            
    while(isOscillating)
    {        
        usleep(oscillateSpeed);
                 
        x = easer(t, b, c, d);
                
        if(i < 5) 
            i++;
        else 
        {
            i = 0;
            [volumeSlider setDoubleValue:x];
            [statusMenuVolumeSlider setDoubleValue:x];
        }
        
        if(t >= 1)
            countUp = NO;
        else if(t < 0)
            countUp = YES;
            
        if(countUp)
            t += 0.001;
        else
            t -= 0.001;
            
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
            [oscillateSpeedSlider setEnabled:NO];
            oscillateSpeed = 1000;
            break;
        case kOscillateSpeedNormal:
            [oscillateSpeedSlider setEnabled:NO];
            oscillateSpeed = 2500;
            break;
        case kOscillateSpeedSlow:
            [oscillateSpeedSlider setEnabled:NO];
            oscillateSpeed = 7000;
            break;
        case kOscillateSpeedCustom:
            [oscillateSpeedSlider setEnabled:YES];
            oscillateSpeed = [oscillateSpeedSlider doubleValue];
            break;
        case kOscillateSpeedSlider:
            oscillateSpeed = [oscillateSpeedSlider doubleValue];
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
    DLog(@"startStopOscillateVolume:");
    
    if([sender state] == NSOnState) 
    {
        [self oscillate:YES];
    } 
    else if([sender state] == NSOffState) 
    {
        [self oscillate:NO];
    }

}

- (void) oscillate:(BOOL) start
{
    DLog(@"oscillate:");
    
    if(!start)
    {        
        if([oscillateVolumeThread isExecuting]) {

            [oscillateVolumeThread cancel];
                
            isOscillating = NO;
            volumeSlider.enabled = YES;
            rangeSlider.enabled = NO;
            statusMenuVolumeSlider.enabled = YES;
        }
    } 
    else
    {
        isOscillating = YES;
        volumeSlider.enabled = NO;
        rangeSlider.enabled = YES;
        statusMenuVolumeSlider.enabled = NO;
        oscillateVolumeThread = [[NSThread alloc] initWithTarget:self selector:@selector(oscillateVolume) object:nil];
        [oscillateVolumeThread start];
    }
}



////////////////////////////////////////////////////////////////////////////////

- (IBAction) playPause:(id) sender
{
    if(isPlaying)
    {
        statusItem.image = [NSImage imageNamed:@"statusbar-inactive.png"];
        playItem.title = @"Play";
        startStopButton.title = @"Play";
        isPlaying = NO;
        StopAU();
    }
    else
    {
        statusItem.image = [NSImage imageNamed:@"statusbar-active.png"];
        playItem.title = @"Pause";
        startStopButton.title = @"Pause";
        isPlaying = YES;
        StartAU();
    }
}



////////////////////////////////////////////////////////////////////////////////

- (IBAction) showPrefsWindow:(id) sender
{
    window.isVisible = YES;
}

- (void) savePrefs
{        
    NSUserDefaults *preferences = [[NSUserDefaults standardUserDefaults] retain];
                
    if(preferences)
    {
        [preferences setInteger:[oscillationButton state] forKey:@"enableOscillation"];
        [preferences setInteger:[oscillationSpeedPopUp selectedTag] forKey:@"oscillationSpeed"];
        [preferences setInteger:[oscillationTypePopUp selectedTag] forKey:@"oscillationType"];
        [preferences setFloat:[rangeSlider floatLoValue] forKey:@"oscillationStart"];
        [preferences setFloat:([rangeSlider floatHiValue]-[rangeSlider floatLoValue]) forKey:@"oscillationRange"];
        [preferences setInteger:[noiseTypePopUp selectedTag] forKey:@"noiseType"];
        [preferences setObject:[NSDate date] forKey:@"prefsLastSaved"];
        [preferences setFloat:oscillateSpeed forKey:@"oscillationCustomSpeed"];
        [preferences setInteger:[filterPopUp selectedTag] forKey:@"filterType"];

        [preferences synchronize];
    }
    
    [preferences release];
}

- (void) loadPrefs
{    
    NSUserDefaults *preferences = [[NSUserDefaults standardUserDefaults] retain];
    
    if(preferences) 
    {
        long pEnableOscillation = [preferences integerForKey:@"enableOscillation"];
        long pOscillationSpeed = [preferences integerForKey:@"oscillationSpeed"];
        long pOscillationType = [preferences integerForKey:@"oscillationType"];
        float pOscillationStart = [preferences floatForKey:@"oscillationStart"];
        float pOscillationRange = [preferences floatForKey:@"oscillationRange"];
        long pNoiseType = [preferences integerForKey:@"noiseType"];
        float pOscillationCustomSpeed = [preferences floatForKey:@"oscillationCustomSpeed"];
        long pFilterType = [preferences integerForKey:@"filterType"];
        
        // Oscillation Speed
        
        [oscillationSpeedPopUp selectItem:[[oscillationSpeedPopUp menu] itemWithTag:pOscillationSpeed]];
                
        switch (pOscillationSpeed) 
        {
            case kOscillateSpeedFast:
                [oscillateSpeedSlider setEnabled:NO];
                oscillateSpeed = 1000;
                break;
            case kOscillateSpeedNormal:
                [oscillateSpeedSlider setEnabled:NO];
                oscillateSpeed = 2500;
                break;
            case kOscillateSpeedSlow:
                [oscillateSpeedSlider setEnabled:NO];
                oscillateSpeed = 7000;
                break;
            case kOscillateSpeedCustom:
                [oscillateSpeedSlider setEnabled:YES];
                oscillateSpeed = pOscillationCustomSpeed;
                [oscillateSpeedSlider setFloatValue:oscillateSpeed];
                break;
        }
        
        // Oscillation Start
                        
        b = pOscillationStart;
        c = pOscillationRange;
        
        // Oscillation Range
        
        [oscillationRangePopUp setState:pOscillationRange];
        
        [rangeSlider setFloatHiValue:b+c];
        [rangeSlider setFloatLoValue:b];
        
        // Oscillation Type 
        
        [oscillationTypePopUp selectItem:[[oscillationTypePopUp menu] itemWithTag:pOscillationType]];
        
        // Noise Type
        
        noiseType = (int) pNoiseType;
        
        [noiseTypePopUp selectItem:[[noiseTypePopUp menu] itemWithTag:pNoiseType]];
        
        // Filter Type
        
        [filterPopUp selectItem:[[filterPopUp menu] itemWithTag:pFilterType]];
        
        [self changeFilter:pFilterType]; 
                
        // Enable Oscillation
                
        if(pEnableOscillation) {
            [oscillationButton setState:NSOnState];
            [self oscillate:YES];
        } else {
            [oscillationButton setState:NSOffState];
            [self oscillate:NO];
        }
    }    
    [preferences release];
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

////////////////////////////////////////////////////////////////////////////////

- (IBAction) showHideDockIcon:(NSButton *)sender
{
    
    if([sender state] == NSOnState)
    {
        ProcessSerialNumber psn = { 0, kCurrentProcess };
        TransformProcessType(&psn, kProcessTransformToForegroundApplication);
        [[[NSBundle mainBundle] infoDictionary] setValue:@"false" forKey:@"LSUIElement"];
    }
    else 
    {
        [[[NSBundle mainBundle] infoDictionary] setValue:@"true" forKey:@"LSUIElement"];
    }
    
    /*
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hideDockIcon"]) {
        ProcessSerialNumber psn = { 0, kCurrentProcess };
        TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    }*/
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) startStopFilter:(NSButton *)sender
{
    if([sender state] == NSOnState)
    {
        enableFilter = YES;
    }
    else 
    {
        enableFilter = NO;
    }
}

@end
