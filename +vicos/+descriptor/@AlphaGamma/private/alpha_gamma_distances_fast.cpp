// distance = ALPHAGAMMA_DISTANCE_FAST (desc1, desc2, num_circles, num_rays, weightA, weightB, weightG)
//
// Computes matrix of pair-wise distances between two sets of AlphaGamma
// descriptors. This is a fast, POPCNT-based implementation of the distance.
//
// Input:
//  - desc1:
//  - desc2:
//  - num_circles:
//  - num_rays:
//  - weightA:
//  - weightB:
//  - weightG:
//
// Output:
//  - distances: N2xN1 double-precision matrix of descriptor distances
//
// Output:
//  - distance: distance
//
// (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>


#include <immintrin.h>
#include <x86intrin.h>

#include <opencv2/core.hpp>

#include <iostream> // For debugging
#include <mex.h>


// Look-up table for fast computation of Hamming distance between two
// unsigned 8-bit integers
static const uint8_t lookup8bit[256] = {
    /* 00 */ 0, /* 01 */ 1, /* 02 */ 1, /* 03 */ 2,
    /* 04 */ 1, /* 05 */ 2, /* 06 */ 2, /* 07 */ 3,
    /* 08 */ 1, /* 09 */ 2, /* 0a */ 2, /* 0b */ 3,
    /* 0c */ 2, /* 0d */ 3, /* 0e */ 3, /* 0f */ 4,
    /* 10 */ 1, /* 11 */ 2, /* 12 */ 2, /* 13 */ 3,
    /* 14 */ 2, /* 15 */ 3, /* 16 */ 3, /* 17 */ 4,
    /* 18 */ 2, /* 19 */ 3, /* 1a */ 3, /* 1b */ 4,
    /* 1c */ 3, /* 1d */ 4, /* 1e */ 4, /* 1f */ 5,
    /* 20 */ 1, /* 21 */ 2, /* 22 */ 2, /* 23 */ 3,
    /* 24 */ 2, /* 25 */ 3, /* 26 */ 3, /* 27 */ 4,
    /* 28 */ 2, /* 29 */ 3, /* 2a */ 3, /* 2b */ 4,
    /* 2c */ 3, /* 2d */ 4, /* 2e */ 4, /* 2f */ 5,
    /* 30 */ 2, /* 31 */ 3, /* 32 */ 3, /* 33 */ 4,
    /* 34 */ 3, /* 35 */ 4, /* 36 */ 4, /* 37 */ 5,
    /* 38 */ 3, /* 39 */ 4, /* 3a */ 4, /* 3b */ 5,
    /* 3c */ 4, /* 3d */ 5, /* 3e */ 5, /* 3f */ 6,
    /* 40 */ 1, /* 41 */ 2, /* 42 */ 2, /* 43 */ 3,
    /* 44 */ 2, /* 45 */ 3, /* 46 */ 3, /* 47 */ 4,
    /* 48 */ 2, /* 49 */ 3, /* 4a */ 3, /* 4b */ 4,
    /* 4c */ 3, /* 4d */ 4, /* 4e */ 4, /* 4f */ 5,
    /* 50 */ 2, /* 51 */ 3, /* 52 */ 3, /* 53 */ 4,
    /* 54 */ 3, /* 55 */ 4, /* 56 */ 4, /* 57 */ 5,
    /* 58 */ 3, /* 59 */ 4, /* 5a */ 4, /* 5b */ 5,
    /* 5c */ 4, /* 5d */ 5, /* 5e */ 5, /* 5f */ 6,
    /* 60 */ 2, /* 61 */ 3, /* 62 */ 3, /* 63 */ 4,
    /* 64 */ 3, /* 65 */ 4, /* 66 */ 4, /* 67 */ 5,
    /* 68 */ 3, /* 69 */ 4, /* 6a */ 4, /* 6b */ 5,
    /* 6c */ 4, /* 6d */ 5, /* 6e */ 5, /* 6f */ 6,
    /* 70 */ 3, /* 71 */ 4, /* 72 */ 4, /* 73 */ 5,
    /* 74 */ 4, /* 75 */ 5, /* 76 */ 5, /* 77 */ 6,
    /* 78 */ 4, /* 79 */ 5, /* 7a */ 5, /* 7b */ 6,
    /* 7c */ 5, /* 7d */ 6, /* 7e */ 6, /* 7f */ 7,
    /* 80 */ 1, /* 81 */ 2, /* 82 */ 2, /* 83 */ 3,
    /* 84 */ 2, /* 85 */ 3, /* 86 */ 3, /* 87 */ 4,
    /* 88 */ 2, /* 89 */ 3, /* 8a */ 3, /* 8b */ 4,
    /* 8c */ 3, /* 8d */ 4, /* 8e */ 4, /* 8f */ 5,
    /* 90 */ 2, /* 91 */ 3, /* 92 */ 3, /* 93 */ 4,
    /* 94 */ 3, /* 95 */ 4, /* 96 */ 4, /* 97 */ 5,
    /* 98 */ 3, /* 99 */ 4, /* 9a */ 4, /* 9b */ 5,
    /* 9c */ 4, /* 9d */ 5, /* 9e */ 5, /* 9f */ 6,
    /* a0 */ 2, /* a1 */ 3, /* a2 */ 3, /* a3 */ 4,
    /* a4 */ 3, /* a5 */ 4, /* a6 */ 4, /* a7 */ 5,
    /* a8 */ 3, /* a9 */ 4, /* aa */ 4, /* ab */ 5,
    /* ac */ 4, /* ad */ 5, /* ae */ 5, /* af */ 6,
    /* b0 */ 3, /* b1 */ 4, /* b2 */ 4, /* b3 */ 5,
    /* b4 */ 4, /* b5 */ 5, /* b6 */ 5, /* b7 */ 6,
    /* b8 */ 4, /* b9 */ 5, /* ba */ 5, /* bb */ 6,
    /* bc */ 5, /* bd */ 6, /* be */ 6, /* bf */ 7,
    /* c0 */ 2, /* c1 */ 3, /* c2 */ 3, /* c3 */ 4,
    /* c4 */ 3, /* c5 */ 4, /* c6 */ 4, /* c7 */ 5,
    /* c8 */ 3, /* c9 */ 4, /* ca */ 4, /* cb */ 5,
    /* cc */ 4, /* cd */ 5, /* ce */ 5, /* cf */ 6,
    /* d0 */ 3, /* d1 */ 4, /* d2 */ 4, /* d3 */ 5,
    /* d4 */ 4, /* d5 */ 5, /* d6 */ 5, /* d7 */ 6,
    /* d8 */ 4, /* d9 */ 5, /* da */ 5, /* db */ 6,
    /* dc */ 5, /* dd */ 6, /* de */ 6, /* df */ 7,
    /* e0 */ 3, /* e1 */ 4, /* e2 */ 4, /* e3 */ 5,
    /* e4 */ 4, /* e5 */ 5, /* e6 */ 5, /* e7 */ 6,
    /* e8 */ 4, /* e9 */ 5, /* ea */ 5, /* eb */ 6,
    /* ec */ 5, /* ed */ 6, /* ee */ 6, /* ef */ 7,
    /* f0 */ 4, /* f1 */ 5, /* f2 */ 5, /* f3 */ 6,
    /* f4 */ 5, /* f5 */ 6, /* f6 */ 6, /* f7 */ 7,
    /* f8 */ 5, /* f9 */ 6, /* fa */ 6, /* fb */ 7,
    /* fc */ 6, /* fd */ 7, /* fe */ 7, /* ff */ 8
};


// General-purpose Hamming distance with support for arbitrary starting
// offset and arbitrary number of bits to be compared
static uint64_t compute_hamming_distance (const unsigned char *desc1, const unsigned char *desc2, size_t bit_offset, size_t bit_length)
{
    uint64_t result = 0;

    // Skip the whole bytes at the beginning...
    size_t byte_pos = bit_offset / 8;
    bit_offset = bit_offset % 8;

    // ... and process the unaligned bits
    if (bit_offset) {
        size_t tmp_len = std::min(8 - bit_offset, bit_length);
        uint8_t mask = (~(0xFF << tmp_len) << bit_offset);

        const uint8_t a = desc1[byte_pos];
        const uint8_t b = desc2[byte_pos];

        result += lookup8bit[(a ^ b) & mask];

        bit_length -= tmp_len;
        byte_pos++;
    }

    // Process 64-bit blocks
    for (; bit_length >= 64; byte_pos += 8, bit_length -= 64) {
        const uint64_t a = *reinterpret_cast<const uint64_t*>(desc1 + byte_pos);
        const uint64_t b = *reinterpret_cast<const uint64_t*>(desc2 + byte_pos);

        result += _popcnt64(a ^ b);
    }

    // Process the remaining 8-bit blocks
    for (; bit_length >= 8; byte_pos++, bit_length -= 8) {
        const uint8_t a = desc1[byte_pos];
        const uint8_t b = desc2[byte_pos];

        result += lookup8bit[a ^ b];
    }

    // Process the remaining unaligned bits
    if (bit_length) {
        const uint8_t mask = ~(0xFF << bit_length);
        const uint8_t a = desc1[byte_pos];
        const uint8_t b = desc2[byte_pos];

        result += lookup8bit[(a ^ b) & mask];
    }

    return result;
}

// General-purpose extended distance for AlphaGamma descriptors, with
// support for arbitrary starting offset and arbitrary number of bits
// to be compared
static uint64_t compute_extended_distance (const unsigned char *desc1, const unsigned char *desc2, size_t bit_offset, size_t bit_length, size_t extended_offset)
{
    uint64_t result = 0;

    // Skip the whole bytes at the beginning...
    size_t byte_pos = bit_offset / 8;
    bit_offset = bit_offset % 8;

    // ... and process the unaligned bits
    if (bit_offset) {
        size_t tmp_len = std::min(8 - bit_offset, bit_length);
        uint8_t mask = (~(0xFF << tmp_len) << bit_offset);

        const uint8_t a = desc1[byte_pos];
        const uint8_t b = desc2[byte_pos];
        const uint8_t a_e = desc1[byte_pos + extended_offset];
        const uint8_t b_e = desc2[byte_pos + extended_offset];

        const uint8_t ab = (a ^ b) & mask;

        result += lookup8bit[ab];
        result += lookup8bit[(a_e ^ b_e) & mask];
        result += 2*lookup8bit[a_e & b_e & ab];

        bit_length -= tmp_len;
        byte_pos++;
    }

    // Process 64-bit blocks
    for (; bit_length >= 64; byte_pos += 8, bit_length -= 64) {
        const uint64_t a = *reinterpret_cast<const uint64_t*>(desc1 + byte_pos);
        const uint64_t b = *reinterpret_cast<const uint64_t*>(desc2 + byte_pos);
        const uint64_t a_e = *reinterpret_cast<const uint64_t*>(desc1 + byte_pos + extended_offset);
        const uint64_t b_e = *reinterpret_cast<const uint64_t*>(desc2 + byte_pos + extended_offset);

        const uint64_t ab = a ^ b;

        result += _popcnt64(ab);
        result += _popcnt64(a_e ^ b_e);
        result += 2*_popcnt64(a_e & b_e & ab);
    }

    // Process the remaining 8-bit blocks
    for (; bit_length >= 8; byte_pos++, bit_length -= 8) {
        const uint8_t a = desc1[byte_pos];
        const uint8_t b = desc2[byte_pos];
        const uint8_t a_e = desc1[byte_pos + extended_offset];
        const uint8_t b_e = desc2[byte_pos + extended_offset];

        const uint8_t ab = a ^ b;

        result += lookup8bit[ab];
        result += lookup8bit[a_e ^ b_e];
        result += 2*lookup8bit[a_e & b_e & ab];
    }

    // Process the remaining unaligned bits
    if (bit_length) {
        const uint8_t mask = ~(0xFF << bit_length);
        const uint8_t a = desc1[byte_pos];
        const uint8_t b = desc2[byte_pos];
        const uint8_t a_e = desc1[byte_pos + extended_offset];
        const uint8_t b_e = desc2[byte_pos + extended_offset];

        const uint8_t ab = (a ^ b) & mask;

        result += lookup8bit[ab];
        result += lookup8bit[(a_e ^ b_e) & mask];
        result += 2*lookup8bit[a_e & b_e & ab];
    }

    return result;
}


static inline size_t compute_byte_descriptor_size (size_t num_circles, size_t num_rays)
{
    size_t descriptor_size = (num_circles + num_circles*num_rays);
    descriptor_size = descriptor_size / 8 + (descriptor_size % 8 > 0);
    return descriptor_size;
}


// *********************************************************************
// *                          MEX entry point                          *
// *********************************************************************
void mexFunction (int nlhs, mxArray **plhs, int nrhs, const mxArray **prhs)
{
    if (nrhs < 4 || nrhs > 7) {
        mexErrMsgTxt("Invalid number of input parameters!");
    }

    // Validate input
    if (!mxIsNumeric(prhs[2]) || mxGetNumberOfElements(prhs[2]) != 1) {
        mexErrMsgTxt("num_circles must be a numeric scalar!");
    }

    if (!mxIsNumeric(prhs[3]) || mxGetNumberOfElements(prhs[3]) != 1) {
        mexErrMsgTxt("num_rays must be a numeric scalar!");
    }

    const size_t numCircles = mxGetScalar(prhs[2]);
    const size_t numRays = mxGetScalar(prhs[3]);
    const size_t descriptorSize = compute_byte_descriptor_size(numCircles, numRays);

    if (mxGetClassID(prhs[0]) != mxUINT8_CLASS) {
        mexErrMsgTxt("desc1 matrix must be a DxN1 uint8 matrix!");
    }
    if (mxGetM(prhs[0]) != descriptorSize && mxGetM(prhs[0]) != 2*descriptorSize) {
        mexErrMsgTxt("Invalid descriptor size!");
    }

    if (mxGetClassID(prhs[1]) != mxUINT8_CLASS) {
        mexErrMsgTxt("desc2 matrix must be a DxN2 uint8 matrix!");
    }
    if (mxGetM(prhs[1]) != descriptorSize && mxGetM(prhs[1]) != 2*descriptorSize) {
        mexErrMsgTxt("Invalid descriptor size!");
    }


    if (mxGetM(prhs[0]) != mxGetM(prhs[1])) {
        mexErrMsgTxt("descriptors must be of same size!");
    }

    const bool extendedDescriptor = (mxGetM(prhs[0]) == 2*descriptorSize);

    // Distance weights
    double A = 5.0;
    double B = 1.0;
    double G = 1.0;

    if (nrhs > 4) {
        A = mxGetScalar(prhs[4]);
    }
    if (nrhs > 5) {
        B = mxGetScalar(prhs[5]);
    }
    if (nrhs > 6) {
        G = mxGetScalar(prhs[6]);
    }

    // Cast the input matrices to CV_8U type
    const cv::Mat desc1 = cv::Mat(mxGetN(prhs[0]), mxGetM(prhs[0]), CV_8U, mxGetData(prhs[0]));
    const cv::Mat desc2 = cv::Mat(mxGetN(prhs[1]), mxGetM(prhs[1]), CV_8U, mxGetData(prhs[1]));

    // *** Compute distance matrix ***
    plhs[0] = mxCreateNumericMatrix(desc2.rows, desc1.rows, mxDOUBLE_CLASS, mxREAL);
    cv::Mat distances = cv::Mat(mxGetN(plhs[0]), mxGetM(plhs[0]), CV_64F, mxGetData(plhs[0])); // Note switched dimensions

    const size_t bitOffsetA = 0;
    const size_t bitLengthA = numCircles;

    const size_t bitOffsetG = bitOffsetA + bitLengthA;
    const size_t bitLengthG = numRays*numCircles;

    if (extendedDescriptor) {
        // Extended descriptor
        for (int i = 0; i < desc1.rows; i++) {
            double *distPtr = distances.ptr<double>(i);
            const unsigned char *desc1p = desc1.ptr<unsigned char>(i);
            for (int j = 0; j < desc2.rows; j++) {
                const unsigned char *desc2p = desc2.ptr<unsigned char>(j);

                distPtr[j] = A*compute_extended_distance(desc1p, desc2p, bitOffsetA, bitLengthA, descriptorSize) +
                             G*compute_extended_distance(desc1p, desc2p, bitOffsetG, bitLengthG, descriptorSize);
            }
        }
    } else {
        // Basic descriptor
        for (int i = 0; i < desc1.rows; i++) {
            double *distPtr = distances.ptr<double>(i);
            const unsigned char *desc1p = desc1.ptr<unsigned char>(i);
            for (int j = 0; j < desc2.rows; j++) {
                const unsigned char *desc2p = desc2.ptr<unsigned char>(j);

                distPtr[j] = A*compute_hamming_distance(desc1p, desc2p, bitOffsetA, bitLengthA) +
                             G*compute_hamming_distance(desc1p, desc2p, bitOffsetG, bitLengthG);
            }
        }
    }
}
