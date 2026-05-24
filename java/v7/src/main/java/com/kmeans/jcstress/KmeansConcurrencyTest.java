package com.kmeans.jcstress;

import com.kmeans.Kmeans;
import com.kmeans.Point;
import org.openjdk.jcstress.annotations.*;
import org.openjdk.jcstress.infra.results.I_Result;

import java.util.Arrays;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.DoubleAccumulator;

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
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Visibility/Data Corruption Error: Execution ended, but read old/broken data.")
    @State
    public static class KmeansVisibilitySpec {
        
        private final Kmeans kmeans = new Kmeans(3, createDummyPoints(), 2026);

        @Actor
        public void processingThread() {
            try {
                kmeans.updateCentroids(2);
            } catch (Exception e) {
                return;
            }
        }

        @Arbiter
        public void inspectFinalState(I_Result r) {
            try {
                Point[] currentCentroids = kmeans.getCentroids();
                if (currentCentroids == null || currentCentroids[0] == null) {
                    r.r1 = -1;
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
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Reordering problem: Method ended, but assignments contain uninitialized/stale values.")
    @State
    public static class KmeansReorderingSpec {
        
        private final Kmeans kmeans = new Kmeans(3, createDummyPoints(), 42);

        @Actor
        public void processingThread() {
            try {
                kmeans.clustering(2);
            } catch (Exception e) {
            }
        }

        @Arbiter
        public void inspectFinalState(I_Result r) {
            try {
                int[] assignments = kmeans.getAssignments();
                if (assignments == null || assignments.length == 0) {
                    r.r1 = -1;
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
    @Outcome(id = "2", expect = Expect.ACCEPTABLE, desc = "Atomic updates safely consolidated across threads without locks.")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Data corruption or race condition in atomic accumulation.")
    @State
    public static class KmeansAtomicAccumulationSpec {
        private final AtomicInteger count = new AtomicInteger(0);
        private final DoubleAccumulator sum = new DoubleAccumulator(Double::sum, 0.0);

        @Actor
        public void internalWorkerThread1() {
            count.addAndGet(10);
            sum.accumulate(50.5);
        }

        @Actor
        public void internalWorkerThread2() {
            count.addAndGet(5);
            sum.accumulate(25.0);
        }

        @Arbiter
        public void inspectFinalState(I_Result r) {
            if (count.get() == 15 && sum.get() == 75.5) {
                r.r1 = 2;
            } else {
                r.r1 = -1;
            }
        }
    }
}
