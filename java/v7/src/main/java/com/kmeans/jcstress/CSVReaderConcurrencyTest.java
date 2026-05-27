package com.kmeans.jcstress;

import org.openjdk.jcstress.annotations.*;
import org.openjdk.jcstress.infra.results.I_Result;

import java.util.ArrayList;
import java.util.List;

public class CSVReaderConcurrencyTest {
    @JCStressTest
    @Outcome(id = "0", expect = Expect.ACCEPTABLE, desc = "Null result (not yet published)")
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "Fully visible list")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Torn / partially visible state")
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

            r.r1 = local.points.contains(42) ? 1 : -1;
        }
    }

    @JCStressTest
    @Outcome(id = "0", expect = Expect.ACCEPTABLE, desc = "Read before completion")
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "Full visibility after completion")
    @State
    public static class IsAliveBarrierTest {

        private final List<Integer> points = new ArrayList<>();
        private volatile boolean done;

        @Actor
        public void worker1() {
            synchronized (points) {
                points.add(1);
            }
            done = true;
        }

        @Actor
        public void worker2() {
            synchronized (points) {
                points.add(2);
            }
            done = true;
        }

        @Actor
        public void observer(I_Result r) {

            while (!done) {
                Thread.yield();
            }

            synchronized (points) {
                int size = points.size();

                if (size == 2) r.r1 = 1;
                else if (size == 0) r.r1 = 0;
                else r.r1 = -1;
            }
        }
    }

    @JCStressTest
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "Correct merge observed")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Corrupted logical state")
    @State
    public static class ArrayListRaceTest {

        static class PaddedResult {
            final List<Integer> points = new ArrayList<>();
            long p1,p2,p3,p4,p5,p6,p7,p8;
        }

        private final List<Integer> shared = new ArrayList<>();

        @Actor
        public void t1() {
            synchronized (shared) {
                shared.add(1);
                shared.add(2);
            }
        }

        @Actor
        public void t2() {
            synchronized (shared) {
                shared.add(3);
            }
        }

        @Arbiter
        public void check(I_Result r) {
            synchronized (shared) {
                boolean ok =
                        shared.size() == 3 &&
                        shared.contains(1) &&
                        shared.contains(2) &&
                        shared.contains(3);

                r.r1 = ok ? 1 : -1;
            }
        }
    }

    @JCStressTest
    @Outcome(id = "0", expect = Expect.ACCEPTABLE, desc = "Read before completion")
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "Fully visible result")
    @State
    public static class FakeJoinVisibilityTest {
    
        private List<Integer> result;
        private volatile boolean done;
    
        @Actor
        public void worker() {
            List<Integer> tmp = new ArrayList<>();
            tmp.add(99);
        
            result = tmp;
            done = true;
        }
    
        @Actor
        public void observer(I_Result r) {
        
            while (!done) {
                Thread.yield();
            }
        
            List<Integer> local = result;
        
            if (local == null) {
                r.r1 = 0;
            } else {
                r.r1 = local.contains(99) ? 1 : -1;
            }
        }
    }
}
