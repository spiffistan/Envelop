//
//  AudioController.c
//  AUTest
//
//  Created by Anders on 7/2/11.
//  Copyright 2011 Capasit. All rights reserved.
//

#include <stdio.h>
#include <AudioUnit/AudioUnit.h>
#include "NoiseUtils.h"

AudioUnit gOutputUnit;

extern Float32 volume;

OSStatus RenderAudio(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, 
                     const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, 
                     UInt32 inNumberFrames, AudioBufferList *ioData)
{
    
	// Get a pointer to the dataBuffer of the AudioBufferList
	Float32 *outData = (Float32 *)ioData->mBuffers[0].mData;
    
    for (UInt32 i = 0; i < inNumberFrames; ++i) 
    { 		
        outData[i] = (SInt16) (brown() * (1 << 16));
    }
    
    filter(outData, inNumberFrames);
    
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
    
    err = AudioUnitSetProperty(gOutputUnit, kAudioUnitProperty_SetRenderCallback, 
                               kAudioUnitScope_Input, 0, &input, sizeof(input));
    
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
    
    err = AudioUnitSetProperty(gOutputUnit, kAudioUnitProperty_StreamFormat, 
                               kAudioUnitScope_Input, 0, &format, sizeof(format));
    
    if (err) { printf ("In:  AudioUnitSetProperty-SF=%4.4s, %d\n", (char*)&err, err); return; }
    
    err = AudioUnitSetProperty(gOutputUnit, kAudioUnitProperty_StreamFormat, 
                               kAudioUnitScope_Output, 0, &format, sizeof(format));
    
    if (err) { printf ("Out: AudioUnitSetProperty-SF=%4.4s, %d\n", (char*)&err, err); return; }
    
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