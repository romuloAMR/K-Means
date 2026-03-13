package com.kmeans;

public class Point {
    private final double[] position;
    private final int dimension;

    public Point(double[] position) {
        if (position == null || position.length == 0) {
            throw new IllegalArgumentException("Position can't be null or empty.");
        }
        this.position = position.clone();
        this.dimension = position.length;
    }

    public Point(Point other) {
        this.position = other.position.clone();
        this.dimension = other.dimension;
    }

    public double sqDistanceTo(Point other) {
        if (this.dimension != other.getDimension()) {
            throw new IllegalArgumentException("The points must have the same dimension.");
        }
        double sum = 0;
        for (int i = 0; i < dimension; i++) {
            double diff = this.position[i] - other.getOnePosition(i);
            sum += diff * diff;
        }
        return sum;
    }

    public void accumulatedAdd(Point other) {
        if (this.dimension != other.getDimension()) {
            throw new IllegalArgumentException("Dimensions must match for addition.");
        }
        for (int i = 0; i < dimension; i++) {
            this.position[i] += other.getOnePosition(i);
        }
    }

    public void accumulatedDivide(double scalar) {
        if (scalar == 0) {
            throw new ArithmeticException("Division by zero.");
        }
        for (int i = 0; i < dimension; i++) {
            this.position[i] /= scalar;
        }
    }

    public double getOnePosition(int i) {
        if (i < 0 || i >= this.dimension) {
            throw new IllegalArgumentException("Index out of bounds.");
        }
        return position[i];
    }

    public int getDimension() {
        return dimension;
    }

    @Override
    public String toString() {
        return java.util.Arrays.toString(this.position);
    }
}
