//
//  loudnoises.h
//  Envelop
//
//  Created by Anders on 6/25/11.
//  Copyright 2011 Capasit. All rights reserved.
//

#include <stdlib.h>

float white(float);
float brown(void);
void butterworth(const double, double* const, double* const);
void filter(double*, int);
void brownNoise(int16_t *, int);
void changeCutoff(const int);