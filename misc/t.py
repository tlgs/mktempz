import collections
import heapq
import itertools
import sys
import textwrap


def huffman(hist):
    heap = [(n, c) for c, n in hist.items()]
    heapq.heapify(heap)
    while len(heap) > 1:
        a, b = heapq.heappop(heap), heapq.heappop(heap)
        node = a[0] + b[0], (a[1], b[1])
        heapq.heappush(heap, node)
    return heap[0][1]


def flatten(tree, prefix=""):
    if isinstance(tree, tuple):
        return flatten(tree[0], prefix + "0") + flatten(tree[1], prefix + "1")
    else:
        return [(tree, prefix)]


def transitions(tree, states, state):
    if isinstance(tree, tuple):
        child = len(states)
        states[state] = -child
        states.extend([None]*2)
        transitions(tree[0], states, child + 0)
        transitions(tree[1], states, child + 1)
    else:
        states[state] = ord(tree)
    return states


def batched(iterable, n):
    if n < 1:
        raise ValueError("n must be at least one")

    it = iter(iterable)
    while batch := list(itertools.islice(it, n)):
        yield batch


def main():
    words = [w.strip() + "\x1e" for w in sys.stdin]
    hist = collections.Counter(itertools.chain(*words))

    tree = huffman(hist)
    codes = dict(flatten(tree))

    bits = "".join("".join(codes[c] for c in w) for w in words)
    u32 = [int(b[::-1], 2) for b in textwrap.wrap(bits, width=32)]

    print(f"const words = [{len(u32)}]u32{{")
    for us in batched(u32, 6):
        print("   ", *[f"{u:#010x}," for u in us])
    print("};")

    states = transitions(tree, [None], 0)

    print(f"\nconst states = [{len(states)}]i8{{")
    for ss in batched(states, 12):
        f = lambda x: f" '{chr(x)}'" if x > 96 else f"{x:#04x}" if x > 0 else x
        print("   ", *[f"{f(s):>4}," for s in ss])
    print("};")


if __name__ == "__main__":
    raise SystemExit(main())
