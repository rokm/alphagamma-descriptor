classdef LiftWrapper < handle
    % LIFTWRAPPER - a wrapper for original python-program-based LIFT implementation
    %
    % This class wraps the corresponding python programs from the official
    % LIFT release: https://github.com/cvlab-epfl/LIFT
    %
    % K. M. Yi, E. Trulls, V. Lepetit, and P. Fua. "LIFT: Learned Invariant 
    % Feature Transform", European Conference on Computer Vision (ECCV), 2016.
    %
    % (C) 2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        lift_code_root
        wrapper_script_detector
        wrapper_script_descriptor
        override_library_path
        
        cleanup = true
    end
    
    methods
        function self = LiftWrapper (varargin)
            % self = LIFTWRAPPER (varargin)
            %
            % Creates LIFT wrapper object.
            %
            % Input: optional key/value pairs:
            %
            % Output:
            %  - self:
                     
            % Input parser
            parser = inputParser();
            parser.parse(varargin{:});
            
            % Resolve the paths of LIFT code, the wrapper scripts, and the
            % OpenCV dependency
            root_dir = fileparts(mfilename('fullpath'));
            
            if isunix()
                % Linux wrapper scripts
                self.wrapper_script_detector = fullfile(root_dir, 'run_lift_detector.sh');
                self.wrapper_script_descriptor = fullfile(root_dir, 'run_lift_descriptor.sh');
                self.lift_code_root = fullfile(root_dir, '..', '..', '..', 'external', 'lift');
                self.override_library_path = fullfile(root_dir, '..', '..', '..', 'external', 'opencv-bin');
            else
                error('Unsupported platform!');
            end
        end
        
        function keypoints = detect_lift_keypoints (self, I)
            % keypoints = DETECT_LIFT_KEYPOINTS (self, I)
            %
            % Detects LIFT keypoints in the image and computes their
            % orientation.
            %
            % Input:
            %  - self:
            %  - I: input image
            %
            % Output:
            %  - keypoints: structure array of OpenCV keypoints
            
            % Temporary folder for data exchange
            tmp_dir = tempname();
            mkdir(tmp_dir);
            
            % Write image; as far as we are concerned, the image could have
            % come from anywhere. Therefore, write it to temporary
            % location.
            tmp_image_file = fullfile(tmp_dir, 'image.png');
            tmp_keypoint_file = fullfile(tmp_dir, 'keypoints.txt');
            tmp_output_file = fullfile(tmp_dir, 'output.txt');
            imwrite(I, tmp_image_file);

            % Run the wrapper script
            command = sprintf('"%s" "%s" "%s" "%s"', self.wrapper_script_detector, tmp_image_file, tmp_keypoint_file, tmp_output_file);
            
            self.run_lift_wrapper_script(command);
            
            % Read the results
            keypoints = self.read_keypoints_from_file(tmp_output_file);
            
            % Sanity check
            self.write_keypoints_to_file(keypoints, [ tmp_output_file, '.2.txt' ]);
            
            % Cleanup
            if self.cleanup
                rmdir(tmp_dir, 's');
            end
        end
        
        function [ descriptors, keypoints ] = compute_lift_descriptors (self, I, keypoints)
            % descriptor = COMPUTE_LIFT_DESCRIPTORS (self, I, keypoints)
            %
            % Computes LIFT descriptors for provided keypoints in the
            % provided image.
            %
            % Input:
            %  - self:
            %  - I: input image
            %  - keypoints: structure array of OpenCV keypoints
            %
            % Output:
            %  - descriptors: DxN matrix of descriptors, with N being the
            %    number of keypoints
            %  - keypoints: structure array of OpenCV keypoints
            
             % Temporary folder for data exchange
            tmp_dir = tempname();
            mkdir(tmp_dir);
            
            % Write image; as far as we are concerned, the image could have
            % come from anywhere. Therefore, write it to temporary
            % location.
            tmp_image_file = fullfile(tmp_dir, 'image.png');
            tmp_keypoint_file = fullfile(tmp_dir, 'keypoints.txt');
            tmp_output_file = fullfile(tmp_dir, 'output.bin');
            imwrite(I, tmp_image_file);
            
            % Write keypoints
            self.write_keypoints_to_file(keypoints, tmp_keypoint_file);
            
            % Run the script
            command = sprintf('"%s" "%s" "%s" "%s"', self.wrapper_script_descriptor, tmp_image_file, tmp_keypoint_file, tmp_output_file);
            
            self.run_lift_wrapper_script(command);
            
            % Read the data
            [ keypoints, descriptors ] = self.read_descriptors_from_file(tmp_output_file);
            
            % Cleanup
            if self.cleanup
                rmdir(tmp_dir, 's');
            end
        end 
    end
    
    methods (Access = protected)
        function run_lift_wrapper_script (self, command)
            % RUN_LIFT_WRAPPER_SCRIPT (self, command)
            %
            % Runs the provided wrapper script/command. The main idea of
            % this method is to prepare/restore the relevant environment
            % variables (the LIFT code path, library path, etc.).
            %
            % Input:
            %  - self:
            %  - command: command to run
            
            %% Prepare environment
            % Store current LD_LIBRARY_PATH
            ld_library_path = getenv('LD_LIBRARY_PATH');
            
            % Override LD_LIBRARY_PATH
            setenv('LD_LIBRARY_PATH', self.override_library_path);
            
            % Set _LIFT_BASE_PATH
            setenv('_LIFT_BASE_PATH', self.lift_code_root);
            
            %% Run the script
            [ status, result ] = system(command);
            
            %% Restore environment
            % Reset _LIFT_BASE_PATH (not strictly required)
            setenv('_LIFT_BASE_PATH');
            
            % Restore LD_LIBRARY_PATH
            setenv('LD_LIBRARY_PATH', ld_library_path);
            
            %% Check script status
            if status
                error('Wrapper script failed! Output:\n%s\n', result);
            end
        end
    end
    
    methods (Static)
        function keypoints = read_keypoints_from_file (filename)
            % keypoints = READ_KEYPOINTS_FROM_FILE (self, filename)
            %
            % Reads text file produced by LIFT code and converts the stored
            % keypoints to OpenCV format.
            %
            % Input:
            %  - self:
            %  - filename: input file
            %
            % Output:
            %  - keypoints: structure array of OpenCV keypoints
            
            % Read data
            fid = fopen(filename, 'r');

            line = fgetl(fid);
            num_dimensions = str2double(line);

            line = fgetl(fid);
            num_keypoints = str2double(line);

            data = textscan(fid, '%f');
            data = reshape(data{1}, num_dimensions, num_keypoints);

            fclose(fid);
            
            % Parse keypoints
            keypoints = repmat(struct('pt', [ 0, 0 ], 'size', 0, 'angle', 0, 'response', 0, 'octave', 0, 'class_id', -1), num_keypoints, 1);
            for i = 1:num_keypoints
                keypoints(i).pt = [ data(1, i), data(2, i) ];
                keypoints(i).size = 2*data(3, i);
                keypoints(i).angle = data(4, i);
                keypoints(i).response = data(5, i);
                keypoints(i).octave = int32(data(6, i));
            end
        end
        
        function [ keypoints, descriptors ] = read_descriptors_from_file (filename)
            % [ keypoints, descriptors ] = READ_DESCRIPTORS_FROM_FILE (self, filename)
            %
            % Reads the LIFT descriptors from HDF5 file produced by LIFT 
            % code.
            %
            % Input:
            %  - self:
            %  - filename: input file
            %
            % Output:
            %  - keypoints: keypoints
            %  - descriptors: descriptors data
            
            % Parse keypoints
            data = h5read(filename, '/keypoints');
            
            num_keypoints = size(data, 2);
            assert(size(data, 1) == 13, 'Invalid output data format!');
            
            keypoints = repmat(struct('pt', [ 0, 0 ], 'size', 0, 'angle', 0, 'response', 0, 'octave', 0, 'class_id', -1), num_keypoints, 1);
            for i = 1:num_keypoints
                keypoints(i).pt = [ data(1, i), data(2, i) ];
                keypoints(i).size = 2*data(3, i);
                keypoints(i).angle = data(4, i);
                keypoints(i).response = data(5, i);
                keypoints(i).octave = int32(data(6, i));
            end

            % Parse descriptors
            data = h5read(filename, '/descriptors');
            descriptors = data'; % transpose to Nx128
        end
        
        function write_keypoints_to_file (keypoints, filename)
            % WRITE_KEYPOINTS_TO_FILE (self)
            %
            % Writes an array of OpenCV keypoints to text file format used
            % by LIFT code.
            %
            % Input:
            %  - self:
            %  - keypoints: structure array of OpenCV keypoints
            %  - filename: output file
            
            % Write data
            fid = fopen(filename, 'w+');
            
            % Number of dimensions: 13
            fprintf(fid, '%d\n', 13); 
            
            % Number of keypoints
            fprintf(fid, '%d\n', numel(keypoints));
            
            % Write keypoints
            for i = 1:numel(keypoints)
                kpt = keypoints(i);
                
                % x, y
                fprintf(fid, '%.12g %.12g', kpt.pt(1), kpt.pt(2));
                
                % size (radius)
                fprintf(fid, ' %.12g', 0.5*kpt.size);
                
                % angle
                fprintf(fid, ' %.12g', kpt.angle);
                
                % response
                fprintf(fid, ' %.12g', kpt.response);
                
                % octave
                fprintf(fid, ' %d', kpt.octave');
                
                % a, b, c for vgg affine
                a = 1 / ((0.5*kpt.size)^2);
                b = 0;
                c = a;
                fprintf(fid, ' %.12g %.12g %.12g', a, b, c);
                
                % A0, A1, A2, A3
                S = [ a, b; b, c ];
                invS = inv(S);
                
                a = sqrt(invS(1,1));
                b = invS(1, 2) / max(a, 1e-18);
                A = [ a, 0;
                      b, sqrt(max(invS(2,2) - b^2, 0)) ];
                
                cos_val = cosd(kpt.angle);
                sin_val = sind(kpt.angle);
                R = [ cos_val, -sin_val;
                      sin_val,  cos_val ];
                  
                A = A * R;
                  
                A0 = A(1, 1);
                A1 = A(1, 2);
                A2 = A(2, 1);
                A3 = A(2, 2);
                
                fprintf(fid, ' %.12g %.12g %.12g %.12g', A0, A1, A2, A3);
                
                % class ID
                % fprintf(' %f', kpt.class_id);
                
                fprintf(fid, '\n');
            end
            
            fclose(fid);
        end
    end
    
end