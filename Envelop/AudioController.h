//
//  AudioController.h
//  Envelop
//
//  Created by Anders on 7/2/11.
//  Copyright 2011 Capasit. All rights reserved.
//

#import <AudioUnit/AudioUnit.h>

@interface AudioController : NSViewController {
@private
    
}

OSStatus RenderNoiseCallback(void *, AudioUnitRenderActionFlags *, const AudioTimeStamp*, UInt32, UInt32, AudioBufferList *);
OSStatus RenderMicrophoneCallback(void *, AudioUnitRenderActionFlags *, const AudioTimeStamp*, UInt32, UInt32, AudioBufferList *);

void CreateAU(void);
void StartAU(void);
void StopAU(void);
/*
void CreateMicrophoneAU(void);
void StartMicrophoneAU(void);
void StopMicrophoneAU(void);*/

enum {
    kNoiseTypeWhite,
    kNoiseTypeBrown,
    kNoiseTypePink
};

void SetAUVolume(float);

@end
