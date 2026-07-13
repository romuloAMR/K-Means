package com.kmeans.jcstress;

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
    @Outcome(id = "10", expect = Expect.ACCEPTABLE, desc = "Correct merged aggregation under synchronization")
    @Outcome(id = "9", expect = Expect.ACCEPTABLE_INTERESTING, desc = "Logical error or missing merge path")
    @State
    public static class PartialSumSyncTest {

        static class State {
            final double[][] centroidsSum = new double[2][2];
            final int[] counts = new int[2];
            final Object mutex = new Object();
        }

        private final State s = new State();

        @Actor
        public void worker1() {
            double[][] local = new double[2][2];
            int[] localCount = new int[2];

            local[0][0] += 1;
            local[0][0] += 2;
            localCount[0] += 2;

            synchronized (s.mutex) {
                s.counts[0] += localCount[0];
                s.centroidsSum[0][0] += local[0][0];
            }
        }

        @Actor
        public void worker2() {
            double[][] local = new double[2][2];
            int[] localCount = new int[2];

            local[1][0] += 3;
            local[1][0] += 4;
            localCount[1] += 2;

            synchronized (s.mutex) {
                s.counts[1] += localCount[1];
                s.centroidsSum[1][0] += local[1][0];
            }
        }

        @Arbiter
        public void arbiter(I_Result r) {
            double total =
                    s.centroidsSum[0][0] +
                    s.centroidsSum[1][0];

            r.r1 = (int) total;
        }
    }

    @JCStressTest
    @Outcome(id = "4", expect = Expect.ACCEPTABLE, desc = "Correct counting under synchronization")
    @Outcome(id = "3", expect = Expect.ACCEPTABLE_INTERESTING, desc = "Missing synchronization or logical error")
    @State
    public static class CountSyncTest {

        static class State {
            final int[] counts = new int[2];
            final Object mutex = new Object();
        }

        private final State s = new State();

        @Actor
        public void worker1() {
            synchronized (s.mutex) {
                s.counts[0]++;
                s.counts[0]++;
            }
        }

        @Actor
        public void worker2() {
            synchronized (s.mutex) {
                s.counts[1]++;
                s.counts[1]++;
            }
        }

        @Arbiter
        public void arbiter(I_Result r) {
            int total = s.counts[0] + s.counts[1];
            r.r1 = total;
        }
    }
}
