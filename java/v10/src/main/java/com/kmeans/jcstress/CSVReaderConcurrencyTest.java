package com.kmeans.jcstress;

import org.openjdk.jcstress.annotations.*;
import org.openjdk.jcstress.infra.results.I_Result;
import java.util.ArrayList;
import java.util.List;

public class CSVReaderConcurrencyTest {

    private static class DummyPoint {
        double[] coords;
        DummyPoint(double[] coords) { this.coords = coords; }
    }

    private static class PaddedResult {
        final List<DummyPoint> points = new ArrayList<>();
        @SuppressWarnings("unused")
        long p1, p2, p3, p4, p5, p6, p7, p8; 
    }

    @JCStressTest
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "No have visibility problem.")
    @Outcome(id = "0", expect = Expect.ACCEPTABLE, desc = "The main thread executed before processing started.")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Corrupted data")
    @State
    public static class RealisticVisibilitySpec {
        private PaddedResult partialResult = null;
        private volatile boolean isThreadAlive = true; 

        @Actor
        public void threadProcessamento() {
            PaddedResult localResult = new PaddedResult();
            localResult.points.add(new DummyPoint(new double[]{1.0, 2.0}));
            partialResult = localResult; 
            isThreadAlive = false; 
        }

        @Actor
        public void threadPrincipal(I_Result r) {
            while (isThreadAlive) {
                Thread.yield();
            }

            PaddedResult local = partialResult; 
            if (local == null) {
                r.r1 = 0;
                return;
            }

            try {
                List<DummyPoint> pts = local.points;
                if (pts.isEmpty()) {
                    r.r1 = 0;
                } else {
                    DummyPoint p = pts.get(0);
                    if (p != null && p.coords != null && p.coords[0] == 1.0) {
                        r.r1 = 1;
                    } else {
                        r.r1 = -1;
                    }
                }
            } catch (Exception e) {
                r.r1 = -1;
            }
        }
    }

    @JCStressTest
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "No have reordering problem")
    @Outcome(id = "0", expect = Expect.ACCEPTABLE, desc = "Main thread executed before list insertion.")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Reordering problem")
    @State
    public static class ReorderingSpec {
        
        private final PaddedResult partialResult = new PaddedResult();
        private volatile boolean isThreadAlive = true;

        @Actor
        public void threadProcessamento() {
            partialResult.points.add(new DummyPoint(new double[]{1.0, 2.0})); 
            isThreadAlive = false; 
        }

        @Actor
        public void threadPrincipal(I_Result r) {
            while (isThreadAlive) {
                Thread.yield();
            }

            try {
                List<DummyPoint> pts = partialResult.points;
                if (pts.isEmpty()) {
                    r.r1 = 0;
                    return;
                }
                DummyPoint p = pts.get(0);
                if (p != null && p.coords != null && p.coords.length > 0 && p.coords[0] == 1.0) {
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
    @Outcome(id = "2", expect = Expect.ACCEPTABLE, desc = "No have Race Condicional.")
    @Outcome(id = "0", expect = Expect.ACCEPTABLE, desc = "Thread principal checked size before insertions.")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Race Conditional")
    @State
    public static class SharedCollectionRaceSpec {
        private final PaddedResult sharedResult = new PaddedResult();
        private volatile boolean isThread1Alive = true;
        private volatile boolean isThread2Alive = true;

        @Actor
        public void threadProcessamento1() {
            try { 
                sharedResult.points.add(new DummyPoint(new double[]{1.0})); 
            } catch (Exception e) {}
            isThread1Alive = false;
        }

        @Actor
        public void threadProcessamento2() {
            try { 
                sharedResult.points.add(new DummyPoint(new double[]{2.0})); 
            } catch (Exception e) {}
            isThread2Alive = false;
        }

        @Actor
        public void threadPrincipal(I_Result r) {
            while (isThread1Alive || isThread2Alive) {
                Thread.yield();
            }

            try {
                if (sharedResult.points.isEmpty()) {
                    r.r1 = 0;
                    return;
                }
                int finalSize = sharedResult.points.size();
                if (finalSize == 2) {
                    r.r1 = 2;
                } else {
                    r.r1 = -1;
                }
            } catch (Exception e) {
                r.r1 = -1;
            }
        }
    }
}
