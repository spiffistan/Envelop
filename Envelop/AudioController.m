//
//  AudioController.c
//  Envelop
//
//  Created by Anders on 7/2/11.
//  Copyright 2011 Capasit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AudioUnit/AudioUnit.h>
#import "AudioController.h"

@implementation AudioController

AudioUnit gOutputUnit;

extern Float32 cutoff;
extern BOOL generateWhite;

double m_brown = 0.0f;

#define ARC4RANDOM_MAX 0x100000000
double white(void)
{
    double f = (float) (arc4random() % ARC4RANDOM_MAX);
    f /= ARC4RANDOM_MAX;
    f -= 0.5;
    return f;
}

double brown(void)
{
    
    while(1)
    {
        double r = white();
        m_brown += r;
        if (m_brown < -2.0f || m_brown > 2.0f) m_brown -= r;
        else break;
    }
    return m_brown * 0.0625f;
}

double xv[3];
double yv[3];

void butterworth(const double cutoff, double* const ax, double* const by)
{    
    double QcRaw  = (2 * M_PI * cutoff) / 44100.0f; // Find cutoff frequency in [0..PI]
    double QcWarp = tan(QcRaw); // Warp cutoff frequency
    
    double gain = 1 / (1 + M_SQRT2 / QcWarp + 2 / (QcWarp * QcWarp));
    
    by[2] = (1 - M_SQRT2 / QcWarp + 2 / (QcWarp *QcWarp)) * gain;
    by[1] = (2 - 2 * 2 / (QcWarp * QcWarp)) * gain;
    by[0] = 1;
    ax[0] = 1 * gain;
    ax[1] = 2 * gain;
    ax[2] = 1 * gain;
}

void filter(double* samples, int count)
{
    double ax[3];
    double by[3];
    
    butterworth(cutoff, ax, by);
    
    for (int i = 0; i < count; i++)
    {
        xv[2] = xv[1]; xv[1] = xv[0];
        xv[0] = samples[i];
        yv[2] = yv[1]; yv[1] = yv[0];
        
        yv[0] = (ax[0] * xv[0] +
                 ax[1] * xv[1] +
                 ax[2] * xv[2] -
                 by[1] * yv[0] -
                 by[2] * yv[1]);
        
        samples[i] = yv[0];
    }
}

static double *tempData;

OSStatus RenderAudio(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, 
                     const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, 
                     UInt32 inNumberFrames, AudioBufferList *ioData)
{
	// Get a pointer to the dataBuffer of the AudioBufferList
	SInt16 *outData = (SInt16 *) ioData->mBuffers[0].mData;
    
    tempData = malloc(inNumberFrames * sizeof(double));
    
    if(generateWhite)
    {
        for (UInt32 i = 0; i < inNumberFrames; ++i) 
            tempData[i] = (white() * (1 << 16));
    } 
    else
    {
        for (UInt32 i = 0; i < inNumberFrames; ++i) 
            tempData[i] = (brown() * (1 << 16));
    }
    
    filter(tempData, inNumberFrames);
    
    for (UInt32 i = 0; i < inNumberFrames; ++i) 
        outData[i] = tempData[i];
        
    free(tempData);

	return noErr;
}

void CreateAU(void) 
{
    OSStatus err = noErr;
    
    // Open the default output unit
    AudioComponentDescription desc;
    
    desc.componentType          = kAudioUnitType_Output;
    desc.componentSubType       = kAudioUnitSubType_DefaultOutput;
    desc.componentFlags         = 0;
    desc.componentFlagsMask     = 0;
    desc.componentManufacturer  = kAudioUnitManufacturer_Apple;
        
    AudioComponent comp = AudioComponentFindNext(NULL, &desc);
    if (comp == NULL) { printf ("FindNextComponent\n"); return; }
    
    err = AudioComponentInstanceNew(comp, &gOutputUnit);
    if (comp == NULL) { printf ("OpenAComponent=%d\n", err); return; }
    
    // Set up a callback function to generate output to the output unit
    AURenderCallbackStruct input;
    input.inputProc = RenderAudio;
    input.inputProcRefCon = NULL;
        
     err = AudioUnitSetProperty(gOutputUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &input, sizeof(input));
    
    if (err) { printf ("AudioUnitSetProperty-CB=%d\n", err); return; }
    
    AudioStreamBasicDescription format;
    
    format.mSampleRate          = 44100.0;
    format.mFormatID            = kAudioFormatLinearPCM;
    format.mFormatFlags         = kAudioFormatFlagIsSignedInteger;
    format.mFramesPerPacket     = 1;
    format.mChannelsPerFrame    = 1;
    format.mBitsPerChannel      = 16;
    format.mBytesPerPacket      = 2;
    format.mBytesPerFrame       = 2;
        
    err = AudioUnitSetProperty(gOutputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &format, sizeof(format));
        
    if (err) { printf ("In:  AudioUnitSetProperty-SF=%4.4s, %d\n", (char*)&err, err); return; }
        
    // HEISENBUG here: no printf if uncommented
    
    // err = AudioUnitSetProperty(gOutputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &format, sizeof(format));
            
    // if (err) { printf ("Out: AudioUnitSetProperty-SF=%4.4s, %d\n", (char*)&err, err); return; }
    
}

void SetAUVolume(Float32 volume)
{
    OSStatus err = noErr;
    
    err = AudioUnitSetParameter(gOutputUnit, kAudioUnitParameterUnit_LinearGain, kAudioUnitScope_Output, 0, volume, 0);
    if (err) { printf ("Out: AudioUnitSetParameter-LinearGain=%4.4s, %d\n", (char*)&err, err); return; }
}

void StartAU()
{
    OSStatus err = noErr;
    
    // Initialize unit
    err = AudioUnitInitialize(gOutputUnit);
    if (err) { printf ("AudioUnitInitialize=%d\n", err); return; }
    
    AudioOutputUnitStart (gOutputUnit);
    
    if (err) { printf ("AudioOutputUnitStart=%d\n", err); return; }
    
    AudioUnitReset (gOutputUnit, kAudioUnitScope_Input, 0);
}

void StopAU()
{
    OSStatus err = noErr;
    
    AudioOutputUnitStop(gOutputUnit);
    
    if (err) { printf ("AudioOutputUnitStop=%d\n", err); return; }
    
    AudioUnitReset (gOutputUnit, kAudioUnitScope_Input, 0);
}

@end
