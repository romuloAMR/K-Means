package com.kmeans.jcstress;

import org.openjdk.jcstress.annotations.*;
import org.openjdk.jcstress.infra.results.I_Result;

import java.util.ArrayList;
import java.util.List;

public class CSVReaderConcurrencyTests {
    @JCStressTest
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "Isolated writes OK")
    @State
    public static class CSVIsolationTest {

        static class PaddedResult {
            final List<Integer> data = new ArrayList<>();
            long p1, p2, p3, p4, p5, p6, p7, p8;
        }

        private volatile PaddedResult[] results = new PaddedResult[2];

        public CSVIsolationTest() {
            results[0] = new PaddedResult();
            results[1] = new PaddedResult();
        }

        @Actor
        public void t1() {
            results[0].data.add(1);
        }

        @Actor
        public void t2() {
            results[1].data.add(2);
        }

        @Arbiter
        public void check(I_Result r) {
            boolean ok =
                    results[0].data.contains(1) &&
                    results[1].data.contains(2);

            r.r1 = ok ? 1 : -1;
        }
    }

    @JCStressTest
    @Outcome(id = "1", expect = Expect.ACCEPTABLE)
    @State
    public static class CSVBoundaryTest {

        private volatile boolean finished = false;
        private volatile int processedLines = 0;

        @Actor
        public void readerThread() {
            String fakeFile = "1,2,3\n4,5,6\n7,8,9\n";

            String segment = fakeFile.substring(0, 6);
            String[] lines = segment.split("\n");

            for (String l : lines) {
                if (!l.isEmpty()) processedLines++;
            }

            finished = true;
        }

        @Actor
        public void mainThread(I_Result r) {
            while (!finished) {}

            r.r1 = processedLines >= 1 ? 1 : -1;
        }
    }

    @JCStressTest
    @Outcome(id = "3", expect = Expect.ACCEPTABLE)
    @State
    public static class CSVMergeTest {

        static class PaddedResult {
            final List<Integer> points = new ArrayList<>();
            long p1, p2, p3, p4, p5, p6, p7, p8;
        }

        private volatile PaddedResult[] partial = new PaddedResult[2];

        public CSVMergeTest() {
            partial[0] = new PaddedResult();
            partial[1] = new PaddedResult();
        }

        @Actor
        public void w1() {
            partial[0].points.add(1);
            partial[0].points.add(2);
        }

        @Actor
        public void w2() {
            partial[1].points.add(3);
        }

        @Arbiter
        public void merge(I_Result r) {
            List<Integer> all = new ArrayList<>();
            all.addAll(partial[0].points);
            all.addAll(partial[1].points);

            r.r1 = all.size();
        }
    }
}
