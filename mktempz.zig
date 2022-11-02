const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

// The following wordlists copied verbatim from moby/moby's pkg/namesgenerator,
// and as such shall carry the following license and copyright notice:
//
// Copyright 2013-2018 Docker, Inc.
// Licensed under the Apache License, Version 2.0
// You may obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0
const left = [_][]const u8{
    "admiring",   "adoring",    "affectionate",  "agitated",   "amazing",       "angry",       "awesome",
    "beautiful",  "blissful",   "bold",          "boring",     "brave",         "busy",        "charming",
    "clever",     "cool",       "compassionate", "competent",  "condescending", "confident",   "cranky",
    "crazy",      "dazzling",   "determined",    "distracted", "dreamy",        "eager",       "ecstatic",
    "elastic",    "elated",     "elegant",       "eloquent",   "epic",          "exciting",    "fervent",
    "festive",    "flamboyant", "focused",       "friendly",   "frosty",        "funny",       "gallant",
    "gifted",     "goofy",      "gracious",      "great",      "happy",         "hardcore",    "heuristic",
    "hopeful",    "hungry",     "infallible",    "inspiring",  "intelligent",   "interesting", "jolly",
    "jovial",     "keen",       "kind",          "laughing",   "loving",        "lucid",       "magical",
    "mystifying", "modest",     "musing",        "naughty",    "nervous",       "nice",        "nifty",
    "nostalgic",  "objective",  "optimistic",    "peaceful",   "pedantic",      "pensive",     "practical",
    "priceless",  "quirky",     "quizzical",     "recursing",  "relaxed",       "reverent",    "romantic",
    "sad",        "serene",     "sharp",         "silly",      "sleepy",        "stoic",       "strange",
    "stupefied",  "suspicious", "sweet",         "tender",     "thirsty",       "trusting",    "unruffled",
    "upbeat",     "vibrant",    "vigilant",      "vigorous",   "wizardly",      "wonderful",   "xenodochial",
    "youthful",   "zealous",    "zen",
};

const right = [_][]const u8{
    "agnesi",     "albattani",     "allen",        "almeida",       "antonelli",  "archimedes",   "ardinghelli", "aryabhata",  "austin",
    "babbage",    "banach",        "banzai",       "bardeen",       "bartik",     "bassi",        "beaver",      "bell",       "benz",
    "bhabha",     "bhaskara",      "black",        "blackburn",     "blackwell",  "bohr",         "booth",       "borg",       "bose",
    "bouman",     "boyd",          "brahmagupta",  "brattain",      "brown",      "buck",         "burnell",     "cannon",     "carson",
    "cartwright", "carver",        "cerf",         "chandrasekhar", "chaplygin",  "chatelet",     "chatterjee",  "chaum",      "chebyshev",
    "clarke",     "cohen",         "colden",       "cori",          "cray",       "curran",       "curie",       "darwin",     "davinci",
    "dewdney",    "dhawan",        "diffie",       "dijkstra",      "dirac",      "driscoll",     "dubinsky",    "easley",     "edison",
    "einstein",   "elbakyan",      "elgamal",      "elion",         "ellis",      "engelbart",    "euclid",      "euler",      "faraday",
    "feistel",    "fermat",        "fermi",        "feynman",       "franklin",   "gagarin",      "galileo",     "galois",     "ganguly",
    "gates",      "gauss",         "germain",      "goldberg",      "goldstine",  "goldwasser",   "golick",      "goodall",    "gould",
    "greider",    "grothendieck",  "haibt",        "hamilton",      "haslett",    "hawking",      "hellman",     "heisenberg", "hermann",
    "herschel",   "hertz",         "heyrovsky",    "hodgkin",       "hofstadter", "hoover",       "hopper",      "hugle",      "hypatia",
    "ishizaka",   "jackson",       "jang",         "jemison",       "jennings",   "jepsen",       "johnson",     "joliot",     "jones",
    "kalam",      "kapitsa",       "kare",         "keldysh",       "keller",     "kepler",       "khayyam",     "khorana",    "kilby",
    "kirch",      "knuth",         "kowalevski",   "lalande",       "lamarr",     "lamport",      "leakey",      "leavitt",    "lederberg",
    "lehmann",    "lewin",         "lichterman",   "liskov",        "lovelace",   "lumiere",      "mahavira",    "margulis",   "matsumoto",
    "maxwell",    "mayer",         "mccarthy",     "mcclintock",    "mclaren",    "mclean",       "mcnulty",     "mendel",     "mendeleev",
    "meitner",    "meninsky",      "merkle",       "mestorf",       "mirzakhani", "montalcini",   "moore",       "morse",      "murdock",
    "moser",      "napier",        "nash",         "neumann",       "newton",     "nightingale",  "nobel",       "noether",    "northcutt",
    "noyce",      "panini",        "pare",         "pascal",        "pasteur",    "payne",        "perlman",     "pike",       "poincare",
    "poitras",    "proskuriakova", "ptolemy",      "raman",         "ramanujan",  "ride",         "ritchie",     "rhodes",     "robinson",
    "roentgen",   "rosalind",      "rubin",        "saha",          "sammet",     "sanderson",    "satoshi",     "shamir",     "shannon",
    "shaw",       "shirley",       "shockley",     "shtern",        "sinoussi",   "snyder",       "solomon",     "spence",     "stonebraker",
    "sutherland", "swanson",       "swartz",       "swirles",       "taussig",    "tesla",        "tharp",       "thompson",   "torvalds",
    "tu",         "turing",        "varahamihira", "vaughan",       "villani",    "visvesvaraya", "volhard",     "wescoff",    "wilbur",
    "wiles",      "williams",      "williamson",   "wilson",        "wing",       "wozniak",      "wright",      "wu",         "yalow",
    "yonath",     "zhukovsky",
};

pub fn main() void {
    const seed = @truncate(u64, @bitCast(u128, std.time.nanoTimestamp()));
    const prng = std.rand.DefaultPrng.init(seed).random();

    const a = prng.uintLessThan(u8, left.len);
    const b = prng.uintLessThan(u8, right.len);

    var buf: [32]u8 = undefined;
    const path = std.fmt.bufPrint(buf[0..], "/tmp/{s}-{s}", .{ left[a], right[b] }) catch unreachable;

    std.os.mkdir(path, 0o700) catch |e| {
        stderr.print("could not create directory: {}\n", .{e}) catch unreachable;
        std.os.exit(1);
    };

    stdout.print("{s}\n", .{path}) catch unreachable;
}
