package com.kmeans.jcstress;

import com.kmeans.Kmeans;
import com.kmeans.Point;
import org.openjdk.jcstress.annotations.*;
import org.openjdk.jcstress.infra.results.I_Result;

import java.util.Arrays;
import java.util.List;

public class KmeansConcurrencyTest {

    private static List<Point> createDummyPoints() {
        return Arrays.asList(
            new Point(new double[]{1.0, 1.0}),
            new Point(new double[]{2.0, 2.0}),
            new Point(new double[]{3.0, 3.0})
        );
    }

    @JCStressTest
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "Visibility guaranteed: Updated centroids successfully read.")
    @Outcome(id = "0", expect = Expect.ACCEPTABLE, desc = "Main thread read state before processing completed.")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Visibility/Data Corruption Error: Execution ended, but read old/broken data.")
    @State
    public static class KmeansVisibilitySpec {
        
        private final Kmeans kmeans = new Kmeans(3, createDummyPoints(), 2026);
        private volatile boolean isProcessingAlive = true;

        @Actor
        public void processingThread() {
            try {
                kmeans.updateCentroids(2);
            } catch (Exception e) {
                return; 
            }
            isProcessingAlive = false;
        }

        @Actor
        public void mainThread(I_Result r) {
            while (isProcessingAlive) {
                Thread.yield();
            }

            try {
                Point[] currentCentroids = kmeans.getCentroids();
                if (currentCentroids == null || currentCentroids[0] == null) {
                    r.r1 = 0;
                    return;
                }

                double[] coords = currentCentroids[0].getCoordinates();
                if (coords != null && coords.length > 0) {
                    r.r1 = 1;
                } else {
                    r.r1 = -1;
                }
            } catch (Exception e) {
                r.r1 = -1;
            }
        }
    }

    @JCStressTest
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "No reordering: Memory mutations published in correct chronological order.")
    @Outcome(id = "0", expect = Expect.ACCEPTABLE, desc = "Main thread evaluated before processing actually started.")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Reordering problem: Thread died, but assignments contain uninitialized/stale values.")
    @State
    public static class KmeansReorderingSpec {
        
        private final Kmeans kmeans = new Kmeans(3, createDummyPoints(), 42);
        private volatile boolean isThreadAlive = true;

        @Actor
        public void processingThread() {
            try {
                kmeans.clustering(2);
            } catch (Exception e) {
                return;
            }
            isThreadAlive = false; 
        }

        @Actor
        public void mainThread(I_Result r) {
            while (isThreadAlive) {
                Thread.yield();
            }

            try {
                int[] assignments = kmeans.getAssignments();
                if (assignments == null || assignments.length == 0) {
                    r.r1 = 0;
                    return;
                }
                int firstAssignment = assignments[0];
                if (firstAssignment >= 0 && firstAssignment < 3) {
                    r.r1 = 1;
                } else {
                    r.r1 = -1;
                }
            } catch (Exception e) {
                r.r1 = -1;
            }
        }
    }

    @JCStressTest
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "No Race Condition: Internal workers mutated disjoint indices safely.")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Race Condition detected: Internal threads interfered with each other's memory slots.")
    @State
    public static class KmeansSharedRaceSpec {
        private final List<Point> dummyPoints = createDummyPoints();
        private final Kmeans kmeans = new Kmeans(3, dummyPoints, 2026);
        private final int numPoints = dummyPoints.size();
        private final int grainSize = (numPoints + 2 - 1) / 2;

        @Actor
        public void internalWorkerThread1() {
            int start = 0 * grainSize;
            int end = Math.min(start + grainSize, numPoints);
            
            int[] assignments = kmeans.getAssignments();
            for (int j = start; j < end; j++) {
                assignments[j] = kmeans.findNearestCentroid(dummyPoints.get(j));
            }
        }

        @Actor
        public void internalWorkerThread2() {
            int start = 1 * grainSize;
            int end = Math.min(start + grainSize, numPoints);
            
            int[] assignments = kmeans.getAssignments();
            for (int j = start; j < end; j++) {
                assignments[j] = kmeans.findNearestCentroid(dummyPoints.get(j));
            }
        }

        @Arbiter
        public void inspectFinalState(I_Result r) {
            try {
                int[] assignments = kmeans.getAssignments();
                if (assignments != null && assignments.length == 3) {
                    boolean valid = true;
                    for (int assignment : assignments) {
                        if (assignment < 0 || assignment >= 3) {
                            valid = false;
                            break;
                        }
                    }
                    r.r1 = valid ? 1 : -1;
                } else {
                    r.r1 = -1;
                }
            } catch (Exception e) {
                r.r1 = -1;
            }
        }
    }
}
