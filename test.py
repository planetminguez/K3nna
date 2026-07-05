"""
K3nna Test Script — Complex Python Showcase
Tests: dataclasses, threading, queues, regex, JSON, math, recursion,
       decorators, generators, context managers, and more.
"""

import sys
import os
import math
import time
import json
import re
import threading
import queue
import hashlib
import random
import string
import itertools
import functools
from dataclasses import dataclass, field, asdict
from typing import List, Dict, Optional, Tuple, Generator
from collections import defaultdict, Counter, deque
from contextlib import contextmanager


# ── ANSI colours ────────────────────────────────────────────────────────────
class C:
    RED    = "\033[91m"
    GREEN  = "\033[92m"
    YELLOW = "\033[93m"
    CYAN   = "\033[96m"
    BOLD   = "\033[1m"
    RESET  = "\033[0m"

def ok(msg):   print(f"  {C.GREEN}✓{C.RESET} {msg}")
def fail(msg): print(f"  {C.RED}✗{C.RESET} {msg}")
def section(title):
    bar = "─" * 50
    print(f"\n{C.BOLD}{C.CYAN}{bar}{C.RESET}")
    print(f"{C.BOLD}{C.CYAN}  {title}{C.RESET}")
    print(f"{C.BOLD}{C.CYAN}{bar}{C.RESET}")


# ── DATACLASSES ──────────────────────────────────────────────────────────────
@dataclass(order=True)
class Vector3:
    x: float = 0.0
    y: float = 0.0
    z: float = 0.0

    def magnitude(self) -> float:
        return math.sqrt(self.x**2 + self.y**2 + self.z**2)

    def dot(self, other: "Vector3") -> float:
        return self.x*other.x + self.y*other.y + self.z*other.z

    def cross(self, other: "Vector3") -> "Vector3":
        return Vector3(
            self.y*other.z - self.z*other.y,
            self.z*other.x - self.x*other.z,
            self.x*other.y - self.y*other.x,
        )

    def normalize(self) -> "Vector3":
        m = self.magnitude()
        if m == 0:
            return Vector3()
        return Vector3(self.x/m, self.y/m, self.z/m)

    def __repr__(self):
        return f"Vec3({self.x:.3f}, {self.y:.3f}, {self.z:.3f})"


@dataclass
class Task:
    task_id: int
    name: str
    priority: int = 0
    tags: List[str] = field(default_factory=list)
    metadata: Dict[str, str] = field(default_factory=dict)
    completed: bool = False

    def complete(self):
        self.completed = True
        return self


# ── DECORATORS ───────────────────────────────────────────────────────────────
def retry(times=3, delay=0.0):
    def decorator(fn):
        @functools.wraps(fn)
        def wrapper(*args, **kwargs):
            last_exc = None
            for attempt in range(times):
                try:
                    return fn(*args, **kwargs)
                except Exception as e:
                    last_exc = e
                    if delay:
                        time.sleep(delay)
            raise last_exc
        return wrapper
    return decorator


def memoize(fn):
    cache = {}
    @functools.wraps(fn)
    def wrapper(*args):
        if args not in cache:
            cache[args] = fn(*args)
        return cache[args]
    wrapper.cache = cache
    return wrapper


def timer(fn):
    @functools.wraps(fn)
    def wrapper(*args, **kwargs):
        t0 = time.perf_counter()
        result = fn(*args, **kwargs)
        elapsed = time.perf_counter() - t0
        wrapper.last_elapsed = elapsed
        return result
    wrapper.last_elapsed = 0.0
    return wrapper


# ── GENERATORS ───────────────────────────────────────────────────────────────
def fibonacci_gen() -> Generator[int, None, None]:
    a, b = 0, 1
    while True:
        yield a
        a, b = b, a + b


def prime_sieve(limit: int) -> List[int]:
    sieve = bytearray([1]) * (limit + 1)
    sieve[0] = sieve[1] = 0
    for i in range(2, int(limit**0.5) + 1):
        if sieve[i]:
            sieve[i*i::i] = bytearray(len(sieve[i*i::i]))
    return [i for i, v in enumerate(sieve) if v]


@memoize
def fib(n: int) -> int:
    if n < 2:
        return n
    return fib(n-1) + fib(n-2)


# ── CONTEXT MANAGER ──────────────────────────────────────────────────────────
@contextmanager
def benchmark(label: str):
    t0 = time.perf_counter()
    yield
    elapsed = (time.perf_counter() - t0) * 1000
    ok(f"{label}: {elapsed:.2f} ms")


# ── THREADING ────────────────────────────────────────────────────────────────
class WorkerPool:
    def __init__(self, n_workers: int = 4):
        self.n_workers = n_workers
        self.job_queue: queue.Queue = queue.Queue()
        self.result_queue: queue.Queue = queue.Queue()
        self.workers: List[threading.Thread] = []
        self._lock = threading.Lock()
        self._done_count = 0

    def _worker(self):
        while True:
            item = self.job_queue.get()
            if item is None:
                break
            job_id, fn, args = item
            try:
                result = fn(*args)
                self.result_queue.put((job_id, result, None))
            except Exception as e:
                self.result_queue.put((job_id, None, e))
            finally:
                self.job_queue.task_done()

    def start(self):
        for _ in range(self.n_workers):
            t = threading.Thread(target=self._worker, daemon=True)
            t.start()
            self.workers.append(t)

    def submit(self, job_id, fn, *args):
        self.job_queue.put((job_id, fn, args))

    def stop(self):
        for _ in self.workers:
            self.job_queue.put(None)
        for w in self.workers:
            w.join(timeout=5)

    def collect_results(self, count: int) -> List[Tuple]:
        results = []
        for _ in range(count):
            results.append(self.result_queue.get(timeout=10))
        return results


# ── COMPLEX DATA STRUCTURES ──────────────────────────────────────────────────
class LRUCache:
    def __init__(self, capacity: int):
        self.capacity = capacity
        self._cache: Dict = {}
        self._order: deque = deque()

    def get(self, key):
        if key not in self._cache:
            return None
        self._order.remove(key)
        self._order.appendleft(key)
        return self._cache[key]

    def put(self, key, value):
        if key in self._cache:
            self._order.remove(key)
        elif len(self._cache) >= self.capacity:
            evicted = self._order.pop()
            del self._cache[evicted]
        self._cache[key] = value
        self._order.appendleft(key)

    def __len__(self):
        return len(self._cache)


class Trie:
    def __init__(self):
        self.children: Dict[str, "Trie"] = {}
        self.is_end = False

    def insert(self, word: str):
        node = self
        for ch in word:
            node = node.children.setdefault(ch, Trie())
        node.is_end = True

    def search(self, word: str) -> bool:
        node = self
        for ch in word:
            if ch not in node.children:
                return False
            node = node.children[ch]
        return node.is_end

    def starts_with(self, prefix: str) -> bool:
        node = self
        for ch in prefix:
            if ch not in node.children:
                return False
            node = node.children[ch]
        return True


# ── ALGORITHMS ───────────────────────────────────────────────────────────────
def quicksort(arr: List) -> List:
    if len(arr) <= 1:
        return arr
    pivot = arr[len(arr) // 2]
    left   = [x for x in arr if x < pivot]
    middle = [x for x in arr if x == pivot]
    right  = [x for x in arr if x > pivot]
    return quicksort(left) + middle + quicksort(right)


def binary_search(arr: List, target) -> int:
    lo, hi = 0, len(arr) - 1
    while lo <= hi:
        mid = (lo + hi) // 2
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            lo = mid + 1
        else:
            hi = mid - 1
    return -1


def levenshtein(a: str, b: str) -> int:
    m, n = len(a), len(b)
    dp = [[0]*(n+1) for _ in range(m+1)]
    for i in range(m+1): dp[i][0] = i
    for j in range(n+1): dp[0][j] = j
    for i in range(1, m+1):
        for j in range(1, n+1):
            cost = 0 if a[i-1] == b[j-1] else 1
            dp[i][j] = min(dp[i-1][j]+1, dp[i][j-1]+1, dp[i-1][j-1]+cost)
    return dp[m][n]


def matrix_multiply(A, B):
    rows_A, cols_A = len(A), len(A[0])
    cols_B = len(B[0])
    C = [[0]*cols_B for _ in range(rows_A)]
    for i in range(rows_A):
        for j in range(cols_B):
            for k in range(cols_A):
                C[i][j] += A[i][k] * B[k][j]
    return C


# ── REGEX UTILITIES ──────────────────────────────────────────────────────────
EMAIL_RE  = re.compile(r'^[\w.+-]+@([\w-]+\.)+[a-zA-Z]{2,}$')
URL_RE    = re.compile(r'https?://[\w./-]+')
IPV4_RE   = re.compile(r'\b(?:\d{1,3}\.){3}\d{1,3}\b')

def extract_urls(text: str) -> List[str]:
    return URL_RE.findall(text)

def is_valid_email(email: str) -> bool:
    return bool(EMAIL_RE.match(email))


# ── HASHING / CRYPTO ─────────────────────────────────────────────────────────
def sha256(data: str) -> str:
    return hashlib.sha256(data.encode()).hexdigest()

def random_token(length: int = 32) -> str:
    alphabet = string.ascii_letters + string.digits
    return ''.join(random.choices(alphabet, k=length))


# ── MAIN TESTS ───────────────────────────────────────────────────────────────
def run_all_tests():
    print(f"\n{C.BOLD}{C.RED}╔══════════════════════════════════════════════════╗{C.RESET}")
    print(f"{C.BOLD}{C.RED}║       K3NNA  TEST SUITE  —  COMPLEX .PY          ║{C.RESET}")
    print(f"{C.BOLD}{C.RED}╚══════════════════════════════════════════════════╝{C.RESET}")

    errors: List[str] = []

    # ── 1. VECTORS ────────────────────────────────────────────────────────────
    section("1 · Vector3 Math")
    v1 = Vector3(1, 2, 3)
    v2 = Vector3(4, 5, 6)
    cross = v1.cross(v2)
    dot   = v1.dot(v2)
    assert abs(dot - 32.0) < 1e-9,   "dot product"
    assert abs(cross.x - (-3)) < 1e-9, "cross.x"
    ok(f"dot({v1}, {v2}) = {dot}")
    ok(f"cross = {cross}")
    norm = v1.normalize()
    ok(f"normalize({v1}) = {norm}, |n|={norm.magnitude():.6f}")
    assert abs(norm.magnitude() - 1.0) < 1e-9, "normalized magnitude"

    # ── 2. DATACLASSES ────────────────────────────────────────────────────────
    section("2 · Dataclass & JSON Round-trip")
    task = Task(1, "Build K3nna", priority=10, tags=["python","compiler"])
    task.complete()
    d = asdict(task)
    assert d["completed"] is True
    serialised = json.dumps(d, indent=2)
    restored   = json.loads(serialised)
    assert restored["name"] == "Build K3nna"
    ok(f"Task round-trip OK — {len(serialised)} bytes")

    # ── 3. GENERATORS & MEMOIZED FIBONACCI ───────────────────────────────────
    section("3 · Generators & Memoized Fibonacci")
    gen = fibonacci_gen()
    first_10 = [next(gen) for _ in range(10)]
    assert first_10 == [0,1,1,2,3,5,8,13,21,34]
    ok(f"First 10 Fibonacci: {first_10}")

    @timer
    def compute_fib(n):
        return fib(n)

    val = compute_fib(50)
    ok(f"fib(50) = {val}  [{compute_fib.last_elapsed*1000:.3f} ms]")
    ok(f"Memoize cache size: {len(fib.cache)} entries")

    # ── 4. PRIME SIEVE ────────────────────────────────────────────────────────
    section("4 · Prime Sieve")
    with benchmark("sieve(100_000)"):
        primes = prime_sieve(100_000)
    assert primes[:5] == [2, 3, 5, 7, 11]
    ok(f"Primes up to 100,000: {len(primes)} found, last={primes[-1]}")

    # ── 5. SORTING & BINARY SEARCH ────────────────────────────────────────────
    section("5 · Quicksort + Binary Search")
    data = random.sample(range(10_000), 1_000)
    with benchmark("quicksort(1000 elements)"):
        sorted_data = quicksort(data)
    assert sorted_data == sorted(data)
    target = sorted_data[500]
    idx = binary_search(sorted_data, target)
    assert sorted_data[idx] == target
    ok(f"Binary search found {target} at index {idx}")

    # ── 6. MATRIX MULTIPLY ───────────────────────────────────────────────────
    section("6 · Matrix Multiply")
    A = [[1,2,3],[4,5,6],[7,8,9]]
    B = [[9,8,7],[6,5,4],[3,2,1]]
    M = matrix_multiply(A, B)
    assert M[0][0] == 30
    assert M[1][1] == 69
    ok(f"3x3 × 3x3 = {M}")

    # ── 7. STRING EDIT DISTANCE ───────────────────────────────────────────────
    section("7 · Levenshtein Distance")
    pairs = [("kitten","sitting",3),("sunday","saturday",3),("","abc",3),("abc","abc",0)]
    for a, b, expected in pairs:
        d = levenshtein(a, b)
        assert d == expected, f"lev({a!r},{b!r}) expected {expected} got {d}"
        ok(f"lev({a!r}, {b!r}) = {d}")

    # ── 8. LRU CACHE ─────────────────────────────────────────────────────────
    section("8 · LRU Cache")
    lru = LRUCache(3)
    for i in range(5):
        lru.put(i, i*i)
    assert lru.get(0) is None   # evicted first
    assert lru.get(1) is None   # evicted second
    assert lru.get(3) == 9
    assert lru.get(4) == 16
    ok(f"LRU eviction correct, size={len(lru)}")

    # ── 9. TRIE ───────────────────────────────────────────────────────────────
    section("9 · Trie")
    trie = Trie()
    words = ["apple","app","application","apply","banana","band","bandana"]
    for w in words:
        trie.insert(w)
    assert trie.search("apple")
    assert not trie.search("ap")
    assert trie.starts_with("app")
    assert trie.starts_with("ban")
    assert not trie.starts_with("cat")
    ok(f"Trie: {len(words)} words inserted, lookups pass")

    # ── 10. REGEX ─────────────────────────────────────────────────────────────
    section("10 · Regex Validation")
    valid_emails = ["user@example.com","a.b+c@domain.co.uk"]
    bad_emails   = ["notanemail","@missing.com","double@@bad.com"]
    for e in valid_emails:
        assert is_valid_email(e), e
        ok(f"Valid email: {e}")
    for e in bad_emails:
        assert not is_valid_email(e), e
        ok(f"Rejected: {e}")

    text = "Visit https://replit.com or http://python.org for docs"
    urls = extract_urls(text)
    assert len(urls) == 2
    ok(f"Extracted URLs: {urls}")

    # ── 11. HASHING ───────────────────────────────────────────────────────────
    section("11 · Hashing & Tokens")
    h1 = sha256("K3nna")
    h2 = sha256("K3nna")
    h3 = sha256("k3nna")
    assert h1 == h2
    assert h1 != h3
    ok(f"SHA256(K3nna) = {h1[:16]}...")
    tokens = {random_token(16) for _ in range(1000)}
    assert len(tokens) == 1000, "collision in token generation"
    ok(f"Generated 1000 unique tokens")

    # ── 12. COUNTER & DEFAULTDICT ─────────────────────────────────────────────
    section("12 · Counter & defaultdict")
    words_sample = "the quick brown fox jumps over the lazy dog the fox".split()
    counter = Counter(words_sample)
    assert counter["the"] == 3
    assert counter["fox"] == 2
    ok(f"Most common: {counter.most_common(3)}")

    dd = defaultdict(list)
    for i, w in enumerate(words_sample):
        dd[w[0]].append(w)
    ok(f"Words starting with 't': {dd['t']}")

    # ── 13. ITERTOOLS ─────────────────────────────────────────────────────────
    section("13 · itertools")
    combos = list(itertools.combinations("ABCD", 2))
    perms  = list(itertools.permutations([1,2,3]))
    assert len(combos) == 6
    assert len(perms)  == 6
    ok(f"C(4,2)={len(combos)} combinations: {combos[:3]}...")
    ok(f"P(3)={len(perms)} permutations")

    groups = {k: list(v) for k, v in
              itertools.groupby([1,1,2,2,2,3,1,1], key=lambda x: x)}
    ok(f"groupby result: {groups}")

    # ── 14. THREADING ─────────────────────────────────────────────────────────
    section("14 · Thread Worker Pool")
    pool = WorkerPool(n_workers=4)
    pool.start()

    def cpu_task(n):
        return sum(i*i for i in range(n))

    n_jobs = 16
    for i in range(n_jobs):
        pool.submit(i, cpu_task, 1000 * (i+1))

    results = pool.collect_results(n_jobs)
    pool.stop()
    assert len(results) == n_jobs
    ok(f"Completed {n_jobs} parallel jobs across 4 threads")
    sample = next(r for r in results if r[0] == 0)
    ok(f"Job 0 result: sum of squares(1..1000) = {sample[1]}")

    # ── 15. CLASSES & INHERITANCE ─────────────────────────────────────────────
    section("15 · OOP — Inheritance & __slots__")
    class Shape:
        def area(self) -> float: ...
        def __repr__(self): return f"{type(self).__name__}(area={self.area():.2f})"

    class Circle(Shape):
        __slots__ = ("r",)
        def __init__(self, r): self.r = r
        def area(self): return math.pi * self.r**2

    class Rectangle(Shape):
        __slots__ = ("w","h")
        def __init__(self, w, h): self.w, self.h = w, h
        def area(self): return self.w * self.h

    class Triangle(Shape):
        __slots__ = ("a","b","c")
        def __init__(self, a, b, c): self.a, self.b, self.c = a, b, c
        def area(self):
            s = (self.a+self.b+self.c)/2
            return math.sqrt(s*(s-self.a)*(s-self.b)*(s-self.c))

    shapes = [Circle(5), Rectangle(4,6), Triangle(3,4,5)]
    for s in shapes:
        ok(f"{s}")

    total_area = sum(s.area() for s in shapes)
    ok(f"Total area: {total_area:.4f}")

    # ── SUMMARY ───────────────────────────────────────────────────────────────
    section("SUMMARY")
    if errors:
        for e in errors:
            fail(e)
        print(f"\n  {C.RED}{C.BOLD}{len(errors)} test(s) FAILED{C.RESET}\n")
        sys.exit(1)
    else:
        print(f"\n  {C.GREEN}{C.BOLD}All 15 test sections PASSED ✓{C.RESET}\n")
        print(f"  Python {sys.version.split()[0]}  |  "
              f"Platform: {sys.platform}  |  "
              f"PID: {os.getpid()}\n")


if __name__ == "__main__":
    run_all_tests()
