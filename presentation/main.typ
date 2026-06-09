#import "@preview/touying:0.7.4": *
#import themes.university: *
// #import "@preview/codly:1.3.0": *
// #import "@preview/codly-languages:0.1.10": *
#import "@preview/numbly:0.1.0": numbly
#import "@preview/callisto:0.2.5"
#import "@preview/pinit:0.2.2": *
#import "@preview/fletcher:0.5.8"
#import "@preview/tiaoma:0.3.0"

// #show: codly-init.with()

#show: university-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [ZK From Scratch],
    subtitle: [build a zk-STARK with minimal external libraries],
    author: [314552031 陳宏彰],
    date: datetime(year: 2026, month: 06, day: 09),
    // logo: emoji.school,
  ),
)

#let (render, Cell, In, Out) = callisto.config(
  nb: json("./demo.ipynb"),
  template: "plain",
)

#let primary = rgb("#04364A")
#let secondary = rgb("#176B87")
#let tertiary = rgb("#448C95")
#let neutral-lightest = rgb("#ffffff")
#let neutral-darkest = rgb("#000000")

#set text(font: "Noto Sans CJK TC", lang: "zho")
// #set text(font: "jf open 粉圓 2.1", lang: "zho")
#set heading(numbering: numbly("{1}.", default: "1.1"))
#show table.cell.where(y: 0): set text(weight: "bold", fill: white)

#let F(x) = $FF_(#x)^*$

#let theorem(body) = box(fill: rgb("#448C95"), radius: 10pt, inset: 20pt, width: 100%)[
  #text(fill: white)[
    #body
  ]
]

#let note(content) = text(size: 20pt, fill: secondary)[Note: #content]

#let mytable(columns, ..content) = table(
  columns: columns,
  inset: 8pt,
  stroke: 0.5pt + rgb("#CCCCCC"),
  fill: (x, y) => {
    if y == 0 {
      rgb("#04364A") // Primary: 標題列
    } else if calc.rem(y, 2) == 0 {
      rgb("#F7F9FA") // 白色系：偶數列背景
    } else {
      rgb("#E8F1F3") // Secondary 的極淡背景色：奇數列背景
    }
  },
  ..content
)

#let pinto(pin-name, body, ..args) = pinit-point-from(pin-name, fill: primary, ..args)[
  #text(fill: primary)[#body]
]

#title-slide()

// #components.adaptive-columns(outline(indent: 1em))
// #outline()

---

#align(center)[
  #figure(
    tiaoma.qrcode("https://github.com/simbafs/zk-STARK", height: 90%),
    caption: [#link("https://github.com/simbafs/zk-STARK")[https://github.com/simbafs/zk-STARK]]
  )
]

---

= Zero Knowledge?

// == Zero Knowledge: know nothing
//
// Prover claims that it has something (e.g. the trace) and it obeys some constraints (VM). Verifier can verify the claim without knowing the trace.
//
// #figure(
//   image("./image/zk-arch.svg"),
//   caption: "ZK architecture",
// )

== Types of ZK

#mytable(
  (0.7fr, 1fr, 1fr),
  table.header([], [zk-SNARK], [zk-STARK]),
  [cryptographic support], [elliptic curve, pairings], [hash functions],
  [trusted setup], [yes], [no],
  [prove size], [small, $O(1)$], [\~100KiB, $O(log(n))$],
  [verifier costs (gas on chain)], [low], [high],
  [quantum resistance], [no], [yes (by changing the hash function)],
)

= Finite Field
== Finite Field
All operations are performed in a finite field $FF_M$
 
$
FF_5 = {0,1,2,3,4} \
1 + 2 = 3 (mod 5) \
2 times 4 = cancel(8) = 3 (mod 5)
$

== Generator

A generator is an element of #F(5) and its powers generate all the elements in #F(5) 

#alternatives[
  #Cell(0)
][
  #figure(
    image("./image/finite_field.svg", 
    height: 70%),
    caption: [#F(5) with generator 2],
  )
]




= The VM

- 2 registers `reg1` and `reg2`
- 4+1 operations: `set`, `swap`, `add`, `mul` and `nop`

#pause

For example $(1 +2) times 3 + 6$ is compiled into
```
set 1 // reg2 = 1
swap  // reg1, reg2 = reg2, reg1
set 2 // reg2 = 2
add   // reg1 = reg1 + reg2
set 3 // reg2 = 3
mul   // reg1 = reg1 * reg2
set 6 // reg2 = 6
add   // reg1 = reg1 + reg2
```

---

after executing the program, the trace is

#mytable(
  (1fr, )*8,
  table.header([reg1], [reg2], [input], [set], [swap], [add], [mul], [nop]),
  [0], [0], [1], [1], [0], [0], [0], [0],
  [0], [1], [0], [0], [1], [0], [0], [0],
  [1], [0], [2], [1], [0], [0], [0], [0],
  [1], [2], [0], [0], [0], [1], [0], [0],
  [3], [2], [4], [1], [0], [0], [0], [0],
  [3], [4], [0], [0], [0], [0], [1], [0],
  [12], [4], [6], [1], [0], [0], [0], [0],
  [12], [6], [0], [0], [0], [1], [0], [0],
  [18], [6], [0], [0], [0], [0], [0], [1],
)

---

= What is in the Proof?

== The Merkle Roots of the Trace Polynomials

#v(50pt)

1. Use Lagrange interpolation to find the polynomials that pass through the points in domain $GG$, where $GG subset FF_M$, $f_"reg1" (x)$, $f_"reg2" (x)$, $f_"input" (x)$ etc.
$ f_"reg1" (g^i) =  "reg1"[i] $
#pause
2. Evaluate those $f_k (x)$ in a larger domain $LL$
#pause
3. Generate Merkle trees for those values and commit the root to the verifier.

== The Trace Size

The trace size $N$ can be used to construct the vanish polynomials
$ u_k (x) = product_(g in GG_k) (x - g) $
where $G_k$ is the domain of $c_k (x)$, which are public parameters. 

= How to Verify

== Challenge Initialization

The verify randomly chooses some number $beta_k$. #pause Prover then constructs the composition polynomial
$ p(x) = sum_k beta_k (c_k (x))/(u_k (x)) $
#pause
Then commit the Merkle root of $p(x)$ in $LL$ to the verifier.

== Check the composition polynomial

The verifier then generates a sequence of $z in LL$, and the prover responses $p(z)$ and $c_k (z)$. The verifier can check if $ p(z) = sum_k beta_k (c_k (z))/(u_k (z)) $ 

#theorem[
  $ c_"r1_add" (x) = f_"add" (x) dot (f_"r1" (x dot g) - (f_"r1" (x) + f_"r2" (x))) = 0 forall x in GG_k $
  $ u_k (x) = Pi_(g in GG_k) (x-g) = 0 forall x in GG_k $
]

#note[The verifier can calculate $u_k (z)$ by itself]

== Check the degree of $p(x)$
// In the previous step, the prover can cheat by constructing a high degree polynomial that can pass the check and modify some points in the trace. So the verifier need to check the degree of $p(x)$ is less than some threshold.

// #pause
1. The verifier randomly chooses some $alpha_j$ and some $z in LL$
#pause
2. The prover uses FRI protocol #footnote[Fast Reed-Solomon Interactive Oracle Proof of Proximity] to fold $p(x)$ into a constant
#pause
3. The verifier checks if the folding is correct and the final constant is identical among all input $z$

// == Why Check Low Degree? 
// A valid $p(x)$ will have a maximum degree (in this VM, it it $2N-3$). If the prover want to cheat and pass the first check, it need to construct a high degree polynomial, because high polynomial degree gives high degrees of freedom.

= Thanks for Listening!


#show: appendix

= Non-Interactive

replace all randomly sampled values with hash

#figure(
  image("./image/Fiat–Shamir-heuristic.svg", height: 50%),
  caption: "Fiat–Shamir heuristic",
)

then the prover can generate $z$, $alpha_j$ and $beta_k$ by itself and generate the proof. 

= Constraints

$GG_k$ is $GG$
- $"set" dot ("set" - 1)$
- $"swap" dot ("swap" - 1)$
- $"add" dot ("add" - 1)$
- $"mul" dot ("mul" - 1)$
- $"nop" dot ("nop" - 1)$
- $"add" + "mul" + "nop" + "set" + "swap" - 1$
- $"input" dot (1 - "set")$

$GG_k$ is $GG$ except the last element
- $"set" dot ("r1_next" - "r1_curr")$
- $"set" dot ("r2_next" - "input")$
- $"swap" dot ("r1_next" - "r2_curr")$
- $"swap" dot ("r2_next" - "r1_curr")$
- $"add" dot ("r1_next" - ("r1_curr" + "r2_curr"))$
- $"add" dot ("r2_next" - "r2_curr")$
- $"mul" dot ("r1_next" - "r1_curr" dot "r2_curr")$
- $"mul" dot ("r2_next" - "r2_curr")$
- $"nop" dot ("r1_next" - "r1_curr")$
- $"nop" dot ("r2_next" - "r2_curr")$

$GG_k$ is the first element in $GG$
- $"r1_curr" - "r"1_"first"$
- $"r2_curr" - "r"2_"first"$

= Finite Field

#slide(repeat: 4, self => [
  #let (uncover, only, alternatives) = utils.methods(self)

  #meanwhile
  A finite field $FF$ is a set of elements with two operations (addition and multiplication). After performing the operations, the result is still in the set.

  $ FF = {0,1,2,3,4} $
  #only("1")[
    $ 1 + 2 = 3 $
    $ 2 times 4 = cancel(8) = 3 $
  ]
  #only("2")[
    How about minus and division?
    $
      1 - 2 = ? \
      1 div 2 = ? \
    $
  ]
  #only("3")[
    $
      1 - 2 = x \
      1 = 2 + x\
      stretch(=>)^(mod 5) 1 + 5 = 6 = 2 + x \
      => x = 4\
      => bold(1 - 2 = 4)
    $
  ]
  #only("4")[
    $
      1 div 2 = y \
      1 = 2 times y \
      stretch(=>)^(mod 5) 1 + 5 = 6 = 2y \
      => y = 3\
      => bold(1 div 2 = 3)
    $
  ]
])

= Fermat's Little Theorem

#theorem[
  If $p$ is not divisor of $a$, then
  $ a^(p-1) = 1 (mod p) $
]

If $p$ is a prime, the theorem holds for all $a$ in #F([p]). Then all elements can be generated by a single element $g$ (generator) by performing multiplication.

#Cell(0)

== Subgroups of $FF$
A subgroup $GG$ of $FF$ is a subset of $FF$ that is closed under the operations. For example, if we take the generator $g=2$ in $FF_17$, we can generate a subgroup $GG$ with 8 elements:

#Cell(1)

---

$ M = 2^(2^k) + 1 $
- Goldilocks Field: $M = 2^64 - 2^32 + 1$
- Mini Goldilocks Field: $M = 2^31 - 2^27 + 1$
- Fermat Primes: 3, 5, 17, 257, 65535
pros:
- size of #F([]) can be divided by many powers of 2
- can accelarate some operations like modulo

== How to choose a proper $GG$?
Support we want to choose a subgroup with size $N = 4$ in #F(17). First we need to know one of the generator of #F(17), which is $omega = 3$. Then with the following fomula, we will get the generator of $GG$
$ g = omega^((M-1)/N) = 3^(16/4) = 13 (mod 17) $

#Cell(2)

= Factor Throrem

#theorem[
  If $a$ is the root of a polynomial $f(x)$, then $f(x)$ can be divided by $x-a$ without remainder.
]
$
  f(x) = x^3 -9x^2 + 26x - 24 \
  f(2) = f(3) = f(4) = 0\
  => f(x)/(x-2) = x^2 - 7x -5 \
  => f(x)/(x-5) = x^2 - 4x + 6 ... #pin(1) 6 #pin(2)
$
#pinto((1, 2))[not divisible]

= Interpolation theorem

#theorem[
  For any $n+1$ data points $(x_i, y_i), i=0,1,...,n$, there exists a unique polynomial $f(x)$ with degree at most $n$ such that $f(x_i) = y_i$ for all $i$.
]

In other words, if a polynomial has degree higher than $n$, it has extra degrees of freedom to pass other points. 

TODO: a graph here

= Generate the Proof

== The Finite Field
- #F(65537)
- $omega = 3$
- size is $63356 = 2^16$

== Trace Polynomials

Then find polynomials that output each column of the trace when evaluated in $GG$ (a subgroup of $FF$). First we need to expand the length of trace to the size of $GG$ (16) by adding `nop` at the end.

$
  g = 64,
  GG = [1, 64, 4096, 65533, 65281, 49153, 16, 1024, \
    65536, 65473, 61441, 4, 256,16384, 65521, 64513] \
$

$f_"reg1" (g^i) = "reg1"[i]$

$f_"reg2" (g^i) = "reg2"[i]$

$f_"input" (g^i) = "input"[i]$

#math.dots.v


---

= Polynomial Commitment

Prover then evaluates $f_k (x)$ in a larger subgroup $LL$ with generator $h$ and generate Merkle trees for those values. Then commit the root of the Merkle tree to the verifier so that verifier can check the values get from prover with Merkle proof in the following steps.

#fletcher.diagram(
  spacing: (5pt, 20pt),
  // debug: true,

  // Nodes
  fletcher.node((2, 0), [$root_k$], name: <tree_a>),
  fletcher.node((0.5, 1), [hash], name: <tree_b>),
  fletcher.node((3.5, 1), [hash], name: <tree_c>),

  fletcher.node((0, 2), [hash($f_k (h^0)$)], name: <tree_d>),
  fletcher.node((1, 2), [hash($f_k (h^1)$)], name: <tree_e>),

  fletcher.node((2, 2), [#math.dots], stroke: none),

  fletcher.node((3, 2), [hash($f_k (h^(n-2))$)], name: <tree_f>),
  fletcher.node((4, 2), [hash($f_k (h^(n-1))$)], name: <tree_g>),

  // Edges
  fletcher.edge(<tree_a>, <tree_b>),
  fletcher.edge(<tree_a>, <tree_c>),
  fletcher.edge(<tree_b>, <tree_d>),
  fletcher.edge(<tree_b>, <tree_e>),
  fletcher.edge(<tree_c>, <tree_f>),
  fletcher.edge(<tree_c>, <tree_g>),
)

= Constraints Polynomials

Now we need to add constraints to the columns of trace. For example, if the `add[i]` is `1`, then `reg1[i+1] = reg1[i] + reg2[i]`.

$
  f_"reg1" (#pin(4)x dot g#pin(5)) = f_"reg1" (x) + f_"reg2" (x) \
  \
  \
  => c_"reg1_add" (x) = f_"add" (x) dot (f_"reg1" (x dot g) - (f_"reg1" (x) + f_"reg2" (x))) \
  c_"reg2_add" (x) = f_"add" (x) dot (f_"reg2" (x dot g) - f_"reg2" (x)) #pin(3) \
$

#pinto((4, 5), offset-dy: 20pt)[$x dot g$ is the next element in $GG$] \
#pinto(3, body-dx: -270pt)[`reg2` should not change when `add`] 

#theorem[
  $c_k (x) = 0 forall x in GG'$, where $GG'$ is the domain of the polynomial
]

the control columns also need to be constrained. 

$ c_"add" (x) = #pin(1) f_"add" (x) dot (f_"add" (x) - 1) #pin(2) $

#pinto((1, 2))[`add` should be either 0 or 1] \

$ c_"one_hot" (x) = #pin(3)f_"set" (x) + f_"swap" (x) + f_"add" (x) + f_"mul" (x) + f_"nop" (x)#pin(4) $ 

#pinto((3, 4), body-dx: -200pt)[exactly one of the operations should be 1] \

The initial state needs be be constrained as well.

$
c_"reg1_init" (x) = f_"reg1" (x) - 0 \
c_"reg2_init" (x) = f_"reg2" (x) - 0 \
$

Each constraint polynomial has its own domain, which is a subset of $GG$. In this VM, it can be categorized into three groups:

#mytable(
  (0.3fr, 1fr, 1fr),
  table.header([group], [polynomials], [description]),
  [all], [$f_"one_hot" (x)$, $f_"add" (x)$ etc.], [domain is all elements in $GG$],
  [first], [$f_"reg1_init" (x)$ and $f_"reg2_init" (x)$], [only the first element],
  [trans], [$f_"r1_add" (x)$, $f_"r1_mul" (x)$ etc.], [except the last one element],
)

#note[verifier can calculate the value of those constraint polynomials once the prover commits the roots of the trace polynomials.]

= Vanish Polynomials

Vanish polynomials are used to make sure that the prover constructs the constraint polynomials correctly. 

$ u_k (x) = product_(g in GG') (x-g) $

#note[verifier constructs the vanish polynomials by itself, so the prover cannot cheat by constructing a wrong vanish polynomial.]

= Composition Polynomial

$ p(x) = (c(x))/(u(x)) $

In $GG'$, $u(x) = 0$, but $c(x) = 0$, too. They can cancel each other out, so $p(x)$ still a good polynomial. However if the prover cheats on the constraint polynomials, for example $c(z) != 0, z in GG'$, $c(x)$ can not be divided by $u(x)$ anymore and verifier can easily check it. 

#pause 
$ p(x) = sum_k beta_k (c_k (x))/(u_k (x)) $

#note[prover needs to commit the composition polynomial as well]

---


= FRI

#theorem[
  $
    p_k (z) &= g_k (z^2) + z dot h_k (z^2) \
  => p_(k+1) (z) &= g_k (z) + alpha_k dot h_k (z)
  $
  $alpha_k$ is a random number generated by the verifier.
]

to check if $p_(k+1) (z)$ is correct
$
cases(
p_k (z) &= g_k (z^2) + z dot h_k (z^2),
p_k (-z) &= g_k (z^2) - z dot h_k (z^2)
) => cases(
  g_k(z^2) =^? (p_k (z) + p_k (-z))/2,
  h_k(z^2) =^? (p_k (z) - p_k (-z)) / (2z)
)
$

== layer 0

$
p_0 (z) &= a z^4 + b z^3 + c z^2 + d z + e \
&= underbrace((a z^4 + c z^2 + e), g_0(z') = a z'^2 + c z' + e) + z dot underbrace((b z^2 + d ), h_0 (z') = b z' + d) \
\
=> p_1(z') &= g_0 (z') + alpha_0 dot h_0 (z') \
&= a z'^2 + (c + alpha_0 b) z' + (e + alpha_0 d) \
$

== layer 1

$
p_1 (z') &= a z'^2 + (c + alpha_0 b) z' + (e + alpha_0 d) \
&= underbrace((a z'^2 + e + alpha_0 d), g_1(z'') = a z'' + e + alpha_0 d) + z' dot underbrace((c + alpha_0 b), h_1 (z'') = c + alpha_0 b) \
\
=> p_2 (z'') &= g_1 (z'') + alpha_1 dot h_1 (z'') \
&= a z'' + (e + alpha_0 d + alpha_1 c + alpha_0 alpha_1 b)
$

== layer 2

$
p_2 (z'') &= a z'' + (e + alpha_0 d + alpha_1 c + alpha_0 alpha_1 b) \
&= underbrace((e + alpha_0 d + alpha_1 c + alpha_0 alpha_1 b), g_2 (z''') = e + alpha_0 d + alpha_1 c + alpha_0 alpha_1 b) + z'' dot underbrace(a, h_2 (z''') = a) \
\
=> p_3 (z''') &= g_2 (z''') + alpha_2 dot h_2 (z''') \
&= #pin(1)e + alpha_0 d + alpha_1 c + alpha_0 alpha_1 b + alpha_2 a#pin(2) \
$

#pinto((1, 2), offset-dx: -200pt)[constant, no matter chooseing what $z$]



== References

- Berentsen, Aleksander and Lenzi, Jeremias and Nyffenegger, Remo, A Walk-through of a Simple Zk-STARK Proof (December 21, 2022).
- Wikipedia for theorems
- Gemini
- ChatGPT
