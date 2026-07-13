package com.kmeans.jcstress;

import org.openjdk.jcstress.annotations.*;
import org.openjdk.jcstress.infra.results.I_Result;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@JCStressTest
@Outcome(id = "2", expect = Expect.ACCEPTABLE, desc = "Synchronisation worked. There are two items on the list.")
@Outcome(id = "1", expect = Expect.ACCEPTABLE_INTERESTING, desc = "ERROR! An insertion has been lost or overwritten.")
@Outcome(id = "-1", expect = Expect.ACCEPTABLE_INTERESTING, desc = "ERROR! The ArrayList has become corrupted (Exception).")
@State
public class CSVReaderConcurrencyTest {
    private final List<Integer> sharedPoints = Collections.synchronizedList(new ArrayList<>());

    @Actor
    public void worker1() {
        try {
            sharedPoints.add(100); 
        } catch (Exception e) {
        }
    }

    @Actor
    public void worker2() {
        try {
            sharedPoints.add(200); 
        } catch (Exception e) {
        }
    }

    @Arbiter
    public void check(I_Result r) {
        try {
            r.r1 = sharedPoints.size();
        } catch (Exception e) {
            r.r1 = -1; 
        }
    }
}
