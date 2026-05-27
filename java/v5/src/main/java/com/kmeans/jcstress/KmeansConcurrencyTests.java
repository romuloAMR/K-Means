package com.kmeans.jcstress;

import com.kmeans.Kmeans;
import com.kmeans.Point;
import org.openjdk.jcstress.annotations.*;
import org.openjdk.jcstress.infra.results.I_Result;

import java.util.Arrays;
import java.util.List;

public class KmeansConcurrencyTests {

    private static List<Point> pts() {
        return Arrays.asList(
                new Point(new double[]{1.0, 1.0}),
                new Point(new double[]{2.0, 2.0}),
                new Point(new double[]{3.0, 3.0})
        );
    }

    @JCStressTest
    @Outcome(id = "0", expect = Expect.ACCEPTABLE, desc = "Observed before update")
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "Fully visible centroid")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Corrupted or partially published centroid")
    @State
    public static class CentroidVisibilityTest {

        private final Kmeans kmeans = new Kmeans(3, pts(), 1);

        @Actor
        public void updater() {
            try {
                kmeans.updateCentroids(2);
            } catch (Exception ignored) {}
        }

        @Actor
        public void reader(I_Result r) {
            Point[] c = kmeans.getCentroids();

            if (c == null || c[0] == null) {
                r.r1 = -1;
                return;
            }

            double[] v = c[0].getCoordinates();

            r.r1 = (v != null && v.length == 2) ? 1 : -1;
        }
    }

    @JCStressTest
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "All values in valid range")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Invalid cluster assignment detected")
    @State
    public static class AssignmentRaceTest {

        private final Kmeans kmeans = new Kmeans(3, pts(), 2);

        @Actor
        public void worker1() {
            int[] a = kmeans.getAssignments();
            a[0] = kmeans.findNearestCentroid(pts().get(0));
        }

        @Actor
        public void worker2() {
            int[] a = kmeans.getAssignments();
            a[1] = kmeans.findNearestCentroid(pts().get(1));
        }

        @Actor
        public void worker3() {
            int[] a = kmeans.getAssignments();
            a[2] = kmeans.findNearestCentroid(pts().get(2));
        }

        @Arbiter
        public void check(I_Result r) {
            int[] a = kmeans.getAssignments();

            for (int v : a) {
                if (v < 0 || v >= 3) {
                    r.r1 = -1;
                    return;
                }
            }

            r.r1 = 1;
        }
    }

    @JCStressTest
    @Outcome(id = "0", expect = Expect.ACCEPTABLE, desc = "Read before work")
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "Valid assignment observed")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Partially updated or torn state")
    @State
    public static class ReorderingExposureTest {

        private final Kmeans kmeans = new Kmeans(3, pts(), 3);

        @Actor
        public void worker() {
            try {
                kmeans.clustering(2);
            } catch (Exception ignored) {}
        }

        @Actor
        public void observer(I_Result r) {
            int[] a = kmeans.getAssignments();

            if (a == null || a.length == 0) {
                r.r1 = 0;
                return;
            }

            int v = a[0];

            r.r1 = (v >= 0 && v < 3) ? 1 : -1;
        }
    }
}

