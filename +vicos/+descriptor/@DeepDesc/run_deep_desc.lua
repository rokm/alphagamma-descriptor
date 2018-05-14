require 'nn'
require 'cunn'
require 'mattorch'

local cmd = torch.CmdLine()
cmd:option( '--model', '../models/CNN3_p8_n8_split4_073000.t7', 'Network model to use' )
cmd:option( '--input', 'patches.mat', 'Input .mat file' )
cmd:option( '--output', 'desc.mat', 'Output .mat file' )
local params = cmd:parse(arg)

-- load input patches
local input = mattorch.load( params.input )
local patches = input.patches:float()

-- handle the case when only a single input patch is provided
-- we need to add singleton dimensions: 64x64 -> 1x1x64x64
if patches:nDimension() == 2 then
    patches = nn.utils.addSingletonDimension(patches, 1)
    patches = nn.utils.addSingletonDimension(patches, 1)
end

-- load model and mean
local data = torch.load( params.model )
local desc = data.desc
local mean = data.mean
local std  = data.std

-- normalize
for i=1,patches:size(1) do
    patches[i] = patches[i]:add( -mean ):cdiv( std )
end

-- convert to cuda for processing on the GPU
patches = patches:cuda()
desc:cuda()

-- compute descriptors
local p = desc:forward( patches )

-- save descriptors
-- Note: mattorch.save can export only double-precision tensors!
mattorch.save( params.output, {x = p:double() } )
