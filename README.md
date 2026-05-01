# K-Means
Implementation and optimisation of the K-Means algorithm in Java and Go language.

## Version legend:
- **V1:** Full serial version of the algorithm (base)
- **V2:** Addition of Platform Threads, CSV segmentation for reading, and optimisation of data structures
- **V3:** Switching from Platform Threads to Virtual Threads
- **V4:** Switching from a virtual thread to a hybrid thread model
- **V5:** Use of *volatile* (There is no equivalent in Go)

> [!NOTE]
> From version 1 to version 5, the code was designed in a Java-like format; Go simply replicated this, which may result in lower-than-expected performance
