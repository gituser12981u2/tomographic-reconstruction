classdef VolumeTest < matlab.unittest.TestCase

    methods(Test)

        function constructsFromOrderedSlices(testCase)
            s1 = Slice(ones(2, 3), [0.5 0.25], 0);
            s2 = Slice(ones(2, 3) * 2, [0.5 0.25], 1);
            s3 = Slice(ones(2, 3) * 3, [0.5 0.25], 2);

            v = Volume([s1; s2; s3]);

            testCase.verifyEqual(size(v.Data), [2 3 3]);
            testCase.verifyEqual(v.SpacingXY, [0.5 0.25]);
            testCase.verifyEqual(v.ZPositions, [0; 1; 2]);
            testCase.verifyEqual(v.SpacingZ, 1);

            testCase.verifyEqual(v.Data(:,:,1), s1.Data);
            testCase.verifyEqual(v.Data(:,:,2), s2.Data);
            testCase.verifyEqual(v.Data(:,:,3), s3.Data);
        end

        function constructsFromUnorderedSlicesAndSorts(testCase)
            low = Slice(ones(2, 2) * 10, [1 1], 0);
            mid = Slice(ones(2, 2) * 20, [1 1], 5);
            high = Slice(ones(2, 2) * 30, [1 1], 10);

            v = Volume([high; low; mid]);

            testCase.verifyEqual(v.ZPositions, [0; 5; 10]);
            testCase.verifyEqual(v.Data(:,:,1), low.Data);
            testCase.verifyEqual(v.Data(:,:,2), mid.Data);
            testCase.verifyEqual(v.Data(:,:,3), high.Data);
        end

        function detectsUniformZSpacing(testCase)
            s1 = Slice(zeros(2, 2), [1 1], 0);
            s2 = Slice(zeros(2, 2), [1 1], 1);
            s3 = Slice(zeros(2, 2), [1 1], 3);

            v = Volume([s1; s2; s3]);

            testCase.verifyFalse(v.hasUniformZ());
            testCase.verifyTrue(isnan(v.SpacingZ));
        end

        function singleSliceVolumeIsAllowed(testCase)
            s = Slice(ones(4, 5), [0.1 0.2], 7);

            v = Volume(s);

            testCase.verifyEqual(size(v.Data), [4 5]);
            testCase.verifyEqual(v.numSlices(), 1);
            testCase.verifyEqual(v.ZPositions, 7);
            testCase.verifyTrue(v.hasUniformZ());
            testCase.verifyTrue(isnan(v.SpacingZ));
        end

        function computeDimensions(testCase)
            s1 = Slice(zeros(7, 11), [0.5 0.75], 0);
            s2 = Slice(zeros(7, 11), [0.5 0.75], 1);

            v = Volume([s1; s2]);

            testCase.verifyEqual(v.rows(), 7);
            testCase.verifyEqual(v.cols(), 11);
            testCase.verifyEqual(v.numSlices(), 2);
            testCase.verifyEqual(v.size3D(), [7 11 2]);
        end

        function computeSpacingAccessors(testCase)
            s1 = Slice(zeros(2, 2), [0.7 0.9], 0);
            s2 = Slice(zeros(2, 2), [0.7 0.9], 1);

            v = Volume([s1; s2]);

            testCase.verifyEqual(v.dx(), 0.7);
            testCase.verifyEqual(v.dy(), 0.9);
        end

        function computeExtents(testCase)
            s1 = Slice(zeros(10, 20), [0.5 2.0], -5, OriginXY = [100 200]);
            s2 = Slice(zeros(10, 20), [0.5 2.0], 5, OriginXY = [100 200]);

            v = Volume([s1; s2]);

            testCase.verifyEqual(v.xExtent(), [100 110]);
            testCase.verifyEqual(v.yExtent(), [200 220]);
            testCase.verifyEqual(v.zExtent(), [-5 5]);

            b = v.bounds();
            testCase.verifyEqual(b.x, [100 110]);
            testCase.verifyEqual(b.y, [200 220]);
            testCase.verifyEqual(b.z, [-5 5]);
        end

        function returnsSliceByIndex(testCase)
            s1 = Slice(ones(2, 2), [1 1], 0);
            s2 = Slice(ones(2 ,2) * 2, [1 1], 1);

            v = Volume([s1; s2]);

            testCase.verifyEqual(v.slice(1).Data, s1.Data);
            testCase.verifyEqual(v.slice(2).Data, s2.Data);
        end

        function rejectsDuplicateZPositions(testCase)
            s1 = Slice(zeros(2, 2), [1 1], 0);
            s2 = Slice(zeros(2, 2), [1 1], 0);

            testCase.verifyError(@() Volume([s1; s2]), ...
                "Volume:DuplicateZPosition");
        end

        function rejectsNearlyDuplicateZPositionsWithTolerance(testCase)
            s1 = Slice(zeros(2, 2), [1 1], 0);
            s2 = Slice(zeros(2, 2), [1 1], 1e-10);

            testCase.verifyError(@() Volume([s1; s2]), ...
                "Volume:DuplicateZPosition");
        end

        function rejectsIncompatibleSliceSizes(testCase)
            s1 = Slice(zeros(2, 2), [1 1], 0);
            s2 = Slice(zeros(3, 2), [1 1], 1);

            testCase.verifyError(@() Volume([s1; s2]), ...
                "Volume:IncompatibleSlices");
        end

        function rejectsIncompatibleSliceSpacing(testCase)
            s1 = Slice(zeros(2, 2), [1 1], 0);
            s2 = Slice(zeros(2, 2), [2 1], 1);

            testCase.verifyError(@() Volume([s1; s2]), ...
                "Volume:IncompatibleSlices");
        end

        function rejectsIncompatibleSliceOrigins(testCase)
            s1 = Slice(zeros(2, 2), [1 1], 0, OriginXY = [0 0]);
            s2 = Slice(zeros(2, 2), [1 1], 1, OriginXY = [1 0]);

            testCase.verifyError(@() Volume([s1; s2]), ...
                "Volume:IncompatibleSlices");
        end

        function rejectsOutOfRangeSliceIndex(testCase)
            s1 = Slice(zeros(2, 2), [1 1], 0);
            v = Volume(s1);

            testCase.verifyError(@() v.slice(2), ...
                "Volume:SliceIndexOutOfRange");
        end
    end
end
