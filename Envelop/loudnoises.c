//
//  loudnoises.c
//  Envelop
//
//  Created by Anders on 6/25/11.
//  Copyright 2011 Capasit. All rights reserved.
//

#include "loudnoises.h"
#include <stdint.h>
#include <math.h>

#define ARC4RANDOM_MAX  0x100000000
#define SAMPLE_RATE     44100

uint64_t    m_count = 1;
uint32_t    cutoff = 4000;
float       m_brown = 0.0f;

double      xv[3];
double      yv[3];

float white(float scale)
{
    /* m_seed   = (m_seed * 196314165) + 907633515;
     m_white  = m_seed >> 9; 
     m_white |= 0x40000000; 
     return ((*(float*)&m_white)-3.0f)*scale; */
    
    float d = (float) (arc4random() % ARC4RANDOM_MAX);
    d /= ARC4RANDOM_MAX;
    d -= 0.5;
    return d;
    
}

void changeCutoff(const int c)
{
    cutoff = c;
}

float brown(void)
{
    while(1)
    {
        float r = white(0.5f);
        m_brown += r;
        if (m_brown < -8.0f || m_brown > 8.0f) m_brown -= r;
        else break;
    }
    return m_brown * 0.0625f;
}

// getLPCoefficientsButterworth2Pole
void butterworth(const double cutoff, double* const ax, double* const by)
{    
    double QcRaw  = (2 * M_PI * cutoff) / SAMPLE_RATE; // Find cutoff frequency in [0..PI]
    double QcWarp = tan(QcRaw); // Warp cutoff frequency
    
    double gain = 1 / (1 + M_SQRT2 / QcWarp + 2 / (QcWarp * QcWarp));
    
    by[2] = (1 - M_SQRT2 / QcWarp + 2 / (QcWarp*QcWarp)) * gain;
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
    
    for (int i=0;i<count;i++)
    {
        xv[2] = xv[1]; xv[1] = xv[0];
        xv[0] = samples[i];
        yv[2] = yv[1]; yv[1] = yv[0];
        
        yv[0] =   (ax[0] * xv[0] + ax[1] * xv[1] + ax[2] * xv[2]
                   - by[1] * yv[0]
                   - by[2] * yv[1]);
        
        samples[i] = yv[0];
    }
}

void brownNoise(int16_t *rawSamples, int seconds)
{
    double *samples = malloc(SAMPLE_RATE * seconds * sizeof(double));
    
    for(int i = 0; i < (SAMPLE_RATE * seconds); i++) 
    {
        m_brown = 0.0f;        
        samples[i] = (brown() * (1 << 16));
    }
    
    filter(samples, (SAMPLE_RATE * seconds));
    
    for(int i = 0; i < (SAMPLE_RATE * seconds); i++) 
    {
        rawSamples[i] = (int16_t) samples[i];
    }
    
    free(samples);
}
