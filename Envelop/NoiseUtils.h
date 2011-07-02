//
//  NoiseUtils.h
//  Envelop
//
//  Created by Anders on 7/2/11.
//  Copyright 2011 Capasit. All rights reserved.
//

#ifndef Envelop_NoiseUtils_h
#define Envelop_NoiseUtils_h

float white(void);
float brown(void);
void butterworth(const double, double* const, double* const);
void filter(float *, int);

#endif
