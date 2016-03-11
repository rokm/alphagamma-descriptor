// bitstring = CONVERT_BYTESTRING_TO_BITSTRING (bytestring)
//
// Converts descriptor from byte-string to bit-string format.
//
// Input:
//  - bytestring: 1xN vector of bytes, each denoting a boolean value
//
// Output:
//  - bitstring: corresponding bitstring vector, of size ceil(N/8)
//
// (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>

#include <mex.h>

#include <iostream> // For debugging

// *********************************************************************
// *                          MEX entry point                          *
// *********************************************************************
void mexFunction (int nlhs, mxArray **plhs, int nrhs, const mxArray **prhs)
{
    if (nrhs != 1)  {
        mexErrMsgTxt("One input argument required!");
    }

    // Validate input
    if (mxGetClassID(prhs[0]) != mxUINT8_CLASS) {
        mexErrMsgTxt("input must be an uint8 vector!");
    }

    unsigned int numSymbols = mxGetNumberOfElements(prhs[0]);
    unsigned int numBytes = 1 + ((numSymbols - 1) / 8); // std::ceil(string_length / 8.0f)

    if (mxGetM(prhs[0]) == 1) {
        plhs[0] = mxCreateNumericMatrix(1, numBytes, mxUINT8_CLASS, mxREAL);
    } else {
        plhs[0] = mxCreateNumericMatrix(numBytes, 1, mxUINT8_CLASS, mxREAL);
    }

    const unsigned char *inputPtr = reinterpret_cast<unsigned char *>(mxGetData(prhs[0]));
    unsigned char *outputPtr = reinterpret_cast<unsigned char *>(mxGetData(plhs[0]));

    for (unsigned int i = 0; i < numSymbols; i++) {
        // Move the write pointer
        if (i > 0 && i % 8 == 0) {
            outputPtr++;
        }
        *outputPtr |= (*inputPtr++) << (i % 8);
    }
}
