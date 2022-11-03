//! This program mimics `mktemp -d` but the generated directory name
//! is drawn from two wordlists; Exactly like how Docker generates container names.
//!
//! The wordlist compression, embedding, and deflating follow the techniques in:
//! https://nullprogram.com/blog/2022/03/07/

const std = @import("std");
const expectEqualStrings = std.testing.expectEqualStrings;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

/// Huffman-encoded wordlist, using RS (0x1e) as a delimiter
const words = [369]u32{
    0x8f7b4527, 0x1ef449ce, 0xaf94539d, 0x9f0738d0, 0x2f070dd3, 0x3d54e273,
    0xf7da373a, 0xe28cf11c, 0x6851fdb3, 0x6b365a85, 0x365a8566, 0xbd0d9934,
    0x23f36747, 0x3de51b3f, 0x1e8b9cb5, 0xbe4f6a9d, 0x8e58a2a7, 0x3e0e71b9,
    0xf0f2c515, 0xf238a903, 0x1ec8feb9, 0xb4a38a9d, 0x445481fc, 0x759bf54b,
    0xed53f54f, 0x5952a791, 0x787c8e8f, 0x232f3d17, 0xc2afc19b, 0x13ff48cb,
    0x7bf4fe7b, 0x741c32be, 0x7431dbcd, 0xcbc1dbcd, 0x81bebdbc, 0xfa1aa1bc,
    0x6ba5f903, 0xe86d6d5e, 0xc9de51d1, 0x0cf2881f, 0x3b147e4d, 0x037ee1b1,
    0x7e52b051, 0x47fbc519, 0x91c51eda, 0x67428f61, 0xbb33e8f6, 0xe056e881,
    0xb2a23465, 0x46d5fb47, 0x07fed1ca, 0x7b2cb729, 0xe8acb9ca, 0x9bd4f29f,
    0x2e0a6ba1, 0xa14b50af, 0x8f4f7da3, 0xd9bd6672, 0xf69787a7, 0x781e9d1e,
    0x903fd6b3, 0x867f781e, 0x34751d1e, 0x648ea3db, 0x9ffd659f, 0x76323dac,
    0x1d1e9754, 0xc747b243, 0x71196d68, 0x0459ebba, 0xa08867ca, 0x7623a3dc,
    0x1ef65686, 0x0baa399d, 0x127799ec, 0x7eba6729, 0x33d815a6, 0xbba670c8,
    0xaff53706, 0x1707e4d0, 0x5d0cd168, 0x57d5fcb3, 0x797965a8, 0xfcb35d03,
    0xc59f9370, 0xb3d742af, 0xedf5de2c, 0xb686a399, 0xd0d47baf, 0x9ebaa956,
    0xe752bfc5, 0x3b7f1d1e, 0x4fe32fb5, 0x1c40ffbe, 0x0d740dc5, 0xffbf0c9f,
    0x2f9cb87c, 0xc3db36e1, 0x61ecbff6, 0xf061aec0, 0xa061fd1b, 0x32fd2bcb,
    0xdae9794c, 0xfc4c3948, 0xbe47e043, 0xc33b4a07, 0xd0ca701e, 0xa9c743a3,
    0xd0cbd8a2, 0x9083fb65, 0x840df9bd, 0x0376dd6c, 0x23a35b21, 0x3aad10e5,
    0xc087b697, 0xb50aef91, 0x8941fda8, 0x7659f4b5, 0x6a1450a4, 0x5219fd51,
    0xa727ea8e, 0xb673b9e7, 0xe74dc01d, 0x26727ecc, 0x06e5e5be, 0x73acde70,
    0x978b4b5e, 0x3d9739cf, 0xe759bcba, 0x1cadbf7c, 0xf4328e5c, 0x3b6dbb64,
    0xae6ed9fd, 0xaa376c96, 0xf2e76ceb, 0x439db27f, 0xb98ed9af, 0xef91fdb3,
    0xdb2cded9, 0xb95b2a8f, 0x72b65cad, 0x365f9ebc, 0xb366babb, 0x7d46ebab,
    0x95d5d9b2, 0x586cb378, 0x94221b3c, 0x1b3ae86c, 0x2a4367f2, 0x2ee1b26e,
    0x7115f9b3, 0xd9702e9a, 0x27ae00fc, 0xd931239b, 0x51b35d68, 0xbd4b379f,
    0x73d49c19, 0x073d49c6, 0x48175bc2, 0x53df273d, 0x72d495df, 0xd7f8fd23,
    0x6e5a9e72, 0xa4f75db1, 0x87b78396, 0xef0072d4, 0xe5a9ffea, 0xbf2d48a8,
    0x4c9e5ced, 0x53f5f3b5, 0xa2a4fcb1, 0xf4549fc9, 0x53dbf54e, 0x52a7f7a9,
    0x73c89bf7, 0xc8f227a2, 0x4f91da9e, 0xb23df9c8, 0xd913711c, 0xd91fd28a,
    0x5f832bea, 0x48d5fb64, 0x1668ae6f, 0x5e1eb749, 0xfdb1fcf7, 0x38cd979e,
    0xef861ef9, 0xeb76dbc9, 0x7d37937e, 0x8d6f2ce2, 0xce6b3793, 0xcedb7e8f,
    0xb5ab4f21, 0x8f7b53cc, 0xf6f27e72, 0x6f0cdf28, 0x41c5de51, 0x51d17794,
    0x13711f7e, 0xeb566fc5, 0xde7d3e89, 0xf6d67d13, 0xcd867d18, 0xda9a37d1,
    0x1cf07d1e, 0xfa39947d, 0x344f5c5d, 0x75dedc9a, 0xe8649a34, 0x493468f9,
    0x347bf31c, 0x1a35d75a, 0x34599e51, 0xfed19352, 0x1da3df2d, 0xfec8fca1,
    0x6f5ca6ba, 0x0da27290, 0xed8e5270, 0x588e5201, 0x37ca747b, 0x3aef6cff,
    0x4dc4cde5, 0x99b8bbca, 0xe5ae7794, 0x541de52d, 0x923bbf29, 0x2829eebc,
    0x8293daf5, 0x7849c30a, 0xdf24414f, 0xde597053, 0x4fb6a853, 0xbe8397d9,
    0xdd569734, 0xbabf517a, 0x6fd44e32, 0x345fd474, 0x67fd44e3, 0xfd47347a,
    0x3a89fe17, 0xa89c6196, 0xd44235a3, 0x9eb39e71, 0x4b7ac89d, 0xf3d65f03,
    0x7726facf, 0xecdf592e, 0xf62feb3d, 0xbedcb59e, 0xd05ac89f, 0xdb6b2e6f,
    0xaf6d67b6, 0x2850eb25, 0x7b389159, 0x9d8ed792, 0x9d8fc8dd, 0x89d8f738,
    0x7f621d05, 0x3fb1efeb, 0x2f6201b2, 0x1d77b7df, 0x266e22fb, 0xac4f44f6,
    0x7177816b, 0x915e6b13, 0x76f9218c, 0xf45463f5, 0x395c47fb, 0xce22fdb2,
    0x88e6b535, 0x0102a603, 0xf12d4e23, 0xbfb71166, 0x0e7ad447, 0xd5a88f65,
    0x1aeb007a, 0x27fced51, 0x44dfdaa2, 0x7b06a1d4, 0x7bcc37c4, 0x8b7c8fc4,
    0xff6f91f8, 0x0f4fc464, 0xfbc47baf, 0x0cf11f6a, 0xbb444ae8, 0xd372d6ea,
    0x56703811, 0xd1023a7b, 0x3f9d023f, 0x823df902, 0x66bac4ba, 0xccf7e96e,
    0x153cc971, 0x02799337, 0x0bad3270, 0xcfb3e8f4, 0xc196f6e0, 0x419ef287,
    0x40295287, 0x59faf706, 0xcb3a7a6e, 0xae3967f9, 0xe18e5967, 0x7db967a9,
    0x89bbcb3e, 0x7ebd2c9b, 0xe7a9ec16, 0xfc1b059f, 0xaf238b38, 0x2456fbd4,
    0xbda00b2f, 0x6e27e3d8, 0xa86e27e2, 0xa0bc4dfa, 0xfcb78e7c, 0xfd2d4378,
    0x187adc71, 0xa03f8e27, 0x67c8e27f, 0xb74e323d, 0x0b95f09e, 0xe10f109f,
    0x38cef91b, 0xd2e403e1, 0x3da272e1, 0x27066e5c, 0x97088e5c, 0x5c3dfb76,
    0x7bf6aeb0, 0x84fbc0b8, 0x7732907b, 0x1ef97678, 0x13814346, 0x87ea7e5e,
    0xbf37e701, 0xa14c3df5, 0x0c8ddbbc, 0x138c3713, 0x1541ce26, 0x39edda26,
    0x75b99470, 0x502ed9e0, 0x414097ce, 0x004e30b1, 0x1c933c9d, 0x3dea01a0,
    0x95f9e43a, 0x2fda5d13, 0x6e5d51e4, 0x4dd9b642, 0x9f266c87, 0x2fdbf3c9,
    0x97395a24, 0x2a2b9e21, 0x8db6884a, 0xe7b6887a, 0x27d66d10, 0xf59b4438,
    0xd109c609, 0x7a2138c6, 0x4d540874, 0x5bc21adf, 0xb3410817, 0x1d91219f,
    0x5544a0e7, 0xaf248ae8, 0x0000007b,
};

/// State transition table to decompress huffman-encoded words
const states = [53]i8{
     -1,  -3, -33,  -5, -15,  -7,  -9, 116, 111, -11, 115, -13, 117, 119,
    118, -17, -31, -19, -21, 109, 100, -23, 103, 102, -25, 122, -27, -29,
    106, 113, 120, 108, 114, -35, -41,  30, -37, -39, 105, 104,  99, -43,
    -51, 110, -45, -47, -49, 112, 107,  98, 121,  97, 101,
};

fn next(c: *u8, offset: usize) usize {
    var n = offset;
    var state: u8 = 0;
    while (states[state] < 0) : (n += 1) {
        const b = @intCast(i32, words[n >> 5] >> @truncate(u5, n) & 1);
        state = @intCast(u8, b - states[state]);
    }

    c.* = @intCast(u8, states[state]);
    return n;
}

fn lookup(buf: []u8, target: usize) [:0x1e]u8 {
    var n: usize = 0;
    var c: u8 = 0;

    // skip ahead
    var word_count: u32 = 0;
    while (word_count < target) : ({ c = 0; word_count += 1; }) {
        while (c != 0x1e) {
            n = next(&c, n);
        }
    }

    // write word to buffer
    var i: u8 = 0;
    while (c != 0x1e) : (i += 1) {
        n = next(&c, n);
        buf[i] = c;
    }
    return buf[0 .. i - 1 :0x1e];
}

pub fn main() !u8 {
    const seed = @truncate(u64, @bitCast(u128, std.time.nanoTimestamp()));

    var prng_state = std.rand.DefaultPrng.init(seed);
    const prng = prng_state.random();

    // each word has a maximum length of 14 (13 + 1 record separator);
    // a buffer of length 32 is enough to keep both words
    var buf = [_]u8{0} ** 32;

    // randomly lookup two words from the wordlist
    // (it's actually two concatenated wordlists with lengths 108 and 236)
    const left = lookup(buf[0..], prng.uintLessThan(u16, 108));
    const right = lookup(buf[16..], 108 + prng.uintLessThan(u16, 236));

    var buf2: [64]u8 = undefined;
    const path = try std.fmt.bufPrint(buf2[0..], "/tmp/{s}-{s}", .{ left, right });

    std.os.mkdir(path, 0o700) catch |e| {
        try stderr.print("could not create directory: {}\n", .{e});
        return 1;
    };

    try stdout.print("{s}\n", .{path});
    return 0;
}

test "valid lookup" {
    var buf = [_]u8{0} ** 16;

    try expectEqualStrings("admiring", lookup(buf[0..], 0));

    try expectEqualStrings("boring", lookup(buf[0..], 10));
    try expectEqualStrings("wozniak", lookup(buf[0..], 338));
}
