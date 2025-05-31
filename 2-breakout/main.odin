package main

import "base:runtime"
import "core:log"
import "core:mem"
import sdl "vendor:sdl3"

PositionColorVertex :: struct {
    x, y, z: f32,
    r, g, b, a: u8,
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

    window := sdl.CreateWindow("Hello SDL3", 1280, 780, {})
    assert(window != nil)

    gpu := sdl.CreateGPUDevice({.MSL}, true, nil)
    assert(gpu != nil)

    ok = sdl.ClaimWindowForGPUDevice(gpu, window)
    assert(ok)

    vert_shader := load_shader(gpu, "vertex_main", .VERTEX)
    assert(vert_shader != nil)

    frag_shader := load_shader(gpu, "fragment_main", .FRAGMENT)
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
            format = .UBYTE4_NORM,
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
        {  -1,  -1,  0,  255,  0,    0,    255  },
        {  1,   -1,  0,  0,    255,  0,    255  },
        {  0,   1,   0,  0,    0,    255,  255  },
    }

    // Might need to change this to len(vertices) * size_of(vertices[0])
    vertices_size := len(vertices) * size_of(vertices[0])

    vertex_buffer := sdl.CreateGPUBuffer(
        gpu,
        sdl.GPUBufferCreateInfo {
            usage = sdl.GPUBufferUsageFlags{sdl.GPUBufferUsageFlag.VERTEX},
            size = u32(vertices_size),
        },
    )

    transfer_buffer := sdl.CreateGPUTransferBuffer(
        gpu,
        sdl.GPUTransferBufferCreateInfo {
            usage = .UPLOAD,
            size = u32(vertices_size),
        },
    )

    transfer_mem := sdl.MapGPUTransferBuffer(gpu, transfer_buffer, cycle = false)
    mem.copy(transfer_mem, raw_data(vertices), vertices_size)
    sdl.UnmapGPUTransferBuffer(gpu, transfer_buffer)

    copy_command_buffer := sdl.AcquireGPUCommandBuffer(gpu)

    copy_pass := sdl.BeginGPUCopyPass(copy_command_buffer)

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

    sdl.EndGPUCopyPass(copy_pass)

    ok = sdl.SubmitGPUCommandBuffer(copy_command_buffer); assert(ok)

    sdl.ReleaseGPUTransferBuffer(gpu, transfer_buffer)

    main_loop: for {
        // process events
        ev: sdl.Event
        for sdl.PollEvent(&ev) {
            #partial switch ev.type {
            case .QUIT:
                break main_loop
            case .KEY_DOWN:
                if ev.key.scancode == .ESCAPE do break main_loop
            }
        }

        // update game state

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
            sdl.BindGPUVertexBuffers(render_pass, first_slot = 0, bindings = &(sdl.GPUBufferBinding { buffer = vertex_buffer }), num_bindings = 1)
            sdl.DrawGPUPrimitives(render_pass, 3, 1, 0, 0)
            sdl.EndGPURenderPass(render_pass)
        }

        ok = sdl.SubmitGPUCommandBuffer(cmd_buf);assert(ok)
    }
}

load_shader :: proc(
    device: ^sdl.GPUDevice,
    entrypoint: cstring,
    stage: sdl.GPUShaderStage,
) -> ^sdl.GPUShader {
    return sdl.CreateGPUShader(
        device,
        {
            code_size = len(shader_code),
            code = raw_data(shader_code),
            entrypoint = entrypoint,
            format = {.MSL},
            stage = stage,
        },
    )
}
