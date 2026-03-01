path = "/Users/belindaserafine/Documents/School/Capstone/Capstone Datasets/B-Scans/NEH_UT_2021RetinalOCTDataset/NORMAL/1/OS";
outputpath = "/Users/belindaserafine/Documents/School/Capstone/Capstone Datasets/stretched_normal_1_os";

bscanfolder = fullfile(path, '*.jpg');
bscans = dir(bscanfolder); % create struct with fields name folder date etc

p = 512;
q = 496;

for i = 1:length(bscans)
    bscanfile = fullfile(path, bscans(i).name);
    
    ascans = Bscan_jpg_to_Ascans(bscanfile);
    [num_ascans, ~] = size(ascans);
    
    ascans_stretched = zeros(num_ascans, p); % storage
    
    for j = 1:num_ascans
        % resamples ascan at p/q times the original sample rate
        stretched = resample(ascans(j,:), p, q);
        ascans_stretched(j, :) = stretched;
    end

    outfile = fullfile(outputpath, bscans(i).name);
    imwrite(uint8(ascansStretched'), outfile);
end