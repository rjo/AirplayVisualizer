//
//  DCRejectionFilter.h
//  grid
//
//  Created by Robert Olivier on 5/29/12.
//  Copyright (c) 2012 RJO Management, inc. All rights reserved.
//

#ifndef grid_DCRejectionFilter_h
#define grid_DCRejectionFilter_h

#include <CoreAudio/CoreAudioTypes.h>
#include <CoreFoundation/CoreFoundation.h>

class DCRejectionFilter
{
public:
	DCRejectionFilter(Float32 poleDist = DCRejectionFilter::kDefaultPoleDist);
    
	void InplaceFilter(SInt32* ioData, UInt32 numFrames, UInt32 strides);
	void Reset();
    
protected:
	
	// Coefficients
	SInt16 mA1;
	SInt16 mGain;
    
	// State variables
	SInt32 mY1;
	SInt32 mX1;
	
	static const Float32 kDefaultPoleDist;
};

#endif
