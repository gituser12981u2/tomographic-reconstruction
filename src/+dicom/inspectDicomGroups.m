function inspectDicomGroups(folder)
%INSPECTDICOMGROUPS Summarize DICOM files by series and orientation.

arguments
    folder (1,:) char
end

files = dir(fullfile(folder, '**', '*.dcm'));

groups = containers.Map();

for k = 1:numel(files)
    path = fullfile(files(k).folder, files(k).name);

    try
        info = dicominfo(path);
    catch
        continue;
    end

    if isfield(info, 'SeriesInstanceUID')
        seriesUID = string(info.SeriesInstanceUID);
    else
        seriesUID = "NO_SERIES_UID";
    end

    if isfield(info, 'SeriesDescription')
        desc = string(info.SeriesDescription);
    else
        desc = "";
    end

    if isfield(info, 'ImageOrientationPatient')
        ori = round(double(info.ImageOrientationPatient(:)), 4);
        oriKey = sprintf('%.4f_', ori);
    else
        oriKey = "NO_ORIENTATION";
    end

    if isfield(info, 'Rows') && isfield(info, 'Columns')
        sizeKey = sprintf('%dx%d', info.Rows, info.Columns);
    else
        sizeKey = "NO_SIZE";
    end

    if isfield(info, 'PixelSpacing')
        ps = double(info.PixelSpacing(:));
        spacingKey = sprintf('%.6f_%.6f', ps(1), ps(2));
    else
        spacingKey = "NO_PIXEL_SPACING";
    end

    key = char(seriesUID + "|" + oriKey + "|" + sizeKey + "|" + spacingKey);

    if ~isKey(groups, key)
        groups(key) = struct( ...
            'SeriesUID', seriesUID, ...
            'Description', desc, ...
            'Orientation', oriKey, ...
            'Size', sizeKey, ...
            'Spacing', spacingKey, ...
            'Count', 0, ...
            'ExampleFile', string(path));
    end

    g = groups(key);
    g.Count = g.Count + 1;
    groups(key) = g;
end

keys_ = keys(groups);

fprintf('Found %d DICOM geometry groups:\n\n', numel(keys_));

for i = 1:numel(keys_)
    g = groups(keys_{i});

    fprintf('Group %d\n', i);
    fprintf('  Count:       %d\n', g.Count);
    fprintf('  Series UID:  %s\n', g.SeriesUID);
    fprintf('  Description: %s\n', g.Description);
    fprintf('  Orientation: %s\n', g.Orientation);
    fprintf('  Size:        %s\n', g.Size);
    fprintf('  Spacing:     %s\n', g.Spacing);
    fprintf('  Example:     %s\n\n', g.ExampleFile);
end

end
