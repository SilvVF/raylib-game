/*
Ported from https://github.com/tsoding/zigout/blob/master/src/main.zig

Copyright 2022 Alexey Kutepov <reximkut@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package main

import "core:fmt"
import "core:math"
import SDL "vendor:sdl2"
import TTF "vendor:sdl2/ttf"

// CONFIG
FPS :: 60
DELTA_TIME_SEC: f32 : 1.0 / FPS
WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600
BACKGROUND_COLOR :: 0xFF181818
PROJ_SIZE: f32 : 25 * 0.80
PROJ_SPEED: f32 : 350
PROJ_COLOR :: 0xFFFFFFFF
BAR_LEN: f32 : 100
BAR_THICCNESS: f32 : PROJ_SIZE
BAR_Y: f32 : WINDOW_HEIGHT - PROJ_SIZE - 50
BAR_SPEED: f32 : PROJ_SPEED * 1.5
BAR_COLOR :: 0xFF3030FF
TARGET_WIDTH :: BAR_LEN
TARGET_HEIGHT :: PROJ_SIZE
TARGET_PADDING_X :: 20
TARGET_PADDING_Y :: 50
TARGET_ROWS :: 4
TARGET_COLS :: 5
TARGET_GRID_WIDTH :: (TARGET_COLS * TARGET_WIDTH + (TARGET_COLS - 1) * TARGET_PADDING_X)
TARGET_GRID_X :: WINDOW_WIDTH / 2 - TARGET_GRID_WIDTH / 2
TARGET_GRID_Y :: 50
TARGET_COLOR :: 0xFF30FF30
TEXT_COLOR :: 0xFFFFFFFF
FONT :: "Roboto-Regular.ttf"
FONT_SIZE :: 24

// GAMESTATE
bar_x: f32 = WINDOW_WIDTH / 2 - BAR_LEN / 2
bar_dx: f32 = 0
proj_x: f32 = WINDOW_WIDTH / 2 - PROJ_SIZE / 2
proj_y: f32 = BAR_Y - BAR_THICCNESS / 2 - PROJ_SIZE
proj_dx: f32 = 1
proj_dy: f32 = 1
quit := false
pause := false
started := false
targets_pool := init_targets()

Target :: struct {
	x, y: f32,
	dead: bool,
}

Text :: struct {
	tex:  ^SDL.Texture,
	dest: SDL.Rect,
}

init_targets :: proc() -> [TARGET_ROWS * TARGET_COLS]Target {
	targets := [TARGET_ROWS * TARGET_COLS]Target{}
	for row in 0 ..< TARGET_ROWS {
		for col in 0 ..< TARGET_COLS {
			targets[row * TARGET_COLS + col] = Target {
				x    = TARGET_GRID_X + (TARGET_WIDTH + TARGET_PADDING_X) * f32(col),
				y    = TARGET_GRID_Y + TARGET_PADDING_Y * f32(row),
				dead = false,
			}
		}
	}
	return targets
}

new_rect :: proc(x, y, w, h: f32) -> SDL.Rect {
	return SDL.Rect{x = i32(x), y = i32(y), w = i32(w), h = i32(h)}
}

proj_rect :: proc(x, y: f32) -> SDL.Rect {
	return new_rect(x, y, PROJ_SIZE, PROJ_SIZE)
}

bar_rect :: proc(x: f32) -> SDL.Rect {
	return new_rect(x, BAR_Y - BAR_THICCNESS / 2, BAR_LEN, BAR_THICCNESS)
}

target_rect :: proc(target: Target) -> SDL.Rect {
	return new_rect(target.x, target.y, TARGET_WIDTH, TARGET_HEIGHT)
}

pause_text: Text
text_init := false

render :: proc(renderer: ^SDL.Renderer, font: ^TTF.Font) {

	if pause {
		if !text_init {
			pause_text = create_text("Paused", 1, font, renderer)
			text_init = true
		}
		// render roughly at the center of the window
		pause_text.dest.x = (WINDOW_WIDTH / 2) - (pause_text.dest.w / 2)
		pause_text.dest.y = (WINDOW_HEIGHT / 2) - (pause_text.dest.h)
		SDL.RenderCopy(renderer, pause_text.tex, nil, &pause_text.dest)
	}

	set_color(renderer, PROJ_COLOR)
	proj_r := proj_rect(proj_x, proj_y)
	SDL.RenderFillRect(renderer, &proj_r)

	set_color(renderer, BAR_COLOR)
	bar_r := bar_rect(bar_x)
	SDL.RenderFillRect(renderer, &bar_r)

	set_color(renderer, TARGET_COLOR)
	for target in targets_pool {
		if !target.dead {
			target_r := target_rect(target)
			SDL.RenderFillRect(renderer, &target_r)
		}
	}
}

bar_collision :: proc(dt: f32) {
	b_wish_x := bar_x + bar_dx * BAR_SPEED * dt
	bar_wish_x: f32 = math.clamp(b_wish_x, 0, WINDOW_WIDTH - BAR_LEN)

	proj_r := proj_rect(proj_x, proj_y)
	bar_nr := bar_rect(bar_wish_x)

	if SDL.HasIntersection(&proj_r, &bar_nr) {
		return
	}
	bar_x = bar_wish_x
}

horz_collision :: proc(dt: f32) {
	proj_wish_x: f32 = proj_x + proj_dx * PROJ_SPEED * dt

	proj_wish_r := proj_rect(proj_wish_x, proj_y)
	bar_r := bar_rect(bar_x)

	if proj_wish_x < 0 ||
	   proj_wish_x + PROJ_SIZE > WINDOW_WIDTH ||
	   SDL.HasIntersection(&proj_wish_r, &bar_r) {
		proj_dx *= -1
		return
	}

	for &target in targets_pool {

		if target.dead {
			continue
		}

		target_r := target_rect(target)
		if SDL.HasIntersection(&proj_wish_r, &target_r) {
			target.dead = true
			proj_dx *= -1
			return
		}
	}
	proj_x = proj_wish_x
}

vert_collision :: proc(dt: f32) {
	proj_wish_y: f32 = proj_y + proj_dy * PROJ_SPEED * dt
	if proj_wish_y < 0 || proj_wish_y + PROJ_SIZE > WINDOW_HEIGHT {
		proj_dy *= -1
		return
	}
	proj_wish_r := proj_rect(proj_x, proj_wish_y)
	bar_r := bar_rect(bar_x)

	if SDL.HasIntersection(&proj_wish_r, &bar_r) {
		if bar_dx != 0 {
			proj_dx = bar_dx
		}
		proj_dy *= -1
		return
	}

	for &target in targets_pool {
		if target.dead {
			continue
		}

		target_r := target_rect(target)
		if SDL.HasIntersection(&proj_wish_r, &target_r) {
			target.dead = true
			proj_dy *= -1
			return
		}
	}
	proj_y = proj_wish_y
}

update :: proc(dt: f32) {
	if pause || !started {
		return
	}
	proj_r := proj_rect(proj_x, proj_y)
	bar_r := bar_rect(bar_x)
	if SDL.HasIntersection(&proj_r, &bar_r) {
		proj_y = BAR_Y - BAR_THICCNESS / 2 - PROJ_SIZE - 1.0
		return
	}
	bar_collision(dt)
	horz_collision(dt)
	vert_collision(dt)
}

main :: proc() {
	if (SDL.Init(SDL.INIT_VIDEO) < 0) {
		SDL.Log("Unable to init SDL %s", SDL.GetError())
		return
	}

	defer SDL.Quit()

	window := SDL.CreateWindow(
		"Odinout",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		{.SHOWN},
	)
	assert(window != nil, SDL.GetErrorString())
	defer SDL.DestroyWindow(window)

	renderer := SDL.CreateRenderer(window, -1, {.ACCELERATED})
	assert(render != nil, SDL.GetErrorString())
	defer SDL.DestroyRenderer(renderer)

	ttf_error := TTF.Init()
	assert(ttf_error != -1, SDL.GetErrorString())
	defer TTF.Quit()

	font := TTF.OpenFont(FONT, FONT_SIZE)
	assert(font != nil, SDL.GetErrorString())

	keyboard := SDL.GetKeyboardState(nil)

	fmt.println("starting game loop")
	game_loop: for !quit {

		event: SDL.Event

		for SDL.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
				quit = true
			case .KEYDOWN:
				if (event.key.keysym.sym == .SPACE) {
					pause = !pause
				}
			}
		}

		bar_dx = 0
		if keyboard[SDL.SCANCODE_A] != 0 {
			bar_dx += -1
			if !started {
				started = true
				proj_dx = -1
			}
		}
		if keyboard[SDL.SCANCODE_D] != 0 {
			bar_dx += 1
			if !started {
				started = true
				proj_dx = 1
			}
		}

		update(DELTA_TIME_SEC)

		set_color(renderer, BACKGROUND_COLOR)
		_ = SDL.RenderClear(renderer)

		render(renderer, font)

		SDL.RenderPresent(renderer)

		SDL.Delay(1000 / FPS)
	}
}

// https://github.com/patrickodacre/sdl2-odin-examples/blob/master/render-static-text/main.odin
// create textures for the given str
// optional scale param allows us to easily size the texture generated
// relative to the current game.font_size
create_text :: proc(
	str: cstring,
	scale: i32 = 1,
	font: ^TTF.Font,
	renderer: ^SDL.Renderer,
) -> Text {
	// create surface
	surface := TTF.RenderText_Solid(font, str, {255, 255, 255, 255})
	defer SDL.FreeSurface(surface)

	// create texture to render
	texture := SDL.CreateTextureFromSurface(renderer, surface)

	// destination SDL.Rect
	dest_rect := SDL.Rect{}
	TTF.SizeText(font, str, &dest_rect.w, &dest_rect.h)

	// scale the size of the text
	dest_rect.w *= scale
	dest_rect.h *= scale

	return Text{tex = texture, dest = dest_rect}
}


set_color :: proc(renderer: ^SDL.Renderer, color: u32) {
	r := u8((color >> (0 * 8)) & 0xFF)
	g := u8((color >> (1 * 8)) & 0xFF)
	b := u8((color >> (2 * 8)) & 0xFF)
	a := u8((color >> (3 * 8)) & 0xFF)
	SDL.SetRenderDrawColor(renderer, r, g, b, a)
}
