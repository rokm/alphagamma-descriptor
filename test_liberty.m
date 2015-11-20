clear;
close all;

dataset = LibertyDataset();

num_patches = 500;
patch_size = dataset.patch_size;

[ patch_idx1, patch_idx2 ] = dataset.get_random_correspondence_set(num_patches);

I = zeros(num_patches*patch_size, 2*patch_size, 'uint8');

for p = 1:num_patches,
    ymin = (p-1)*patch_size + 1;
    ymax = ymin + patch_size - 1;
    
    xmin = 0*patch_size + 1;
    xmax = xmin + patch_size - 1;
    
    I(ymin:ymax, xmin:xmax) = dataset.get_patch(patch_idx1(p));
    
    xmin = 1*patch_size + 1;
    xmax = xmin + patch_size - 1;
    
    I(ymin:ymax, xmin:xmax) = dataset.get_patch(patch_idx2(p));
end

imwrite(I, 'test.png');