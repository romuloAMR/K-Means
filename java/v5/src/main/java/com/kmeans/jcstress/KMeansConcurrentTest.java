package com.kmeans.jcstress;

import org.openjdk.jcstress.annotations.*;
import org.openjdk.jcstress.infra.results.I_Result;

public class KMeansConcurrentTest {
    @State
    public static class KMeansState {
        volatile int[] assignments = new int[4];
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
    @Outcome(id = "10", expect = Expect.ACCEPTABLE, desc = "Correct aggregated partial sums")
    @Outcome(id = "9", expect = Expect.ACCEPTABLE_INTERESTING, desc = "Lost update in partial accumulation")
    @State
    public static class PartialSumRaceTest {

        private final KMeansState s = new KMeansState();

        @Actor
        public void worker1() {
            s.sumsPartial[0][0] += 1;
            s.sumsPartial[0][0] += 2;
            s.countsPartial[0][0] += 2;
        }

        @Actor
        public void worker2() {
            s.sumsPartial[1][0] += 3;
            s.sumsPartial[1][0] += 4;
            s.countsPartial[1][0] += 2;
        }

        @Arbiter
        public void arbiter(I_Result r) {
            double total =
                    s.sumsPartial[0][0] +
                    s.sumsPartial[1][0];

            r.r1 = (int) total;
        }
    }

    @JCStressTest
    @Outcome(id = "4", expect = Expect.ACCEPTABLE, desc = "Correct count aggregation")
    @Outcome(id = "3", expect = Expect.ACCEPTABLE_INTERESTING, desc = "Lost update in counter")
    @State
    public static class CountRaceTest {

        private final KMeansState s = new KMeansState();

        @Actor
        public void worker1() {
            s.countsPartial[0][0]++;
            s.countsPartial[0][0]++;
        }

        @Actor
        public void worker2() {
            s.countsPartial[1][0]++;
            s.countsPartial[1][0]++;
        }

        @Arbiter
        public void arbiter(I_Result r) {
            int total =
                    s.countsPartial[0][0] +
                    s.countsPartial[1][0];

            r.r1 = total;
        }
    }
}
