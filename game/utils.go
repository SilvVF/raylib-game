package main

import (
	"math"

	rl "github.com/gen2brain/raylib-go/raylib"
)

func Vector2(x float32, y float32) rl.Vector2 {
	return rl.Vector2{X: x, Y: y}
}

func Cos[T int | float32 | float64](x T) float32 {
	return float32(math.Cos(float64(x)))
}

func Sin[T int | float32 | float64](x T) float32 {
	return float32(math.Sin(float64(x)))
}

func Atan2[T float32 | float64](y, x T) float32 {
	return float32(math.Atan2(float64(y), float64(x)))
}

func Rads[T float32 | float64](x T) float32 {
	return float32(x * (math.Pi / 180))
}
