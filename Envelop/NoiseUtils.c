//
//  NoiseUtils.c
//  Envelop
//
//  Created by Anders on 7/2/11.
//  Copyright 2011 Capasit. All rights reserved.
//

#include "NoiseUtils.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define ARC4RANDOM_MAX 0x100000000

extern float cutoff;

float white(void)
{
    float f = (float) (arc4random() % ARC4RANDOM_MAX);
    f /= ARC4RANDOM_MAX;
    f -= 0.5;
    return f;
}

float m_brown = 0.0f;

float brown(void)
{
    
    while(1)
    {
        float r = white();
        m_brown += r;
        if (m_brown < -8.0f || m_brown > 8.0f) m_brown -= r;
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
    
    by[2] = (1 - M_SQRT2 / QcWarp + 2 / (QcWarp*QcWarp)) * gain;
    by[1] = (2 - 2 * 2 / (QcWarp * QcWarp)) * gain;
    by[0] = 1;
    ax[0] = 1 * gain;
    ax[1] = 2 * gain;
    ax[2] = 1 * gain;
}

void filter(float* samples, int count)
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