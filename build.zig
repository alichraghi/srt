const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const version_h = b.addConfigHeader(
        .{
            .style = .{ .cmake = .{ .path = "srtcore/version.h.in" } },
            .include_path = "version.h",
        },
        .{
            .SRT_VERSION_MAJOR = 1,
            .SRT_VERSION_MINOR = 5,
            .SRT_VERSION_PATCH = 3,
            .SRT_VERSION_BUILD = 153,
        },
    );

    const lib = b.addStaticLibrary(.{
        .name = "srt",
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibC();
    lib.linkLibCpp();
    lib.addCSourceFiles(.{
        .files = sources,
        .flags = &.{
            "-DUSE_OPENSSL",
            "-DSRT_VERSION=\"1.5.3\"",
            "-D_GNU_SOURCE",
            "-DHAI_PATCH=1",
            "-DHAI_ENABLE_SRT=1",
        },
    });
    lib.addConfigHeader(version_h);
    lib.addIncludePath(.{ .path = "haicrypt" });
    lib.addIncludePath(.{ .path = "srtcore" });
    lib.installConfigHeader(version_h, .{});
    lib.installHeadersDirectoryOptions(.{
        .source_dir = .{ .path = "srtcore" },
        .include_extensions = &.{".h"},
        .install_dir = .header,
        .install_subdir = "",
    });
    b.installArtifact(lib);

    inline for (&.{
        .{ .name = "example-client-nonblock", .type = .c },
        .{ .name = "recvfile", .type = .cpp },
        .{ .name = "recvlive", .type = .cpp },
        .{ .name = "recvmsg", .type = .cpp },
        .{ .name = "sendfile", .type = .cpp },
        .{ .name = "sendmsg", .type = .cpp },
        .{ .name = "testcapi-connect", .type = .c },
        .{ .name = "test-c-client-bonding", .type = .c },
        .{ .name = "test-c-client", .type = .c },
        .{ .name = "test-c-server-bonding", .type = .c },
        .{ .name = "test-c-server", .type = .c },
    }) |desc| {
        const example = b.addExecutable(.{
            .name = desc.name,
            .target = target,
            .optimize = optimize,
        });
        example.addCSourceFile(.{ .file = .{ .path = "examples/" ++ desc.name ++ "." ++ @tagName(desc.type) }, .flags = &.{} });
        example.linkLibrary(lib);
        b.installArtifact(example);

        const run_cmd = b.addRunArtifact(example);
        if (b.args) |args| run_cmd.addArgs(args);
        const run_step = b.step("run-" ++ desc.name, "Run " ++ desc.name ++ " example");
        run_step.dependOn(&run_cmd.step);
    }

    {
        const live_transmit = b.addExecutable(.{
            .name = "live-transmit",
            .target = target,
            .optimize = optimize,
        });
        live_transmit.addCSourceFiles(.{ .files = &.{
            "apps/srt-live-transmit.cpp",
            "apps/verbose.cpp",
            "apps/apputil.cpp",
            "apps/uriparser.cpp",
            "apps/socketoptions.cpp",
            "apps/logsupport.cpp",
            "apps/logsupport_appdefs.cpp",
            "apps/transmitmedia.cpp",
            "apps/statswriter.cpp",
        }, .flags = &.{
            "-DSRT_VERSION=\"1.5.3\"",
        } });
        live_transmit.linkLibrary(lib);
        b.installArtifact(live_transmit);

        const run_cmd = b.addRunArtifact(live_transmit);
        if (b.args) |args| run_cmd.addArgs(args);
        const run_step = b.step("run-live-transmit", "Run Live transmit app");
        run_step.dependOn(&run_cmd.step);
    }
}

const sources = &[_][]const u8{
    "haicrypt/cryspr.c",
    "haicrypt/cryspr-openssl.c",
    "haicrypt/hcrypt.c",
    "haicrypt/hcrypt_ctx_rx.c",
    "haicrypt/hcrypt_ctx_tx.c",
    "haicrypt/hcrypt_rx.c",
    "haicrypt/hcrypt_sa.c",
    "haicrypt/hcrypt_tx.c",
    "haicrypt/hcrypt_xpt_srt.c",
    "haicrypt/haicrypt_log.cpp",

    "srtcore/srt_compat.c",
    "srtcore/api.cpp",
    "srtcore/buffer_rcv.cpp",
    "srtcore/buffer_snd.cpp",
    "srtcore/buffer_tools.cpp",
    "srtcore/cache.cpp",
    "srtcore/channel.cpp",
    "srtcore/common.cpp",
    "srtcore/congctl.cpp",
    "srtcore/core.cpp",
    "srtcore/crypto.cpp",
    "srtcore/epoll.cpp",
    "srtcore/fec.cpp",
    "srtcore/handshake.cpp",
    "srtcore/list.cpp",
    "srtcore/logger_default.cpp",
    "srtcore/logger_defs.cpp",
    "srtcore/logging.cpp",
    "srtcore/md5.cpp",
    "srtcore/packet.cpp",
    "srtcore/packetfilter.cpp",
    "srtcore/queue.cpp",
    "srtcore/socketconfig.cpp",
    "srtcore/srt_c_api.cpp",
    "srtcore/strerror_defs.cpp",
    "srtcore/sync.cpp",
    // "srtcore/sync_cxx11.cpp",
    "srtcore/sync_posix.cpp",
    "srtcore/tsbpd_time.cpp",
    "srtcore/window.cpp",

    // "srtcore/group_backup.cpp",
    // "srtcore/group_common.cpp",
    // "srtcore/group.cpp",
};

const cpp_sources = &[_][]const u8{};
