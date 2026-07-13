package com.kmeans.jcstress;

import org.openjdk.jcstress.annotations.*;
import org.openjdk.jcstress.infra.results.I_Result;

import java.util.ArrayList;
import java.util.List;

public class CSVReaderConcurrencyTest {
    @JCStressTest
    @Outcome(id = "0", expect = Expect.ACCEPTABLE, desc = "Observer saw null or empty")
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "Fully visible state")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Partially visible / torn object state")
    @State
    public static class PublicationRacyTest {

        static class PaddedResult {
            final List<Integer> points = new ArrayList<>();
            long p1,p2,p3,p4,p5,p6,p7,p8;
        }

        private PaddedResult shared;

        @Actor
        public void worker() {
            PaddedResult r = new PaddedResult();
            r.points.add(42);
            shared = r;
        }

        @Actor
        public void observer(I_Result r) {
            PaddedResult local = shared;

            if (local == null) {
                r.r1 = 0;
                return;
            }

            if (local.points.isEmpty()) {
                r.r1 = -1;
            } else {
                r.r1 = (local.points.get(0) == 42) ? 1 : -1;
            }
        }
    }

    @JCStressTest
    @Outcome(id = "0", expect = Expect.ACCEPTABLE, desc = "Observer ran too early")
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "Safe completion observed")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Visibility failure after completion")
    @State
    public static class IsAliveBarrierTest {

        static class PaddedResult {
            final List<Integer> points = new ArrayList<>();
            long p1,p2,p3,p4,p5,p6,p7,p8;
        }

        private final PaddedResult[] partial = new PaddedResult[2];

        private volatile boolean done1;
        private volatile boolean done2;

        public IsAliveBarrierTest() {
            partial[0] = new PaddedResult();
            partial[1] = new PaddedResult();
        }

        @Actor
        public void worker1() {
            partial[0].points.add(1);
            done1 = true;
        }

        @Actor
        public void worker2() {
            partial[1].points.add(2);
            done2 = true;
        }

        @Actor
        public void observer(I_Result r) {
            while (!done1 || !done2) {
                Thread.yield();
            }

            List<Integer> merged = new ArrayList<>();
            merged.addAll(partial[0].points);
            merged.addAll(partial[1].points);

            if (merged.size() == 2) {
                r.r1 = 1;
            } else if (merged.isEmpty()) {
                r.r1 = 0;
            } else {
                r.r1 = -1;
            }
        }
    }

    @JCStressTest
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "No corruption observed")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Logical corruption in merge result")
    @State
    public static class ArrayListRaceTest {

        static class PaddedResult {
            final List<Integer> points = new ArrayList<>();
            long p1,p2,p3,p4,p5,p6,p7,p8;
        }

        private final PaddedResult[] partial = new PaddedResult[2];

        public ArrayListRaceTest() {
            partial[0] = new PaddedResult();
            partial[1] = new PaddedResult();
        }

        @Actor
        public void t1() {
            partial[0].points.add(1);
            partial[0].points.add(2);
        }

        @Actor
        public void t2() {
            partial[1].points.add(3);
        }

        @Arbiter
        public void check(I_Result r) {
            List<Integer> merged = new ArrayList<>();
            merged.addAll(partial[0].points);
            merged.addAll(partial[1].points);

            boolean valid =
                    merged.size() == 3 &&
                    merged.contains(1) &&
                    merged.contains(2) &&
                    merged.contains(3);

            r.r1 = valid ? 1 : -1;
        }
    }

    @JCStressTest
    @Outcome(id = "0", expect = Expect.ACCEPTABLE, desc = "Read before publish")
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "Correct visibility after publish")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Torn visibility after supposed completion")
    @State
    public static class FakeJoinVisibilityTest {

        static class PaddedResult {
            final List<Integer> points = new ArrayList<>();
            long p1,p2,p3,p4,p5,p6,p7,p8;
        }

        private PaddedResult result;
        private volatile boolean done;

        @Actor
        public void worker() {
            PaddedResult r = new PaddedResult();
            r.points.add(99);

            result = r;
            done = true;
        }

        @Actor
        public void observer(I_Result r) {
            while (!done) {}

            PaddedResult local = result;

            if (local == null) {
                r.r1 = 0;
                return;
            }

            if (local.points.isEmpty()) {
                r.r1 = -1;
            } else {
                r.r1 = (local.points.get(0) == 99) ? 1 : -1;
            }
        }
    }
}
