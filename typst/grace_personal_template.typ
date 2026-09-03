#import "@preview/rose-pine:0.2.1": apply, rose-pine-moon

#let dt(date_str) = {
  let parts = date_str.split("-")
  datetime(
    year: int(parts.at(0)),
    month: int(parts.at(1)),
    day: int(parts.at(2))
  )
}

#let grace_header_block(
  title: str,
  subtitle: str,
  course: str,
  author: str,
  date: datetime,
  text-color: color,
  font-size: length,
  header-color: color,
) = block[
  #rect(
    width: 100%,
    height: auto,
    fill: header-color,
    radius: .5em,
    stroke: none,
    inset: (x: 1em, y: 0em),
    [
      #set align(center + horizon)
      #set text(fill: text-color, size: font-size, weight: "medium")
      #v(1em)
      #grid(
        columns: (1fr),
        rows: (auto, auto, auto),
        row-gutter: 1em,
        [
          #set text(size: font-size + 8pt, weight: "bold")
          #title
        ],
        [
          #if subtitle != none [
            #set text(size: font-size + 4pt, weight: "light", style: "italic")
            #subtitle
          ]
        ],
        [
          #set text(size: font-size + 2pt, weight: "regular")
          #v(2em)
          #grid(
            columns: (1fr, 1fr, 1fr),
            align: (left, center, right),
            [#if author != none [#author]],
            [#if course != none [#course]],
            [#date.display("[month repr:long] [day padding:none], [year]")]
          )
          #v(1em)
        ]
      )
    ]
  )
]




#let grace_template(
  title: "Document Title",
  author: "Grace Yoder",
  subtitle: none,
  course: none,
  date: datetime.today(),
  header-color: rose-pine-moon.overlay,
  footer-color: rose-pine-moon.overlay,
  text-color: white,
  font-size: 11pt,
  in_outline: bool,
  doc
) = {
  set document(title: title, author: author, date: date)
  set page(
    paper: "us-letter",
    margin: (top: 2.2cm, bottom: 2.2cm, left: 2cm, right: 2cm),
    header: context {
      set text(fill: text-color, size: font-size, style: "italic")
      let page-num = counter(page).get().first()

      if page-num != 1 {
        rect(
          width: 100%,
          height: .8cm,
          fill: header-color,
          radius: .5em,
          stroke: none,
          inset: (x: 1em, y: 0em),
          [
            #set align(center + horizon)
            #grid(
              columns: (1fr, auto),
              align: (left + horizon, right + horizon),
              [#title],
              [#date.display("[year].[month].[day]")]
            )
          ]
        )
      }
    },
    footer: [
      #set text(fill: text-color, size: font-size, style: "italic")
      #rect(
        width: 100%,
        height: 0.8cm,
        fill: footer-color,
        radius: .5em,
        stroke: none,
        inset: (x: 1em, y: 0em),
        [
          #set align(center + horizon)
          #grid(
            columns: (1fr, auto),
            align: (left + horizon, right + horizon),
            [#if author != none [#author] else []],
            [#context counter(page).display()]
          )
        ]
      )
    ]
  )
  set text(font: "Montserrat", size: 11pt)
  set par(justify: true, leading: 0.75em)
  show math.equation: set text(font: "Fira Math", fallback: false)

  set raw(theme: rose-pine-moon.codeThemePath)
  show raw: it => [
    #set text(fill: rose-pine-moon.text)
    #block(
      fill: rose-pine-moon.overlay,
      inset: 8pt,
      radius: 5pt,
      breakable: true,

      it
    )
  ]

  show heading.where(level: 1): it => [
    #set text(size: 18pt, weight: "bold")
    #pad(top: 1.2em, bottom: 0.6em)[#it]
  ]
  show heading.where(level: 2): it => [
    #set text(size: 15pt, weight: "bold")
    #pad(top: 1em, bottom: 0.4em)[#it]
  ]
  show heading.where(level: 3): it => [
    #set text(size: 13pt, weight: "bold")
    #pad(top: 0.8em, bottom: 0.3em)[#it]
  ]
  place(top + center, dy: -1.5cm,
    grace_header_block(
      title: title,
      subtitle: subtitle,
      author: author,
      course: course,
      date: date,
      text-color: text-color,
      font-size: font-size,
      header-color: header-color,
    )
  )
  if in_outline == true {
    set heading(outlined: false)
    show heading.where(outlined: true): set text(size: 100pt)
    place(
      dx: -200%,
      dy: -20%,
      heading(outlined: true, )[#title]
    )
  }
  v(7em)
  doc
}


#import "@preview/zero:0.6.0": num, set-num, format-table, ztable, zi, nonum

#let page_num_function(cur: num, last: num) = {
  [Page #cur of #last]
}

#let ecet227_report(
  title: str,
  week: num,
  course: "ECET 227",
  prof: "Professor Weissbach",
  author: "Grace Yoder",
  ymd: (num, num, num),
  section: "Monday 11:30",
  doc
) = {
  set heading(numbering: "1.1 ")
  set text(font: "Times New Roman", size: 12pt)
  set image(width: 80%)
  show ref: it => strong(it)
  show figure.caption: it => context [
    *#it.supplement~#it.counter.display()#it.separator*#it.body
  ]
  show figure.where(kind: table): set figure.caption(position: top)
  let date = datetime(year: ymd.at(0), month: ymd.at(1), day: ymd.at(2))
  set grid(column-gutter: 15pt)
  set page(
    margin: (
      top: 1.7in,
      bottom: 1in,
      left: 1in,
      right: 1in,
    ),
    paper: "us-letter",
    header: {
      set text(size: 10pt)
      v(5pt)
      set par(spacing: .8em)
      align(right)[
        #author

        #course

        #prof

        #week: #title

        #section

        #date.display("[month repr:long] [day], [year]")
      ]
      v(-15pt)
    },
    footer: context {
      align(center)[Page #counter(page).display() of #counter(page).final().first()]
    },
  )

  // set-num(
  //   exponent: "eng"
  // )

  doc
}

// For usage in ztables
#let t = (
  // Volt
  Tv: nonum[TV],
  Gv: nonum[GV],
  Mv: nonum[MV],
  kv: nonum[kV],
  v: nonum[V],
  mv: nonum[mV],
  uv: nonum[#sym.mu\V],
  nv: nonum[nV],
  pv: nonum[pV],

  // Volt rms
  Tvrms: nonum[TV#sub[rms]],
  Gvrms: nonum[GV#sub[rms]],
  Mvrms: nonum[MV#sub[rms]],
  kvrms: nonum[kV#sub[rms]],
  vrms: nonum[V#sub[rms]],
  mvrms: nonum[mV#sub[rms]],
  uvrms: nonum[#sym.mu\V#sub[rms]],
  nvrms: nonum[nV#sub[rms]],
  pvrms: nonum[pV#sub[rms]],

  // Volt peak
  Tvp: nonum[TV#sub[p]],
  Gvp: nonum[GV#sub[p]],
  Mvp: nonum[MV#sub[p]],
  kvp: nonum[kV#sub[p]],
  vp: nonum[V#sub[p]],
  mvp: nonum[mV#sub[p]],
  uvp: nonum[#sym.mu\V#sub[p]],
  nvp: nonum[nV#sub[p]],
  pvp: nonum[pV#sub[p]],

  // Volt p to p
  Tvpp: nonum[TV#sub[pp]],
  Gvpp: nonum[GV#sub[pp]],
  Mvpp: nonum[MV#sub[pp]],
  kvpp: nonum[kV#sub[pp]],
  vpp: nonum[V#sub[pp]],
  mvpp: nonum[mV#sub[pp]],
  uvpp: nonum[#sym.mu\V#sub[pp]],
  nvpp: nonum[nV#sub[pp]],
  pvpp: nonum[pV#sub[pp]],

  // Volt dc
  Tvdc: nonum[TV#sub[dc]],
  Gvdc: nonum[GV#sub[dc]],
  Mvdc: nonum[MV#sub[dc]],
  kvdc: nonum[kV#sub[dc]],
  vdc: nonum[V#sub[dc]],
  mvdc: nonum[mV#sub[dc]],
  uvdc: nonum[#sym.mu\V#sub[dc]],
  nvdc: nonum[nV#sub[dc]],
  pvdc: nonum[pV#sub[dc]],

  // Farad
  Tf: nonum[TF],
  Gf: nonum[GF],
  Mf: nonum[MF],
  kf: nonum[kF],
  f: nonum[F],
  mf: nonum[mF],
  uf: nonum[#sym.mu\F],
  nf: nonum[nF],
  pf: nonum[pF],


  // Ohm
  To: nonum[T#sym.Omega],
  Go: nonum[G#sym.Omega],
  Mo: nonum[M#sym.Omega],
  ko: nonum[k#sym.Omega],
  o: nonum[#sym.Omega],
  mo: nonum[m#sym.Omega],
  uo: nonum[#sym.mu#sym.Omega],
  no: nonum[n#sym.Omega],
  po: nonum[p#sym.Omega],

  // Henry
  Th: nonum[TH],
  Gh: nonum[GH],
  Mh: nonum[MH],
  kh: nonum[kH],
  h: nonum[H],
  mh: nonum[mH],
  uh: nonum[#sym.mu\H],
  nh: nonum[nH],
  ph: nonum[pH],

  // Amp
  Ta: nonum[TA],
  Ga: nonum[GA],
  Ma: nonum[MA],
  ka: nonum[kA],
  a: nonum[A],
  ma: nonum[mA],
  ua: nonum[#sym.mu\A],
  na: nonum[nA],
  pa: nonum[pA],

  // Hertz
  Thz: nonum[THz],
  Ghz: nonum[GHz],
  Mhz: nonum[MHz],
  khz: nonum[kHz],
  hz: nonum[Hz],
  mhz: nonum[mHz],
  uhz: nonum[#sym.mu\Hz],
  nhz: nonum[nHz],
  phz: nonum[pHz],
)

// For usage everywhere but ztables
#let u = (
  // Volt
  Tv: [TV],
  Gv: [GV],
  Mv: [MV],
  kv: [kV],
  v: [V],
  mv: [mV],
  uv: [#sym.mu\V],
  nv: [nV],
  pv: [pV],

  // Volt rms
  Tvrms: [TV#sub[rms]],
  Gvrms: [GV#sub[rms]],
  Mvrms: [MV#sub[rms]],
  kvrms: [kV#sub[rms]],
  vrms: [V#sub[rms]],
  mvrms: [mV#sub[rms]],
  uvrms: [#sym.mu\V#sub[rms]],
  nvrms: [nV#sub[rms]],
  pvrms: [pV#sub[rms]],

  // Volt peak
  Tvp: [TV#sub[p]],
  Gvp: [GV#sub[p]],
  Mvp: [MV#sub[p]],
  kvp: [kV#sub[p]],
  vp: [V#sub[p]],
  mvp: [mV#sub[p]],
  uvp: [#sym.mu\V#sub[p]],
  nvp: [nV#sub[p]],
  pvp: [pV#sub[p]],

  // Volt p to p
  Tvpp: [TV#sub[pp]],
  Gvpp: [GV#sub[pp]],
  Mvpp: [MV#sub[pp]],
  kvpp: [kV#sub[pp]],
  vpp: [V#sub[pp]],
  mvpp: [mV#sub[pp]],
  uvpp: [#sym.mu\V#sub[pp]],
  nvpp: [nV#sub[pp]],
  pvpp: [pV#sub[pp]],

  // Volt dc
  Tvdc: [TV#sub[dc]],
  Gvdc: [GV#sub[dc]],
  Mvdc: [MV#sub[dc]],
  kvdc: [kV#sub[dc]],
  vdc: [V#sub[dc]],
  mvdc: [mV#sub[dc]],
  uvdc: [#sym.mu\V#sub[dc]],
  nvdc: [nV#sub[dc]],
  pvdc: [pV#sub[dc]],

  // Farad
  Tf: [TF],
  Gf: [GF],
  Mf: [MF],
  kf: [kF],
  f: [F],
  mf: [mF],
  uf: [#sym.mu\F],
  nf: [nF],
  pf: [pF],


  // Ohm
  To: [T#sym.Omega],
  Go: [G#sym.Omega],
  Mo: [M#sym.Omega],
  ko: [k#sym.Omega],
  o: [#sym.Omega],
  mo: [m#sym.Omega],
  uo: [#sym.mu#sym.Omega],
  no: [n#sym.Omega],
  po: [p#sym.Omega],

  // Henry
  Th: [TH],
  Gh: [GH],
  Mh: [MH],
  kh: [kH],
  h: [H],
  mh: [mH],
  uh: [#sym.mu\H],
  nh: [nH],
  ph: [pH],

  // Amp
  Ta: [TA],
  Ga: [GA],
  Ma: [MA],
  ka: [kA],
  a: [A],
  ma: [mA],
  ua: [#sym.mu\A],
  na: [nA],
  pa: [pA],

  // Hertz
  Thz: [THz],
  Ghz: [GHz],
  Mhz: [MHz],
  khz: [kHz],
  hz: [Hz],
  mhz: [mHz],
  uhz: [#sym.mu\Hz],
  nhz: [nHz],
  phz: [pHz],

  // Watt
  Tw: [TW],
  Gw: [GW],
  Mw: [MW],
  kw: [kW],
  w: [W],
  mw: [mW],
  uw: [#sym.mu\W],
  nw: [nW],
  pw: [pW],

  // Sec
  Ts: [Ts],
  Gs: [Gs],
  Ms: [Ms],
  ks: [ks],
  s: [s],
  ms: [ms],
  us: [#sym.mu\s],
  ns: [ns],
  ps: [ps],
)

#let blackcell = table.cell(
  fill: black,
)[]
