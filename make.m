mex mex/compute_keypoint_distances.cpp -I/opt/opencv-3.1.0-matlab/include -L/opt/opencv-3.1.0-matlab/lib -lopencv_core
mex +vicos/+descriptor/@AlphaGamma/private/alpha_gamma_distances.cpp -outdir +vicos/+descriptor/@AlphaGamma/private/ -I/opt/opencv-3.1.0-matlab/include -L/opt/opencv-3.1.0-matlab/lib -lopencv_core 


mex convert_bytestring_to_bitstring.cpp
mex alphagamma_distance_fast.cpp

