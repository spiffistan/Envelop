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

Float32 cutoff = 4000.0f;
Float32 volume = 0.5f;

@implementation EnvelopAppDelegate

@synthesize window, filterSlider, playItem, showAdvancedButton, advancedBox;
@synthesize volumeItem, volumeSlider;
@synthesize closePrefsButton;

////////////////////////////////////////////////////////////////////////////////
// Overrides
////////////////////////////////////////////////////////////////////////////////

- (void) applicationDidFinishLaunching:(NSNotification *) aNotification
{    
    StatusVolumeView *controller = [[StatusVolumeView alloc] initWithNibName:@"StatusVolumeView" bundle:nil];
    
    [volumeItem setView:[controller view]];
    
    CreateAU();
	StartAU();
}

- (void) awakeFromNib
{
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    NSImage * image = [NSImage imageNamed:@"envelop-icon-status.png"];
    
    [statusItem setImage:image];
    [statusItem setMenu:statusMenu];
    [statusItem setHighlightMode:YES];
}
/*
////////////////////////////////////////////////////////////////////////////////

- (void) generateNoise:(id) sender
{
    if(sound != NULL)
    {
        [sound stop];
        [sound dealloc];
    }
    
    [spinner setHidden:NO];
    
    int16_t buf[SAMPLE_RATE * 5]; // malloc(SECONDS * SAMPLE_RATE * sizeof(int16_t));

    brownNoise(buf, 5);
    
    sound = [[Sound alloc] initWithData:buf 
                                   size:(sizeof buf) 
                                 format:AL_FORMAT_MONO16 
                             sampleRate:SAMPLE_RATE 
                               duration:SECONDS];
    
    [sound setLoop:YES];
    [sound setPitch:0.2f];
    [sound setGain:0.2f];
    
    [spinner setHidden:YES];

}
*/

- (void) changeCutoff:(id) sender
{
    [hzLabel setStringValue:[NSString stringWithFormat:@"%d Hz", [filterSlider intValue]]];
    
    cutoff = [filterSlider floatValue];
}
/*

double b = 0.2, c = 0.3, d = 1.3, t = 0;

- (void) oscillateGain:(id) sender
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
    int i = 0;
        
    while(oscillateGain)
    {
        usleep(oscillateGainSpeed);
        
        double x = -c/2 * (cos((M_PI * t) / d) - 1) + b;
        
        if(i < 10) 
            i++;
        else 
        {
            i = 0;
            [gainSlider setDoubleValue:x];
        }
                
        [sound setGain:(float) x];
        t += 0.0001;
    }
    
    [pool drain];
} */

- (IBAction) changeVolume:(id) sender
{
    volume = [volumeSlider floatValue];
    
    SetAUVolume(volume);
}

/*

- (IBAction) startStopOscillateGain:(id) sender
{
    if(!oscillateGain)
    {
        oscillateGain = YES;
        oscillateGainThread = [[NSThread alloc] initWithTarget:self selector:@selector(oscillateGain:) object:nil];
        [oscillateGainThread start];
    }
    else
    {
        oscillateGain = NO;
    }
}

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
}

- (IBAction) playPause:(id) sender
{
    if([sound playing])
    {
        [statusItem setImage:[NSImage imageNamed:@"envelop-icon-status.png"]];
        [playItem setTitle:@"Play"];
        [playButton setTitle:@"Play"];
        [sound stop];
    }
    else
    {
        [statusItem setImage:[NSImage imageNamed:@"envelop-icon-status-active.png"]];
        [playItem setTitle:@"Pause"];
        [playButton setTitle:@"Pause"];
        [sound play];
    }
}
*/
- (IBAction) showPrefsWindow:(id) sender
{
    [window setIsVisible:YES];
}

- (IBAction) showHideAdvancedPanel:(id) sender
{
    NSRect advancedBoxFrame = [advancedBox frame];
    NSRect windowFrame = [window frame];
    
    UInt16 sizeDiff = 232; 
        
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
