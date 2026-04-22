classdef Slice
    %SLICE One reconstructed 2D slice with spatial metadata.
    %
    % A Slice represents one reconstructed 2D image together with the
    % geometric metadata needed to place that image in a 3D stack.
    %
    % Convention:
    % - SpacingXY = [dx dy]
    % - OriginXY  = [x0 y0]

    properties (SetAccess = private)
        Data (:,:) double
        SpacingXY (1,2) double
        ZPosition (1,1) double
        OriginXY (1,2) double
        ID
        Metadata
    end

    methods
        function obj = Slice(data, spacingXY, zPosition, options)
            %SLICE Construct a Slice.
            %
            %
            %  Name-value inputs:
            %  - OriginXY: 1x2 finite numeric vector [x0 y0]
            %              default [0 0]
            %  - ID: optional identifier
            %        default []
            %  - Metadata: optional metadata payload
            %              default struct()

            arguments
                data (:,:) double {mustBeReal, mustBeFinite, mustBeNonempty}
                spacingXY (1,2) double {mustBeReal, mustBeFinite, mustBePositive}
                zPosition (1,1) double {mustBeReal, mustBeFinite}
                options.OriginXY (1,2) double = [0 0]
                options.ID = []
                options.Metadata = struct()
            end

            obj.Data = data;
            obj.SpacingXY = spacingXY;
            obj.ZPosition = zPosition;
            obj.OriginXY = options.OriginXY;
            obj.ID = options.ID;
            obj.Metadata = options.Metadata;
        end

        function tf = hasID(obj)
            tf = ~isempty(obj.ID);
        end

        function out = size2D(obj)
            out = size(obj.Data);
        end

        function out = rows(obj)
            out = size(obj.Data, 1);
        end

        function out = cols(obj)
            out = size(obj.Data, 2);
        end

        function out = dx(obj)
            %DX In-plane spacing along x.
            out = obj.SpacingXY(1);
        end

        function out = dy(obj)
            %DY In-place spacing along y.
            out = obj.SpacingXY(2);
        end

        function out = width(obj)
            %WIDTH Physical width of the slice domain along x.
            out = obj.cols() * obj.dx();
        end

        function out = height(obj)
            %HEIGHT Physical height of the slice domain along y.
            out = obj.rows() * obj.dy();
        end

        function out = xExtent(obj)
            %XEXTENT Return [xmin xmax] for the slice plane.
            x0 = obj.OriginXY(1);
            out = [x0, x0 + obj.width()];
        end

        function out = yExtent(obj)
            %YEXTENT Return [ymin ymax] for the slice plane.
            y0 = obj.OriginXY(2);
            out = [y0, y0 + obj.height()];
        end

        function out = bounds(obj)
            %BOUNDS Return struct of spatial bounds for the slice.
            out = struct( ...
                'x', obj.xExtent(), ...
                'y', obj.yExtent(), ...
                'z', [obj.ZPosition, obj.ZPosition]);
        end

        function tf = isCompatibleWith(a, b)
            %ISCOMPATIBLEWITH Check whether two slices are stack compatible.
            %
            % Two slices are considered compatible here if they have the same data dimensions,
            % spacing, and origin.
            tf = isequal(size(a.Data), size(b.Data)) && ...
                isequal(a.SpacingXY, b.SpacingXY) && ...
                isequal(a.OriginXY, b.OriginXY);
        end

        function disp(obj)
            %DISP Display for Slice objects.
            if numel(obj) ~= 1
                builtin('disp', obj);
                return;
            end

            sz = size(obj.Data);
            fprintf('  Slice\n');
            fprintf('    Size:        [%d %d]\n', sz(1), sz(2));
            fprintf('    SpacingXY:   [%.6g %.6g]\n', obj.SpacingXY(1), obj.SpacingXY(2));
            fprintf('    ZPosition:   %.6g\n', obj.ZPosition);
            fprintf('    OriginXY:    [%.6g %.6g]\n', obj.OriginXY(1), obj.OriginXY(2));

            if obj.hasID()
                try
                    fprintf('    ID:          %s\n', string(obj.ID));
                catch
                    fprintf('    ID:          <non-displayable identifier>\n');
                end
            else
                fprintf('    ID:          []\n');
            end
        end
    end
end
