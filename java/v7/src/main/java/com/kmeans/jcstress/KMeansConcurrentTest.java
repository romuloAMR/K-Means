package com.kmeans.jcstress;

import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.DoubleAccumulator;

import org.openjdk.jcstress.annotations.*;
import org.openjdk.jcstress.infra.results.I_Result;

public class KMeansConcurrentTest {
    @State
    public static class KMeansState {
        final int[] assignments = new int[4];
        final double[][] sumsPartial = new double[2][2];
        final int[][] countsPartial = new int[2][2];
    }

    @JCStressTest
    @Outcome(id = "4", expect = Expect.ACCEPTABLE, desc = "All assignments correctly written and visible")
    @Outcome(id = "3", expect = Expect.ACCEPTABLE_INTERESTING, desc = "Lost update or inconsistent visibility observed")
    @State
    public static class AssignmentRaceTest {

        private final KMeansState s = new KMeansState();

        @Actor
        public void worker1() {
            s.assignments[0] = 0;
            s.assignments[1] = 1;
        }

        @Actor
        public void worker2() {
            s.assignments[2] = 1;
            s.assignments[3] = 0;
        }

        @Arbiter
        public void arbiter(I_Result r) {
            int sum = 0;
            for (int v : s.assignments) {
                sum += v;
            }
            r.r1 = sum;
        }
    }

    @JCStressTest
    @Outcome(id = "10", expect = Expect.ACCEPTABLE, desc = "Correct aggregation of sums")
    @Outcome(id = "9", expect = Expect.ACCEPTABLE_INTERESTING, desc = "Logical mismatch between count and sum")
    @State
    public static class AtomicAccumulatorTest {

        static class State {
            final AtomicInteger count = new AtomicInteger();
            final DoubleAccumulator sum =
                    new DoubleAccumulator(Double::sum, 0.0);
        }

        private final State s = new State();

        @Actor
        public void worker1() {
            s.count.addAndGet(2);
            s.sum.accumulate(3.0);
            s.sum.accumulate(4.0);
        }

        @Actor
        public void worker2() {
            s.count.addAndGet(2);
            s.sum.accumulate(1.0);
            s.sum.accumulate(2.0);
        }

        @Arbiter
        public void arbiter(I_Result r) {
            double total = s.sum.get();
            r.r1 = (int) total;
        }
    }

    @JCStressTest
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "Consistent clustering state observed")
    @Outcome(id = "0", expect = Expect.ACCEPTABLE_INTERESTING, desc = "Inconsistent cluster/centroid snapshot")
    @State
    public static class ClusterConsistencyTest {

        private final int[] assignments = new int[4];
        private volatile double centroid = 10.0;

        @Actor
        public void clusteringWorker() {
            assignments[0] = (centroid > 5) ? 1 : 0;
            assignments[1] = (centroid > 5) ? 1 : 0;
        }

        @Actor
        public void centroidUpdater() {
            centroid = 20.0;
        }

        @Arbiter
        public void arbiter(I_Result r) {
            boolean ok =
                    (assignments[0] == assignments[1]);

            r.r1 = ok ? 1 : 0;
        }
    }

    @JCStressTest
    @Outcome(id = "10.0", expect = Expect.ACCEPTABLE, desc = "Correct accumulated sum observed")
    @Outcome(expect = Expect.ACCEPTABLE_INTERESTING, desc = "Non-deterministic intermediate accumulation observed")
    @State
    public static class DoubleAccumulatorTest {
    
        private final DoubleAccumulator acc =
                new DoubleAccumulator(Double::sum, 0.0);
    
        @Actor
        public void worker1() {
            acc.accumulate(1.0);
            acc.accumulate(2.0);
        }
    
        @Actor
        public void worker2() {
            acc.accumulate(3.0);
            acc.accumulate(4.0);
        }
    
        @Arbiter
        public void arbiter(I_Result r) {
            r.r1 = (int) acc.get();
        }
    }
}
