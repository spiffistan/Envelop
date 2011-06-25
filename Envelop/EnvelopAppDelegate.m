//
//  EnvelopAppDelegate.m
//  Envelop
//
//  Created by Anders on 6/20/11.
//  Copyright 2011 Capasit. All rights reserved.
//

#import "EnvelopAppDelegate.h"
#import "Finch.h"
#import "Sound.h"

#include "loudnoises.h"

#define SAMPLE_RATE 44100
#define SECONDS 5

Sound *sound;

NSThread *oscillatePitchThread, *oscillateGainThread;

BOOL oscillateGain = NO, oscillatePitch = NO;

////////////////////////////////////////////////////////////////////////////////

@implementation EnvelopAppDelegate

@synthesize window, pitchSlider, gainSlider, filterSlider, playItem, playButton, spinner;

- (void) applicationDidFinishLaunching:(NSNotification *) aNotification
{    
    [[Finch alloc] init];
        
    [self generateNoise:nil];
    [self playPause:nil];
}

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

- (void) changeCutoff:(id) sender
{
    [hzLabel setStringValue:[NSString stringWithFormat:@"%d Hz", [filterSlider intValue]]];
    changeCutoff([filterSlider floatValue]);
    
    [self generateNoise:nil];
    
    if([gainButton isEnabled])
    {
        [oscillateGainThread cancel];
        [oscillateGainThread dealloc];
    }

    [self playPause:nil];
    
    if([gainButton isEnabled])
    {
        oscillateGainThread = [[NSThread alloc] initWithTarget:self selector:@selector(oscillateGain:) object:nil];
        [oscillateGainThread start];
    }
}

- (void) awakeFromNib
{
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    NSImage * image = [NSImage imageNamed:@"envelop-icon-status.png"];
    
    [statusItem setImage:image];
    [statusItem setMenu:statusMenu];
    [statusItem setHighlightMode:YES];
}


- (void) oscillateGain:(id) sender
{
    [[NSAutoreleasePool alloc] init];
    
    if(sound == NULL)
        return;
    
    double b = 0.2, c = 0.3, d = 1.3, t = 0;
    
    int i = 0;
    
    while(true)
    {
        if(!oscillateGain) return;
        
        double x = -c/2 * (cos((M_PI * t) / d) - 1) + b;
        
        if(i < 10) 
            i++;
        else 
        {
            i = 0;
            [gainSlider setDoubleValue:x];
        }
        
        usleep(1000);
        [sound setGain:(float) x];
        t += 0.0001;
    }
}

- (void) oscillatePitch:(id) sender
{
    [[NSAutoreleasePool alloc] init];
    
    if(sound == NULL)
        return;
    
    double b = 0.2, c = 0.1, d = 1.3, t = 0;
    
    int i = 0;
    
    while(true)
    {
        if(!oscillatePitch) return;
        
        double x = -c/2 * (cos((M_PI * t) / d) - 1) + b;
        
        if(i < 10) 
            i++;
        else 
        {
            i = 0;
            [pitchSlider setDoubleValue:x];
        }

        usleep(1000);
        [sound setPitch:(float) x];
        t += 0.0001;
    }
}

- (IBAction) changePitch:(id) sender
{
    [sound setPitch:[pitchSlider floatValue]];
}

- (IBAction) changeGain:(id) sender
{
    [sound setGain:[gainSlider floatValue]];
}

- (IBAction) startStopOscillatePitch:(id) sender
{
    if(!oscillatePitch)
    {
        oscillatePitchThread = [[NSThread alloc] initWithTarget:self selector:@selector(oscillatePitch:) object:nil];
        [oscillatePitchThread start];
    }
    else
    {
        oscillatePitch = NO;
    }
}

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

- (IBAction) playPause:(id) sender
{
    if([sound playing])
    {
        [playItem setTitle:@"Play"];
        [playButton setTitle:@"Play"];
        [sound stop];
    }
    else
    {
        [playItem setTitle:@"Pause"];
        [playButton setTitle:@"Pause"];
        [sound play];
    }
}

- (IBAction) showPrefsWindow:(id) sender
{
    [window setIsVisible:YES];
}

@end
