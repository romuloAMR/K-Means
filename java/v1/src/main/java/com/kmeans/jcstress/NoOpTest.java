package com.kmeans.jcstress;

import org.openjdk.jcstress.annotations.*;
import org.openjdk.jcstress.infra.results.I_Result;

@JCStressTest
@Outcome(id = "1", expect = Expect.ACCEPTABLE)
@State
public class NoOpTest {

    private volatile int x = 0;

    @Actor
    public void actor1() {
        x = 1;
    }

    @Actor
    public void actor2() {
        x = 1;
    }

    @Arbiter
    public void arbiter(I_Result r) {
        r.r1 = (x == 1) ? 1 : -1;
    }
}