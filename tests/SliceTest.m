classdef SliceTest < matlab.unittest.TestCase

    methods (Test)
        function constructsValidSlice(testCase)
            data = [1 2; 3 4];
            spacingXY = [0.5 0.25];
            zPosition = 12.0;

            s = Slice(data, spacingXY, zPosition);

            testCase.verifyEqual(s.Data, data);
            testCase.verifyEqual(s.SpacingXY, spacingXY);
            testCase.verifyEqual(s.ZPosition, zPosition);
            testCase.verifyEqual(s.OriginXY, [0 0]);
            testCase.verifyEmpty(s.ID);
            testCase.verifyEqual(s.Metadata, struct());
        end

        function constructWithOptions(testCase)
            data = ones(3, 4);
            metadata = struct("Source", "synthetic");

            s = Slice(data, [1.5 2.0], -3.25, ...
                OriginXY = [10 20], ...
                ID = "slice-001", ...
                Metadata = metadata);

            testCase.verifyEqual(s.OriginXY, [10 20]);
            testCase.verifyEqual(s.ID, "slice-001");
            testCase.verifyEqual(s.Metadata, metadata);
        end

        function computeDimensions(testCase)
            data = zeros(7, 11);
            s = Slice(data, [0.2 0.4], 0);

            testCase.verifyEqual(s.size2D(), [7 11]);
            testCase.verifyEqual(s.rows(), 7);
            testCase.verifyEqual(s.cols(), 11);
        end

        function computeSpacingAccessotrs(testCase)
            s = Slice(zeros(2, 2), [0.7 0.9], 0);

            testCase.verifyEqual(s.dx(), 0.7);
            testCase.verifyEqual(s.dy(), 0.9);
        end

        function computePhysicalWidthAndHeight(testCase)
            data = zeros(10, 20);
            s = Slice(data, [0.5 2.0], 0);

            testCase.verifyEqual(s.width(), 10.0);
            testCase.verifyEqual(s.height(), 20.0);
        end

        function computeExtents(testCase)
            data = zeros(10, 20);
            s = Slice(data, [0.5 2.0], 7.5, OriginXY = [100 200]);

            testCase.verifyEqual(s.xExtent(), [100 110]);
            testCase.verifyEqual(s.yExtent(), [200 220]);

            b = s.bounds();
            testCase.verifyEqual(b.x, [100 110]);
            testCase.verifyEqual(b.y, [200 220]);
            testCase.verifyEqual(b.z, [7.5 7.5]);
        end

        function detectsIDPresence(testCase)
            s1 = Slice(zeros(2, 2), [1 1], 0);
            s2 = Slice(zeros(2, 2), [1 1], 0, ID = "abc");

            testCase.verifyFalse(s1.hasID());
            testCase.verifyTrue(s2.hasID());
        end

        function compatibleSlicesMatch(testCase)
            a = Slice(zeros(3, 4), [0.5 0.5], 0, OriginXY = [1 2]);
            b = Slice(ones(3, 4), [0.5 0.5], 10, OriginXY = [1 2]);

            testCase.verifyTrue(a.isCompatibleWith(b));
        end

        function incompatibleSlicesDifferentSize(testCase)
            a = Slice(zeros(3, 4), [0.5 0.5], 0);
            b = Slice(zeros(4, 4), [0.5 0.5], 1);

            testCase.verifyFalse(a.isCompatibleWith(b));
        end

        function incompatibleSlicesDifferentSpacing(testCase)
            a = Slice(zeros(3, 4), [0.5 0.5], 0);
            b = Slice(zeros(3, 4), [0.5 0.6], 1);

            testCase.verifyFalse(a.isCompatibleWith(b));
        end

        function incompatibleSlicesDifferentOrigin(testCase)
            a = Slice(zeros(3, 4), [0.5 0.5], 0, OriginXY = [0 0]);
            b = Slice(zeros(3, 4), [0.5 0.5], 1, OriginXY = [1 0]);

            testCase.verifyFalse(a.isCompatibleWith(b));
        end

        function rejectsEmptyData(testCase)
            testCase.verifyError(@() Slice([], [1 1], 0), ...
                "MATLAB:validators:mustBeNonempty");
        end

        function rejectsNaNData(testCase)
            testCase.verifyError(@() Slice([1 NaN], [1 1], 0), ...
                "MATLAB:validators:mustBeFinite");
        end
    end
end
