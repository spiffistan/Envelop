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

#define kOutputBus 0
#define kInputBus 1
#define ARC4RANDOM_MAX 0x100000000
#define NUM_PINK 16

@implementation AudioController

AudioUnit gOutputUnit;

extern Float32 cutoff;
extern BOOL enableFilter;
extern int noiseType;

double m_white = 0.0f, m_brown = 0.0f, m_pink = 0.0f, m_count = 1;
double m_pink_octaves[NUM_PINK];

void init(void)
{
    memset(m_pink_octaves, NUM_PINK, 0);
}

double white(void)
{
    double f = (float) (arc4random() % ARC4RANDOM_MAX);
    f /= ARC4RANDOM_MAX;
    f -= 0.5;
    return f;
}

int CTZ(int num)
{
    int i=0;
    while (( (num>>i) & 1 ) == 0 && i < sizeof(int) ) i++;
    return i;
}

double pink(void)
{
    double prevr;
    double r;
    unsigned long k;
    k = CTZ(m_count);
    k = k & 16; 
    
    // get previous value of this octave 
    prevr = m_pink_octaves[k]; 
    
    while (true)
    {
        r = white();
        
        // store new value 
        m_pink_octaves[k] = r;
        
        r -= prevr;
        
        // update total 
        m_pink += r; 
        
        if (m_pink <-2.0f || m_pink > 2.0f) m_pink -= r;
        else break;
    }
    
    // update counter 
    m_count++; 
    
    return (white() + m_pink) * 0.125f; 
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

////////////////////////////////////////////////////////////////////////////////

OSStatus RenderNoiseCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, 
                             const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, 
                             UInt32 inNumberFrames, AudioBufferList *ioData)
{
	// Get a pointer to the dataBuffer of the AudioBufferList
	SInt16 *outData = (SInt16 *) ioData->mBuffers[0].mData;
    
    tempData = malloc(inNumberFrames * sizeof(double));
    
    double (*generator)(void);
    
    switch (noiseType) {
        case kNoiseTypeWhite:
            generator = &white;
            break;
        case kNoiseTypeBrown:
            generator = &brown;
            break;
        case kNoiseTypePink:
            generator = &pink;
            break;
    }
    
    for (UInt32 i = 0; i < inNumberFrames; ++i) 
        tempData[i] = (generator() * (1 << 16));
    
    if(enableFilter)
        filter(tempData, inNumberFrames);
    
    for (UInt32 i = 0; i < inNumberFrames; ++i) 
        outData[i] = tempData[i];
        
    free(tempData);

	return noErr;
}

////////////////////////////////////////////////////////////////////////////////

OSStatus RenderMicrophoneCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, 
                                  const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, 
                                  UInt32 inNumberFrames, AudioBufferList *ioData)
{
    /*
    AudioBuffer buffer;
    
    buffer.mNumberChannels = 1;
    buffer.mDataByteSize = inNumberFrames * 2;
    NSLog(@"%d",inNumberFrames);
    buffer.mData = malloc( inNumberFrames * 2 );
    
    // Put buffer in a AudioBufferList
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    
    OSStatus status;
    status = AudioUnitRender(gInputUnit, 
                             ioActionFlags, 
                             inTimeStamp, 
                             inBusNumber, 
                             inNumberFrames, 
                             &bufferList);  

    int16_t *q = (int16_t *)(&bufferList)->mBuffers[0].mData;
    for(int i=0; i < strlen((const char *)(&bufferList)->mBuffers[0].mData); i++)
    {
        //i sometimes doesn't get past 0, sometimes goes into 20s
        NSLog(@"%d",q[i]);//returns NaN, 0.00, or some times actual data
    }
    */
    return noErr; 
}

////////////////////////////////////////////////////////////////////////////////

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
    input.inputProc = RenderNoiseCallback;
    input.inputProcRefCon = NULL;
        
     err = AudioUnitSetProperty(gOutputUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, kOutputBus, &input, sizeof(input));
    
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
        
    err = AudioUnitSetProperty(gOutputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, kOutputBus, &format, sizeof(format));
        
    if (err) { printf ("In:  AudioUnitSetProperty-SF=%4.4s, %d\n", (char*)&err, err); return; }
        
    // HEISENBUG here: no printf if uncommented
    // err = AudioUnitSetProperty(gOutputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &format, sizeof(format));
    // if (err) { printf ("Out: AudioUnitSetProperty-SF=%4.4s, %d\n", (char*)&err, err); return; }
    
}
/*
////////////////////////////////////////////////////////////////////////////////
void CreateMicrophoneAU(void) 
{    
    OSStatus err = noErr;
    
    // Open the default output unit
    AudioComponentDescription desc;
    
    desc.componentType          = kAudioUnitType_Output;
    desc.componentSubType       = kAudioUnitSubType_HALOutput;
    desc.componentFlags         = 0;
    desc.componentFlagsMask     = 0;
    desc.componentManufacturer  = kAudioUnitManufacturer_Apple;
    
    AudioComponent comp = AudioComponentFindNext(NULL, &desc);
    if (comp == NULL) { printf ("FindNextComponent\n"); return; }
    
    err = AudioComponentInstanceNew(comp, &gInputUnit);
    if (comp == NULL) { printf ("OpenAComponent=%d\n", err); return; }
        
    UInt32 param = 1; // Enable input on the AUHAL
	err = AudioUnitSetProperty(gInputUnit,
							   kAudioOutputUnitProperty_EnableIO,
							   kAudioUnitScope_Input,
							   kInputBus, // bus
							   &param,
							   sizeof(UInt32));
    
	if (err != noErr)
	{
		printf("AudioUnitSetProperty() failed for input scope: %d", err);
		return;
	} 
    
    // Set up a callback function to generate output to the output unit
    AURenderCallbackStruct input;
    input.inputProc = RenderMicrophoneCallback;
    input.inputProcRefCon = NULL;
    
    err = AudioUnitSetProperty(gInputUnit, kAudioUnitProperty_SetRenderCallback, 
        kAudioUnitScope_Input, kInputBus, &input, sizeof(input));
    
    
    if (err) { printf ("AudioUnitSetProperty-CB-Mic=%d\n", err); return; }
    
    AudioStreamBasicDescription format;
    
    format.mSampleRate          = 44100.0;
    format.mFormatID            = kAudioFormatLinearPCM;
    format.mFormatFlags         = kAudioFormatFlagIsSignedInteger;
    format.mFramesPerPacket     = 1;
    format.mChannelsPerFrame    = 1;
    format.mBitsPerChannel      = 16;
    format.mBytesPerPacket      = 2;
    format.mBytesPerFrame       = 2;
    
    err = AudioUnitSetProperty(gInputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &format, sizeof(format));
    
    if (err) { printf ("In:  AudioUnitSetProperty-SF=%4.4s, %d\n", (char*)&err, err); return; }
    
}
*/

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
    AudioOutputUnitStart(gOutputUnit);    
    if (err) { printf ("AudioOutputUnitStart=%d\n", err); return; }
    AudioUnitReset(gOutputUnit, kAudioUnitScope_Input, 0);
}

void StopAU()
{
    OSStatus err = noErr;
    AudioOutputUnitStop(gOutputUnit);    
    if (err) { printf ("AudioOutputUnitStop=%d\n", err); return; }
    AudioUnitReset(gOutputUnit, kAudioUnitScope_Input, 0);
}

@end
