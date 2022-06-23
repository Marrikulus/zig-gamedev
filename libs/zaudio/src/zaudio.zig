const std = @import("std");
const assert = std.debug.assert;
const c = @cImport(@cInclude("miniaudio.h"));

pub const SoundFlags = packed struct {
    stream: bool = false,
    decode: bool = false,
    @"async": bool = false,
    wait_init: bool = false,
    no_default_attachment: bool = false,
    no_pitch: bool = false,
    no_spatialization: bool = false,

    _pad0: u9 = 0,
    _pad1: u16 = 0,

    comptime {
        assert(@sizeOf(@This()) == @sizeOf(u32) and @bitSizeOf(@This()) == @bitSizeOf(u32));
    }
};

pub const PanMode = enum(c_int) {
    balance,
    pan,
};

pub const AttenuationModel = enum(c_int) {
    none,
    inverse,
    linear,
    exponential,
};

pub const Positioning = enum(c_int) {
    absolute,
    relative,
};

pub const Format = enum(c_int) {
    unknown,
    format_u8,
    format_s16,
    format_s24,
    format_s32,
    format_f32,
};

pub const Channel = c.ma_channel;

pub const EngineConfig = struct {
    raw: c.ma_engine_config,

    pub fn init() EngineConfig {
        return .{ .raw = c.ma_engine_config_init() };
    }
};

pub const SoundConfig = struct {
    raw: c.ma_sound_config,

    pub fn init() SoundConfig {
        return .{ .raw = c.ma_sound_config_init() };
    }
};

pub const NodeGraph = struct {
    handle: *c.ma_node_graph,
    // TODO: Add methods.
};

pub const ResourceManager = struct {
    handle: *c.ma_resource_manager,
    // TODO: Add methods.
};

pub const Device = struct {
    handle: *c.ma_device,
    // TODO: Add methods.
};

pub const Log = struct {
    handle: *c.ma_log,
    // TODO: Add methods.
};

pub const Node = struct {
    handle: *c.ma_node,
    // TODO: Add methods.
};

pub const Engine = struct {
    handle: *c.ma_engine,

    pub fn init(allocator: std.mem.Allocator) Error!Engine {
        var handle = allocator.create(c.ma_engine) catch return error.OutOfMemory;
        errdefer allocator.destroy(handle);

        try checkResult(c.ma_engine_init(null, handle));

        return Engine{ .handle = handle };
    }

    pub fn initWithConfig(allocator: std.mem.Allocator, config: EngineConfig) Error!Engine {
        var handle = allocator.create(c.ma_engine) catch return error.OutOfMemory;
        errdefer allocator.destroy(handle);

        try checkResult(c.ma_engine_init(&config.raw, handle));

        return Engine{ .handle = handle };
    }

    pub fn deinit(engine: Engine, allocator: std.mem.Allocator) void {
        c.ma_engine_uninit(engine.handle);
        allocator.destroy(engine.handle);
    }

    pub fn readPcmFrames(engine: Engine, comptime T: type, frames: []T, frames_read: ?*u64) Error!void {
        try checkResult(c.ma_engine_read_pcm_frames(engine.handle, frames.ptr, frames.len, frames_read));
    }

    pub fn getNodeGraph(engine: Engine) NodeGraph {
        return .{ .handle = c.ma_engine_get_node_graph(engine.handle) };
    }

    pub fn getResourceManager(engine: Engine) ResourceManager {
        return .{ .handle = c.ma_engine_get_resource_manager(engine.handle) };
    }

    pub fn getDevice(engine: Engine) Device {
        return .{ .handle = c.ma_engine_get_device(engine.handle) };
    }

    pub fn getLog(engine: Engine) Log {
        return .{ .handle = c.ma_engine_get_log(engine.handle) };
    }

    pub fn getEndpoint(engine: Engine) Node {
        return .{ .handle = c.ma_engine_get_endpoint(engine.handle) };
    }

    pub fn getTime(engine: Engine) u64 {
        return c.ma_engine_get_time(engine.handle);
    }
    pub fn setTime(engine: Engine, global_time: u64) Error!void {
        try checkResult(c.ma_engine_set_time(engine.handle, global_time));
    }

    pub fn getChannels(engine: Engine) u32 {
        return c.ma_engine_get_channels(engine.handle);
    }

    pub fn getSampleRate(engine: Engine) u32 {
        return c.ma_engine_get_sample_rate(engine.handle);
    }

    pub fn start(engine: Engine) Error!void {
        try checkResult(c.ma_engine_start(engine.handle));
    }
    pub fn stop(engine: Engine) Error!void {
        try checkResult(c.ma_engine_stop(engine.handle));
    }

    pub fn setVolume(engine: Engine, volume: f32) Error!void {
        try checkResult(c.ma_engine_set_volume(engine.handle, volume));
    }

    pub fn setGainDb(engine: Engine, gain_db: f32) Error!void {
        try checkResult(c.ma_engine_set_gain_db(engine.handle, gain_db));
    }

    pub fn getNumListeners(engine: Engine) u32 {
        return c.ma_engine_get_listener_count(engine.handle);
    }

    pub fn findClosestListener(engine: Engine, absolute_pos_xyz: [3]f32) u32 {
        return c.ma_engine_find_closest_listener(
            engine.handle,
            absolute_pos_xyz[0],
            absolute_pos_xyz[1],
            absolute_pos_xyz[2],
        );
    }

    pub fn setListenerPosition(engine: Engine, index: u32, v: [3]f32) void {
        c.ma_engine_listener_set_position(engine.handle, index, v[0], v[1], v[2]);
    }
    pub fn getListenerPosition(engine: Engine, index: u32) [3]f32 {
        const v = c.ma_engine_listener_get_position(engine.handle, index);
        return .{ v.x, v.y, v.z };
    }

    pub fn setListenerDirection(engine: Engine, index: u32, v: [3]f32) void {
        c.ma_engine_listener_set_direction(engine.handle, index, v[0], v[1], v[2]);
    }
    pub fn getListenerDirection(engine: Engine, index: u32) [3]f32 {
        const v = c.ma_engine_listener_get_direction(engine.handle, index);
        return .{ v.x, v.y, v.z };
    }

    pub fn setListenerVelocity(engine: Engine, index: u32, v: [3]f32) void {
        c.ma_engine_listener_set_velocity(engine.handle, index, v[0], v[1], v[2]);
    }
    pub fn getListenerVelocity(engine: Engine, index: u32) [3]f32 {
        const v = c.ma_engine_listener_get_velocity(engine.handle, index);
        return .{ v.x, v.y, v.z };
    }

    pub fn setListenerWorldUp(engine: Engine, index: u32, v: [3]f32) void {
        c.ma_engine_listener_set_world_up(engine.handle, index, v[0], v[1], v[2]);
    }
    pub fn getListenerWorldUp(engine: Engine, index: u32) [3]f32 {
        const v = c.ma_engine_listener_get_world_up(engine.handle, index);
        return .{ v.x, v.y, v.z };
    }

    pub fn setListenerEnabled(engine: Engine, index: u32, enabled: bool) void {
        c.ma_engine_listener_set_enabled(engine.handle, index, if (enabled) c.MA_TRUE else c.MA_FALSE);
    }
    pub fn isListenerEnabled(engine: Engine, index: u32) bool {
        return c.ma_engine_listener_is_enabled(engine.handle, index) == c.MA_TRUE;
    }

    pub fn setListenerCone(
        engine: Engine,
        index: u32,
        inner_radians: f32,
        outer_radians: f32,
        outer_gain: f32,
    ) void {
        c.ma_engine_listener_set_cone(engine.handle, index, inner_radians, outer_radians, outer_gain);
    }
    pub fn getListenerCone(
        engine: Engine,
        index: u32,
        inner_radians: ?*f32,
        outer_radians: ?*f32,
        outer_gain: ?*f32,
    ) void {
        c.ma_engine_listener_get_cone(engine.handle, index, inner_radians, outer_radians, outer_gain);
    }

    pub fn playSound(engine: Engine, filepath: [:0]const u8, sgroup: ?SoundGroup) Error!void {
        try checkResult(c.ma_engine_play_sound(engine.handle, filepath.ptr, if (sgroup) |g| g.handle else null));
    }

    pub fn playSoundEx(engine: Engine, filepath: [:0]const u8, node: ?Node, node_input_bus_index: u32) Error!void {
        try checkResult(c.ma_engine_play_sound_ex(engine.handle, filepath.ptr, if (node) |n| n.handle else null, node_input_bus_index));
    }
};

pub const Sound = struct {
    handle: *c.ma_sound,

    pub fn initFromFile(
        allocator: std.mem.Allocator,
        engine: Engine,
        filepath: [:0]const u8,
        flags: SoundFlags,
        sgroup: ?SoundGroup,
        done_fence: ?Fence,
    ) Error!Sound {
        var handle = allocator.create(c.ma_sound) catch return error.OutOfMemory;
        errdefer allocator.destroy(handle);

        try checkResult(c.ma_sound_init_from_file(
            engine.handle,
            filepath.ptr,
            @bitCast(u32, flags),
            if (sgroup) |g| g.handle else null,
            if (done_fence) |f| f.handle else null,
            handle,
        ));

        return Sound{ .handle = handle };
    }

    pub fn initFromDataSource(
        allocator: std.mem.Allocator,
        engine: Engine,
        data_source: DataSource,
        flags: SoundFlags,
        sgroup: ?SoundGroup,
    ) Error!Sound {
        var handle = allocator.create(c.ma_sound) catch return error.OutOfMemory;
        errdefer allocator.destroy(handle);

        try checkResult(c.ma_sound_init_from_data_source(
            engine.handle,
            data_source.handle,
            @bitCast(u32, flags),
            if (sgroup) |g| g.handle else null,
            handle,
        ));

        return Sound{ .handle = handle };
    }

    pub fn initCopy(
        allocator: std.mem.Allocator,
        engine: Engine,
        existing_sound: Sound,
        flags: SoundFlags,
        sgroup: ?SoundGroup,
    ) Error!Sound {
        var handle = allocator.create(c.ma_sound) catch return error.OutOfMemory;
        errdefer allocator.destroy(handle);

        try checkResult(c.ma_sound_init_copy(
            engine.handle,
            existing_sound.handle,
            @bitCast(u32, flags),
            if (sgroup) |g| g.handle else null,
            handle,
        ));

        return Sound{ .handle = handle };
    }

    pub fn initWithConfig(
        allocator: std.mem.Allocator,
        engine: Engine,
        config: SoundConfig,
    ) Error!Sound {
        var handle = allocator.create(c.ma_sound) catch return error.OutOfMemory;
        errdefer allocator.destroy(handle);

        try checkResult(c.ma_sound_init_ex(engine.handle, &config.raw, handle));

        return Sound{ .handle = handle };
    }

    pub fn deinit(sound: Sound, allocator: std.mem.Allocator) void {
        c.ma_sound_uninit(sound.handle);
        allocator.destroy(sound.handle);
    }

    pub fn getEngine(sound: Sound) Engine {
        return .{ .handle = c.ma_sound_get_engine(sound.handle) };
    }

    pub fn getDataSource(sound: Sound) ?DataSource {
        const ds = c.ma_sound_get_data_source(sound.handle);
        if (ds != null) return DataSource{ .handle = ds };
        return null;
    }

    pub fn start(sound: Sound) Error!void {
        try checkResult(c.ma_sound_start(sound.handle));
    }
    pub fn stop(sound: Sound) Error!void {
        try checkResult(c.ma_sound_stop(sound.handle));
    }

    pub fn setVolume(sound: Sound, volume: f32) void {
        c.ma_sound_set_volume(sound.handle, volume);
    }
    pub fn getVolume(sound: Sound) f32 {
        return c.ma_sound_get_volume(sound.handle);
    }

    pub fn setPan(sound: Sound, pan: f32) void {
        c.ma_sound_set_pan(sound.handle, pan);
    }
    pub fn getPan(sound: Sound) f32 {
        return c.ma_sound_get_pan(sound.handle);
    }

    pub fn setPanMode(sound: Sound, pan_mode: PanMode) void {
        c.ma_sound_set_pan_mode(sound.handle, pan_mode);
    }
    pub fn getPanMode(sound: Sound) PanMode {
        return c.ma_sound_get_pan_mode(sound.handle);
    }

    pub fn setPitch(sound: Sound, pitch: f32) void {
        c.ma_sound_set_pitch(sound.handle, pitch);
    }
    pub fn getPitch(sound: Sound) f32 {
        return c.ma_sound_get_pitch(sound.handle);
    }

    pub fn setSpatializationEnabled(sound: Sound, enabled: bool) void {
        c.ma_sound_set_spatialization_enabled(sound.handle, if (enabled) c.MA_TRUE else c.MA_FALSE);
    }
    pub fn isSpatializationEnabled(sound: Sound) bool {
        return c.ma_sound_is_spatialization_enabled(sound.handle) == c.MA_TRUE;
    }

    pub fn setPinnedListenerIndex(sound: Sound, index: u32) void {
        c.ma_sound_set_pinned_listener_index(sound.handle, index);
    }
    pub fn getPinnedListenerIndex(sound: Sound) u32 {
        return c.ma_sound_get_pinned_listener_index(sound.handle);
    }
    pub fn getListenerIndex(sound: Sound) u32 {
        return c.ma_sound_get_listener_index(sound.handle);
    }

    pub fn getDirectionToListener(sound: Sound) [3]f32 {
        const v = c.ma_sound_get_direction_to_listener(sound.handle);
        return .{ v.x, v.y, v.z };
    }

    pub fn setPosition(sound: Sound, v: [3]f32) void {
        c.ma_sound_set_position(sound.handle, v[0], v[1], v[2]);
    }
    pub fn getPosition(sound: Sound) [3]f32 {
        const v = c.ma_sound_get_position(sound.handle);
        return .{ v.x, v.y, v.z };
    }

    pub fn setDirection(sound: Sound, v: [3]f32) void {
        c.ma_sound_set_direction(sound.handle, v[0], v[1], v[2]);
    }
    pub fn getDirection(sound: Sound) [3]f32 {
        const v = c.ma_sound_get_direction(sound.handle);
        return .{ v.x, v.y, v.z };
    }

    pub fn setVelocity(sound: Sound, v: [3]f32) void {
        c.ma_sound_set_velocity(sound.handle, v[0], v[1], v[2]);
    }
    pub fn getVelocity(sound: Sound) [3]f32 {
        const v = c.ma_sound_get_velocity(sound.handle);
        return .{ v.x, v.y, v.z };
    }

    pub fn setAttenuationModel(sound: Sound, model: AttenuationModel) void {
        c.ma_sound_set_attenuation_model(sound.handle, model);
    }
    pub fn getAttenuationModel(sound: Sound) AttenuationModel {
        return c.ma_sound_get_attenuation_model(sound.handle);
    }

    pub fn setPositioning(sound: Sound, pos: Positioning) void {
        c.ma_sound_set_positioning(sound.handle, pos);
    }
    pub fn getPositioning(sound: Sound) Positioning {
        return c.ma_sound_get_positioning(sound.handle);
    }

    pub fn setRolloff(sound: Sound, rolloff: f32) void {
        c.ma_sound_set_rolloff(sound.handle, rolloff);
    }
    pub fn getRolloff(sound: Sound) f32 {
        return c.ma_sound_get_rolloff(sound.handle);
    }

    pub fn setMinGain(sound: Sound, min_gain: f32) void {
        c.ma_sound_set_min_gain(sound.handle, min_gain);
    }
    pub fn getMinGain(sound: Sound) f32 {
        return c.ma_sound_get_min_gain(sound.handle);
    }

    pub fn setMaxGain(sound: Sound, max_gain: f32) void {
        c.ma_sound_set_max_gain(sound.handle, max_gain);
    }
    pub fn getMaxGain(sound: Sound) f32 {
        return c.ma_sound_get_max_gain(sound.handle);
    }

    pub fn setMinDistance(sound: Sound, min_distance: f32) void {
        c.ma_sound_set_min_distance(sound.handle, min_distance);
    }
    pub fn getMinDistance(sound: Sound) f32 {
        return c.ma_sound_get_min_distance(sound.handle);
    }

    pub fn setMaxDistance(sound: Sound, max_distance: f32) void {
        c.ma_sound_set_max_distance(sound.handle, max_distance);
    }
    pub fn getMaxDistance(sound: Sound) f32 {
        return c.ma_sound_get_max_distance(sound.handle);
    }

    pub fn setCone(sound: Sound, inner_radians: f32, outer_radians: f32, outer_gain: f32) void {
        c.ma_sound_set_cone(sound.handle, inner_radians, outer_radians, outer_gain);
    }
    pub fn getCone(sound: Sound, inner_radians: ?*f32, outer_radians: ?*f32, outer_gain: ?*f32) void {
        c.ma_sound_get_cone(sound.handle, inner_radians, outer_radians, outer_gain);
    }

    pub fn setDopplerFactor(sound: Sound, factor: f32) void {
        c.ma_sound_set_doppler_factor(sound.handle, factor);
    }
    pub fn getDopplerFactor(sound: Sound) f32 {
        return c.ma_sound_get_doppler_factor(sound.handle);
    }

    pub fn setDirectionalAttenuationFactor(sound: Sound, factor: f32) void {
        c.ma_sound_set_directional_attenuation_factor(sound.handle, factor);
    }
    pub fn getDirectionalAttenuationFactor(sound: Sound) f32 {
        return c.ma_sound_get_directional_attenuation_factor(sound.handle);
    }

    pub fn setFadeInPcmFrames(sound: Sound, volume_begin: f32, volume_end: f32, len_in_frames: u64) void {
        c.ma_sound_set_fade_in_pcm_frames(sound.handle, volume_begin, volume_end, len_in_frames);
    }
    pub fn setFadeInMilliseconds(sound: Sound, volume_begin: f32, volume_end: f32, len_in_ms: u64) void {
        c.ma_sound_set_fade_in_milliseconds(sound.handle, volume_begin, volume_end, len_in_ms);
    }
    pub fn getCurrentFadeVolume(sound: Sound) f32 {
        return c.ma_sound_get_current_fade_volume(sound.handle);
    }

    pub fn setStartTimeInPcmFrames(sound: Sound, abs_global_time_in_frames: u64) void {
        c.ma_sound_set_start_time_in_pcm_frames(sound.handle, abs_global_time_in_frames);
    }
    pub fn setStartTimeInMilliseconds(sound: Sound, abs_global_time_in_ms: u64) void {
        c.ma_sound_set_start_time_in_milliseconds(sound.handle, abs_global_time_in_ms);
    }

    pub fn setStopTimeInPcmFrames(sound: Sound, abs_global_time_in_frames: u64) void {
        c.ma_sound_set_stop_time_in_pcm_frames(sound.handle, abs_global_time_in_frames);
    }
    pub fn setStopTimeInMilliseconds(sound: Sound, abs_global_time_in_ms: u64) void {
        c.ma_sound_set_stop_time_in_milliseconds(sound.handle, abs_global_time_in_ms);
    }

    pub fn isPlaying(sound: Sound) bool {
        return c.ma_sound_is_playing(sound.handle) == c.MA_TRUE;
    }

    pub fn getTimeInPcmFrames(sound: Sound) u64 {
        return c.ma_sound_get_time_in_pcm_frames(sound.handle);
    }

    pub fn setLooping(sound: Sound, looping: bool) void {
        return c.ma_sound_set_looping(sound.handle, if (looping) c.MA_TRUE else c.MA_FALSE);
    }
    pub fn isLooping(sound: Sound) bool {
        return c.ma_sound_is_looping(sound.handle) == c.MA_TRUE;
    }

    pub fn isAtEnd(sound: Sound) bool {
        return c.ma_sound_at_end(sound.handle) == c.MA_TRUE;
    }

    pub fn seekToPcmFrame(sound: Sound, frame: u64) Error!void {
        try checkResult(c.ma_sound_seek_to_pcm_frame(sound.handle, frame));
    }

    pub fn getDataFormat(
        sound: Sound,
        format: ?*Format,
        num_channels: ?*u32,
        sample_rate: ?*u32,
        channel_map: ?[]Channel,
    ) Error!void {
        try checkResult(c.ma_sound_get_data_format(
            sound.handle,
            format,
            num_channels,
            sample_rate,
            if (channel_map) |chm| chm.ptr else null,
            if (channel_map) |chm| chm.len else 0,
        ));
    }

    pub fn getCursorInPcmFrames(sound: Sound) Error!u64 {
        var cursor: u64 = undefined;
        try checkResult(c.ma_sound_get_cursor_in_pcm_frames(sound.handle, &cursor));
        return cursor;
    }

    pub fn getLengthInPcmFrames(sound: Sound) Error!u64 {
        var length: u64 = undefined;
        try checkResult(c.ma_sound_get_length_in_pcm_frames(sound.handle, &length));
        return length;
    }

    pub fn getCursorInSeconds(sound: Sound) Error!f32 {
        var cursor: f32 = undefined;
        try checkResult(c.ma_sound_get_cursor_in_seconds(sound.handle, &cursor));
        return cursor;
    }

    pub fn getLengthInSeconds(sound: Sound) Error!f32 {
        var length: f32 = undefined;
        try checkResult(c.ma_sound_get_length_in_seconds(sound.handle, &length));
        return length;
    }
};

pub const SoundGroup = struct {
    handle: *c.ma_sound_group,

    pub fn init(
        allocator: std.mem.Allocator,
        engine: Engine,
        flags: SoundFlags,
        parent: ?SoundGroup,
    ) Error!SoundGroup {
        var handle = allocator.create(c.ma_sound_group) catch return error.OutOfMemory;
        errdefer allocator.destroy(handle);

        try checkResult(c.ma_sound_group_init(
            engine.handle,
            @bitCast(u32, flags),
            if (parent) |p| p.handle else null,
            handle,
        ));

        return SoundGroup{ .handle = handle };
    }

    pub fn deinit(sgroup: SoundGroup, allocator: std.mem.Allocator) void {
        c.ma_sound_group_uninit(sgroup.handle);
        allocator.destroy(sgroup.handle);
    }

    pub fn getEngine(sgroup: SoundGroup) Engine {
        return Engine{ .handle = c.ma_sound_group_get_engine(sgroup.handle) };
    }

    pub fn start(sgroup: SoundGroup) Error!void {
        try checkResult(c.ma_sound_group_start(sgroup.handle));
    }
    pub fn stop(sgroup: SoundGroup) Error!void {
        try checkResult(c.ma_sound_group_stop(sgroup.handle));
    }

    pub fn setVolume(sgroup: SoundGroup, volume: f32) void {
        c.ma_sound_group_set_volume(sgroup.handle, volume);
    }
    pub fn getVolume(sgroup: SoundGroup) f32 {
        return c.ma_sound_group_get_volume(sgroup.handle);
    }

    pub fn setPan(sgroup: SoundGroup, pan: f32) void {
        c.ma_sound_group_set_pan(sgroup.handle, pan);
    }
    pub fn getPan(sgroup: SoundGroup) f32 {
        return c.ma_sound_group_get_pan(sgroup.handle);
    }

    pub fn setPanMode(sgroup: SoundGroup, pan_mode: PanMode) void {
        c.ma_sound_group_set_pan_mode(sgroup.handle, pan_mode);
    }
    pub fn getPanMode(sgroup: SoundGroup) PanMode {
        return c.ma_sound_group_get_pan_mode(sgroup.handle);
    }

    pub fn setPitch(sgroup: SoundGroup, pitch: f32) void {
        c.ma_sound_group_set_pitch(sgroup.handle, pitch);
    }
    pub fn getPitch(sgroup: SoundGroup) f32 {
        return c.ma_sound_group_get_pitch(sgroup.handle);
    }

    pub fn setSpatializationEnabled(sgroup: SoundGroup, enabled: bool) void {
        c.ma_sound_group_set_spatialization_enabled(sgroup.handle, if (enabled) c.MA_TRUE else c.MA_FALSE);
    }
    pub fn isSpatializationEnabled(sgroup: SoundGroup) bool {
        return c.ma_sound_group_is_spatialization_enabled(sgroup.handle) == c.MA_TRUE;
    }

    pub fn setPinnedListenerIndex(sgroup: SoundGroup, index: u32) void {
        c.ma_sound_group_set_pinned_listener_index(sgroup.handle, index);
    }
    pub fn getPinnedListenerIndex(sgroup: SoundGroup) u32 {
        return c.ma_sound_group_get_pinned_listener_index(sgroup.handle);
    }
    pub fn getListenerIndex(sgroup: SoundGroup) u32 {
        return c.ma_sound_group_get_listener_index(sgroup.handle);
    }

    pub fn getDirectionToListener(sgroup: SoundGroup) [3]f32 {
        const v = c.ma_sound_group_get_direction_to_listener(sgroup.handle);
        return .{ v.x, v.y, v.z };
    }

    pub fn setPosition(sgroup: SoundGroup, v: [3]f32) void {
        c.ma_sound_group_set_position(sgroup.handle, v[0], v[1], v[2]);
    }
    pub fn getPosition(sgroup: SoundGroup) [3]f32 {
        const v = c.ma_sound_group_get_position(sgroup.handle);
        return .{ v.x, v.y, v.z };
    }

    pub fn setDirection(sgroup: SoundGroup, v: [3]f32) void {
        c.ma_sound_group_set_direction(sgroup.handle, v[0], v[1], v[2]);
    }
    pub fn getDirection(sgroup: SoundGroup) [3]f32 {
        const v = c.ma_sound_group_get_direction(sgroup.handle);
        return .{ v.x, v.y, v.z };
    }

    pub fn setVelocity(sgroup: SoundGroup, v: [3]f32) void {
        c.ma_sound_group_set_velocity(sgroup.handle, v[0], v[1], v[2]);
    }
    pub fn getVelocity(sgroup: SoundGroup) [3]f32 {
        const v = c.ma_sound_group_get_velocity(sgroup.handle);
        return .{ v.x, v.y, v.z };
    }

    pub fn setAttenuationModel(sgroup: SoundGroup, model: AttenuationModel) void {
        c.ma_sound_group_set_attenuation_model(sgroup.handle, model);
    }
    pub fn getAttenuationModel(sgroup: SoundGroup) AttenuationModel {
        return c.ma_sound_group_get_attenuation_model(sgroup.handle);
    }

    pub fn setPositioning(sgroup: SoundGroup, pos: Positioning) void {
        c.ma_sound_group_set_positioning(sgroup.handle, pos);
    }
    pub fn getPositioning(sgroup: SoundGroup) Positioning {
        return c.ma_sound_group_get_positioning(sgroup.handle);
    }

    pub fn setRolloff(sgroup: SoundGroup, rolloff: f32) void {
        c.ma_sound_group_set_rolloff(sgroup.handle, rolloff);
    }
    pub fn getRolloff(sgroup: SoundGroup) f32 {
        return c.ma_sound_group_get_rolloff(sgroup.handle);
    }

    pub fn setMinGain(sgroup: SoundGroup, min_gain: f32) void {
        c.ma_sound_group_set_min_gain(sgroup.handle, min_gain);
    }
    pub fn getMinGain(sgroup: SoundGroup) f32 {
        return c.ma_sound_group_get_min_gain(sgroup.handle);
    }

    pub fn setMaxGain(sgroup: SoundGroup, max_gain: f32) void {
        c.ma_sound_group_set_max_gain(sgroup.handle, max_gain);
    }
    pub fn getMaxGain(sgroup: SoundGroup) f32 {
        return c.ma_sound_group_get_max_gain(sgroup.handle);
    }

    pub fn setMinDistance(sgroup: SoundGroup, min_distance: f32) void {
        c.ma_sound_group_set_min_distance(sgroup.handle, min_distance);
    }
    pub fn getMinDistance(sgroup: SoundGroup) f32 {
        return c.ma_sound_group_get_min_distance(sgroup.handle);
    }

    pub fn setMaxDistance(sgroup: SoundGroup, max_distance: f32) void {
        c.ma_sound_group_set_max_distance(sgroup.handle, max_distance);
    }
    pub fn getMaxDistance(sgroup: SoundGroup) f32 {
        return c.ma_sound_group_get_max_distance(sgroup.handle);
    }

    pub fn setCone(sgroup: SoundGroup, inner_radians: f32, outer_radians: f32, outer_gain: f32) void {
        c.ma_sound_group_set_cone(sgroup.handle, inner_radians, outer_radians, outer_gain);
    }
    pub fn getCone(sgroup: SoundGroup, inner_radians: ?*f32, outer_radians: ?*f32, outer_gain: ?*f32) void {
        c.ma_sound_group_get_cone(sgroup.handle, inner_radians, outer_radians, outer_gain);
    }

    pub fn setDopplerFactor(sgroup: SoundGroup, factor: f32) void {
        c.ma_sound_group_set_doppler_factor(sgroup.handle, factor);
    }
    pub fn getDopplerFactor(sgroup: SoundGroup) f32 {
        return c.ma_sound_group_get_doppler_factor(sgroup.handle);
    }

    pub fn setDirectionalAttenuationFactor(sgroup: SoundGroup, factor: f32) void {
        c.ma_sound_group_set_directional_attenuation_factor(sgroup.handle, factor);
    }
    pub fn getDirectionalAttenuationFactor(sgroup: SoundGroup) f32 {
        return c.ma_sound_group_get_directional_attenuation_factor(sgroup.handle);
    }

    pub fn setFadeInPcmFrames(sgroup: SoundGroup, volume_begin: f32, volume_end: f32, len_in_frames: u64) void {
        c.ma_sound_group_set_fade_in_pcm_frames(sgroup.handle, volume_begin, volume_end, len_in_frames);
    }
    pub fn setFadeInMilliseconds(sgroup: SoundGroup, volume_begin: f32, volume_end: f32, len_in_ms: u64) void {
        c.ma_sound_group_set_fade_in_milliseconds(sgroup.handle, volume_begin, volume_end, len_in_ms);
    }
    pub fn getCurrentFadeVolume(sgroup: SoundGroup) f32 {
        return c.ma_sound_group_get_current_fade_volume(sgroup.handle);
    }

    pub fn setStartTimeInPcmFrames(sgroup: SoundGroup, abs_global_time_in_frames: u64) void {
        c.ma_sound_group_set_start_time_in_pcm_frames(sgroup.handle, abs_global_time_in_frames);
    }
    pub fn setStartTimeInMilliseconds(sgroup: SoundGroup, abs_global_time_in_ms: u64) void {
        c.ma_sound_group_set_start_time_in_milliseconds(sgroup.handle, abs_global_time_in_ms);
    }

    pub fn setStopTimeInPcmFrames(sgroup: SoundGroup, abs_global_time_in_frames: u64) void {
        c.ma_sound_group_set_stop_time_in_pcm_frames(sgroup.handle, abs_global_time_in_frames);
    }
    pub fn setStopTimeInMilliseconds(sgroup: SoundGroup, abs_global_time_in_ms: u64) void {
        c.ma_sound_group_set_stop_time_in_milliseconds(sgroup.handle, abs_global_time_in_ms);
    }

    pub fn isPlaying(sgroup: SoundGroup) bool {
        return c.ma_sound_group_is_playing(sgroup.handle) == c.MA_TRUE;
    }

    pub fn getTimeInPcmFrames(sgroup: SoundGroup) u64 {
        return c.ma_sound_group_get_time_in_pcm_frames(sgroup.handle);
    }
};

pub const Fence = struct {
    handle: *c.ma_fence,

    pub fn init(allocator: std.mem.Allocator) Error!Fence {
        var handle = allocator.create(c.ma_fence) catch return error.OutOfMemory;
        errdefer allocator.destroy(handle);

        try checkResult(c.ma_fence_init(handle));

        return Fence{ .handle = handle };
    }

    pub fn deinit(fence: Fence, allocator: std.mem.Allocator) void {
        c.ma_fence_uninit(fence.handle);
        allocator.destroy(fence.handle);
    }

    pub fn acquire(fence: Fence) Error!void {
        try checkResult(c.ma_fence_acquire(fence.handle));
    }

    pub fn release(fence: Fence) Error!void {
        try checkResult(c.ma_fence_release(fence.handle));
    }

    pub fn wait(fence: Fence) Error!void {
        try checkResult(c.ma_fence_wait(fence.handle));
    }
};

pub const DataSource = struct {
    handle: *c.ma_data_source,
    // TODO: Add methods.
};

pub const Error = error{
    GenericError,
    InvalidArgs,
    InvalidOperation,
    OutOfMemory,
};

fn checkResult(result: c.ma_result) Error!void {
    // TODO: Handle all errors.
    if (result != c.MA_SUCCESS)
        return error.GenericError;
}

const expect = std.testing.expect;

test "zaudio.engine.basic" {
    const engine = try Engine.init(std.testing.allocator);
    defer engine.deinit(std.testing.allocator);

    var frames: [2]f32 = undefined;
    try engine.readPcmFrames(f32, frames[0..], null);

    try engine.setTime(engine.getTime());

    std.debug.print("Channels: {}, SampleRate: {}, NumListeners: {}, ClosestListener: {}\n", .{
        engine.getChannels(),
        engine.getSampleRate(),
        engine.getNumListeners(),
        engine.findClosestListener(.{ 0.0, 0.0, 0.0 }),
    });

    try engine.start();
    try engine.stop();
    try engine.start();
    try engine.setVolume(1.0);
    try engine.setGainDb(1.0);

    engine.setListenerEnabled(0, true);
    try expect(engine.isListenerEnabled(0) == true);
}

test "zaudio.soundgroup.basic" {
    const engine = try Engine.init(std.testing.allocator);
    defer engine.deinit(std.testing.allocator);

    const sgroup = try SoundGroup.init(std.testing.allocator, engine, .{}, null);
    defer sgroup.deinit(std.testing.allocator);

    try expect(sgroup.getEngine().handle == engine.handle);

    try sgroup.start();
    try sgroup.stop();
    try sgroup.start();

    sgroup.setVolume(0.5);
    try expect(sgroup.getVolume() == 0.5);

    sgroup.setPan(0.25);
    try expect(sgroup.getPan() == 0.25);

    sgroup.setDirection(.{ 1.0, 2.0, 3.0 });
    {
        const dir = sgroup.getDirection();
        try expect(dir[0] == 1.0 and dir[1] == 2.0 and dir[2] == 3.0);
    }
}

test "zaudio.fence.basic" {
    const fence = try Fence.init(std.testing.allocator);
    defer fence.deinit(std.testing.allocator);

    try fence.acquire();
    try fence.release();
    try fence.wait();
}

test "zaudio.sound.basic" {
    const engine = try Engine.init(std.testing.allocator);
    defer engine.deinit(std.testing.allocator);

    var config = SoundConfig.init();
    config.raw.channelsIn = 1;
    const sound = try Sound.initWithConfig(std.testing.allocator, engine, config);
    defer sound.deinit(std.testing.allocator);

    sound.setVolume(0.25);
    try expect(sound.getVolume() == 0.25);
}