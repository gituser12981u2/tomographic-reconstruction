classdef Volume
    properties (SetAccess = private)
        Data (:, :, :) double
        Slices (:, 1) Slice
        SpacingXY (1,2) double
        ZPositions (:,1) double
        IsUniformZ (1,1) logical
        SpacingZ (1,1) double = NaN
    end

    methods
        function obj = Volume(slices, options)
            arguments
                slices (:, 1) Slice
                options.ZTolerance (1,1) double {mustBeReal, mustBeFinite, mustBeNonnegative} = 1e-9
            end

            if isempty(slices)
                error('Volume:EmptyInput', ...
                    'Volume requires at least one Slice.');
            end

            z = [slices.ZPosition];
            [sortedZ, order] = sort(z);
            sortedZ = sortedZ(:);
            sortedSlices = slices(order);
            sortedSlices = sortedSlices(:);

            if numel(sortedZ) > 1
                dz = diff(sortedZ);
                if any(abs(dz) <= options.ZTolerance)
                    error('Volume:DuplicateZPosition', ...
                        'Volume cannot contain duplicate or indistinguishably close z-positions.');
                end
            end

            ref = sortedSlices(1);
            for k = 2:numel(sortedSlices)
                if ~ref.isCompatibleWith(sortedSlices(k))
                    error('Volume:IncompatibleSlices', ...
                        'All slices in a Volume must have matching dimensions, SpacingXY, OriginXY.');
                end
            end

            rows = ref.rows();
            cols = ref.cols();
            numSlices = numel(sortedSlices);

            data = zeros(rows, cols, numSlices, 'double');
            for k = 1:numSlices
                data(:, :, k) = sortedSlices(k).Data;
            end

            obj.Data = data;
            obj.Slices = sortedSlices;
            obj.SpacingXY = ref.SpacingXY;
            obj.ZPositions = sortedZ;

            if numSlices == 1
                obj.IsUniformZ = true;
                obj.SpacingZ = NaN;
            else
                dz = diff(sortedZ);
                obj.IsUniformZ = all(abs(dz - dz(1)) <= options.ZTolerance);
                if obj.IsUniformZ
                    obj.SpacingZ = dz(1);
                end
            end
        end

        function out = size3D(obj)
            out = size(obj.Data);
        end

        function out = rows(obj)
            out = size(obj.Data, 1);
        end

        function out = cols(obj)
            out = size(obj.Data, 2);
        end

        function out = numSlices(obj)
            out = size(obj.Data, 3);
        end

        function out = dx(obj)
            out = obj.SpacingXY(1);
        end

        function out = dy(obj)
            out = obj.SpacingXY(2);
        end

        function out = zExtent(obj)
            out = [obj.ZPositions(1), obj.ZPositions(end)];
        end

        function out = xExtent(obj)
            out = obj.Slices(1).xExtent();
        end

        function out = yExtent(obj)
            out = obj.Slices(1).yExtent();
        end

        function out = bounds(obj)
            out = struct( ...
                'x', obj.xExtent(), ...
                'y', obj.yExtent(), ...
                'z', obj.zExtent());
        end

        function tf = hasUniformZ(obj)
            tf = obj.IsUniformZ;
        end

        function out = slice(obj, k)
            arguments
                obj
                k (1,1) double {mustBeInteger, mustBePositive}
            end

            if k > obj.numSlices()
                error('Volume:SliceIndexOutOfRange', ...
                    'Slice index exceeds the number of slices in the volume.');
            end

            out = obj.Slices(k);
        end

        function disp(obj)
            if numel(obj) ~= 1
                builtin('disp', obj);
                return;
            end

            sz = size(obj.Data);
            fprintf('  Volume\n');
            fprintf('    Size:        [%d %d %d]\n', sz(1), sz(2), sz(3));
            fprintf('    SpacingXY:   [%.6g %.6g]\n', obj.SpacingXY(1), obj.SpacingXY(2));
            fprintf('    ZExtent:     [%.6g %.6g]\n', obj.ZPositions(1), obj.ZPositions(end));
            fprintf('    Uniform Z:   %s\n', string(obj.IsUniformZ));

            if obj.IsUniformZ && numel(obj.ZPositions) > 1
                fprintf('    SpacingZ:    %.6g\n', obj.SpacingZ);
            else
                fprintf('    SpacingZ:    NaN\n');
            end
        end
    end
end
