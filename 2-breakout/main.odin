package main

import "base:runtime"
import "core:log"
import "core:math/linalg"
import "core:mem"
import "core:slice"
import sdl "vendor:sdl3"

PositionColorVertex :: struct {
    x, y, z: f32,
    r, g, b, a: u8,
}

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

Size :: struct {
    width, height: f32
}

Vector2 :: [2]f32

UBO :: struct {
    // 8 byte data
    screen_size: Size,

    ball_pos: Vector2,

    paddle_pos: Vector2,
    paddle_size: Size,

    bricks_pos: Vector2,
    bricks_size: Size,

    // 4 byte data
    ball_radius: f32,

    bricks_line_width: f32,
    bricks_h_spacing: f32,
}

default_context: runtime.Context
shader_code := #load("shader.metal")

main :: proc() {
    context.logger = log.create_console_logger()
    default_context = context

    sdl.SetLogPriorities(.VERBOSE)
    sdl.SetLogOutputFunction(
        proc "c" (
            userdata: rawptr,
            category: sdl.LogCategory,
            priority: sdl.LogPriority,
            message: cstring,
        ) {
            context = default_context
            log.debugf("SDL {} [{}]: {}", category, priority, message)
        },
        nil,
    )

    ok := sdl.Init({.VIDEO})
    assert(ok)

    window := sdl.CreateWindow("Breakout", WINDOW_WIDTH, WINDOW_HEIGHT, {})
    assert(window != nil)

    gpu := sdl.CreateGPUDevice({.MSL}, true, nil)
    assert(gpu != nil)

    ok = sdl.ClaimWindowForGPUDevice(gpu, window)
    assert(ok)

    vert_shader := load_shader(gpu, "vertex_main", .VERTEX, 0)
    assert(vert_shader != nil)

    frag_shader := load_shader(gpu, "fragment_main", .FRAGMENT, 1)
    assert(frag_shader != nil)

    vertex_buffer_descriptions := [1]sdl.GPUVertexBufferDescription {
        {
            slot = 0,
            input_rate = .VERTEX,
            pitch = size_of(PositionColorVertex),
        },
    }

    vertex_attributes := [2]sdl.GPUVertexAttribute {
        {
            buffer_slot = 0,
            format = .FLOAT3,
            location = 0,
            offset = 0,
        },
        {
            buffer_slot = 0,
            format = .UBYTE4,
            location = 1,
            offset = size_of(f32) * 3,
        },
    }

    pipeline := sdl.CreateGPUGraphicsPipeline(
        gpu,
        sdl.GPUGraphicsPipelineCreateInfo {
            vertex_shader = vert_shader,
            fragment_shader = frag_shader,
            primitive_type = .TRIANGLELIST,
            // Change fill_mode to line for wireframe
            rasterizer_state = sdl.GPURasterizerState {fill_mode = .FILL},
            target_info = {
                num_color_targets = 1,
                color_target_descriptions = &(sdl.GPUColorTargetDescription {
                    format = sdl.GetGPUSwapchainTextureFormat(gpu, window),
                }),
            },
            vertex_input_state = sdl.GPUVertexInputState {
                num_vertex_buffers = len(vertex_buffer_descriptions),
                vertex_buffer_descriptions = &vertex_buffer_descriptions[0],
                num_vertex_attributes = len(vertex_attributes),
                vertex_attributes = &vertex_attributes[0],
            },
        },
    )

    sdl.ReleaseGPUShader(gpu, vert_shader)
    sdl.ReleaseGPUShader(gpu, frag_shader)

    vertices := []PositionColorVertex {
        {  -1,  -1,  0,  0,    0,    255,  255  },
        {  -1,  1,   0,  255,  0,    0,    255  },
        {  1,   1,   0,  0,    255,  0,    255  },
        {  1,   -1,  0,  0,    0,    255,  255  },
    }

    indicies := []u16 {
        0, 1, 2, 0, 2, 3
    }

    transfer_data := slice.concatenate(
        [][]byte{ slice.to_bytes(vertices), slice.to_bytes(indicies) }
    )

    vertices_size := slice.size(vertices)
    indicies_size := slice.size(indicies)
    transfer_size := slice.size(transfer_data)

    transfer_buffer := sdl.CreateGPUTransferBuffer(
        gpu,
        sdl.GPUTransferBufferCreateInfo {
            usage = .UPLOAD,
            size = u32(vertices_size + indicies_size),
        },
    )

    transfer_mem := sdl.MapGPUTransferBuffer(gpu, transfer_buffer, cycle = false)
    mem.copy(transfer_mem, raw_data(transfer_data), transfer_size)
    sdl.UnmapGPUTransferBuffer(gpu, transfer_buffer)

    copy_command_buffer := sdl.AcquireGPUCommandBuffer(gpu)
    copy_pass := sdl.BeginGPUCopyPass(copy_command_buffer)

    vertex_buffer := sdl.CreateGPUBuffer(
        gpu,
        sdl.GPUBufferCreateInfo {
            usage = sdl.GPUBufferUsageFlags{sdl.GPUBufferUsageFlag.VERTEX},
            size = u32(vertices_size),
        },
    )

    sdl.UploadToGPUBuffer(
        copy_pass,
        sdl.GPUTransferBufferLocation {
            transfer_buffer = transfer_buffer
        },
        sdl.GPUBufferRegion {
            buffer = vertex_buffer,
            size = u32(vertices_size)
        },
        cycle = false,
    )

    index_buffer := sdl.CreateGPUBuffer(
        gpu,
        sdl.GPUBufferCreateInfo {
            usage = sdl.GPUBufferUsageFlags{sdl.GPUBufferUsageFlag.INDEX},
            size = u32(indicies_size),
        },
    )

    sdl.UploadToGPUBuffer(
        copy_pass,
        sdl.GPUTransferBufferLocation {
            transfer_buffer = transfer_buffer,
            offset = u32(vertices_size)
        },
        sdl.GPUBufferRegion {
            buffer = index_buffer,
            size = u32(indicies_size)
        },
        cycle = false,
    )

    sdl.EndGPUCopyPass(copy_pass)

    ok = sdl.SubmitGPUCommandBuffer(copy_command_buffer); assert(ok)

    sdl.ReleaseGPUTransferBuffer(gpu, transfer_buffer)

    // Fetch the current window size in case user has changed resolution
    window_size: [2]i32
    ok = sdl.GetWindowSize(window, &window_size.x, &window_size.y); assert(ok)

    ubo := UBO {
        screen_size = { f32(window_size.x), f32(window_size.y) },
        ball_pos = { (f32(window_size.x) / 2), f32(window_size.y) / 2 },
        ball_radius = 16,
        paddle_size = { 200, 30 },
        bricks_pos = { 140, 50 },
        bricks_size = { 1000, 50 },
        bricks_line_width = 4,
        bricks_h_spacing = 100,
    }

    ubo.paddle_pos = { (f32(window_size.x) / 2) - (ubo.paddle_size.width / 2), f32(window_size.y) - 100 }

    ball_velocity: f32 = 400
    ball_direction: [2]f32 = { 1, 0 }

    playing := false

    current_time := sdl.GetTicks()
    last_time: u64
    delta_time: f32

    main_loop: for {
        // calculate delta time
        last_time = current_time
        current_time = sdl.GetTicks()
        delta_time = f32(current_time - last_time) / 1000

        // process events
        space_pressed: bool

        ev: sdl.Event
        for sdl.PollEvent(&ev) {
            #partial switch ev.type {
            case .QUIT:
                break main_loop
            case .KEY_DOWN:
                if ev.key.scancode == .ESCAPE do break main_loop
                if ev.key.scancode == .SPACE do space_pressed = true
            }
        }

        // update game state
        paddle_middle := ubo.paddle_pos
        paddle_middle.x += ubo.paddle_size.width / 2

        if !playing && space_pressed {
            playing = true
            ball_direction = linalg.normalize(paddle_middle - ubo.ball_pos)
        }

        at_edge := !(ubo.ball_pos.x > ubo.ball_radius && ubo.ball_pos.x < f32(window_size.x) - ubo.ball_radius)
        at_top := ubo.ball_pos.y < ubo.ball_radius

        if at_edge && !playing {
            ball_direction.x = -ball_direction.x
        }

        // update - ball distance to paddle
        closest_x := clamp(ubo.ball_pos.x, ubo.paddle_pos.x, ubo.paddle_pos.x + ubo.paddle_size.width)
        closest_y := clamp(ubo.ball_pos.y, ubo.paddle_pos.y, ubo.paddle_pos.y + ubo.paddle_size.width)
        closest_point: [2]f32 = { closest_x, closest_y }
        distance := linalg.distance(ubo.ball_pos, closest_point)

        // update - ball direction

        if distance < ubo.ball_radius || at_top {
            ball_direction.y = -ball_direction.y
        }

        if at_edge && playing {
            ball_direction.x = -ball_direction.x
        }

        // update - ball position

        ubo.ball_pos += ball_direction * ball_velocity * delta_time

        // render
        cmd_buf := sdl.AcquireGPUCommandBuffer(gpu)

        swapchain_tex: ^sdl.GPUTexture
        ok = sdl.WaitAndAcquireGPUSwapchainTexture(
            cmd_buf,
            window,
            &swapchain_tex,
            nil,
            nil,
        );assert(ok)

        if swapchain_tex != nil {
            color_target := sdl.GPUColorTargetInfo {
                texture     = swapchain_tex,
                load_op     = .CLEAR,
                clear_color = {0, 0.2, 0.4, 1},
                store_op    = .STORE,
            }
            render_pass := sdl.BeginGPURenderPass(
                cmd_buf,
                &color_target,
                1,
                nil,
            )
            sdl.BindGPUGraphicsPipeline(render_pass, pipeline)
            sdl.BindGPUVertexBuffers(
                render_pass,
                first_slot = 0,
                bindings = &(sdl.GPUBufferBinding { buffer = vertex_buffer }),
                num_bindings = 1
            )
            sdl.BindGPUIndexBuffer(
                render_pass,
                binding = sdl.GPUBufferBinding { buffer = index_buffer },
                index_element_size = sdl.GPUIndexElementSize._16BIT,
            )
            sdl.PushGPUFragmentUniformData(cmd_buf, 0, &ubo, size_of(ubo))
            sdl.DrawGPUIndexedPrimitives(render_pass, 6, 1, 0, 0, 0)
            sdl.EndGPURenderPass(render_pass)
        }

        ok = sdl.SubmitGPUCommandBuffer(cmd_buf);assert(ok)
    }
}

load_shader :: proc(
    device: ^sdl.GPUDevice,
    entrypoint: cstring,
    stage: sdl.GPUShaderStage,
    num_uniform_buffers: u32,
) -> ^sdl.GPUShader {
    return sdl.CreateGPUShader(
        device,
        {
            code_size = len(shader_code),
            code = raw_data(shader_code),
            entrypoint = entrypoint,
            format = {.MSL},
            stage = stage,
            num_uniform_buffers = num_uniform_buffers,
        },
    )
}
