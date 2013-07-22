//
//  DCRejectionFilter.cpp
//  grid
//
//  Created by Robert Olivier on 5/29/12.
//  Copyright (c) 2012 RJO Management, inc. All rights reserved.
//

#include "DCRejectionFilter.h"

// FIXME - integrate these as class members

inline SInt32 smul32by16(SInt32 i32, SInt16 i16)
{
#if defined __arm__
	register SInt32 r;
	asm volatile("smulwb %0, %1, %2" : "=r"(r) : "r"(i32), "r"(i16));
	return r;
#else	
	return (SInt32)(((SInt64)i32 * (SInt64)i16) >> 16);
#endif
}

inline SInt32 smulAdd32by16(SInt32 i32, SInt16 i16, SInt32 acc)
{
#if defined __arm__
	register SInt32 r;
	asm volatile("smlawb %0, %1, %2, %3" : "=r"(r) : "r"(i32), "r"(i16), "r"(acc));
	return r;
#else		
	return ((SInt32)(((SInt64)i32 * (SInt64)i16) >> 16) + acc);
#endif
}

const Float32 DCRejectionFilter::kDefaultPoleDist = 0.975f;

DCRejectionFilter::DCRejectionFilter(Float32 poleDist)
{
	mA1 = (SInt16)((float)(1<<15)*poleDist);
	mGain = (mA1 >> 1) + (1<<14); // Normalization factor: (r+1)/2 = r/2 + 0.5
	Reset();
}

void DCRejectionFilter::Reset()
{
	mY1 = mX1 = 0;	
}

void DCRejectionFilter::InplaceFilter(SInt32* ioData, UInt32 numFrames, UInt32 strides)
{
	register SInt32 y1 = mY1, x1 = mX1;
	for (UInt32 i=0; i < numFrames; i++)
	{
		register SInt32 x0, y0;
		x0 = ioData[i*strides];
		y0 = smul32by16(y1, mA1);
		y1 = smulAdd32by16(x0 - x1, mGain, y0) << 1;
		ioData[i*strides] = y1;
		x1 = x0;
	}
	mY1 = y1;
	mX1 = x1;
}
