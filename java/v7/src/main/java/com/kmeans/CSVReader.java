package com.kmeans;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.List;

public class CSVReader {

    private static final int SCALAR_FOR_WORKERS_READ = 1;
    private static final int ONE_MB = 1048576;
    private record Segment(long start, long size) {}

    private static List<Segment> getSegments(Path path) throws IOException {
        List<Segment> segments = new ArrayList<>();
        try (RandomAccessFile raf = new RandomAccessFile(path.toFile(), "r")) {
            long totalSize = raf.length();
            int cores = Runtime.getRuntime().availableProcessors() * SCALAR_FOR_WORKERS_READ;
            long targetSize = totalSize / cores;
            if (targetSize < ONE_MB) {
                targetSize = ONE_MB;
            }
            long currentPos = 0; 

            while (currentPos < totalSize) {
                long start = currentPos;
                long endCandidate = currentPos + targetSize;

                if (endCandidate >= totalSize) {
                    segments.add(new Segment(start, totalSize - start));
                    break;
                }

                raf.seek(endCandidate);
                long extraBytes = 0;
                while (true) {
                    int b = raf.read();
                    if (b == -1) {
                        break;
                    }
                    extraBytes++;
                    if (b == '\n') {
                        break;
                    }
                }

                long actualEnd = endCandidate + extraBytes;
                segments.add(new Segment(start, actualEnd - start));
                currentPos = actualEnd;
            }
        }
        return segments;
    }

    public static List<Point> loadPoints(Path path) throws Exception {
        List<Segment> segments = getSegments(path);
        int numSegments = segments.size();
        List<Point> points = new ArrayList<>();
        Object mutex = new Object();
        
        Thread[] threads = new Thread[numSegments];

        for (int i = 0; i < numSegments; i++) {
            Segment segment = segments.get(i);
        
            threads[i] = Thread.ofPlatform().start(() -> {
                List<Point> pointsPartition = new ArrayList<>();
                try (FileChannel ch = FileChannel.open(path, StandardOpenOption.READ)) {
                    ByteBuffer buffer = ch.map(FileChannel.MapMode.READ_ONLY, segment.start(), segment.size());
                
                    if (segment.start() == 0) {
                        while (buffer.hasRemaining() && buffer.get() != '\n');
                    }
                
                    ByteArrayOutputStream lineBuffer = new ByteArrayOutputStream();
                    while (buffer.hasRemaining()) {
                        byte b = buffer.get();
                        if (b == '\n') {
                            Point p = processLine(lineBuffer.toByteArray());
                            if (p != null) {
                                pointsPartition.add(p);
                            }
                            lineBuffer.reset();
                        } else if (b != '\r') {
                            lineBuffer.write(b);
                        }
                    }
                    if (lineBuffer.size() > 0) {
                        Point p = processLine(lineBuffer.toByteArray());
                        if (p != null) {
                            pointsPartition.add(p);
                        }
                    }
                    
                    synchronized (mutex) {
                        points.addAll(pointsPartition);
                    }
                    
                } catch (Exception e) {
                    e.printStackTrace();
                }
            });
        }

        for (int i = 0; i < threads.length; i++) {
            if (threads[i] == null) continue;
            while (threads[i].isAlive()) {
                Thread.yield();
            }
        }

        return points;
    }

    public static Point processLine(byte[] lineBytes) {
        String currentLine = new String(lineBytes).trim();
        if (currentLine.isEmpty()) {
            return null;
        }

        try {
            String[] parts = currentLine.split(",");
            double[] coords = new double[parts.length];
            for (int i = 0; i < parts.length; i++) {
                coords[i] = Double.parseDouble(parts[i].trim());
            }
            return new Point(coords); 
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
