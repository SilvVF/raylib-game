package main

import (
	"fmt"
	"math"

	rl "github.com/gen2brain/raylib-go/raylib"
)

const (
	FPS           = 60
	WINDOW_HEIGHT = 1080
	WINDOW_WIDTH  = 1920

	CIRCLE_STROKE_WIDTH float32 = 10.0
)

var (
	circleRadius float32 = min(WINDOW_WIDTH, WINDOW_HEIGHT) * 0.35

	center rl.Vector2 = Vector2(WINDOW_WIDTH/2, WINDOW_HEIGHT/2)

	indicatorSize rl.Vector2 = rl.Vector2{X: 20, Y: 40}

	circleColor    rl.Color = rl.Gray
	indicatorColor rl.Color = rl.Red

	rotationSpeed float32 = 1

	indicatorCenterAngle float32 = Rads(-90.0)

	iterations    = 0
	maxIterations = 100

	targetStartDeg float32 = 90
	targetEndDeg   float32 = 120
)

func drawCirclePath() {
	rl.DrawRing(center, circleRadius, circleRadius-CIRCLE_STROKE_WIDTH, 0, 360, 0, circleColor)
}

func getInicatorPosDeg() (float32, float32) {
	hw := float64(indicatorSize.Y / 2.0)
	rectDeg := 2 * math.Asin(hw/float64(2*circleRadius)) * (180 / math.Pi)
	centerAngle := indicatorCenterAngle * (180 / math.Pi)

	return centerAngle - float32(rectDeg)/2, centerAngle + float32(rectDeg)/2
}

func drawTargetIndicator() {
	rect_position := rl.Vector2Add(center, rl.Vector2Scale(Vector2(Cos(indicatorCenterAngle), Sin(indicatorCenterAngle)), circleRadius))

	offset := rl.Vector2Scale(Vector2(Cos(indicatorCenterAngle), Sin(indicatorCenterAngle)), -(indicatorSize.X-CIRCLE_STROKE_WIDTH)/2)
	rect_position = rl.Vector2Add(rect_position, offset)

	var half_width = indicatorSize.X / 2
	var half_height = indicatorSize.Y / 2

	// bl tl tr br
	corners := []rl.Vector2{
		rl.Vector2Add(rl.Vector2Rotate(Vector2(-half_height, -half_width), indicatorCenterAngle), rect_position),
		rl.Vector2Add(rl.Vector2Rotate(Vector2(half_height, -half_width), indicatorCenterAngle), rect_position),
		rl.Vector2Add(rl.Vector2Rotate(Vector2(half_height, half_width), indicatorCenterAngle), rect_position),
		rl.Vector2Add(rl.Vector2Rotate(Vector2(-half_height, half_width), indicatorCenterAngle), rect_position),
	}

	rl.DrawTriangle(corners[0], corners[3], corners[2], rl.Red)
	rl.DrawTriangle(corners[2], corners[1], corners[0], rl.Red)
}

func drawCircleTarget() {
	rl.DrawRing(center, circleRadius+1, circleRadius-CIRCLE_STROKE_WIDTH-1, targetStartDeg, targetEndDeg, 0, rl.Blue)
}

func drawGreeting() {
	s, e := getInicatorPosDeg()
	greetText := fmt.Sprintf("Congrats! You created your first window! %.2f %.2f", s, e)
	greetX := (WINDOW_WIDTH - rl.MeasureText(greetText, 20)) / 2
	rl.DrawText(greetText, greetX, WINDOW_HEIGHT/2, 20, rl.LightGray)
}

func update(delta float32) {
	indicatorCenterAngle += rotationSpeed * delta

	_, e := getInicatorPosDeg()

	if e >= 270 {
		indicatorCenterAngle = Rads(-90.0)
	}

	rotationSpeed = rl.Lerp(1.0, 2.0, float32(iterations)/float32(maxIterations))
}

func draw() {
	rl.ClearBackground(rl.RayWhite)
	drawGreeting()

	drawCirclePath()
	drawCircleTarget()

	drawTargetIndicator()
}

func main() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "raylib [core] example - basic window")
	defer rl.CloseWindow()

	rl.SetTargetFPS(FPS)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		draw()
		update(rl.GetFrameTime())

		rl.EndDrawing()
	}
}
