//
//  AudioController.h
//  AUTest
//
//  Created by Anders on 7/2/11.
//  Copyright 2011 Capasit. All rights reserved.
//

#include <AudioUnit/AudioUnit.h>

#ifndef AUTest_AudioController_h
#define AUTest_AudioController_h

OSStatus RenderAudio(void *, AudioUnitRenderActionFlags *, const AudioTimeStamp*, UInt32, UInt32, AudioBufferList *);
void CreateAU(void);
void StartAU(void);
void SetAUVolume(float);

#endif
